/* NSArray - Array object to hold other objects.
   Copyright (C) 1993,1994 Free Software Foundation, Inc.
   
   Written by:  Adam Fedor <fedor@boulder.colorado.edu>
   Date: Mar 1995
   
   This file is part of the GNU Objective C Class Library.
   
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

#include <foundation/NSArray.h>
#include <foundation/NSString.h>

@implementation NSArray

+ allocWithZone:(NSZone *)zone
{
  return [[[NSArray alloc] init] autorelease];
}

+ array
{
  return [[[self alloc] init] autorelease];
}

+ arrayWithObject:anObject
{
  return [[[[self alloc] init] addObject: anObject] autorelease];
}

+ arrayWithObjects:firstObj, ...
{
  va_list ap;
  Array *n = [[self alloc] init];
  id o;
 
  [n addObject:firstObject];
  va_start(ap, firstObject);
  while ((o = va_arg(ap, id)))
    [n addObject:o];
  va_end(ap);
  return [n autorelease];
}

- initWithObjects:(id *)objects count:(unsigned)count
{
  [self initWithCapacity:count];
  while (count--)
    [self addObject:objects[count]];
  return self;
}

- initWithObjects:firstObj, ...
{
  va_list ap;
  id o;
 
  [super init];
  [self addObject:firstObject];
  va_start(ap, firstObject);
  while ((o = va_arg(ap, id)))
    [self addObject:o];
  va_end(ap);
  return self;
}

- initWithArray:(NSArray *)array
{
  int i, c;
 
  c = [array count];
  [self initWithCapacity:c];
  for (i = 0; i < c; i++)
    [self addObject:[array objectAtIndex:i]];
  return self;
}


- (unsigned)count
{
  return [super count];
}

- objectAtIndex:(unsigned)index
{
  return [super objectAtIndex:index];
}

- (unsigned)indexOfObjectIdenticalTo:anObject
{
  [self notImplemented:_cmd];
  return 0;
}

- (unsigned)indexOfObject:anObject
{
  return [super indexOfObject:anObject];
}

- (BOOL)containsObject:anObject
{
  return [super includesObject:anObject];
}

- (BOOL)isEqualToArray:(NSArray *)otherArray;
{
  int i;
 
  if (_count != [otherArray count])
    return NO;
  for (i = 0; i < _count; i++)
    if ([_contents_array[i].id_u isEqual:[otherArray objectAtIndex:i]])
      return NO;
  return YES;
}

- lastObject
{
  return [super lastObject];
}

- (void)makeObjectsPerform:(SEL)aSelector
{
  [self notImplemented:_cmd];
}

- (void)makeObjectsPerform:(SEL)aSelector withObject:argument
{
  [self notImplemented:_cmd];
}


- (NSArray *)sortedArrayUsingSelector:(SEL)comparator
{
  id n = [self copy];
  int compare(id o1, id o2)
    {
      return (int) [o1 perform:comparator with:o2];
    }
  [n sortObjectsByCalling:compare];
  return [n autorelease];
}

- (NSArray *)sortedArrayUsingFunction:(int (*)(id, id, void *))comparator 
 context:(void *)context
{
  id n = [self copy];
  int compare(id o1, id o2)
    {
      return comparator(o1, o2, context);
    }
  [n sortObjectsByCalling:compare];
  return [n autorelease];
}

- (NSString *)componentsJoinedByString:(NSString *)separator
{
  [self notImplemented:_cmd];
  return 0;
}


- firstObjectCommonWithArray:(NSArray *)otherArray
{
  BOOL is_in_otherArray (id o)
    {
      return [otherArray containsObject:o];
    }
  id none_found(arglist_t a)
    {
      return nil;
    }
  return [self detectObjectByCalling:is_in_otherArray
	ifNoneCall:none_found];
}

- (NSArray *)subarrayWithRange:(NSRange)range
{
  id n = [self emptyCopy];
  [self notImplemented:_cmd];
  return [n autorelease];
}

//- (NSEnumerator *)objectEnumerator
//{
  //    [self notImplemented:_cmd];
  //}

//- (NSEnumerator *)reverseObjectEnumerator
//{
  //    [self notImplemented:_cmd];
  //    return 0;
  //}

- (NSString *)description
{
  [self notImplemented:_cmd];
  return 0;
}

- (NSString *)descriptionWithIndent:(unsigned)level
{
  [self notImplemented:_cmd];
  return 0;
}


@end

@implementation NSMutableArray: NSArray

+ allocWithZone:(NSZone *)zone
{
  return [[[NSMutableArray alloc] init] autorelease];
}

+ arrayWithCapacity:(unsigned)numItems
{
  return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- initWithCapacity:(unsigned)numItems
{
  return [super initWithCapacity:numItems];
}

- (void)addObject:anObject
{
  [super addObject:[anObject retain]];
}

- (void)replaceObjectAtIndex:(unsigned)index withObject:anObject
{
  id old;
  old = [super replaceObjectAtIndex:index with:[anObject retain]];
  [old release];
}

- (void)removeLastObject
{
  [[super removeLastObject] release];
}

- (void)insertObject:anObject atIndex:(unsigned)index
{
  [super insertObject:[anObject retain] atIndex:index];
}

- (void)removeObjectAtIndex:(unsigned)index
{
  [[super removeObjectAtIndex:index] release];
}

- (void)removeObjectIdenticalTo:anObject
{
  int i;
  for (i = 0; i < _count; i++)
    if (anObject == _contents_array[i].id_u)
      return i;
  return UINT_MAX;
}

- (void)removeObject:anObject
{
  [[super removeObjectAtIndex:[super indexOfObject:anObject]] release];
}

- (void)removeAllObjects
{
  [self notImplemented:_cmd];
}

- (void)addObjectsFromArray:(NSArray *)otherArray
{
  [self notImplemented:_cmd];
}

- (void)removeObjectsFromIndices:(unsigned *)indices numIndices:(unsigned)count
{
  [self notImplemented:_cmd];
}

- (void)removeObjectsInArray:(NSArray *)otherArray
{
  [self notImplemented:_cmd];
}

- (void)sortUsingFunction:(int (*)(id, id, void *))compare 
 context:(void *)context
{
  [self notImplemented:_cmd];
}

@end

