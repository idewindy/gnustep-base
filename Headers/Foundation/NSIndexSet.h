/** Interface for NSIndexSet, NSMutableIndexSet for GNUStep
   Copyright (C) 2004 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <rfm@gnu.org>
   Created: Feb 2004
   
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
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02111 USA.

   AutogsdocSource: NSIndexSet.m

   */ 

#ifndef _NSIndexSet_h_GNUSTEP_BASE_INCLUDE
#define _NSIndexSet_h_GNUSTEP_BASE_INCLUDE

#ifndef	STRICT_OPENSTEP

#include	<Foundation/NSObject.h>
#include	<Foundation/NSRange.h>

/**
 * Instances of this class are collections of unsigned integers in the
 * range 0 to NSNotFound-1.<br />
 * Each integer can appear in a collection only once.
 */
@interface	NSIndexSet : NSObject <NSCopying, NSMutableCopying, NSCoding>
{
  void	*_data;
}

/**
 * Return an empty set.
 */
+ (id) indexSet;

/**
 * Return a set containing the single value anIndex, or returns nil if
 * anIndex is NSNotFound.
 */
+ (id) indexSetWithIndex: (unsigned int)anIndex;

/**
 * Return a set containing all the values in aRange, or returns nil if
 * aRange contains NSNotFound.
 */
+ (id) indexSetWithIndexesInRange: (NSRange)aRange;

/**
 * Returns YES if the receiver contains anIndex, NO otherwise.
 */
- (BOOL) containsIndex: (unsigned int)anIndex;

/**
 * Returns YES if the receiver contains all the index values present
 * in aSet, NO otherwise.
 */
- (BOOL) containsIndexes: (NSIndexSet*)aSet;

/**
 * Returns YES if the receiver contains all the index values present
 * in aRange, NO otherwise.
 */
- (BOOL) containsIndexesInRange: (NSRange)aRange;

/**
 * Returns the number of index values present in the receiver.
 */
- (unsigned int) count;

/**
 * Returns the first index value in the receiver or NSNotFound if the
 * receiver is empty.
 */
- (unsigned int) firstIndex;

/**
 * Copies index values into aBuffer until there are no index values left or
 * aBuffer is full (assuming that the size of aBuffer is given by aCount).<br />
 * Only copies index values present in aRange and copies them in order.<br />
 * Returns the number of index values placed in aBuffer.<br />
 * Modifies aRange to start after the last index value copied.<br />
 * If aRange is a null pointer, this method attempts to get <em>all</em>
 * index values from the set (and of course no range can be returned in it).
 */
- (unsigned int) getIndexes: (unsigned int*)aBuffer
		   maxCount: (unsigned int)aCount
	       inIndexRange: (NSRangePointer)aRange;

/**
 * Return the first index value in the receiver which is greater than
 * anIndex.
 */
- (unsigned int) indexGreaterThanIndex: (unsigned int)anIndex;

/**
 * Return the first index value in the receiver which is greater than
 * or equal to anIndex.
 */
- (unsigned int) indexGreaterThanOrEqualToIndex: (unsigned int)anIndex;

/**
 * Return the first index value in the receiver which is less than
 * anIndex.
 */
- (unsigned int) indexLessThanIndex: (unsigned int)anIndex;

/**
 * Return the first index value in the receiver which is less than
 * or equal to anIndex.
 */
- (unsigned int) indexLessThanOrEqualToIndex: (unsigned int)anIndex;

/**
 * Initialise the receiver to contain anIndex.  Returns the initialised
 * object or nil if anIndex is NSNotFound.
 */
- (id) initWithIndex: (unsigned int)anIndex;

/** <init />
 * Initialise the receiver to contain all index values in aRange.
 * Returns the initialised object or nil if aRange contains NSNotFound.
 */
- (id) initWithIndexesInRange: (NSRange)aRange;

/**
 * Initialises the receiver with the index values from aSet.
 */
- (id) initWithIndexSet: (NSIndexSet*)aSet;

/**
 * Returns YES if the receiver contains any index values which lie in aRange,
 * No otherwise.
 */
- (BOOL) intersectsIndexesInRange: (NSRange)aRange;

/**
 * Tests two index sets for equality and returns either YES or NO.
 */
- (BOOL) isEqualToIndexSet: (NSIndexSet*)aSet;

/**
 * Returns the last index value in the receiver or NSNotFound if the
 * receiver is empty.
 */
- (unsigned int) lastIndex;
@end


@interface	NSMutableIndexSet : NSIndexSet

/**
 * Adds anIndex to the set of indexes stored in the receiver.
 */
- (void) addIndex: (unsigned int)anIndex;

/**
 * Adds all the indexes from aSet to the set of indexes stored in the receiver.
 */
- (void) addIndexes: (NSIndexSet*)aSet;

/**
 * Adds all the indexes in aRange to the set of indexes stored in the receiver.
 */
- (void) addIndexesInRange: (NSRange)aRange;

/**
 * Removes all indexes stored in the receiver.
 */
- (void) removeAllIndexes;

/**
 * Removes anIndex from the set of indexes stored in the receiver.
 */
- (void) removeIndex: (unsigned int)anIndex;

/**
 * Removes all the indexes in aSet from the set of indexes
 * stored in the receiver.
 */
- (void) removeIndexes: (NSIndexSet*)aSet;

/**
 * Removes all the indexes in aRange from the set of indexes
 * stored in the receiver.
 */
- (void) removeIndexesInRange: (NSRange)aRange;

/**
 * Not implemented.<br />
 * Moves all the indexes from anIndex upwards by the amount specified.<br />
 * If amount is negative, index values below anIndex will be overwritten
 * by the shifted values.<br />
 * If amount is positive, a 'hole' will be left in the index range after
 * anIndex.
 */
- (void) shiftIndexesStartingAtIndex: (unsigned int)anIndex by: (int)amount;   

@end

#endif
#endif
