//
//  AIListGroup+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-04-21.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "AIListGroup+Remodium.h"

@implementation AIListGroup (Remodium)

- (NSDictionary *)blb_dictionaryRepresentation
{
    NSDictionary *dictionary = @{
                                 @"type": @"group",
                                 @"identifier": self.internalObjectID ? : @"",
                                 @"alias": self.displayName ? : @"",
                                 @"contents": [self.visibleContainedObjects valueForKey:@"blb_dictionaryRepresentation"] ?: @[],
                                 };
    
    return dictionary;
}

@end
