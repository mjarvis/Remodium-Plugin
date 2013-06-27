//
//  AIContactList+Remodium.m
//  Remodium
//
//  Created by Malcolm on 2013-04-22.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "AIContactList+Remodium.h"

@implementation AIContactList (Remodium)

- (NSDictionary *)blb_dictionaryRepresentation
{
    NSDictionary *dictionary = @{
                                 @"contents": [self.visibleContainedObjects valueForKey:@"blb_dictionaryRepresentation"] ?: @[],
                                 };
    
    return dictionary;
}

@end
