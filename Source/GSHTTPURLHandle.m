/* GSHTTPURLHandle.m - Class GSHTTPURLHandle
   Copyright (C) 2000 Free Software Foundation, Inc.
   
   Written by: 	Mark Allison <mark@brainstorm.co.uk>
   Integrated:	Richard Frith-Macdonald <rfm@gnu.org>
   Date:	November 2000 		
   
   This file is part of the GNUstep Library.
   
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

#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSData.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSURLHandle.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSByteOrder.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSFileHandle.h>
#include <Foundation/NSDebug.h>
#include <Foundation/GSMime.h>
#include <string.h>

static NSString	*httpVersion = @"1.0";

char emp[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9','+','/'
};
 
@interface GSHTTPURLHandle : NSURLHandle
{
  BOOL			tunnel;
  NSFileHandle          *sock;
  NSURL                 *url;
  NSMutableData         *dat;
  GSMimeParser		*parser;
  GSMimeDocument	*document;
  NSMutableDictionary	*headers;
  NSMutableDictionary   *pageInfo;
  NSMutableDictionary   *wProperties;
  NSMutableDictionary   *request;
  unsigned int          contentLength;
  enum {
    idle,
    connecting,
    writing,
    reading,
  } connectionState;
}
- (NSString*) encodebase64: (NSString*) input;
@end


@implementation GSHTTPURLHandle

static NSMutableDictionary	*urlCache = nil;
static NSLock			*urlLock = nil;

+ (NSURLHandle*) cachedHandleForURL: (NSURL*)newUrl
{
  NSURLHandle	*obj = nil;

  if ([[newUrl scheme] caseInsensitiveCompare: @"http"] == NSOrderedSame
    || [[newUrl scheme] caseInsensitiveCompare: @"https"] == NSOrderedSame)
    {
      NSString	*page = [newUrl absoluteString];
      //NSLog(@"Lookup for handle for '%@'", page);
      [urlLock lock];
      obj = [urlCache objectForKey: page];
      AUTORELEASE(RETAIN(obj));
      [urlLock unlock];
      //NSLog(@"Found handle %@", obj);
    }
  return obj;
}

+ (void) initialize
{
  if (self == [GSHTTPURLHandle class])
    {
      urlCache = [NSMutableDictionary new];
      urlLock = [NSLock new];
    }
}

- (void) dealloc
{
  RELEASE(sock);
  RELEASE(url);
  RELEASE(dat);
  RELEASE(parser);
  RELEASE(document);
  RELEASE(headers);
  RELEASE(pageInfo);
  RELEASE(wProperties);
  RELEASE(request);
  [super dealloc];
}

- (id) initWithURL: (NSURL*)newUrl
	    cached: (BOOL)cached
{
  if ((self = [super initWithURL: newUrl cached: cached]) != nil)
    {
      dat = [NSMutableData new];
      headers = [NSMutableDictionary new];
      pageInfo = [NSMutableDictionary new];
      wProperties = [NSMutableDictionary new];
      request = [NSMutableDictionary new];

      ASSIGN(url, newUrl);
      connectionState = idle;
      if (cached == YES)
        {
	  NSString	*page = [newUrl absoluteString];

	  [urlLock lock];
	  [urlCache setObject: self forKey: page];
	  [urlLock unlock];
	  //NSLog(@"Cache handle %@ for '%@'", self, page);
	}
    }
  return self;
}

+ (BOOL) canInitWithURL: (NSURL*)newUrl
{
  if ([[newUrl scheme] isEqualToString: @"http"]
    || [[newUrl scheme] isEqualToString: @"https"])
    {
      return YES;
    }
  return NO;
}

- (void) bgdRead: (NSNotification*) not
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary		*dict = [not userInfo];
  NSData		*d;

  d = [dict objectForKey: NSFileHandleNotificationDataItem];
  [parser parse: d];
  if ([d length] == 0)
    {
      NSDictionary	*info;
      NSString		*val;

      connectionState = idle;
      [nc removeObserver: self
	            name: NSFileHandleReadCompletionNotification
                  object: sock];
      [sock closeFile];
      DESTROY(sock);
      /*
       * Retrieve essential keys from document
       */
      info = [document headerNamed: @"http"];
      val = [info objectForKey: NSHTTPPropertyServerHTTPVersionKey];
      if (val != nil)
	[pageInfo setObject: val forKey: NSHTTPPropertyServerHTTPVersionKey];
      val = [info objectForKey: NSHTTPPropertyStatusCodeKey];
      if (val != nil)
	[pageInfo setObject: val forKey: NSHTTPPropertyStatusCodeKey];
      val = [info objectForKey: NSHTTPPropertyStatusReasonKey];
      if (val != nil)
	[pageInfo setObject: val forKey: NSHTTPPropertyStatusReasonKey];
      /*
       * Tell superclass that we have successfully loaded the data.
       */
      [self didLoadBytes: [parser data] loadComplete: YES];
    }
  else
    {
      [sock readInBackgroundAndNotify];
    }
}

