//
//  AIContentObject+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-04-21.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "AIContentObject+Remodium.h"
#import "AIChat+Remodium.h"
#import "AIListContact+Remodium.h"

@implementation AIContentObject (Remodium)

- (NSDictionary *)blb_dictionaryRepresentation
{
    NSString *alias = nil;
    if ([self.source isKindOfClass:[AIListContact class]])
    {
        AIListContact *contact = (AIListContact *)self.source;
        alias = contact.parentContact.displayName;
    }
    else
    {
        AIAccount *account = (AIAccount *)self.source;
        alias = account.displayName;
    }
    
    NSMutableString *string = [[NSMutableString alloc] init];
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	
    // Filter out attachments?
	do
    {
		NSDictionary *results = [self.message attributesAtIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
        
		if ([results objectForKey:NSAttachmentAttributeName])
        {
			[string appendString:[[results objectForKey:NSAttachmentAttributeName] string]];
            
            continue;
        }
        
        [string appendString:[[self.message attributedSubstringFromRange:effectiveRange] string]];
	}
    while (NSMaxRange(effectiveRange) < [self.message length]);
    
    NSDictionary *dictionary = @{
                                 @"chat"    : self.chat.uniqueChatID,
                                 @"alias"   : alias,
                                 @"date"    : @([self.date timeIntervalSince1970]),
                                 @"message" : [[NSString alloc] initWithString:string],
                                 @"outgoing": @(self.isOutgoing),
                                 };
    
    return dictionary;
}

@end
