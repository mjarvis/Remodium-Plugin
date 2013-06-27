//
//  NSObject+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-04-28.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "NSObject+Remodium.h"

@implementation NSObject (Remodium)

- (id)blb_initWithBlock:(void(^)(id object))block
{
    id object = [self init];
    if (object)
    {
        block(object);
    }
    return object;
}

@end
