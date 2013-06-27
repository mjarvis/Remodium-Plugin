//
//  NSObject+Remodium.h
//  Remodium
//
//  Created by Malcolm on 13-04-28.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Remodium)

- (id)blb_initWithBlock:(void(^)(id object))block;

@end
