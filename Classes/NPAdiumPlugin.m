//
//  NPAdiumPlugin.m
//  Remodium
//
//  Created by Malcolm on 28/01/10.
//  Copyright 2011 Boolable.
//

/*
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "NPAdiumPlugin.h"
#import "NPPairCodeEntry.h"

@implementation NPAdiumPlugin

- (void)installPlugin
{
	// Port Mapping
	// Map the port.. we should really register for some notifications to make sure it forwards okay.
	
	[[TCMPortMapper sharedInstance] addPortMapping:[TCMPortMapping portMappingWithLocalPort:[NPRemodium port] 
																		desiredExternalPort:[NPRemodium port]
																		  transportProtocol:TCMPortMappingTransportProtocolTCP
																				   userInfo:nil]];
	
	services = [[NSMutableArray alloc] init];
	searching = NO;
	
	[self addMenuItems];
	[self startNetServiceBrowser:nil];
	[self addPluginObservers];
	
	messageQueueController = [NPRemodium messageQueueController];
	
	[[TCMPortMapper sharedInstance] start];
	
	[self statusDidChange:nil];

	[NPRemodium publishToServer];
	
	[[adium contactAlertsController] registerActionID:@"Remodium" withHandler:self];
	
	/*{// Build our stuff!
		// Build online contact list
		// Build open chats
		if (!DEPLOY)
			NSLog(@"NP Open Chats: %@", [[adium chatController] openChats]);
	}*/
	NSLog(@"NP Remodium Plugin Loaded!");
}

- (void) uninstallPlugin
{
	
	[[TCMPortMapper sharedInstance] stopBlocking];
	
	[services release];
	 
	[self removePluginObservers];
	[messageQueueController release];
}

- (void) addPluginObservers
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	// Chats opening / closing for Queue
	[notificationCenter addObserver:self selector:@selector(chatDidOpen:) name:Chat_DidOpen object:nil];
	[notificationCenter addObserver:self selector:@selector(chatDidClose:) name:Chat_WillClose object:nil];
	
	// Messages Received for PUSH
	[notificationCenter addObserver:self selector:@selector(messageReceived:) name:CONTENT_MESSAGE_RECEIVED object:nil];
	[notificationCenter addObserver:self selector:@selector(messageReceivedGroup:) name:CONTENT_MESSAGE_RECEIVED_GROUP object:nil];
	
	// Messages sent for Queue
	[notificationCenter addObserver:self selector:@selector(messageSentFromAdium:) name:CONTENT_MESSAGE_SENT object:nil];
	
	[notificationCenter addObserver:self selector:@selector(statusDidChange:) name:AIStatusActiveStateChangedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(statusArrayDidChange:) name:AIStatusStateArrayChangedNotification object:nil];
	
	// Messages from the socket
	[notificationCenter addObserver:self selector:@selector(iPhoneAppDidOpen:) name:NPSocketConnectionDidOpenNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(iPhoneAppDidClose:) name:NPSocketConnectionDidCloseNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(socketMessageReceived:) name:NPSocketMessageReceivedNotifiation object:nil];
}

- (void) removePluginObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Activity
- (void) iPhoneAppDidOpen: (id) sender
{
	iPhoneAppIsOpen = YES;
	

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	// Accounts
	[notificationCenter addObserver:self selector:@selector(accountConnected:) name:ACCOUNT_CONNECTED object:nil];
	[notificationCenter addObserver:self selector:@selector(accountDisconnected:) name:ACCOUNT_DISCONNECTED object:nil];

	// Status Changes
	[notificationCenter addObserver:self selector:@selector(contactSignsOn:) name:CONTACT_STATUS_ONLINE_YES object:nil];
	[notificationCenter addObserver:self selector:@selector(contactSignsOff:) name:CONTACT_STATUS_ONLINE_NO object:nil];
	[notificationCenter addObserver:self selector:@selector(contactStatusDidChange:) name:CONTACT_STATUS_AWAY_YES object:nil];
	[notificationCenter addObserver:self selector:@selector(contactStatusDidChange:) name:CONTACT_STATUS_AWAY_NO object:nil];

	[notificationCenter addObserver:self selector:@selector(contactStatusDidChange:) name:CONTACT_STATUS_IDLE_YES object:nil];
	[notificationCenter addObserver:self selector:@selector(contactStatusDidChange:) name:CONTACT_STATUS_IDLE_NO object:nil];
		 
	// Messages
	//[notificationCenter addObserver:self selector:@selector(messageSentFromAdium:) name:CONTENT_MESSAGE_SENT object:nil];
	//[notificationCenter addObserver:self selector:@selector(messageReceived:) name:CONTENT_MESSAGE_RECEIVED object:nil];

	if (!DEPLOY)
		NSLog(@"NP iPhone App did Open");
}

