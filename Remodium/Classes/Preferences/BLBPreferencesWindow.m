//
//  BLBPreferencesWindow.m
//  Remodium
//
//  Created by Malcolm on 13-04-28.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "BLBPreferencesWindow.h"
#import "NSLayoutConstraint+Remodium.h"

@interface BLBPreferencesWindow ()

@property (nonatomic, strong) NSTextField *emailTextField;
@property (nonatomic, strong) NSSecureTextField *passwordTextField;

@property (nonatomic, strong) NSButton *loginButton;

@property (nonatomic, strong) NSButton *pushButton;
@property (nonatomic, strong) NSTextField *pushLabel;

@property (nonatomic, strong) NSTextField *pushHelpLabel;

@end

@implementation BLBPreferencesWindow

- (id)init
{
    self = [super initWithContentRect:NSMakeRect(0, 0, 400, 300)
                            styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask
                              backing:NSBackingStoreBuffered
                                defer:YES];
    if (self)
    {
        [self center];
        
        [self.contentView addSubview:self.emailTextField];
        [self.contentView addSubview:self.passwordTextField];
        [self.contentView addSubview:self.loginButton];
        [self.contentView addSubview:self.pushButton];
        [self.contentView addSubview:self.pushLabel];
        [self.contentView addSubview:self.pushHelpLabel];
        
        [self constrain];
    }
    return self;
}

- (void)constrain
{
    NSArray *formats = @[
                         @"V:|[email][password][login][push]-(helpSpacing)-[pushHelp]|",
                         @"H:|[push][pushLabel]|",
                         ];
    
    NSDictionary *metrics = @{
                              @"helpSpacing": @(20),
                              };
    
    NSDictionary *views = @{
                            @"email": self.emailTextField,
                            @"password": self.passwordTextField,
                            @"login": self.loginButton,
                            @"push": self.pushButton,
                            @"pushLabel": self.pushLabel,
                            @"pushHelp": self.pushHelpLabel,
                            };
    
    NSArray *constraints = [NSLayoutConstraint blb_constraintsWithVisualFormats:formats
                                                                        metrics:metrics
                                                                          views:views];
    
    [self.contentView addConstraints:constraints];
}

#pragma mark - Overrides -

- (void)setDelegate:(id)delegate
{
    [super setDelegate:delegate];
    
    if ([delegate conformsToProtocol:@protocol(BLBPreferencesWindowDelegate)] == NO)
    {
        self.passwordTextField.target = nil;
        self.loginButton.target = nil;
        self.pushButton.target = nil;
        return;
    }
    
    self.passwordTextField.target = delegate;
    self.passwordTextField.action = @selector(preferencesWindowDidClickLogin);
    
    self.loginButton.target = delegate;
    self.loginButton.action = @selector(preferencesWindowDidClickLogin);
    
    self.pushButton.target = delegate;
    self.pushButton.action = @selector(preferencesWindowDidChangePush);
}

#pragma mark - Getters -

- (NSTextField *)emailTextField
{
    if (_emailTextField == nil)
    {
        _emailTextField = [[NSTextField alloc] blb_initWithBlock:^(NSTextField *textField) {
            
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            [textField.cell setPlaceholderString:NSLocalizedString(@"Email", nil)];
        }];
    }
    return _emailTextField;
}

- (NSSecureTextField *)passwordTextField
{
    if (_passwordTextField == nil)
    {
        _passwordTextField = [[NSSecureTextField alloc] blb_initWithBlock:^(NSSecureTextField *textField) {
            
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            [textField.cell setPlaceholderString:NSLocalizedString(@"Password", nil)];
        }];
    }
    return _passwordTextField;
}

- (NSButton *)loginButton
{
    if (_loginButton == nil)
    {
        _loginButton = [[NSButton alloc] blb_initWithBlock:^(NSButton *button) {
            
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.title = NSLocalizedString(@"Login", nil);
        }];
    }
    return _loginButton;
}

- (NSButton *)pushButton
{
    if (_pushButton == nil)
    {
        _pushButton = [[NSButton alloc] blb_initWithBlock:^(NSButton *button) {
            
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.buttonType = NSSwitchButton;
        }];
    }
    return _pushButton;
}

- (NSTextField *)pushLabel
{
    if (_pushLabel == nil)
    {
        _pushLabel = [[NSTextField alloc] blb_initWithBlock:^(NSTextField *textField) {
            
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            textField.editable = NO;
            textField.bezeled = NO;
            textField.stringValue = NSLocalizedString(@"Show full message in push notifications", nil);
        }];
    }
    return _pushLabel;
}

- (NSTextField *)pushHelpLabel
{
    if (_pushHelpLabel == nil)
    {
        _pushHelpLabel = [[NSTextField alloc] blb_initWithBlock:^(NSTextField *textField) {
            
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            textField.editable = NO;
            textField.bezeled = NO;
            textField.stringValue = NSLocalizedString(@"Push notifications can be enabled by adding an action in Adium Preferences -> Events", nil);
        }];
    }
    return _pushHelpLabel;
}

@end
