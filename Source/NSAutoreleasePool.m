/* Implementation of auto release pool for delayed disposal
   Copyright (C) 1995, 1996, 1997 Free Software Foundation, Inc.
   
   Written by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date: January 1995
   
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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */ 

#include <config.h>
#include <gnustep/base/preface.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSZone.h>
#include <limits.h>

/* TODO:
   Doesn't work multi-threaded.
   */

/* When this is `NO', autoreleased objects are never actually recorded
   in an NSAutoreleasePool, and are not sent a `release' message.
   Thus memory for objects use grows, and grows, and... */
static BOOL autorelease_enabled = YES;

/* When the _released_count of a pool gets over this value, we raise
   an exception.  This can be adjusted with -setPoolCountThreshhold */
static unsigned pool_count_warning_threshhold = UINT_MAX;

/* The size of the first _released array. */
#define BEGINNING_POOL_SIZE 32

/* Easy access to the thread variables belonging to NSAutoreleasePool. */
#define ARP_THREAD_VARS (&([NSThread currentThread]->_autorelease_vars))


@interface NSAutoreleasePool (Private)
- _parentAutoreleasePool;
- (unsigned) autoreleaseCount;
- (unsigned) autoreleaseCountForObject: anObject;
+ (unsigned) autoreleaseCountForObject: anObject;
+ currentPool;
- (void) _setChildPool: pool;
@end


/* Functions for managing a per-thread cache of NSAutoreleasedPool's
   already alloc'ed.  The cache is kept in the autorelease_thread_var 
   structure, which is an ivar of NSThread. */

static inline void
init_pool_cache (struct autorelease_thread_vars *tv)
{
  tv->pool_cache_size = 32;
  tv->pool_cache_count = 0;
  OBJC_MALLOC (tv->pool_cache, id, tv->pool_cache_size);
}

static void
push_pool_to_cache (struct autorelease_thread_vars *tv, id p)
{
  if (!tv->pool_cache)
    init_pool_cache (tv);
  else if (tv->pool_cache_count == tv->pool_cache_size)
    {
      tv->pool_cache_size *= 2;
      OBJC_REALLOC (tv->pool_cache, id, tv->pool_cache_size);
    }
  tv->pool_cache[tv->pool_cache_count++] = p;
}

static id
pop_pool_from_cache (struct autorelease_thread_vars *tv)
{
  return tv->pool_cache[--(tv->pool_cache_count)];
}


@implementation NSAutoreleasePool

+ (void) initialize
{
  if (self == [NSAutoreleasePool class])
    ;				// Anything to put here?
}

+ allocWithZone: (NSZone*)zone
{
  /* If there is an already-allocated NSAutoreleasePool available,
     save time by just returning that, rather than allocating a new one. */
  struct autorelease_thread_vars *tv = ARP_THREAD_VARS;
  if (tv->pool_cache_count)
    return pop_pool_from_cache (tv);

  return NSAllocateObject (self, 0, zone);
}

- init
{
  if (!_released_head)
    {
      /* Allocate the array that will be the new head of the list of arrays. */
      _released = (struct autorelease_array_list*)
	objc_malloc (sizeof(struct autorelease_array_list) + 
		     (BEGINNING_POOL_SIZE * sizeof(id)));
      /* Currently no NEXT array in the list, so NEXT == NULL. */
      _released->next = NULL;
      _released->size = BEGINNING_POOL_SIZE;
      _released->count = 0;
      _released_head = _released;
    }
  else
    /* Already initialized; (it came from autorelease_pool_cache);
       we don't have to allocate new array list memory. */
    {
      _released = _released_head;
      _released->count = 0;
    }

  /* This NSAutoreleasePool contains no objects yet. */
  _released_count = 0;

  /* Install ourselves as the current pool. */
  {
    struct autorelease_thread_vars *tv = ARP_THREAD_VARS;
    _parent = tv->current_pool;
    _child = nil;
    [tv->current_pool _setChildPool: self];
    tv->current_pool = self;
  }

  return self;
}

- (void) _setChildPool: pool
{
  _child = pool;
}

/* This method not in OpenStep */
- _parentAutoreleasePool
{
  return _parent;
}

/* This method not in OpenStep */
- (unsigned) autoreleaseCount
{
  unsigned count = 0;
  struct autorelease_array_list *released = _released_head;
  while (released && released->count)
    {
      count += released->count;
      released = released->next;
    }
  return count;
}

/* This method not in OpenStep */
- (unsigned) autoreleaseCountForObject: anObject
{
  unsigned count = 0;
  struct autorelease_array_list *released = _released_head;
  int i;

  while (released && released->count)
    {
      for (i = 0; i < released->count; i++)
	if (released->objects[i] == anObject)
	  count++;
      released = released->next;
    }
  return count;
}

/* This method not in OpenStep */
/* xxx This count should be made for *all* threads, but currently is 
   only madefor the current thread! */
