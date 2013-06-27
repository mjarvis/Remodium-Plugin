//
//  AIChat+Remodium.h
//  Remodium
//
//  Created by Malcolm on 13-04-21.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Adium/AIChat.h>

@interface AIChat (Remodium)

@property (nonatomic, readonly) NSDictionary *blb_dictionaryRepresentation;

@property (nonatomic, readonly) NSMutableArray *blb_messages;

@end
