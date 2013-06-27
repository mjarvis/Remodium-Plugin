//
//  NSLayoutConstraint+Remodium.h
//  Remodium
//
//  Created by Malcolm on 13-04-28.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLayoutConstraint (Remodium)

+ (NSArray *)blb_constraintsWithVisualFormats:(NSArray *)formats views:(NSDictionary *)views;
+ (NSArray *)blb_constraintsWithVisualFormats:(NSArray *)formats metrics:(NSDictionary *)metrics views:(NSDictionary *)views;

@end
