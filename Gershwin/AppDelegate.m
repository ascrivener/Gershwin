//
// Gershwin
//
// Created by Nicole Giggey, Dan Hassin, and Adam Scrivener on 9/28/2014
// Copyright (c) 2014 Nicole Giggey. All rights reserved.
//
//

#import "AppDelegate.h"
#import "Gershwin.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _gershwin = [[Gershwin alloc]init];
    [_gershwin run];
    
    [_label1 removeConstraints:_label1.constraints];
    [_label2 removeConstraints:_label2.constraints];
    [_pointer_l removeConstraints:_pointer_l.constraints];
    [_pointer_r removeConstraints:_pointer_r.constraints];
    [_bar.layer setBackgroundColor:[NSColor greenColor].CGColor];
}

@end
