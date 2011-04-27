//
//  NPAdiumPlugin.h
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

#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>
#import <Adium/AISharedAdium.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIStatusDefines.h>
#import <Adium/AIStatusItem.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIMetaContact.h>

/*
#import "NPSocketConnection.h"
#import "NPMessageQueueController.h"
#import "NPMessageQueue.h"
#import "NPRemodium.h"
#import <TCMPortMapper/TCMPortMapper.h>

#import "NPMessageDefines.h"
 */
#import <NPRemodium/NPSocketConnection.h>
#import <NPRemodium/NPMessageQueueController.h>
#import <NPRemodium/NPMessageQueue.h>
#import <NPRemodium/NPRemodium.h>
#import <TCMPortMapper/TCMPortMapper.h>

#import <NPRemodium/NPMessageDefines.h>

/*
 * 0 - Log Nothing
 * 1 - Log Everything
 * 2 - Log Important Messages
 */
#define LOGTOCONSOLE 2

@interface NPAdiumPlugin : AIPlugin <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
	BOOL iPhoneAppIsOpen;
	BOOL push;
		
	NPSocketConnection *socket;
	
	NPMessageQueueController *messageQueueController;
	
	NSNetServiceBrowser *browser;
	NSMutableArray *services;
	BOOL searching;
	NSMenu *pairMenu;
	NSInteger pairCode;
	NPSocketConnection *pairSocket;
}

- (void) addPluginObservers;
- (void) removePluginObservers;

- (void) addMenuItems;

- (void) iPhoneAppDidOpen: (id) sender;
- (void) iPhoneAppDidClose: (id) sender;

- (void) statusDidChange: (id) sender;

+ (NSSet *) visibleGroups;
+ (NSArray *) visibleContactsByGroup;

+ (NSNumber *) statusTypeAsNSNumber: (AIStatusType) statusType;

+ (void) sendMessage:(NSString *) message toContact: (NSString *) contactInternalID;

- (void) startNetServiceBrowser: (id) sender;
- (void) matchPairingCode: (NSInteger) code withService: (NSNetService *) service;

@end