- (void) bgdTunnelRead: (NSNotification*) not
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary		*dict = [not userInfo];
  NSData		*d;
  NSString		*str;
  NSRange range;

  d = [dict objectForKey: NSFileHandleNotificationDataItem];

  if ([d length] > 0)
    {
      [dat appendData: d];
    }
  str = [NSString alloc];
  str = [str initWithData: dat encoding: NSASCIIStringEncoding];
  range = [str rangeOfString: @"\n\n" 
	             options: NSCaseInsensitiveSearch];
  if ([d length] == 0 || range.length > 0)
    {
      [nc removeObserver: self
	            name: NSFileHandleReadCompletionNotification
                  object: sock];
      tunnel = NO;
    }
  else
    {
      [sock readInBackgroundAndNotify];
    }
  RELEASE(str);
}

- (void) loadInBackground
{
  NSNotificationCenter	*nc;

  /*
   * Don't start a load if one is in progress.
   */
  if (connectionState != idle)
    return;

  RELEASE(dat);
  dat = [NSMutableData new];
  RELEASE(document);
  RELEASE(parser);
  parser = [GSMimeParser new];
  document = RETAIN([parser document]);
  [self beginLoadInBackground];
  [sock closeFile];
  RELEASE(sock);
  contentLength = 0;
  if ([request objectForKey: GSHTTPPropertyProxyHostKey] == nil)
    {
      if ([[url scheme] isEqualToString: @"https"])
	{
	  sock = [GSUnixSSLHandle 
	    fileHandleAsClientInBackgroundAtAddress: [url host]
					    service: [url scheme]
					   protocol: @"tcp"];
	}
      else
	{
	  sock = [NSFileHandle 
	    fileHandleAsClientInBackgroundAtAddress: [url host]
					    service: [url scheme]
					   protocol: @"tcp"];
	}
    }
  else
    {
      if ([request objectForKey: GSHTTPPropertyProxyPortKey] == nil)
	{
	  [request setObject: @"8080" forKey: GSHTTPPropertyProxyPortKey];
	}
      if ([[url scheme] isEqualToString: @"https"])
	{
	  sock = [GSUnixSSLHandle 
	    fileHandleAsClientInBackgroundAtAddress: 
	      [request objectForKey: GSHTTPPropertyProxyHostKey]
					    service:
	      [request objectForKey: GSHTTPPropertyProxyPortKey]
					   protocol: @"tcp"];
	}
      else
	{
	  sock = [NSFileHandle 
	    fileHandleAsClientInBackgroundAtAddress: 
	      [request objectForKey: GSHTTPPropertyProxyHostKey]
					    service:
	      [request objectForKey: GSHTTPPropertyProxyPortKey]
					   protocol: @"tcp"];
	}
    }
  if (sock == nil)
    {
      /*
       * Tell superclass that the load failed - let it do housekeeping.
       */
      [self backgroundLoadDidFailWithReason: @"Unable to connect to host"];
      return;
    }
  RETAIN(sock);
  nc = [NSNotificationCenter defaultCenter];
  [nc addObserver: self
         selector: @selector(bgdConnect:)
             name: GSFileHandleConnectCompletionNotification
           object: sock];
  connectionState = connecting;
}

- (void) endLoadInBackground
{
  if (connectionState != idle)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSString			*name;

      if (connectionState == connecting)
	name = GSFileHandleConnectCompletionNotification;
      else if (connectionState == writing)
	name = GSFileHandleWriteCompletionNotification;
      else if (connectionState == reading)
	name = NSFileHandleReadCompletionNotification;

      [nc removeObserver: self name: name object: sock];
      [sock closeFile];
      DESTROY(sock);
      connectionState = idle;
    }
  [super endLoadInBackground];
}

