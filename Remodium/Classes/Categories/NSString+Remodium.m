//
//  NSString+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-08-10.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "NSString+Remodium.h"

@implementation NSString (Remodium)

- (NSString *)blb_sha256String
{
    const char *ptr = [self UTF8String];
    
    unsigned char sha256Buffer[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(ptr, (CC_LONG)strlen(ptr), sha256Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",sha256Buffer[i]];
    
    return output;
}


@end
