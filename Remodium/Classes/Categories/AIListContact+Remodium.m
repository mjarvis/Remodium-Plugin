//
//  AIListContact+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-04-21.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "AIListContact+Remodium.h"
#import "AIStatus+Remodium.h"

@implementation AIListContact (Remodium)

- (NSDictionary *)blb_dictionaryRepresentation
{
    NSDictionary *dictionary = @{
                                 @"type": @"contact",
                                 @"identifier": self.parentContact.internalObjectID,
                                 @"alias": self.parentContact.displayName,
                                 @"status": [AIStatus statusOfType:self.parentContact.statusType].blb_statusTypeString,
                                 };
    
    return dictionary;
}

@end
