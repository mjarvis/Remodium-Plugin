//
//  AIChat+Remodium.m
//  Remodium
//
//  Created by Malcolm on 13-04-21.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "AIChat+Remodium.h"
#import "AIListContact+Remodium.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import <objc/runtime.h>

const void *BLBAIChatMessagesKey;

// These are private keys...
#ifndef KEY_TABBAR_SHOW_UNREAD_MENTION_ONLYGROUP
#define KEY_TABBAR_SHOW_UNREAD_MENTION_ONLYGROUP @"Show Unread Mention Count Only in Group Chat Tabs"
#endif

#ifndef PREF_GROUP_DUAL_WINDOW_INTERFACE
#define	PREF_GROUP_DUAL_WINDOW_INTERFACE @"Dual Window Interface"
#endif

@implementation AIChat (Remodium)

- (NSDictionary *)blb_dictionaryRepresentation
{    
    if (self.isGroupChat)
    {
        BOOL showMentions = [[[adium preferenceController] preferenceForKey:KEY_TABBAR_SHOW_UNREAD_MENTION_ONLYGROUP
                                                                      group:PREF_GROUP_DUAL_WINDOW_INTERFACE] boolValue];
        
        NSDictionary *dictionary = @{
                                     @"identifier": self.uniqueChatID,
                                     @"alias": self.name,
                                     @"unreadCount": showMentions ? @(self.unviewedMentionCount) : @(self.unviewedContentCount),
                                     @"contentCount": @([self.blb_messages count]),
                                     @"type": @"groupchat",
                                     };
        
        return dictionary;
    }
    
    NSDictionary *dictionary = @{
                                 @"identifier": self.uniqueChatID,
                                 @"alias": self.name ?: self.listObject.displayName,
                                 @"contact": self.listObject.parentContact.blb_dictionaryRepresentation,
                                 @"unreadCount": @(self.unviewedContentCount),
                                 @"contentCount": @([self.blb_messages count]),
                                 @"type": @"chat",
                                 };
    
    return dictionary;
}

- (NSMutableArray *)blb_messages
{
    NSMutableArray *array = objc_getAssociatedObject(self, BLBAIChatMessagesKey);
    
    if (array == nil)
    {
        array = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, BLBAIChatMessagesKey, array, OBJC_ASSOCIATION_RETAIN);
    }
    
    return array;
}

@end