- (void) iPhoneAppDidClose: (id) sender
{
	iPhoneAppIsOpen = NO;
	[self removePluginObservers];
	[self addPluginObservers];
	
	if (!DEPLOY)
		NSLog(@"NP iPhone App did Close");
}

#pragma mark -
#pragma mark Status

- (void) statusDidChange: (id) sender
{
	NSLog(@"Status changed");
	
	if ([[[[adium statusController] activeStatusState] title] rangeOfString:@"Push" options:NSCaseInsensitiveSearch].location != NSNotFound)
		push = YES;
	else
		push = NO;
	
	if (iPhoneAppIsOpen)
	{
		AIStatus *status = [[adium statusController] activeStatusState];
		NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[status uniqueStatusID], [status title], [NSNumber numberWithInt:[status statusType]], nil]
														 forKeys:[NSArray arrayWithObjects:@"ID", @"Title", @"Type", nil]];
		
		[messageQueueController.rootQueue addMessage:dict ofType:NPAStatusDidChange withRemoteStatus:iPhoneAppIsOpen skipQueue:NO];
	}
	
}

- (void) statusArrayDidChange: (id) sender
{
	NSLog(@"Status array changed");
	
	NSMutableSet *set = [[NSMutableSet alloc] initWithCapacity:[[[adium statusController] sortedFullStateArray] count]];
	
	for (AIStatus *status in [[adium statusController] sortedFullStateArray])
	{
		[set addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[status uniqueStatusID], [status title], [NSNumber numberWithInt:[status statusType]], nil]
												   forKeys:[NSArray arrayWithObjects:@"ID", @"Title", @"Type", nil]]];
	}
	
	[messageQueueController.rootQueue addMessage:[set autorelease]
										  ofType:NPAStatusList
								withRemoteStatus:iPhoneAppIsOpen
									   skipQueue:NO];
}

- (void) changeStatus: (NSNumber *) statusUniqueID
{
	AIStatus *status = [adium.statusController statusStateWithUniqueStatusID:statusUniqueID];
	[adium.statusController setActiveStatusState:status];
}

#pragma mark -
#pragma mark Application Notifications
- (void) applicationDidFinishLoading: (id) sender
{
	if (!DEPLOY)
		NSLog(@"Application Did Finish Loading");
}

#pragma mark -
#pragma mark Account Changes
- (void) accountConnected: (id) sender
{
	if (!DEPLOY)
		NSLog(@"NP Account Connected: %@", [[sender object] UID]);
	
	[messageQueueController.rootQueue addMessage:[NPAdiumPlugin visibleContactsByGroup] ofType:NPAContactList withRemoteStatus:iPhoneAppIsOpen skipQueue:YES];
}

- (void) accountDisconnected: (id) sender
{
	[messageQueueController.rootQueue addMessage:[NPAdiumPlugin visibleContactsByGroup] ofType:NPAContactList withRemoteStatus:iPhoneAppIsOpen skipQueue:YES];
}

#pragma mark -
#pragma mark Contact Status Changes
+ (NSNumber *) statusTypeAsNSNumber: (AIStatusType) statusType
{
	switch (statusType) {
		case AIAvailableStatusType:
			return [NSNumber numberWithInt:AIAvailableStatusType];
			break;
		case AIAwayStatusType:
			return [NSNumber numberWithInt:AIAwayStatusType];
			break;
		case AIInvisibleStatusType:
			return [NSNumber numberWithInt:AIInvisibleStatusType];
			break;
		case AIOfflineStatusType:
			return [NSNumber numberWithInt:AIOfflineStatusType];
			break;
		default:
			return [NSNumber numberWithInt:-1];
			break;
	}
}

