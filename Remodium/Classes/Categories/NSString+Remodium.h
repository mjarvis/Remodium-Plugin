//
//  NSString+Remodium.h
//  Remodium
//
//  Created by Malcolm on 13-08-10.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface NSString (Remodium)

- (NSString *)blb_sha256String;

@end
