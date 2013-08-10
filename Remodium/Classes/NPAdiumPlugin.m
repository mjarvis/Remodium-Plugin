//
//  NPAdiumPlugin.m
//  Remodium
//
//  Created by Malcolm on 2013-04-14.
//  Copyright (c) 2013 Boolable. All rights reserved.
//

#import "NPAdiumPlugin.h"

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIModularPane.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIMenuControllerProtocol.h>

#import "BLBSocketController.h"
#import "BLBMessageDefines.h"
#import "BLBPreferencesWindowController.h"

// Categories
#import "AIChat+Remodium.h"
#import "AIContactList+Remodium.h"
#import "AIContentObject+Remodium.h"
#import "AIListContact+Remodium.h"
#import "AIListGroup+Remodium.h"
#import "AIStatus+Remodium.h"

@interface NPAdiumPlugin () <BLBSocketControllerDelegate, AIActionHandler>

@property (nonatomic, strong) BLBPreferencesWindowController *preferencesWindowController;

@end

@implementation NPAdiumPlugin

- (void)installPlugin
{
    // Add Menu item
	NSMenuItem *item = [[NSMenuItem alloc] blb_initWithBlock:^(NSMenuItem *item) {
        
        item.title = NSLocalizedString(@"Remodium Preferences", nil);
        
        item.target = self;
        item.action = @selector(displayPreferences:);
    }];
	[[adium menuController] addMenuItem:item toLocation:LOC_Adium_About];
    
    // Turn on the socket controller
    [BLBSocketController sharedController].delegate = self;
    
    // Register our event action for push notifications
    [[adium contactAlertsController] registerActionID:@"Remodium"
                                          withHandler:self];
    
    // Add observers for Adium notification
    NSDictionary *notifications = @{
                                    Chat_DidOpen:                           @"chatDidOpen:",
                                    Chat_WillClose:                         @"chatWillClose:",
                                    Chat_AttributesChanged:                 @"chatAttributesChanged:",
                                    
                                    CONTENT_MESSAGE_SENT:                   @"contentAdded:",
                                    CONTENT_MESSAGE_RECEIVED:               @"contentAdded:",
                                    CONTENT_MESSAGE_SENT_GROUP:             @"contentAdded:",
                                    CONTENT_MESSAGE_RECEIVED_GROUP:         @"contentAdded:",
                                    
                                    AIStatusActiveStateChangedNotification: @"activeStatusChanged:",
                                    AIStatusStateArrayChangedNotification:  @"statusArrayChanged:",
                                    
                                    CONTACT_STATUS_ONLINE_YES:              @"contactStatusChanged:",
                                    CONTACT_STATUS_ONLINE_NO:               @"contactStatusChanged:",
                                    CONTACT_STATUS_AWAY_YES:                @"contactStatusChanged:",
                                    CONTACT_STATUS_AWAY_NO:                 @"contactStatusChanged:",
                                    CONTACT_STATUS_IDLE_YES:                @"contactStatusChanged:",
                                    CONTACT_STATUS_IDLE_NO:                 @"contactStatusChanged:",
                                    
                                    ACCOUNT_CONNECTED:                      @"accountConnectionChanged:",
                                    ACCOUNT_DISCONNECTED:                   @"accountConnectionChanged:",
                                    };
    
    [notifications enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        
        SEL selector = NSSelectorFromString(value);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:selector
                                                     name:key
                                                   object:nil];
    }];
}

- (void)uninstallPlugin
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions -

- (void)displayPreferences:(NSMenuItem *)sender
{
    [self.preferencesWindowController display];
}

#pragma mark - Getters -

- (BLBPreferencesWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        _preferencesWindowController = [[BLBPreferencesWindowController alloc] init];
    }
    return _preferencesWindowController;
}

#pragma mark - Notifications -

- (void)chatDidOpen:(NSNotification *)sender
{
    AIChat *chat = [sender object];
    
    NSDictionary *dictionary = chat.blb_dictionaryRepresentation;
    
    [[BLBSocketController sharedController] relayMessage:BLBMessageKeyChat
                                                contents:dictionary
                                                response:NULL];
}

- (void)chatWillClose:(NSNotification *)sender
{
    AIChat *chat = [sender object];
    
    NSDictionary *dictionary = chat.blb_dictionaryRepresentation;
    
    [[BLBSocketController sharedController] relayMessage:BLBMessageKeyChatClose
                                                contents:dictionary
                                                response:NULL];
}

- (void)chatAttributesChanged:(NSNotification *)sender
{
    NSLog(@"REMODIUM - Chat attributes changed: %@ - %@", [sender object], [sender userInfo]);
}

- (void)contentAdded:(NSNotification *)sender
{
    AIContentObject *contentObject = [sender userInfo][@"AIContentObject"];
    
    NSDictionary *dictionary = contentObject.blb_dictionaryRepresentation;
    
    [[BLBSocketController sharedController] relayMessage:BLBMessageKeyMessage
                                                contents:dictionary
                                                response:NULL];
    
    [contentObject.chat.blb_messages addObject:contentObject];
}

- (void)activeStatusChanged:(NSNotification *)sender
{
    AIStatus *status = [adium statusController].activeStatusState;
    
    NSDictionary *dictionary = status.blb_dictionaryRepresentation;
    
    [[BLBSocketController sharedController] relayMessage:BLBMessageKeyStatus
                                                contents:dictionary
                                                response:NULL];
}

