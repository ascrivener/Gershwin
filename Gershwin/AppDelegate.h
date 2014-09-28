//
// Gershwin
//
// Created by Nicole Giggey, Dan Hassin, and Adam Scrivener on 9/28/2014
// Copyright (c) 2014 Nicole Giggey. All rights reserved.
//
//

#import <Cocoa/Cocoa.h>

@class Gershwin;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong, readwrite) IBOutlet NSWindow *window;
@property (nonatomic, strong, readwrite) Gershwin *gershwin;

@property (nonatomic, strong, readwrite) IBOutlet NSTextField *label1;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField *label2;
@property (nonatomic, strong, readwrite) IBOutlet NSView *bar;
@property (nonatomic, strong, readwrite) IBOutlet NSBox *pointer_l;
@property (nonatomic, strong, readwrite) IBOutlet NSBox *pointer_r;
//@property (nonatomic, strong, readwrite) IBOutlet NSTextField *wave;

@end
