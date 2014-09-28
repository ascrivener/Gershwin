//
//  ToneGenerator.h
//  theremin
//
//  Created by Dan Hassin on 9/27/14.
//  Copyright (c) 2014 Dan Hassin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ToneGeneratorWaveTypeSine,
    ToneGeneratorWaveTypeSquare,
    ToneGeneratorWaveTypeSawtooth
} ToneGeneratorWaveType;

@interface ToneGenerator : NSObject

@property double frequency, volume, pan;
@property ToneGeneratorWaveType waveType;

- (void) start;
- (void) terminate;

@end