- (void)statusArrayChanged:(NSNotification *)sender
{
    NSArray *statuses = [adium statusController].sortedFullStateArray;
    
    NSArray *array = [statuses valueForKey:@"blb_dictionaryRepresentation"];
    
    [[BLBSocketController sharedController] relayMessage:BLBMessageKeyStatusList
                                                contents:array
                                                response:NULL];
}

- (void)contactStatusChanged:(NSNotification *)sender
{
    AIListContact *contact = [sender object];
    
    NSDictionary *dictionary = contact.blb_dictionaryRepresentation;
    
    [[BLBSocketController sharedController] relayMessage:BLBMessageKeyContactStatus
                                                contents:dictionary
                                                response:NULL];
}

- (void)accountConnectionChanged:(NSNotification *)sender
{
    AIContactList *contactList = [adium contactController].contactList;
    
    NSDictionary *dictionary = contactList.blb_dictionaryRepresentation;
    
    [[BLBSocketController sharedController] relayMessage:BLBMessageKeyContactList
                                                contents:dictionary
                                                response:NULL];
}

#pragma mark - BLBSocketControllerDelegate -

- (id)respondToMessage:(NSString *)message contents:(id)contents
{
    // Contacts
    if ([message isEqualToString:BLBMessageKeyContactList])
    {
        return [adium contactController].contactList.blb_dictionaryRepresentation;
    }
    
    // Statuses
    else if ([message isEqualToString:BLBMessageKeyStatusList])
    {
        NSArray *statuses = [[adium statusController].sortedFullStateArray valueForKey:@"blb_dictionaryRepresentation"];
        
        return statuses ?: @[];
    }
    else if ([message isEqualToString:BLBMessageKeyStatus])
    {
        AIStatus *status = [adium.statusController statusStateWithUniqueStatusID:contents[@"identifier"]];
        [adium.statusController setActiveStatusState:status];
    }
    
    // Chats
    else if ([message isEqualToString:BLBMessageKeyChatList])
    {
        NSArray *chats = [[[adium chatController].openChats valueForKey:@"blb_dictionaryRepresentation"] allObjects];
        
        return chats ?: @[];
    }
    else if ([message isEqualToString:BLBMessageKeyChatMessages])
    {
        NSString *chatIdentifier = contents[@"chat"][@"identifier"];
        NSNumber *index = contents[@"range"][@"index"];
        NSNumber *length = contents[@"range"][@"length"];
        NSRange range = NSMakeRange([index unsignedIntegerValue], [length unsignedIntegerValue]);
        
        AIChat *chat = [[adium chatController] existingChatWithUniqueChatID:chatIdentifier];
        
        NSArray *messages = [[chat.blb_messages subarrayWithRange:range] valueForKey:@"blb_dictionaryRepresentation"];
        
        return messages ?: @[];
    }
    else if ([message isEqualToString:BLBMessageKeyChat])
    {
        NSString *contactIdentifier = contents[@"contact"][@"identifier"];
        
        AIListContact *contact = (AIListContact *)[[adium contactController] existingListObjectWithUniqueID:contactIdentifier];
        
        AIChat *chat = [[adium chatController] openChatWithContact:contact onPreferredAccount:YES];
        
        return chat.blb_dictionaryRepresentation;
    }
    else if ([message isEqualToString:BLBMessageKeyChatClearUnread])
    {
        NSString *chatIdentifier = contents[@"chat"][@"identifier"];
        
        AIChat *chat = [[adium chatController] existingChatWithUniqueChatID:chatIdentifier];
        
        [chat clearUnviewedContentCount];
        
        return chat.blb_dictionaryRepresentation;
    }
    
    // Messages
    else if ([message isEqualToString:BLBMessageKeyMessage])
    {
        NSString *chatIdentifier = contents[@"chat"];
        
        AIChat *chat = [[adium chatController] existingChatWithUniqueChatID:chatIdentifier];
        
        if (chat == nil)
        {
            return nil;
        }
        
        AIContentMessage *message = [AIContentMessage messageInChat:chat
                                                         withSource:chat.account
                                                        destination:chat.listObject
                                                               date:[NSDate date] // TODO: Possibly use device sent time
                                                            message:[[NSAttributedString alloc] initWithString:contents[@"message"]]
                                                          autoreply:NO];
        
        [[adium contentController] sendContentObject:message];
    }
    
    return nil;
}

#pragma mark - AIActionHandler -

- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return NSLocalizedString(@"Send a PUSH Notification to Remodium", nil);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return NSLocalizedString(@"Send a PUSH Notification to Remodium", nil);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"Remodium" forClass:[self class]];
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
    // TODO: Add details pane for choosing to include message or not
	return nil;
}

- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	if ([userInfo respondsToSelector:@selector(objectForKey:)] == NO)
    {
        return NO;
    }
    
    AIContentObject *contentObject = userInfo[@"AIContentObject"];
    if (contentObject.source)
    {
        BOOL shouldContainMessage = [[NSUserDefaults standardUserDefaults] boolForKey:BLBRemodiumPushShouldContainMessageKey];
//        [[BLBSocketController sharedController] pushMessage:<#(NSString *)#>
//                                                     source:<#(NSString *)#>]
        // TODO: Tell server to send push notification
    }
	
	return YES;
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

@end
