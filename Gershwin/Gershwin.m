//
// Gershwin
// 
// Created by Nicole Giggey, Dan Hassin, and Adam Scrivener on 9/28/2014
// Copyright (c) 2014 Nicole Giggey. All rights reserved.
//
//


#import "Gershwin.h"
#import "ToneGenerator.h"

#import "AppDelegate.h"

@implementation Gershwin
{
    LeapController *controller;
    NSArray *fingerNames;
    NSArray *boneNames;
    
    NSView *bar;
    
    ToneGenerator *tone1, *tone2;
    
    BOOL doingGesture;
}

static NSArray *noteNames;

- (id)init
{
    static const NSString *const fingerNamesInit[] = {
        @"Thumb", @"Index finger", @"Middle finger",
        @"Ring finger", @"Little finger"
    };
    static const NSString *const boneNamesInit[] = {
        @"Metacarpal", @"Proximal phalanx",
        @"Intermediate phalanx", @"Distal phalanx"
    };

    if ((self = [super init])) {
        fingerNames = [[NSArray alloc] initWithObjects:fingerNamesInit count:5];
        boneNames = [[NSArray alloc] initWithObjects:boneNamesInit count:4];
        
        bar = [(AppDelegate *)[NSApplication sharedApplication].delegate bar];
        
        tone1 = [[ToneGenerator alloc] init];
        tone2 = [[ToneGenerator alloc] init];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            noteNames = @[@"G#",@"A",@"A#",@"B",@"C",@"C#",@"D",@"D#",@"E",@"F",@"F#",@"G"];
        });
    }
    return self;
}

- (void)run
{
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    NSLog(@"running");
    
    [tone1 start];
    [tone2 start];
}

#pragma mark - SampleListener Callbacks

- (void)onInit:(NSNotification *)notification
{
    NSLog(@"Initialized");
}

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Connected");
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification
{
    //Note: not dispatched when running in a debugger.
    NSLog(@"Disconnected");
}

- (void)onServiceConnect:(NSNotification *)notification
{
    NSLog(@"Service Connected");
}

- (void)onServiceDisconnect:(NSNotification *)notification
{
    NSLog(@"Service Disconnected");
}

- (void)onDeviceChange:(NSNotification *)notification
{
    NSLog(@"Device Changed");
}

- (void)onExit:(NSNotification *)notification
{
    NSLog(@"Exited");
}

- (void) updateTone:(ToneGenerator *)tg withLabel:(NSTextField *)label pointer:(NSBox *)pointer fromVector:(LeapVector *)vector
{
    int right_high = 200;
    int right_low = -200;
    int vol_high = 300;
    int vol_low = -50;
    int note_high = 64;
    int note_low = 28;
    int pan_left = 50;
    int pan_right = -50;
    
    if (tg.waveType == ToneGeneratorWaveTypeSawtooth) {
        note_low = 4;
        note_high = 28;
    }
    
    if (isinf(vector.x) || isinf(vector.y) || isinf(vector.z) || !vector) {
        tg.volume = 0;
        label.hidden = YES;
        pointer.hidden = YES;
    }
    else {
        label.hidden = NO;
        pointer.hidden = NO;
        
        double x = ((MIN(MAX(vector.x, right_low), right_high) - right_low) / (right_high - right_low));
        double y = ((MIN(MAX(vector.y, vol_low), vol_high) - vol_low)/(vol_high - vol_low));
        double z = ((MIN(MAX(vector.z, pan_right), pan_left) - pan_right) * 2 / (pan_left - pan_right)) - 1;
        
        double note = (x  * (note_high - note_low) + note_low);
        double freq = pow(2, ((note - 49.0) / 12)) * 440;
        
        tg.frequency = freq;
        tg.volume = y;
        //tg.pan = z;
        
        NSString *name = noteNames[(int)(note + .5)%noteNames.count];
        
        label.stringValue = name;
        
        float bar_pos = (note-note_low)*(bar.frame.size.width)/(note_high-note_low) + bar.frame.origin.x;
        
        pointer.frame = NSMakeRect(bar_pos-2, pointer.frame.origin.y, pointer.frame.size.width, pointer.frame.size.height);
        label.frame = NSMakeRect(bar_pos - 6, pointer.frame.origin.y + 25, 50, 50);
    }
}

