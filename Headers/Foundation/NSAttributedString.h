/* 
   NSAttributedString.h

   String class with attributes

   Copyright (C) 1997,1999 Free Software Foundation, Inc.

   Written by: ANOQ of the sun <anoq@vip.cybercity.dk>
   Date: November 1997
   Rewrite by: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: April 1999
   
   This file is part of GNUStep-base

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

/* Warning -	[-initWithString:attributes:] is the designated initialiser,
 *		but it doesn't provide any way to perform the function of the
 *		[-initWithAttributedString:] initialiser.
 *		In order to work youd this, the string argument of the
 *		designated initialiser has been overloaded such that it
 *		is expected to accept an NSAttributedString here instead of
 *		a string.  If you create an NSAttributedString subclass, you
 *		must make sure that your implementation of the initialiser
 *		copes with either an NSString or an NSAttributedString.
 *		If it receives an NSAttributedString, it should ignore the
 *		attributes argument and use the values from the string.
 */


#ifndef _NSXKit_H_NSAttributedString
#define _NSXKit_H_NSAttributedString

#ifndef	STRICT_OPENSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSCoder.h>

@interface NSAttributedString : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
}

//Creating an NSAttributedString
- (id) initWithString: (NSString*)aString;
- (id) initWithAttributedString: (NSAttributedString*)attributedString;
- (id) initWithString: (NSString*)aString attributes: (NSDictionary*)attributes;

//Retrieving character information
- (unsigned int) length;
- (NSString*) string;					//Primitive method!

//Retrieving attribute information
- (NSDictionary*) attributesAtIndex: (unsigned int)index
		     effectiveRange: (NSRange*)aRange;	//Primitive method!
- (NSDictionary*) attributesAtIndex: (unsigned int)index
	      longestEffectiveRange: (NSRange*)aRange
			    inRange: (NSRange)rangeLimit;
- (id) attribute: (NSString*)attributeName
	 atIndex: (unsigned int)index
  effectiveRange: (NSRange*)aRange;
- (id) attribute: (NSString*)attributeName atIndex: (unsigned int)index
  longestEffectiveRange: (NSRange*)aRange inRange: (NSRange)rangeLimit;

//Comparing attributed strings
- (BOOL) isEqualToAttributedString: (NSAttributedString*)otherString;

//Extracting a substring
- (NSAttributedString*) attributedSubstringFromRange: (NSRange)aRange;

#ifndef	NO_GNUSTEP
/*
 * Synonym for attributedSubstringFromRange: - for consistency with NSString
 */
- (NSAttributedString*) attributedSubstringWithRange: (NSRange)aRange;
#endif

@end //NSAttributedString


@interface NSMutableAttributedString : NSAttributedString
{
}

//Retrieving character information
- (NSMutableString*) mutableString;

//Changing characters
- (void) deleteCharactersInRange: (NSRange)aRange;

//Changing attributes
- (void) setAttributes: (NSDictionary*)attributes
		 range: (NSRange)aRange;		//Primitive method!
- (void) addAttribute: (NSString*)name value: (id)value range: (NSRange)aRange;
- (void) addAttributes: (NSDictionary*)attributes range: (NSRange)aRange;
- (void) removeAttribute: (NSString*)name range: (NSRange)aRange;

//Changing characters and attributes
- (void) appendAttributedString: (NSAttributedString*)attributedString;
- (void) insertAttributedString: (NSAttributedString*)attributedString
			atIndex: (unsigned int)index;
- (void) replaceCharactersInRange: (NSRange)aRange
	     withAttributedString: (NSAttributedString*)attributedString;
- (void) replaceCharactersInRange: (NSRange)aRange
		       withString: (NSString*)aString;	//Primitive method!
- (void) setAttributedString: (NSAttributedString*)attributedString;

//Grouping changes
- (void) beginEditing;
- (void) endEditing;

@end //NSMutableAttributedString

#endif //STRICT_OPENSTEP

#endif //_NSXKit_H_NSAttributedString