- (void) contactStatusDidChange: (id) sender
{
	if (!DEPLOY)
		NSLog(@"Contact status changed");
	
	NPMessageQueue *messageQueue = [messageQueueController messageQueue:[[sender object] internalObjectID]];
	[messageQueue addMessage:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[[sender object] internalObjectID],
																  [NPAdiumPlugin statusTypeAsNSNumber:[[[sender object] parentContact] statusType]], nil]
														 forKeys:[NSArray arrayWithObjects:@"ID", @"Status", nil]]
					  ofType:NPAContactStatusDidChange
			withRemoteStatus:iPhoneAppIsOpen
				   skipQueue:NO];
}

- (void) contactSignsOn: (id) sender
{
	if (!DEPLOY)
		NSLog(@"Contact signs on.");
	
	// We should probably build some sort of check for on/off/on or off/on/off sequences while !iPhoneAppIsOpen to save bandwidth
	
	id sObject = [sender object];
	
	NSString *alias;

	// Build the groups into a nice set of dictionarys
	NSMutableSet *groups = [[NSMutableSet alloc] init];
	for (id group in [sObject groups])
	{	
		if ([(NSString *)[group displayName] compare:[NSString stringWithString:ADIUM_ROOT_GROUP_NAME]] == NSOrderedSame)
			alias = [NSString stringWithString:@"Contacts"];
		else
			alias = [group displayName];

		[groups addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[group internalObjectID], alias, nil]
													  forKeys:[NSArray arrayWithObjects:@"ID", @"Alias", nil]]];
	}
	
	NPMessageQueue *messageQueue = [messageQueueController messageQueue:[sObject internalObjectID]];
	[messageQueue addMessage:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[sObject internalObjectID],
																  [[sObject parentContact] displayName],
																  [NPAdiumPlugin statusTypeAsNSNumber:[[sObject parentContact] statusType]],
																  groups, nil]
														 forKeys:[NSArray arrayWithObjects:@"ID", @"Alias", @"Status", @"Groups", nil]]
					  ofType:NPAContactDidSignOn
			withRemoteStatus:iPhoneAppIsOpen
				   skipQueue:NO];
	
	[groups release];
}

- (void) contactSignsOff: (id) sender
{
	if (!DEPLOY)
		NSLog(@"Contact signs off");
	
	[[messageQueueController messageQueue:[[[sender object] parentContact] internalObjectID]] addMessage:[[[sender object] parentContact] internalObjectID]
																								  ofType:NPAContactDidSignOff
																						withRemoteStatus:iPhoneAppIsOpen
																							   skipQueue:NO];
}


#pragma mark -
#pragma mark Messages and Chats
// Chat did open and did close send an AIChat Object.
- (void) chatDidOpen: (id) sender
{
	//[[messageQueueController messageQueue:[[sender object] uniqueChatID]] addMessage:[[sender object] uniqueChatID]
	//																		  ofType:NPAChatDidOpen
	//																withRemoteStatus:iPhoneAppIsOpen
	//																	   skipQueue:YES];
}

- (void) chatDidClose: (id) sender
{
	NSString *internalObjectID = [[[[sender object] listObject] parentContact] internalObjectID];
	// The chat closed, so lets remove all queued messages by releasing the queue
	[messageQueueController removeMessageQueue:internalObjectID];
	[[messageQueueController messageQueue:internalObjectID] addMessage:internalObjectID
																ofType:NPAChatDidClose
													  withRemoteStatus:iPhoneAppIsOpen
															 skipQueue:NO];
}

