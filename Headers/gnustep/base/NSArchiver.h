/* Interface for NSArchiver for GNUStep
   Copyright (C) 1995, 1996, 1997, 1998 Free Software Foundation, Inc.

   Written by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date: March 1995
   
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

#ifndef __NSArchiver_h_GNUSTEP_BASE_INCLUDE
#define __NSArchiver_h_GNUSTEP_BASE_INCLUDE

#include <Foundation/NSCoder.h>

@class NSMutableDictionary, NSMutableData, NSData, NSString;

#define	_C_NONE	0x00		/* No type information.		*/
#define	_C_MASK	0x7f		/* Basic type info.		*/
#define	_C_XREF	0x80		/* Cross reference to an item.	*/

@interface NSArchiver : NSCoder
{
  NSMutableData	*data;		/* Data to write into.		*/
  id		dst;		/* Serialization destination.	*/
  IMP		serImp;		/* Method to serialize with.	*/
  IMP		tagImp;		/* Serialize a type tag.	*/
  IMP		xRefImp;	/* Serialize a crossref.	*/
  IMP		eObjImp;	/* Method to encode an id.	*/
  IMP		eValImp;	/* Method to encode others.	*/
#ifndef	_IN_NSARCHIVER_M
#define	FastMapTable	void*
#endif
  FastMapTable	clsMap;		/* Class cross references.	*/
  FastMapTable	cIdMap;		/* Conditionally coded.		*/
  FastMapTable	uIdMap;		/* Unconditionally coded.	*/
  FastMapTable	ptrMap;		/* Constant pointers.		*/
  FastMapTable	namMap;		/* Mappings for class names.	*/
  FastMapTable	repMap;		/* Mappings for objects.	*/
#ifndef	_IN_NSARCHIVER_M
#undef	FastMapTable
#endif
  unsigned	xRefC;		/* Counter for cross-reference.	*/
  unsigned	xRefO;		/* Counter for cross-reference.	*/
  unsigned	xRefP;		/* Counter for cross-reference.	*/
  unsigned	startPos;	/* Where in data we started.	*/
  BOOL		isEncodingRootObject;
  BOOL		isInPreparatoryPass;
}

/* Initializing an archiver */
- (id) initForWritingWithMutableData: (NSMutableData*)mdata;

/* Archiving Data */
+ (NSData*) archivedDataWithRootObject: (id)rootObject;
+ (BOOL) archiveRootObject: (id)rootObject toFile: (NSString*)path;

/* Getting data from the archiver */
- (NSMutableData*) archiverData;

/* Substituting Classes */
- (NSString*) classNameEncodedForTrueClassName: (NSString*) trueName;
- (void) encodeClassName: (NSString*)trueName
           intoClassName: (NSString*)inArchiveName;

#ifndef	STRICT_OPENSTEP
/* Substituting Objects */
- (void) replaceObject: (id)object
	    withObject: (id)newObject;
#endif
@end

#ifndef	NO_GNUSTEP
@interface	NSArchiver (GNUstep)

/*
 *	Re-using the archiver - the 'resetArchiver' method resets the internal
 *	state of the archiver so that you can re-use it rather than having to
 *	destroy it and create a new one.
 *	NB. you would normally want to issue a 'setLength:0' message to the
 *	mutable data object used by the archiver as well, othewrwise the next
 *	root object encoded will be appended to data.
 */
- (void) resetArchiver;

/*
 *	Subclassing with different output format.
 *	NSArchiver normally writes directly to an NSMutableData object using
 *	the methods -
 *		[-serializeTypeTag:]
 *		    to encode type tags for data items, the tag is the
 *		    first byte of the character encoding string for the
 *		    data type (as provided by '@encode(xxx)'), possibly
 *		    with the top bit set to indicate that what follows is
 *		    a crossreference to an item already encoded.
 *		[-serializeCrossRef:],
 *		    to encode a crossreference number either to identify the
 *		    following item, or to refer to a previously encoded item.
 *		    Objects, Classes, Selectors, CStrings and Pointer items
 *		    have crossreference encoding, other types do not.
 *		[-serializeData:ofObjCType:context:]
 *		    to encode all other information.
 *
 *	And uses other NSMutableData methods to write the archive header
 *	information from within the method:
 *		[-serializeHeaderAt:version:classes:objects:pointers:]
 *		    to write a fixed size header including archiver version
 *		    (obtained by [self systemVersion]) and crossreference
 *		    table sizes.  The archiver will do this twice, once with
 *		    dummy values at initialisation time and once with the real
 *		    values.
 *
 *	To subclass NSArchiver, you must implement your own versions of the
 *	four methods above, and override the 'directDataAccess' method to
 *	return NO so that the archiver knows to use your serialization
 *	methods rather than those in the NSMutableData object.
 */
- (BOOL) directDataAccess;
- (void) serializeHeaderAt: (unsigned)positionInData
		   version: (unsigned)systemVersion
		   classes: (unsigned)classCount
		   objects: (unsigned)objectCount
		  pointers: (unsigned)pointerCount;

/* libObjects compatibility */
- (void) encodeArrayOfObjCType: (const char*) type
		         count: (unsigned)count
			    at: (const void*)buf
		      withName: (id)name;
- (void) encodeIndent;
- (void) encodeValueOfCType: (const char*) type
			 at: (const void*)buf
		   withName: (id)name;
