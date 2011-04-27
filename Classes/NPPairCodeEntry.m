//
//  NPPairCodeEntry.m
//  Remodium
//
//  Created by Malcolm on 10-04-11.
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

#import "NPPairCodeEntry.h"
#import "NPAdiumPlugin.h"

@implementation NPPairCodeEntry

- (id) initWithPlugin: (NPAdiumPlugin *) aPlugin service: (NSNetService *) aService
{
	if (![super initWithWindowNibName:@"PairCodeEntry"])
		return nil;
	
	plugin = aPlugin;
	service = aService;

	[pairEntry setAction:@selector(pairSubmit:)];
	[pairEntry setTarget:self];
	
	return self;
}

- (IBAction) pairSubmit: (id) sender
{
	[plugin matchPairingCode:[pairEntry intValue] withService:service];
	[self close];
}

@end