// Notifying about sent messages
- (void) messageSentFromAdium: (id) sender
{
	//if (!DEPLOY)
	//	NSLog(@"NP Message Sent: %@", sender);
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	
	AIContentObject *object = [[sender userInfo] valueForKey:@"AIContentObject"];
	NSMutableString *string = [[NSMutableString alloc] init];
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	do {
		NSDictionary *results = [object.message attributesAtIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
		if ([results objectForKey:NSAttachmentAttributeName])
			[string appendString:[[results objectForKey:NSAttachmentAttributeName] string]];
		else
			[string appendString:[[object.message attributedSubstringFromRange:effectiveRange] string]];
	} while (NSMaxRange(effectiveRange) < [object.message length]);
	
	NSString *uniqueID;
	if (object.chat.isGroupChat)
		uniqueID = object.chat.uniqueChatID;
	else
		uniqueID = [[[sender object] parentContact] internalObjectID];
		
	/* NSArray Indexes:
	 0: Who the message is to
	 1: The message itself
	 2: The Alias of the destination
	 3: The Time it was sent at
	 4: The Alias of the source
	 */
	NSArray * msgArray = [NSArray arrayWithObjects:
						  uniqueID,
						  string,
						  (object.chat.isGroupChat) ? object.chat.name : [[[sender object] parentContact] displayName],
						  [formatter stringFromDate:object.date],
						  (object.chat.isGroupChat) ? object.chat.account.displayName : [[[[sender object] parentContact] account] displayName],
						  nil];
	
	[formatter release];
	[string release];
	
	NPMessageQueue *queue = [messageQueueController messageQueue:(object.chat.isGroupChat) ? object.chat.uniqueChatID : [[[sender object] parentContact] internalObjectID]];
	
	[queue addMessage:msgArray
			   ofType:(object.chat.isGroupChat) ? NPAGroupMessageSentFromMac : NPAMessageSentFromMac
	 withRemoteStatus:iPhoneAppIsOpen
			skipQueue:NO];
}

// Receiving messages
- (void) messageReceived: (NSAttributedString *)message inChat: (NSString *) uniqueChatID withTitle: (NSString *) title from: (NSString *) fromAlias atDate: (NSDate *)date
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	
	NSMutableString *string = [[NSMutableString alloc] init];
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	do {
		NSDictionary *results = [message attributesAtIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
		if ([results objectForKey:NSAttachmentAttributeName])
			[string appendString:[[results objectForKey:NSAttachmentAttributeName] string]];
		else
			[string appendString:[[message attributedSubstringFromRange:effectiveRange] string]];
	} while (NSMaxRange(effectiveRange) < [message length]);
	
	/* NSArray Indexes:
	 0: Who the message is from (or which chat)
	 1: The message itself (NSString)
	 2: The Alias of the sender
	 3: The Time it was sent at
	 4: The title/name of the chat [only in group chats]
	 */
	NSArray * msgArray = [NSArray arrayWithObjects:
						  uniqueChatID,
						  string, 
						  fromAlias,
						  [formatter stringFromDate:date],
						  title,
						  nil];
	
	[formatter release];
	[string release];
	
	[[messageQueueController messageQueue:uniqueChatID] addMessage:msgArray
															ofType:(title != nil) ? NPAGroupMessageReceivedOnMac : NPAMessageReceivedOnMac
												  withRemoteStatus:iPhoneAppIsOpen
														 skipQueue:NO];
	
	if (!iPhoneAppIsOpen && push)
		[NSThread detachNewThreadSelector:@selector(push:) toTarget:[NPRemodium class] withObject:fromAlias];
}

- (void) messageReceived: (id) sender
{
	if (!DEPLOY)
		NSLog(@"Message received: %@", [[sender userInfo] valueForKey:@"AIContentObject"]);
	
	[self messageReceived:(NSAttributedString *)[[[sender userInfo] valueForKey:@"AIContentObject"] message]
				   inChat:[[[sender object] parentContact] internalObjectID]
				withTitle:nil
					 from:[[[sender object] parentContact] displayName]
				   atDate:[[[sender userInfo] valueForKey:@"AIContentObject"] date]];
}

- (void) messageReceivedGroup: (id) sender
{
	if (!DEPLOY)
		NSLog(@"Message received: %@", [[[[sender userInfo] valueForKey:@"AIContentObject"] chat] uniqueChatID]);
	
	AIContentObject *object = [[sender userInfo] valueForKey:@"AIContentObject"];
	
	[self messageReceived:(NSAttributedString *)object.message
				   inChat:object.chat.uniqueChatID
				withTitle:object.chat.name
					 from:object.source.displayName
				   atDate:object.date];
}

+ (void) sendMessage:(NSString *) message toChat: (NSString *) uniqueChatID
{
	AIChat *chat = [adium.chatController existingChatWithUniqueChatID:uniqueChatID];
	
	[adium.contentController sendContentObject:[AIContentMessage messageInChat:chat
																	withSource:chat.account
																   destination:chat.listObject
																		  date:[NSDate date]
																	   message:[[[NSAttributedString alloc] initWithString:message] autorelease]
																	 autoreply:NO]];
	
}

// Send a message to a contact using only information we pass to and from the iPhone
+ (void) sendMessage:(NSString *) message toContact: (NSString *) contactInternalID
{
	AIListObject *destinationContact = [[adium contactController] existingListObjectWithUniqueID:contactInternalID];
		
	AIChat *chat;
	if (destinationContact != nil)
		chat = [adium.chatController chatWithContact:(AIListContact *)destinationContact];
	else
		chat = [adium.chatController existingChatWithUniqueChatID:contactInternalID]; // Guess its a group chat!
	
	[[adium contentController] sendContentObject:[AIContentMessage  messageInChat:chat 
																	   withSource:chat.account
																	  destination:chat.listObject
																			 date:[NSDate date] 
																		  message:[[[NSAttributedString alloc] initWithString:message] autorelease]
																		autoreply:NO]];
}


#pragma mark -
#pragma mark Socket Messages
- (void) socketMessageReceived: (id) sender
{
	if (!DEPLOY)
		NSLog(@"NP Dealing with Message Received");
	
	switch ([[[sender object] objectAtIndex:0] unsignedIntValue]) {
		case NPAMessageSentFromiPhone:
			[NPAdiumPlugin sendMessage:[[[sender object] objectAtIndex:1] objectAtIndex:1]
							 toContact:[[[sender object] objectAtIndex:1] objectAtIndex:0]];
			break;
		case NPAContactListRequest:
			[messageQueueController.rootQueue addMessage:[NPAdiumPlugin visibleContactsByGroup] ofType:NPAContactList withRemoteStatus:iPhoneAppIsOpen skipQueue:YES];
			[self statusArrayDidChange:nil];
			[self statusDidChange:nil];
			break;
		case NPAMessagesRequest:
			// Send any queued messages!
			[messageQueueController sendMessageQueues];
			break;
		case NPAStatusDidChange:
			[self changeStatus:[[sender object] objectAtIndex:1]];
			break;
		default:
			break;
	}
}






#pragma mark -
#pragma mark Utility Methods
+ (NSSet *) visibleGroups
{
	NSMutableSet *set = [[NSMutableSet alloc] init];
	
	for (id group in [[[adium contactController] contactList] visibleContainedObjects])
	{
		[set addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[group internalObjectID], [group displayName], nil]
												   forKeys:[NSArray arrayWithObjects:@"ID", @"Alias", nil]]];
	}
	
	NSLog(@"NP Visible Groups: %@", set);
	
	return [set autorelease];
}

