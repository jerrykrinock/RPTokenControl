#import <Cocoa/Cocoa.h>

/*!
 @brief    RPCountedToken is an NSString with a count.
 Although the count may be used for any arbitrary purpose, it is normally used to
 represent the number of times that an RPCountedToken has been "added" to its parent collection.
 Because its count is settable, it is used internally by RPTokenControl to represent tokens,
 and may be used externally in applications where the inability to set the count makes
 NSCountedSet too cumbersome.
 @detail
 <h3>INHERITANCE</h3>
 RPCountedToken is a subclass of NSObject
 <h3>SYSTEM REQUIREMENTS</h3>
 RPTokenControl has been tested on systems as early as Mac OS 10.3.
 <h3>KVC-COMPLIANT PROPERTIES</h3>
 The following properties may be set and observed using key-value coding,
 except those noted as read-only may be only observed.
 Accessor methods may also be available.
 <ul>
 <li>
 <h4>NSString* text</h4>
 The string.
 </li>
 <li>
 <h4>int count</h4> 
 The count.  The value count=0 is reserved for the special "ellipsis" RPCountedToken
 </li>
 </ul>
 <h3>VERSION HISTORY, AUTHOR, ETC.</h3>
 See RPTokenControl.h for this info.
 */
@interface RPCountedToken : NSObject {
	NSString *_text ;
	int _count ;
	// _count = 0 denotes a special "ellipsis token"
}

/*!
 @brief    designated initializer, sets both instance variables.
 @param    text new value for the text property of the receiver
 @param    count new value for the count property of the receiver
 @result   an instance of RPCountedToken
 */
- (id)initWithText:(NSString*)text
			 count:(int)count ;
/*!
 @brief    Increments the count property of the receiver.
 */
- (void)incCount ;

/*!
 @brief    getter for the ivar text
 */
- (NSString*)text ;

/*!
 @result   The text value of the receiver with the count value appended in square brackets.
 Example: "MyText [5]"
 */
- (NSString*)textWithCountAppended ;

/*!
 @brief    getter for the ivar count
 */
- (int)count ;

/*!
 @result   NSOrderedAscending, NSOrderedSame or NSOrderedDescending,
 determined by sending -localizedCaseInsensitiveCompare:other to the receiver.
 */
- (NSComparisonResult)textCompare:(RPCountedToken*)other ;

/*!
 @result   if count of the receiver < count of other, returns NSOrderedDescending.
 If count of the receiver > count of other, returns NSOrderedAscending.
 If count of the receiver == count of other, returns result of -textCompare:other.
 */
- (NSComparisonResult)countCompare:(RPCountedToken*)other ;

/*!
 @result   If the receiver is an ellipsis token, returns YES.
 Otherwise, returns NO.
 @details  With the current design, -[myCountedToken isEllipsisToken] is equivalent to
 -[myCountedToken count] == 0 && myCountedToken != nil.  This method is a convenience
 and attempt to avert future bugs.
 */
- (BOOL)isEllipsisToken ;

/*!
 @brief    gets a special "ellipsis" RPCountedToken
 @details  The text of the special "ellipsis" RPCountedToken is a one-character string, 
 the unicode eliipsis (0x2026).  The count is 0.  This special RPCountedToken is used by
 RPTokenControl as the last token when there are too many to fit in the given frame.
 @result   an autoreleased instance of the special "ellipsis" RPCountedoken
 */
+ (RPCountedToken*)ellipsisToken ;

@end

