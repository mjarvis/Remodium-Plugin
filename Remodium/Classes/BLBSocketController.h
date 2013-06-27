//
//  BLBSocketController.h
//  Remodium
//
//  Created by Malcolm on 2013-04-20.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BLBSocketControllerDidConnectNotification       @"BLBSocketControllerDidConnectNotification"
#define BLBSocketControllerDidDisconnectNotification    @"BLBSocketControllerDidDisconnectNotification"
#define BLBSocketControllerDidLoginNotification         @"BLBSocketControllerDidLoginNotification"

@protocol BLBSocketControllerDelegate <NSObject>

- (id)respondToMessage:(NSString *)message
              contents:(id)contents;

@end

@interface BLBSocketController : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) BOOL authenticated;

@property (nonatomic, weak) id<BLBSocketControllerDelegate> delegate;

+ (BLBSocketController *)sharedController;

- (void)relayMessage:(NSString *)message
            contents:(id)contents
            response:(void(^)(id data))response;

- (void)pushMessage:(NSString *)message
             source:(NSString *)alias;

@end