+ (NSDictionary *) dictForContact: (id) contact
{	
	NSMutableDictionary *contactDict = [[NSMutableDictionary alloc] init];
	[contactDict setValue:[contact internalObjectID] forKey:@"ID"];
	[contactDict setValue:[[contact parentContact] displayName] forKey:@"Alias"];
	
	// See AIStatusDefines.h for AIStatusType enum ([[contact parentContact] statusType])
	[contactDict setValue:[NPAdiumPlugin statusTypeAsNSNumber:[[contact parentContact] statusType]] forKey:@"Status"];
	
	return [contactDict autorelease];
}

+ (NSArray *) visibleContactsByGroup
{
	if ([[[[adium contactController] contactList] visibleContainedObjects] count] == 0)
	{
		NSLog(@"NP no contacts found in contact list");
		return nil;
	}
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	NSMutableDictionary *outGroup = [[NSMutableDictionary alloc] init];
	[outGroup setValue:ADIUM_ROOT_GROUP_NAME
				forKey:@"ID"];
	[outGroup setValue:@"Contacts"
				forKey:@"Alias"];
	NSMutableArray *outGroupContacts = [[NSMutableArray alloc] init];
	
	for (id object in [[[adium contactController] contactList] visibleContainedObjects])
	{
		if ([[[[[adium contactController] contactList] visibleContainedObjects] objectAtIndex:0] isKindOfClass:[AIListGroup class]])
		{
			NSMutableDictionary *groupContents = [[NSMutableDictionary alloc] init];
			[groupContents setValue:[object internalObjectID]
							 forKey:@"ID"];
			[groupContents setValue:[object displayName]
							 forKey:@"Alias"];
			
			NSMutableArray *contacts = [[NSMutableArray alloc] init];
			
			for (id contact in [object visibleContainedObjects])
				[contacts addObject:[NPAdiumPlugin dictForContact:contact]];
			
			[groupContents setObject:contacts
							  forKey:@"Contents"];
			[contacts release];
			
			[array addObject:groupContents];
			[groupContents release];
		}
		else
		{
			[outGroupContacts addObject:[NPAdiumPlugin dictForContact:object]];
		}
	}
	
	if ([outGroupContacts count] > 0)
	{
		[outGroup setObject:outGroupContacts
					 forKey:@"Contents"];
		[outGroupContacts release];
		[array addObject:outGroup];
		[outGroup release];
	}
	
	return [array autorelease];
}

