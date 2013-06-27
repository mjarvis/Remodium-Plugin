//
//  NSLayoutConstraint+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-04-28.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "NSLayoutConstraint+Remodium.h"

@implementation NSLayoutConstraint (Remodium)

+ (NSArray *)blb_constraintsWithVisualFormats:(NSArray *)formats views:(NSDictionary *)views
{
    return [self blb_constraintsWithVisualFormats:formats metrics:nil views:views];
}

+ (NSArray *)blb_constraintsWithVisualFormats:(NSArray *)formats metrics:(NSDictionary *)metrics views:(NSDictionary *)views
{
    __block NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[formats count]];
    
    [formats enumerateObjectsUsingBlock:^(NSString *constraint, NSUInteger index, BOOL *stop) {
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:constraint
                                                                       options:0
                                                                       metrics:metrics
                                                                         views:views];
        [array addObjectsFromArray:constraints];
    }];
    
    return [[NSArray alloc] initWithArray:array];
}

@end