- (void) bgdConnect: (NSNotification*)notification
{
  NSDictionary          *userInfo = [notification userInfo];
  NSEnumerator          *wpEnumerator = [wProperties keyEnumerator];
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSMutableString	*s;
  NSString		*e;
  NSString              *key;
  NSMutableString       *body = nil;
  int 			i;

  /*
   * See if the connection attempt caused an error.
   */
  e = [userInfo objectForKey: GSFileHandleNotificationError];
  if (e != nil)
    {
      NSLog(@"Unable to connect via socket");
      /*
       * Tell superclass that the load failed - let it do housekeeping.
       */
      [self endLoadInBackground];
      [self backgroundLoadDidFailWithReason: e];
      return;
    }

  [nc removeObserver: self
                name: GSFileHandleConnectCompletionNotification
              object: sock];

  /*
   * Build HTTP request.
   */

  /* 
   * If SSL via proxy, set up tunnel first
   */
  if ([[url scheme] isEqualToString: @"https"]
    && [request objectForKey: GSHTTPPropertyProxyHostKey] != nil)
    {
      NSRunLoop	*loop = [NSRunLoop currentRunLoop];
      NSString	*cmd;

      if ([url port] == nil)
	{
	  cmd = [NSString stringWithFormat: @"CONNECT %@:443 HTTP/%@\n\n",
	    [url host], httpVersion];
	}
      else
	{
	  cmd = [NSString stringWithFormat: @"CONNECT %@:%@ HTTP/%@\n\n",
	    [url host], [url port], httpVersion];
	}
      
      [sock writeInBackgroundAndNotify: 
	[cmd dataUsingEncoding: NSASCIIStringEncoding]];

      tunnel = YES;
      [nc addObserver: self
	     selector: @selector(bgdWrite:)
                 name: GSFileHandleWriteCompletionNotification
               object: sock];
      while (tunnel == YES)
	{
	  [loop runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
	}
    }
  if ([[url scheme] isEqualToString: @"https"])
    {
      /*
       * If we are an https connection, negotiate secure connection
       */
      if ([sock sslConnect] == NO)
	{
	  [self endLoadInBackground];
	  [self backgroundLoadDidFailWithReason: @"Failed to make ssl connect"];
	  return;
	}
    }
  if ([request objectForKey: GSHTTPPropertyMethodKey] == nil)
    {
      [request setObject: @"GET" forKey: GSHTTPPropertyMethodKey];
    }
  if ([request objectForKey: GSHTTPPropertyProxyHostKey] != nil)
    {
      s = [[NSMutableString alloc] initWithFormat: @"\n%@ http://%@%@", 
	[request objectForKey: GSHTTPPropertyMethodKey],
	[url host], [url path]];
      if ([[url query] length] > 0)
	{
	  [s appendFormat: @"?%@", [url query]];
	}
      [s appendFormat: @" HTTP/%@\n", httpVersion];
    }
  else    // no proxy
    {
      s = [[NSMutableString alloc] initWithFormat: @"\n%@ %@", 
	[request objectForKey: GSHTTPPropertyMethodKey], [url path]];
      if ([[url query] length] > 0)
	{
	  [s appendFormat: @"?%@", [url query]];
	}
      [s appendFormat: @" HTTP/%@\nHost: %@\n", [url host], httpVersion];
    }

  while ((key = [wpEnumerator nextObject]))
    {
      if ([key compare: GSHTTPBodyKey] == NSOrderedSame)
	{ 
	  NSArray	*array = [wProperties objectForKey: key];

	  if (array != nil)
	    {
	      body = [NSMutableString new];
	      for (i = 0; i < [array count]; i++)
		{
		  NSString	*t = [array objectAtIndex:i];

		  [body appendFormat: @"%@\n", t];
		}
	    }
	  [s appendFormat: @"Content-Length: %d\n", [body length]];
	  if ([wProperties objectForKey: @"content-type"] == nil)
	    {
	      [s appendString: 
		@"Content-Type: application/x-www-form-urlencoded\n"];
	    }
	}
      else
	{
	  [s appendFormat: @"%@: %@\n", key, [wProperties objectForKey: key]];
	}
    }
  if ([url user] != nil)
    {
      NSString *auth;
      if ([[url password] length] > 0)
	{ 
	  auth = [NSString stringWithFormat: @"%@:%@", 
	    [url user], [url password]];
	}
      else
	{
	  auth = [NSString stringWithFormat: @"%@", [url user]];
	}
      [s appendFormat: @"Authorization: Basic %@\n", 
	[self encodebase64: auth]];
    }
  [s appendString: @"\n"];

  if (body != nil)
    {
      [s appendString: body];
      RELEASE (body);
    }

  [wProperties removeAllObjects];

  /*
   * Send request to server.
   */
  [sock writeInBackgroundAndNotify:
    [s dataUsingEncoding: NSASCIIStringEncoding]];
  RELEASE(s);

  /*
   * Watch for write completion.
   */
  [nc addObserver: self
         selector: @selector(bgdWrite:)
             name: GSFileHandleWriteCompletionNotification
           object: sock];
  connectionState = writing;
}

- (void) bgdWrite: (NSNotification*)notification
{
  NSDictionary    	*userInfo = [notification userInfo];
  NSString        	*e;
 
  e = [userInfo objectForKey: GSFileHandleNotificationError];
  if (e != nil)
    {
      NSLog(@"Failed to write command to socket - %@", e);
      /*
       * Tell superclass that the load failed - let it do housekeeping.
       */
      [self endLoadInBackground];
      [self backgroundLoadDidFailWithReason: @"Failed to write request"];
      return;
    }
  else
    {
      NSNotificationCenter	*nc;

      /*
       * Don't watch for write completions any more.
       */
      nc = [NSNotificationCenter defaultCenter];
      [nc removeObserver: self
		    name: GSFileHandleWriteCompletionNotification
		  object: sock];

      /*
       * Ok - write completed, let's read the response.
       */
      if (tunnel == YES)
	{
	  [nc addObserver: self
	         selector: @selector(bgdTunnelRead:)
		     name: NSFileHandleReadCompletionNotification
	           object: sock];
	}
      else
	{
	  [nc addObserver: self
	         selector: @selector(bgdRead:)
		     name: NSFileHandleReadCompletionNotification
	           object: sock];
	}
      [sock readInBackgroundAndNotify];
      connectionState = reading;
    }
}

- (id) propertyForKey: (NSString*) propertyKey
{
  if (document == nil)
    [self loadInForeground];
  return [self propertyForKeyIfAvailable: propertyKey];
}

- (id) propertyForKeyIfAvailable: (NSString*) propertyKey
{
  id	result = [pageInfo objectForKey: propertyKey];

  if (result == nil)
    {
      NSString	*key = [propertyKey lowercaseString];
      NSArray	*array = [document headersNamed: key];

      if ([array count] == 1)
	{
	  result = [[array objectAtIndex: 0] objectForKey: @"BaseValue"];
	}
      else
	{
	  NSEnumerator	*enumerator = [array objectEnumerator];
	  NSDictionary	*val;

	  result = [NSMutableArray arrayWithCapacity: [array count]];
	  while ((val = [enumerator nextObject]) != nil)
	    {
	      [result addObject: [val objectForKey: @"BaseValue"]];
	    }
	}
    }
  return result;
}

- (BOOL) writeProperty: (id) property forKey: (NSString*) propertyKey
{
  if ([propertyKey hasPrefix: @"GSHTTPProperty"])
    {
      [request setObject: property forKey: propertyKey];
    }
  else if ([propertyKey compare: @"GSHTTPBodyKey"] == NSOrderedSame)
    {
      NSMutableArray *array = [wProperties objectForKey: propertyKey];
      if (array == nil)
	{
	  array = [[NSMutableArray alloc] init];
	}
      [array addObject: property];
      [wProperties setObject: array forKey: GSHTTPBodyKey];
    }
  else
    {
      [wProperties setObject: property forKey: [propertyKey lowercaseString]];
    }
  return YES;
}

- (NSString*) encodebase64: (NSString*) input
{
   char			*str = calloc([input length], sizeof(char));
   char			*sptr = str;
   NSMutableString	*nstr = [NSMutableString string];
   int i;

   strcpy(str, [input cString]);
 
   for (i=0; i < [input length]; i += 3) 
     {
       [nstr appendFormat: @"%c", emp[*sptr >> 2]];
       [nstr appendFormat: @"%c", 
	 emp[((*sptr << 4) & 060) | ((sptr[1] >> 4) & 017)]];
       [nstr appendFormat: @"%c", 
	 emp[((sptr[1] << 2) & 074) | ((sptr[2] >> 6) & 03)]];
       [nstr appendFormat: @"%c", emp[sptr[2] & 077]];
       sptr += 3;
     }
 
   /* If len was not a multiple of 3, then we have encoded too
    * many characters.  Adjust appropriately.
    */
   if (i == [input length] + 1) 
     {
       /* There were only 2 bytes in that last group */
       [nstr deleteCharactersInRange: NSMakeRange([nstr length] - 1, 1)];
     } 
   else if (i == [input length] + 2) 
     {
       /* There was only 1 byte in that last group */
       [nstr deleteCharactersInRange: NSMakeRange([nstr length] - 2, 2)];
     }
   free (str);
   return (nstr);
}
@end

