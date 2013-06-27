//
//  BLBPreferencesWindow.h
//  Remodium
//
//  Created by Malcolm on 13-04-28.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol BLBPreferencesWindowDelegate <NSObject>

- (void)preferencesWindowDidClickLogin;
- (void)preferencesWindowDidChangePush;

@end

@interface BLBPreferencesWindow : NSWindow

@property (nonatomic, readonly) NSButton *pushButton;

@end