+ (unsigned) autoreleaseCountForObject: anObject
{
  unsigned count = 0;
  id pool = ARP_THREAD_VARS->current_pool;
  while (pool)
    {
      count += [pool autoreleaseCountForObject: anObject];
      pool = [pool _parentAutoreleasePool];
    }
  return count;
}

+ currentPool
{
  return ARP_THREAD_VARS->current_pool;
}

+ (void) addObject: anObj
{
  NSAutoreleasePool	*pool = ARP_THREAD_VARS->current_pool;

  if (pool)
    [pool addObject: anObj];
  else
    {
      NSAutoreleasePool	*arp = [NSAutoreleasePool new];

      if (anObj)
	NSLog(@"autorelease called without pool for object (%x) of class %s\n",
                anObj, [NSStringFromClass([anObj class]) cString]);
      else
	NSLog(@"autorelease called without pool for nil object.\n");
      [arp release];
    }
}

- (void) addObject: anObj
{
  /* If the global, static variable AUTORELEASE_ENABLED is not set,
     do nothing, just return. */
  if (!autorelease_enabled)
    return;

  if (_released_count >= pool_count_warning_threshhold)
    [NSException raise: NSGenericException
		 format: @"AutoreleasePool count threshhold exceeded."];

  /* Get a new array for the list, if the current one is full. */
  if (_released->count == _released->size)
    {
      if (_released->next)
	{
	  /* There is an already-allocated one in the chain; use it. */
	  _released = _released->next;
	  _released->count = 0;
	}
      else
	{
	  /* We are at the end of the chain, and need to allocate a new one. */
	  struct autorelease_array_list *new_released;
	  unsigned new_size = _released->size * 2;
	  
	  new_released = (struct autorelease_array_list*)
	    objc_malloc (sizeof(struct autorelease_array_list) + 
			 (new_size * sizeof(id)));
	  new_released->next = NULL;
	  new_released->size = new_size;
	  new_released->count = 0;
	  _released->next = new_released;
	  _released = new_released;
	}
    }

  /* Put the object at the end of the list. */
  _released->objects[_released->count] = anObj;
  (_released->count)++;

  /* Keep track of the total number of objects autoreleased across all
     pools. */
  ARP_THREAD_VARS->total_objects_count++;

  /* Keep track of the total number of objects autoreleased in this pool */
  _released_count++;
}

- (id) retain
{
  [NSException raise: NSGenericException
	       format: @"Don't call `-retain' on a NSAutoreleasePool"];
  return self;
}

- (oneway void) release
{
  [self dealloc];
}

- (void) dealloc
{
  /* If there are NSAutoreleasePool below us in the stack of
     NSAutoreleasePools, then deallocate them also.  The (only) way we
     could get in this situation (in correctly written programs, that
     don't release NSAutoreleasePools in weird ways), is if an
     exception threw us up the stack. */
  if (_child)
    [_child dealloc];

  /* Make debugging easier by checking to see if the user already
     dealloced the object before trying to release it.  Also, take the
     object out of the released list just before releasing it, so if
     we are doing "double_release_check"ing, then
     autoreleaseCountForObject: won't find the object we are currently
     releasing. */
  {
    struct autorelease_array_list *released = _released_head;
    int i;

    while (released)
      {
	for (i = 0; i < released->count; i++)
	  {
	    id anObject = released->objects[i];
#if 0
	    /* There is no general method to find out whether a memory
               chunk has been deallocated or not, especially when
               custom zone functions might be used.  So we #if this
               out. */
	    if (!NSZoneMemInUse(anObject))
              [NSException 
                raise: NSGenericException
                format: @"Autoreleasing deallocated object.\n"
                @"Suggest you debug after setting [NSObject "
		@"enableDoubleReleaseCheck:YES]\n"
		@"to check for release errors."];
#endif
	    released->objects[i] = nil;
	    [anObject release];
	  }
	released = released->next;
      }
  }

  {
    struct autorelease_thread_vars *tv;
    NSAutoreleasePool **cp;

    /* Uninstall ourselves as the current pool; install our parent pool. */
    tv = ARP_THREAD_VARS;
    cp = &(tv->current_pool);
    *cp = _parent;
    if (*cp)
      (*cp)->_child = nil;

    /* Don't deallocate ourself, just save us for later use. */
    push_pool_to_cache (tv, self);
  }
}

- (void) reallyDealloc
{
  struct autorelease_array_list *a;
  for (a = _released_head; a; )
    {
      void *n = a->next;
      objc_free (a);
      a = n;
    }
  [super dealloc];
}

- autorelease
{
  [NSException raise: NSGenericException
	       format: @"Don't call `-autorelease' on a NSAutoreleasePool"];
  return self;
}

+ (void) resetTotalAutoreleasedObjects
{
  ARP_THREAD_VARS->total_objects_count = 0;
}

+ (unsigned) totalAutoreleasedObjects
{
  return ARP_THREAD_VARS->total_objects_count;
}

+ (void) enableRelease: (BOOL)enable
{
  autorelease_enabled = enable;
}

+ (void) setPoolCountThreshhold: (unsigned)c
{
  pool_count_warning_threshhold = c;
}

@end