#pragma mark -
#pragma mark AIActionHandler
/*!
 * @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return @"Send a PUSH Notification to Remodium";
}

/*!
 * @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return @"Send a PUSH Notification to Remodium";
}

/*!
 * @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"Remodium" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIModularPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return nil;
}

/*!
 * @brief Perform an action
 *
 * @param actionID The ID of the action to perform
 * @param listObject The listObject associated with the event triggering the action. It may be nil
 * @param details If set by the details pane when the action was created, the details dictionary for this particular action
 * @param eventID The eventID which triggered this action
 * @param userInfo Additional information associated with the event; userInfo's type will vary with the actionID.
 *
 * @result YES if the action was performed successfully.  If NO, other actions of the same type will be attempted even if allowMultipleActionsWithID: returns NO for eventID.
 */
- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{	
	if ([userInfo respondsToSelector:@selector(objectForKey:)]) {
		AIContentObject *contentObject = [userInfo objectForKey:@"AIContentObject"];
		if (contentObject.source) {
			[NSThread detachNewThreadSelector:@selector(push:) toTarget:[NPRemodium class] withObject:contentObject.source.displayName];

		}
	}
	
	return YES;
}

/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * Example of relevance: An action which plays a sound may return NO so that if the user has sound actions associated
 * with the "Message Received (Initial)" and "Message Received" events will hear the "Message Received (Initial)"
 * sound [which is triggered first] and not the "Message Received" sound when an initial message is received. If this
 * method returned YES, both sounds would be played.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

#pragma mark -
#pragma mark Pairing
- (void) addMenuItems
{
	pairMenu = [[NSMenu alloc] initWithTitle:@"Pairing Menu"];
	
	NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:@"Update List" action:@selector(startNetServiceBrowser:) keyEquivalent:@""];
	[newItem setTarget:self];
	[pairMenu addItem:newItem];
	[newItem release];
	
	NSMenuItem *item = [[NSMenuItem alloc] init];
	[item setTitle:@"Pair with Remodium"];
	[item setSubmenu:pairMenu];
	[item setTarget:self];
	[[adium menuController] addMenuItem:item toLocation:LOC_Adium_About];
}

- (void) pairWithMenuItem: (id) sender
{
	//NSLog(@"NP Pressed menu item! %d", [[sender object] tag]);
	
	//NSLog(@"NP Pressed. %d", [pairMenu indexOfItem:sender]-1);
	
	NPPairCodeEntry *pairCodeEntry = [[NPPairCodeEntry alloc] initWithPlugin:self service:[services objectAtIndex:[pairMenu indexOfItem:sender]-1]];
	[pairCodeEntry showWindow:self];
}

- (void) matchPairingCode: (NSInteger) code withService: (NSNetService *) service
{
	pairCode = code;
	
	[self removePluginObservers];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pairingSocketDidConnect:) name:NPSocketConnectionDidOpenNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pairingSocketDidClose:) name:NPSocketConnectionDidCloseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pairingSocketMessageReceived:) name:NPSocketMessageReceivedNotifiation object:nil];
	
	pairSocket = [[NPSocketConnection alloc] initWithHash:nil];

	pairSocket.port = 11301;
	pairSocket.hostName = [service hostName];
	[pairSocket connect:nil];
}

