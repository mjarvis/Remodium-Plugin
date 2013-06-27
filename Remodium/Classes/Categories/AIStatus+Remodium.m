//
//  AIStatus+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-04-27.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "AIStatus+Remodium.h"

@implementation AIStatus (Remodium)

- (NSString *)blb_statusTypeString
{
    switch (self.statusType)
    {
        case AIAvailableStatusType: return @"available";
        case AIAwayStatusType:      return @"away";
        case AIInvisibleStatusType: return @"invisible";
        case AIOfflineStatusType:   return @"offline";
    }
    
    return @"";
}

- (NSDictionary *)blb_dictionaryRepresentation
{
    NSDictionary *dictionary = @{
                                 @"identifier": self.uniqueStatusID,
                                 @"title": self.title,
                                 @"type": self.blb_statusTypeString,
                                 };
    
    return dictionary;
}

@end