- (void) encodeValueOfObjCType: (const char*) type
			    at: (const void*)buf
		      withName: (id)name;
- (void) encodeObject: (id)anObject
	     withName: (id)name;
@end
#endif



@interface NSUnarchiver : NSCoder
{
  NSData		*data;		/* Data to write into.		*/
  Class			dataClass;	/* What sort of data is it?	*/
  id			src;		/* Deserialization source.	*/
  IMP			desImp;		/* Method to deserialize with.	*/
  unsigned char		(*tagImp)(id, SEL, unsigned*);
  unsigned		(*xRefImp)(id, SEL, unsigned*);
  IMP			dValImp;	/* Method to decode data with.	*/
#ifndef	_IN_NSUNARCHIVER_M
#define	FastArray	void*
#endif
  FastArray		clsMap;		/* Class crossreference map.	*/
  FastArray		objMap;		/* Object crossreference map.	*/
  FastArray		ptrMap;		/* Pointer crossreference map.	*/
#ifndef	_IN_NSUNARCHIVER_M
#undef	GSUnarchiverArray
#endif
  unsigned		cursor;		/* Position in data buffer.	*/
  unsigned		version;	/* Version of archiver used.	*/
  NSZone		*zone;		/* Zone for allocating objs.	*/
  NSMutableDictionary	*objDict;	/* Class information store.	*/
}

/* Initializing an unarchiver */
- (id) initForReadingWithData: (NSData*)data;

/* Decoding objects */
+ (id) unarchiveObjectWithData: (NSData*)data;
+ (id) unarchiveObjectWithFile: (NSString*)path;

/* Managing */
- (BOOL) isAtEnd;
- (NSZone*) objectZone;
- (void) setObjectZone: (NSZone*)zone;
- (unsigned int) systemVersion;

/* Substituting Classes */
+ (NSString*) classNameDecodedForArchiveClassName: (NSString*)nameInArchive;
+ (void) decodeClassName: (NSString*)nameInArchive
	     asClassName: (NSString*)trueName;
- (NSString*) classNameDecodedForArchiveClassName: (NSString*)nameInArchive;
- (void) decodeClassName: (NSString*)nameInArchive 
	     asClassName: (NSString*)trueName;

#ifndef	STRICT_OPENSTEP
/* Substituting objects */
- (void) replaceObject: (id)anObject withObject: (id)replacement;
#endif
@end

#ifndef	NO_GNUSTEP
@interface	NSUnarchiver (GNUstep)

/*
 *	Re-using the unarchiver - the 'resetUnarchiverWithdata:atIndex:'
 *	method lets you re-use the archive to decode a new data object
 *	or, in conjunction with the 'cursor' method (which reports the
 *	current decoding position in the archive), decode a second
 *	archive that exists in the data object after the first one.
 */
- (unsigned) cursor;
- (void) resetUnarchiverWithData: (NSData*)data
			 atIndex: (unsigned)pos;

/*
 *	Subclassing with different input format.
 *	NSUnarchiver normally reads directly from an NSData object using
 *	the methods -
 *		[-deserializeTypeTagAtCursor:]
 *		    to decode type tags for data items, the tag is the
 *		    first byte of the character encoding string for the
 *		    data type (as provided by '@encode(xxx)'), possibly
 *		    with the top bit set to indicate that what follows is
 *		    a crossreference to an item already encoded.
 *		[-deserializeCrossRefAtCursor:],
 *		    to decode a crossreference number either to identify the
 *		    following item, or to refer to a previously encoded item.
 *		    Objects, Classes, Selectors, CStrings and Pointer items
 *		    have crossreference encoding, other types do not.
 *		[-deserializeData:ofObjCType:atCursor:context:]
 *		    to decode all other information.
 *
 *	And uses other NSData methods to read the archive header information
 *	from within the method:
 *		[-deserializeHeaderAt:version:classes:objects:pointers:]
 *		    to read a fixed size header including archiver version
 *		    (obtained by [self systemVersion]) and crossreference
 *		    table sizes.
 *
 *	To subclass NSUnarchiver, you must implement your own versions of the
 *	four methods above, and override the 'directDataAccess' method to
 *	return NO so that the archiver knows to use your serialization
 *	methods rather than those in the NSData object.
 */
- (BOOL) directDataAccess;
- (void) deserializeHeaderAt: (unsigned*)cursor
		     version: (unsigned*)systemVersion
		     classes: (unsigned*)classCount
		     objects: (unsigned*)objectCount
		    pointers: (unsigned*)pointerCount;

/* Compatibility with libObjects */
- (void) decodeArrayOfObjCType: (const char*) type
		         count: (unsigned)count
			    at: (void*)buf
		      withName: (id*)name;
- (void) decodeIndent;
- (void) decodeValueOfCType: (const char*) type
			 at: (void*)buf
		   withName: (id*)name;
- (void) decodeValueOfObjCType: (const char*) type
			    at: (void*)buf
		      withName: (id*)name;
- (void) decodeObjectAt: (id*)anObject
	       withName: (id*)name;
@end
#endif


/* Exceptions */
extern NSString *NSInconsistentArchiveException;

#endif	/* __NSArchiver_h_GNUSTEP_BASE_INCLUDE */