- (void) pairingSocketDidConnect: (id) sender
{
	if (!DEPLOY)
		NSLog(@"NP Sending message with code: %@", [NSNumber numberWithInt:pairCode]);
	
	if (!DEPLOY)
		NSLog(@"NP hostname: %@", [NSHost currentHost].name);
	
	// Send code to iPhone for verification
	// if it is incorrect nothing happens. we need to change that.
	[pairSocket sendMessage:NO ofType:NPAPairCode withObject:[NSNumber numberWithInt:pairCode]];
}

- (void) pairingSocketDidClose: (id) sender
{
	if (!DEPLOY)
		NSLog(@"NP closing pairing connection");
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self addPluginObservers];
}

- (void) pairingSocketMessageReceived: (id) sender
{
	switch ([[[sender object] objectAtIndex:0] unsignedIntValue]) {
		case NPADeviceID:
			// Code was verified correct on iPhone
			messageQueueController.deviceID = [[sender object] objectAtIndex:1];
			[NPRemodium setDeviceID:[[sender object] objectAtIndex:1]];
			[NPRemodium publishToServer];
			[pairSocket sendMessage:NO ofType:NPAHostName withObject:[NSHost currentHost].name];
			[pairSocket disconnect:nil];
			NSLog(@"NP Did finish pairing");
			[[NSNotificationCenter defaultCenter] removeObserver:self];
			[self addPluginObservers];
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark NetService Methods
// UI update code
- (void)updateUI
{
	// Remove any old items:
	NSMenuItem *item = [pairMenu itemAtIndex: [pairMenu numberOfItems] -1];
	while([item target] == self)
	{
		[pairMenu removeItemAtIndex: [pairMenu numberOfItems] -1];
		if ([pairMenu numberOfItems] > 0)
			item = [pairMenu itemAtIndex: [pairMenu numberOfItems] -1];
		else
			break;
		
	}
	
    if(searching)
    {
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:@"Searching..." action:nil keyEquivalent:@""];
		[newItem setTarget:self];
		[newItem setEnabled:NO];
		[pairMenu addItem:newItem];
		[newItem release];
	}
    else
    {
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:@"Update List" action:@selector(startNetServiceBrowser:) keyEquivalent:@""];
		[newItem setTarget:self];
		[pairMenu addItem:newItem];
		[newItem release];
		
		for (NSNetService *netService in services)
		{
			NSString *title = [[netService hostName] stringByReplacingOccurrencesOfString:@".local." withString:@""];
			newItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(pairWithMenuItem:) keyEquivalent:@""];
			[newItem setTarget:self];
			[pairMenu addItem:newItem];
			[newItem release];
		}
    }
}

- (void) startNetServiceBrowser: (id) sender
{
	if (browser != nil)
		[browser release];
	
	browser = [[NSNetServiceBrowser alloc] init];
	[browser setDelegate:self];
	
	NSLog(@"NP Searching for devices...");
	[browser searchForServicesOfType:@"_remodium._tcp." inDomain:@"local."];
	searching = YES;
	[self updateUI];
}

// Sent when browsing begins
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
    searching = YES;
    [self updateUI];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
			 didNotSearch:(NSDictionary *)errorDict
{
    searching = NO;
	//NSLog(@"NP Error on resolve: %@", [errorDict objectForKey:NSNetServicesErrorCode]);
	[self updateUI];
}

// Sent when browsing stops
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    searching = NO;
    [self updateUI];
}

// Sent when a service appears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	[aNetService retain];
	[aNetService setDelegate:self];
	[aNetService resolveWithTimeout:0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	if ([services indexOfObject:aNetService] != NSNotFound)
		[services removeObject:aNetService];

	[aNetService release];
}

- (void) netServiceDidResolveAddress:(NSNetService *)aService
{
	if ([services indexOfObject:aService] == NSNotFound)
		[services addObject:aService];
	searching = NO;
	[self updateUI];
}

- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict
{
	//NSLog(@"NP Error on resolve: %@", [errorDict objectForKey:NSNetServicesErrorCode]);
}

@end
