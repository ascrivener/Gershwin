//
//  ToneGenerator.m
//  theremin
//
//  Created by Dan Hassin on 9/27/14.
//  Copyright (c) 2014 Dan Hassin. All rights reserved.
//
// Adapted from http://stackoverflow.com/questions/14466371/ios-generate-and-play-indefinite-simple-audio-sine-wave
//

#import "ToneGenerator.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>

@interface ToneGenerator ()

@property AudioUnit outputUnit;
@property double renderPhase;

@end

@implementation ToneGenerator

- (void) start
{
    //  First, we need to establish which Audio Unit we want.
    
    //  We start with its description, which is:
    AudioComponentDescription outputUnitDescription = {
        .componentType         = kAudioUnitType_Output,
        .componentSubType      = kAudioUnitSubType_DefaultOutput,
        .componentManufacturer = kAudioUnitManufacturer_Apple
    };
    
    //  Next, we get the first (and only) component corresponding to that description
    AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputUnitDescription);
    
    //  Now we can create an instance of that component, which will create an
    //  instance of the Audio Unit we're looking for (the default output)
    AudioComponentInstanceNew(outputComponent, &_outputUnit);
    AudioUnitInitialize(self.outputUnit);
    
    //  Next we'll tell the output unit what format our generated audio will
    //  be in. Generally speaking, you'll want to stick to sane formats, since
    //  the output unit won't accept every single possible stream format.
    //  Here, we're specifying floating point samples with a sample rate of
    //  44100 Hz in mono (i.e. 1 channel)
    AudioStreamBasicDescription ASBD = {
        .mSampleRate       = 44100,
        .mFormatID         = kAudioFormatLinearPCM,
        .mFormatFlags      = kAudioFormatFlagsNativeFloatPacked|kAudioFormatFlagIsNonInterleaved,
        .mChannelsPerFrame = 2,
        .mFramesPerPacket  = 1,
        .mBitsPerChannel   = sizeof(Float32) * 8,
        .mBytesPerPacket   = sizeof(Float32),
        .mBytesPerFrame    = sizeof(Float32)
    };
    
    AudioUnitSetProperty(_outputUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,
                         &ASBD,
                         sizeof(ASBD));
    
    //  Next step is to tell our output unit which function we'd like it
    //  to call to get audio samples. We'll also pass in a context pointer,
    //  which can be a pointer to anything you need to maintain state between
    //  render callbacks. We only need to point to a double which represents
    //  the current phase of the sine wave we're creating.
    AURenderCallbackStruct callbackInfo = {
        .inputProc       = SineWaveRenderCallback,
        .inputProcRefCon = (__bridge void *)(self)
    };
    
    AudioUnitSetProperty(_outputUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Global,
                         0,
                         &callbackInfo,
                         sizeof(callbackInfo));
    
    //  Here we're telling the output unit to start requesting audio samples
    //  from our render callback. This is the line of code that starts actually
    //  sending audio to your speakers.
    AudioOutputUnitStart(_outputUnit);
}

// This is our render callback. It will be called very frequently for short
// buffers of audio (512 samples per call on my machine).
OSStatus SineWaveRenderCallback(void * inRefCon,
                                AudioUnitRenderActionFlags * ioActionFlags,
                                const AudioTimeStamp * inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList * ioData)
{
    // inRefCon is the context pointer we passed in earlier when setting the render callback
    ToneGenerator *tg = (__bridge ToneGenerator *)(inRefCon);
    double currentPhase = tg.renderPhase;

    // create audio sample
    Float32 * outputBuffer = (Float32 *)malloc(sizeof(Float32)*inNumberFrames);
    const double frequency = tg.frequency;
    const double phaseStep = (frequency / 44100.) * (M_PI * 2.);
    
    for(int i = 0; i < inNumberFrames; i++) {
        if (tg.waveType == ToneGeneratorWaveTypeSine) {
            outputBuffer[i] = sin(currentPhase);
        }
        else if (tg.waveType == ToneGeneratorWaveTypeSquare) {
            outputBuffer[i] = sin(currentPhase) > 0 ? 1 : -1;
        }
        else if (tg.waveType == ToneGeneratorWaveTypeSawtooth) {
            outputBuffer[i] = currentPhase - floor(currentPhase);
        }
        
        currentPhase += phaseStep;
    }

    
    //put it in ioData, per channel
    for(int channel = 0; channel < ioData->mNumberBuffers; channel++) {
        memcpy(ioData->mBuffers[channel].mData, outputBuffer, ioData->mBuffers[channel].mDataByteSize);

        double pan = tg.pan*0.5;
        if (channel == 0) {
            pan *= -1;
        }

        float desiredGain = (0.5+pan)*tg.volume;
        
        if (tg.waveType == ToneGeneratorWaveTypeSquare) {
            desiredGain *= 0.2;
        }
        else if (tg.waveType == ToneGeneratorWaveTypeSawtooth) {
            desiredGain *= 0.45;
        }
        else if (tg.waveType == ToneGeneratorWaveTypeSine) {
            desiredGain *= 1.15;
        }
        
        //apply the gain
        //thanks to http://stackoverflow.com/questions/11573796/audio-unit-recording-increased-volume-of-buffers
        float *rawBuffer = (float *)ioData->mBuffers[channel].mData;
        vDSP_Length frameCount = ioData->mBuffers[channel].mDataByteSize / sizeof(float);
        vDSP_vsmul(rawBuffer, 1, &desiredGain, rawBuffer, 1, frameCount);
    }
    
    free(outputBuffer);
        
    // writing the current phase back to inRefCon so we can use it on the next call
    tg.renderPhase = currentPhase;
    return noErr;
}

- (void) terminate
{
    AudioOutputUnitStop(_outputUnit);
    AudioUnitUninitialize(_outputUnit);
    AudioComponentInstanceDispose(_outputUnit);
}

@end
