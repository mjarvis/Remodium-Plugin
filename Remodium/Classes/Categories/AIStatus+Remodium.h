//
//  AIStatus+Remodium.h
//  Remodium
//
//  Created by Malcolm on 13-04-27.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Adium/AIStatus.h>

@interface AIStatus (Remodium)

@property (nonatomic, readonly) NSString *blb_statusTypeString;
@property (nonatomic, readonly) NSDictionary *blb_dictionaryRepresentation;

@end