- (void)onFrame:(NSNotification *)notification
{
    LeapController *aController = (LeapController *)[notification object];

    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];

    //NSLog(@"Frame id: %lld, timestamp: %lld, hands: %ld, fingers: %ld, tools: %ld, gestures: %ld",
     //     [frame id], [frame timestamp], [[frame hands] count],
     //     [[frame fingers] count], [[frame tools] count], [[frame gestures:nil] count]);

    // Get hands
    LeapVector *left = nil;
    LeapVector *right = nil;
    
    for (LeapHand *hand in frame.hands) {
        
        if (hand.isRight){
            for (LeapFinger *finger in hand.fingers) {
                if (finger.type == LEAP_FINGER_TYPE_INDEX){
                    right = finger.tipPosition;
                }
            }
        }
        
        if (hand.isLeft){
            for (LeapFinger *finger in hand.fingers) {
                if (finger.type == LEAP_FINGER_TYPE_INDEX){
                    left = finger.tipPosition;
                }
            }
        }
    }
    
    NSBox *pointer_r = [(AppDelegate *)[NSApplication sharedApplication].delegate pointer_r];
    NSBox *pointer_l = [(AppDelegate *)[NSApplication sharedApplication].delegate pointer_l];

    NSTextField *label_r = [(AppDelegate *)[NSApplication sharedApplication].delegate label1];
    NSTextField *label_l = [(AppDelegate *)[NSApplication sharedApplication].delegate label2];

    [self updateTone:tone1 withLabel:label_r pointer:pointer_r fromVector:right];
    [self updateTone:tone2 withLabel:label_l pointer:pointer_l fromVector:left];
    
    
    int swipeGestures = 0;
    NSArray *gestures = [frame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        if (gesture.type == LEAP_GESTURE_TYPE_SWIPE) {
            LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
            
            if (fabs(swipeGesture.direction.y) < 0.5) {
                continue;
            }
            
            swipeGestures++;
            if (!doingGesture) {
                doingGesture = YES;

                int direction = (swipeGesture.direction.y > 0) ? 1 : -1;
                
                LeapHand *hand = swipeGesture.hands.firstObject;
                
                NSArray *colors = @[[NSColor blackColor], [NSColor redColor], [NSColor blueColor]];
                
                if (hand.isRight) {
                    tone1.waveType = (tone1.waveType + direction) % 3;
                    if (direction == -1 && tone1.waveType == 0) {
                        tone1.waveType = 2;
                    }
                    
                    label_r.textColor = colors[tone1.waveType];
                } else {
                    tone2.waveType = (tone2.waveType + direction) % 3;
                    if (direction == -1 && tone2.waveType == 0) {
                        tone2.waveType = 2;
                    }

                    label_l.textColor = colors[tone2.waveType];
                }
            }
        }
    }
    
    if (swipeGestures == 0) {
        doingGesture = NO;
    }
    
//        NSLog(@"");
//        NSLog(@"Furthest finger left in right hand is at position %f", x);
//        NSLog(@"Highest finger in left hand is at position %f", min_y);
//        NSLog(@"Freq %.5f   vol %.3f", freq, min_y);

}

- (void)onFocusGained:(NSNotification *)notification
{
    NSLog(@"Focus Gained");
}

- (void)onFocusLost:(NSNotification *)notification
{
    NSLog(@"Focus Lost");
}

+ (NSString *)stringForState:(LeapGestureState)state
{
    switch (state) {
        case LEAP_GESTURE_STATE_INVALID:
            return @"STATE_INVALID";
        case LEAP_GESTURE_STATE_START:
            return @"STATE_START";
        case LEAP_GESTURE_STATE_UPDATE:
            return @"STATE_UPDATED";
        case LEAP_GESTURE_STATE_STOP:
            return @"STATE_STOP";
        default:
            return @"STATE_INVALID";
    }
}

@end
