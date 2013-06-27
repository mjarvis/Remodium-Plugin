//
//  BLBPreferencesWindowController.m
//  Remodium
//
//  Created by Malcolm on 13-04-28.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "BLBPreferencesWindowController.h"
#import "BLBPreferencesWindow.h"

NSString *BLBRemodiumPushShouldContainMessageKey = @"BLBRemodiumPushShouldContainMessageKey"

@interface BLBPreferencesWindowController () <BLBPreferencesWindowDelegate>

@property (nonatomic, assign) BOOL pushShouldContainMessage;

@end

@implementation BLBPreferencesWindowController

- (void)loadWindow
{
    self.window = [[BLBPreferencesWindow alloc] blb_initWithBlock:^(BLBPreferencesWindow *window) {
        
        window.delegate = self;
        [window.pushButton highlight:self.pushShouldContainMessage];
    }];
}

- (void)windowDidLoad
{
    // whoo
}

#pragma mark - Public -

- (void)display
{
    [self.window makeKeyAndOrderFront:self.window];
}

#pragma mark - Setters -

- (void)setPushShouldContainMessage:(BOOL)pushShouldContainMessage
{
    [[NSUserDefaults standardUserDefaults] setBool:pushShouldContainMessage
                                            forKey:BLBRemodiumPushShouldContainMessageKey];
}

#pragma mark - Getters -

- (BOOL)pushShouldContainMessage
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:BLBRemodiumPushShouldContainMessageKey];
}

@end
