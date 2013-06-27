//
//  BLBSocketController.m
//  Remodium
//
//  Created by Malcolm on 2013-04-20.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "BLBSocketController.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"

@interface BLBSocketController () <SocketIODelegate>

@property (nonatomic, strong) SocketIO *socket;

@property (nonatomic, assign) BOOL authenticated;

@end

@implementation BLBSocketController

+ (BLBSocketController *)sharedController
{
    static BLBSocketController *sharedController = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[BLBSocketController alloc] init];
    });
    
    return sharedController;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.socket = [[SocketIO alloc] initWithDelegate:self];
        self.socket.useSecure = NO;
        
        [self connect];
    }
    return self;
}

- (void)connect
{
    if (self.connected)
    {
        return;
    }
    
    [self.socket connectToHost:@"127.0.0.1"
                        onPort:5000];
}

#pragma mark - Public -

- (BOOL)connected
{
    return self.socket.isConnected;
}

- (void)relayMessage:(NSString *)message contents:(id)contents response:(void(^)(id data))response
{
    if (message == nil)
    {
        [NSException raise:@"BLBSocketControllerException"
                    format:@"Message: '%@', contents: '%@'", message, contents];
        return;
    }
    
    if (contents == nil)
    {
        contents = @"";
    }
    
    NSDictionary *data = @{
                           @"message": message,
                           @"contents": contents,
                           };
    
    if (response)
    {
        [self.socket sendEvent:@"relay"
                      withData:data
                andAcknowledge:response];
    }
    else
    {
        [self.socket sendEvent:@"relay"
                      withData:data];
    }
}

- (void)pushMessage:(NSString *)message source:(NSString *)alias
{
    NSDictionary *data = @{
                           @"message": message ?: @"",
                           @"alias": alias ?: @"",
                           };
    
    [self.socket sendEvent:@"push"
                  withData:data];
}

#pragma mark - SocketIODelegate -

- (void)socketIODidConnect:(SocketIO *)socket
{
    NSLog(@"BLBSocketController did connect");
    [[NSNotificationCenter defaultCenter] postNotificationName:BLBSocketControllerDidConnectNotification
                                                        object:self];
    
    NSDictionary *data = @{
                           @"email": @"malcolm@metalabdesign.com",
                           @"password": @"b1946ac92492d2347c6235b4d2611184",
                           @"type": @"server",
                           @"identifier": self.identifier ?: [NSNull null],
                           };
    
    [self.socket sendEvent:@"login"
                  withData:data
            andAcknowledge:^(id data) {
                
                if ([data boolValue] == false)
                {
                    // Did not login
                    self.authenticated = NO;
                }
                else
                {
                    self.authenticated = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:BLBSocketControllerDidLoginNotification
                                                                        object:self];
                }
            }];
    
}

- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"BLBSocketController did disconnect: %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:BLBSocketControllerDidDisconnectNotification
                                                        object:self];
}

- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    if ([packet.name isEqualToString:@"relay"])
    {
        // Relay event!
        NSDictionary *dictionary = [packet.args lastObject];
        
        if (dictionary == nil)
        {
            NSLog(@"BLBSocketController relay with no arguments");
            return;
        }
        
        NSString *message = dictionary[@"message"];
        id contents = dictionary[@"contents"];
        
        id data = [self.delegate respondToMessage:message
                                         contents:contents];
        
        if (data)
        {
            [socket sendAcknowledgement:packet.pId
                               withArgs:@[data]];
        }
    }
}

@end
