/* Interface for host class
   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Written by: Luke Howard <lukeh@xedoc.com.au> 
   Date: 1996
   
   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
   */ 
#ifndef __NSHost_h_GNUSTEP_BASE_INCLUDE
#define __NSHost_h_GNUSTEP_BASE_INCLUDE

#include <Foundation/NSObject.h>

@class NSString, NSArray, NSSet;

@interface NSHost : NSObject
{
  @private
  NSSet	*_names;
  NSSet	*_addresses;
}

/*
 * Get a host object.  Hosts are cached for efficiency.  Only one
 * shared instance of a host will exist.
 * Addresses must be "Dotted Decimal" strings, e.g.
 *
 * NSHost aHost = [NSHost hostWithAddress:@"192.42.172.1"];
 *
 */
+ (NSHost*) currentHost;
+ (NSHost*) hostWithName: (NSString*)name;
+ (NSHost*) hostWithAddress: (NSString*)address;

/*
 * Host cache management
 * If enabled, only one object representing each host will be created, and
 * a shared instance will be returned by all methods that return a host.
 */
+ (void) setHostCacheEnabled: (BOOL)flag;
+ (BOOL) isHostCacheEnabled;
+ (void) flushHostCache;

/*
 * Compare hosts
 * Hosts are equal if they share at least one address
 */
- (BOOL) isEqualToHost: (NSHost*) aHost;

/*
 * Host names.
 * "name" will return one name (arbitrarily chosen) if a host has several.
 */
- (NSString*) name;
- (NSArray*) names;

/*
 * Host addresses.
 * Addresses are represented as "Dotted Decimal" strings, e.g.  @"192.42.172.1"
 * "address" will return one address (arbitrarily chosen) if there are several.
 */
- (NSString*) address;
- (NSArray*) addresses;

@end

@interface NSHost (GNUstep)
+ (NSHost*) localHost;		/* All local IP addresses	*/
@end

#endif
