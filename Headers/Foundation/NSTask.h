/* Interface for NSTask for GNUstep
   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1998

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

#ifndef __NSTask_h_GNUSTEP_BASE_INCLUDE
#define __NSTask_h_GNUSTEP_BASE_INCLUDE

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSFileHandle.h>

@interface NSTask : NSObject <GCFinalization>
{
  NSString	*_currentDirectoryPath;
  NSString	*_launchPath;
  NSArray	*_arguments;
  NSDictionary	*_environment;
  id		_standardError;
  id		_standardInput;
  id		_standardOutput;
  int		_taskId;
  int		_terminationStatus;
  BOOL		_hasLaunched;
  BOOL		_hasTerminated;
  BOOL		_hasCollected;
  BOOL		_hasNotified;
}

+ (NSTask*) launchedTaskWithLaunchPath: (NSString*)path
			     arguments: (NSArray*)args;

/*
 *	Querying task parameters.
 */
- (NSArray*) arguments;
- (NSString*) currentDirectoryPath;
- (NSDictionary*) environment;
- (NSString*) launchPath;
- (id) standardError;
- (id) standardInput;
- (id) standardOutput;

/*
 *	Setting task parameters.
 */
- (void) setArguments: (NSArray*)args;
- (void) setCurrentDirectoryPath: (NSString*)path;
- (void) setEnvironment: (NSDictionary*)env;
- (void) setLaunchPath: (NSString*)path;
- (void) setStandardError: (id)hdl;
- (void) setStandardInput: (id)hdl;
- (void) setStandardOutput: (id)hdl;

/*
 *	Obtaining task state
 */
- (BOOL) isRunning;
#ifndef	STRICT_OPENSTEP
- (int) processIdentifier;
#endif
- (int) terminationStatus;

/*
 *	Handling a task.
 */
- (void) interrupt;
- (void) launch;
#ifndef	STRICT_OPENSTEP
- (BOOL) resume;
- (BOOL) suspend;
#endif
- (void) terminate;
- (void) waitUntilExit;

#ifndef	NO_GNUSTEP
- (BOOL) usePseudoTerminal;
- (NSString*) validatedLaunchPath;
#endif
@end

GS_EXPORT NSString*	NSTaskDidTerminateNotification;

#endif /* __NSTask_h_GNUSTEP_BASE_INCLUDE */