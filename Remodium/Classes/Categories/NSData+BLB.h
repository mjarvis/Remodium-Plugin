//
//  NSData+BLB.h
//  Remodium
//
//  Created by Malcolm on 13-08-07.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

@interface NSData (BLB)

- (NSData *)blb_AES256EncryptWithKey:(NSData *)key;
- (NSData *)blb_AES256DecryptWithKey:(NSData *)key;

@end
