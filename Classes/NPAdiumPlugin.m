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
	
	[[TCMPortMapper sharedInstance] addPortMapping:[TCMPortMapping portMappingWithLocalPort:11300 
																		desiredExternalPort:11300 
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
	
	// Messages sent for Queue
	[notificationCenter addObserver:self selector:@selector(messageSentFromAdium:) name:CONTENT_MESSAGE_SENT object:nil];
	
	[notificationCenter addObserver:self selector:@selector(statusDidChange:) name:AIStatusActiveStateChangedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(statusDidChange:) name:AIStatusStateArrayChangedNotification object:nil];
	
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

- (void) statusDidChange: (id) sender
{
	if ([[[[adium statusController] activeStatusState] title] rangeOfString:@"Push" options:NSCaseInsensitiveSearch].location != NSNotFound)
		push = YES;
	else
		push = NO;
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
	
	NSAttributedString *nonMutableString = (NSAttributedString *)[[[sender userInfo] valueForKey:@"AIContentObject"] message];
	NSMutableString *string = [[NSMutableString alloc] init];
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	do {
		NSDictionary *results = [nonMutableString attributesAtIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
		if ([results objectForKey:NSAttachmentAttributeName])
			[string appendString:[[results objectForKey:NSAttachmentAttributeName] string]];
		else
			[string appendString:[[nonMutableString attributedSubstringFromRange:effectiveRange] string]];
	} while (NSMaxRange(effectiveRange) < [nonMutableString length]);
	
	/* NSArray Indexes:
	 0: Who the message is to
	 1: The message itself
	 2: The Alias of the destination
	 3: The Time it was sent at
	 4: The Alias of the source
	 */
	NSArray * msgArray = [NSArray arrayWithObjects:
						  [[[sender object] parentContact] internalObjectID],
						  string,
						  [[[sender object] parentContact] displayName],
						  [formatter stringFromDate:[[[sender userInfo] valueForKey:@"AIContentObject"] date]],
						  [[[[sender object] parentContact] account] displayName],
						  nil];
	
	[formatter release];
	[string release];
	
	[[messageQueueController messageQueue:[[[sender object] parentContact] internalObjectID]] addMessage:msgArray
																								  ofType:NPAMessageSentFromMac
																						withRemoteStatus:iPhoneAppIsOpen
																							   skipQueue:NO];
}

// Receiving messages
- (void) messageReceived: (id) sender
{
	//if (!DEPLOY)
	//	NSLog(@"Message received: %@ - %@", [[sender object] UID], [(NSAttributedString *)[[[sender userInfo] valueForKey:@"AIContentObject"] message] string]);

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	
	NSAttributedString *nonMutableString = (NSAttributedString *)[[[sender userInfo] valueForKey:@"AIContentObject"] message];
	NSMutableString *string = [[NSMutableString alloc] init];
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	do {
		NSDictionary *results = [nonMutableString attributesAtIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
		if ([results objectForKey:NSAttachmentAttributeName])
			[string appendString:[[results objectForKey:NSAttachmentAttributeName] string]];
		else
			[string appendString:[[nonMutableString attributedSubstringFromRange:effectiveRange] string]];
	} while (NSMaxRange(effectiveRange) < [nonMutableString length]);
	
	/* NSArray Indexes:
	 0: Who the message is from
	 1: The message itself (NSString)
	 2: The Alias of the sender
	 3: The Time it was sent at
	 */
	NSArray * msgArray = [NSArray arrayWithObjects:
							[[[sender object] parentContact] internalObjectID],
							string, 
							[[[sender object] parentContact] displayName],
							[formatter stringFromDate:[[[sender userInfo] valueForKey:@"AIContentObject"] date]],
							nil];
	
	[formatter release];
	[string release];
	
	[[messageQueueController messageQueue:[[[sender object] parentContact] internalObjectID]] addMessage:msgArray
																								  ofType:NPAMessageReceivedOnMac
																						withRemoteStatus:iPhoneAppIsOpen
																							   skipQueue:NO];
	
	if (!iPhoneAppIsOpen && push)
		[NSThread detachNewThreadSelector:@selector(push:) toTarget:[NPRemodium class] withObject:[[[sender object] parentContact] displayName]];
}

// Send a message to a contact using only information we pass to and from the iPhone
+ (void) sendMessage:(NSString *) message toContact: (NSString *) contactInternalID
{
	AIListObject *destinationContact = [[adium contactController] existingListObjectWithUniqueID:contactInternalID];
	AIChat *chat = [[adium chatController] chatWithContact:(AIListContact *)destinationContact];
	
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
			break;
		case NPAMessagesRequest:
			// Send any queued messages!
			[messageQueueController sendMessageQueues];
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
