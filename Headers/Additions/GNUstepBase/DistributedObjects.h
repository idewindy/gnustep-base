/* Interface internal use by Distributed Objects components
   Copyright (C) 1997 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: August 1997

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

#ifndef __DistributedObjects_h
#define __DistributedObjects_h

/*
 *	For internal use by the GNUstep base library.
 *	This file should not be installed.  The only reason why it is
 *	located here, is to allow target specific headers (like mframe.h), 
 *	which are located according to dis/enabled-flattened,
 *	may include this file via standard "GNUstepBase/DistributedObjects.h"
 *	and won't require an extra -I flag.
 *	
 *	Classes should implement [-classForPortCoder] to return the class
 *	that should be sent over the wire.
 *
 *	Classes should implement [-replacementObjectForPortCoder:] to encode
 *	objects.
 *	The default action is to send a proxy.
 */

#include <Foundation/NSConnection.h>
#include <Foundation/NSDistantObject.h>
#include <Foundation/NSPortCoder.h>

@class	NSDistantObject;
@class	NSConnection;
@class	NSPort;

/*
 *	Distributed Objects identifiers
 *	These define the type of messages sent by the D.O. system.
 */
enum {
 METHOD_REQUEST = 0,
 METHOD_REPLY,
 ROOTPROXY_REQUEST,
 ROOTPROXY_REPLY,
 CONNECTION_SHUTDOWN,
 METHODTYPE_REQUEST,
 METHODTYPE_REPLY,
 PROXY_RELEASE,
 PROXY_RETAIN,
 RETAIN_REPLY
};


/*
 *	Category containing the methods by which the public interface to
 *	NSConnection must be extended in order to allow it's use by
 *	by NSDistantObject et al for implementation of Distributed objects.
 */
@interface NSConnection (Internal)
- (NSDistantObject*) includesLocalTarget: (unsigned)target;
- (NSDistantObject*) localForObject: (id)object;
- (NSDistantObject*) locateLocalTarget: (unsigned)target;
- (NSDistantObject*) proxyForTarget: (unsigned)target;
- (void) retainTarget: (unsigned)target;
@end

/*
 * A structure for passing context information using in encoding/decoding
 * arguments for DO
 */
typedef struct {
  const char	*type;		// The type of the data
  int		flags;		// Type qualifier flags
  void		*datum;		// Where to get/store data
  NSConnection	*connection;	// The connection in use
  NSPortCoder	*decoder;	// The coder to use
  NSPortCoder	*encoder;	// The coder to use
  unsigned	seq;		// Sequence number
  /*
   * These next fields can store allocated memory that will need to be
   * tidied up iff an exception occurs before they can be tidied normally.
   */
  void		*datToFree;	// Data needing NSZoneFree()
  id		objToFree;	// Data needing NSDeallocateObject()
} DOContext;

#endif /* __DistributedObjects_h */