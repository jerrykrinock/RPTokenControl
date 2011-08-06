#import <Cocoa/Cocoa.h>

extern id const SSYNoTokensMarker ;

/*!
 @brief    RPTokenControl is a replacement for NSTokenField.
 It is geared toward looking presenting a nice-looking "Tag Cloud" for bookmarks.
 In that context, think "token" = "tag".
  @detail
 <h3>INHERITANCE</h3>
 RPTokenControl is a subclass of NSControl : NSView : NSObject
 <h3>SYSTEM REQUIREMENTS</h3>
 RPTokenControl requires Mac OS 10.5 or later.  It was originally written for Mac OS X 10.3,
 though, so it still has some old-fashioned accessors, etc.
 <h3>KVC-COMPLIANT PROPERTIES</h3>
 The following properties may be set and observed using key-value coding,
 except those noted as read-only may be only observed.
 Accessor methods may also be available.
 <ul>
 <li>
 <h4>id objectValue</h4>
 The tokens displayed in the control.
 May be an NSArray, NSSet or NSCountedSet of tokens, or an NSStateMarker.
 The array elements (tokens) may be NSString or RPCountedToken objects.
 
 A token is composed of (1) text (a string) and, optionally, (2) a count.
 If  is an NSCountedSet, counts are evaluated with -countForObject:.
 In other collections, NSString objects have an implied count of 1.
 
 Note: NSCountedSet has some limitations.  For example, you cannot setCount:
 for an object.  The only way to set a members count to N is to add it N times.  Arghhhh.
 Thus, for many applications, a simple collection of RPCountedToken objects may be better
 than an NSCountedSet.
 
 If objectValue is nil, the view will display the No Tokens placeholder.
 
 </li>
 <li>
 <h4>NSMutableIndexSet* selectedIndexSet</h4>
 Index set giving the indexes of tokens that are selected (highlighted) in the RPTokenControl.
 "Safe" accessors which make immutable copies are available.
 </li>
 <li>
 <h4>NSArray* selectedTokens</h4>
 An array of NSString objects, the text values of all tokens which are selected (highlighted) in the RPTokenControl.
 This array is derived from selectedIndexSet.
 This property is KVC-compliant for reading only.
 You can observe it to find when the selection has changed.
 But there is no actual instance variable and there is no setter.
 </li>
 <li>
 <h4>NSCharacterSet* disallowedCharacterSet</h4>
 If, while typing in a new token, the user enters a character from the disallowedCharacterSet, it will be replaced
 with an underscore ("_"), and the System Alert will sound.  The user may continue typing after this happens.
 Note: Don't confuse disallowedCharacterSet with tokenizingCharacterSet.
 </li>
 <li>
 <h4>NSString* placeholderString</h4>
 String which will be displayed if tokens is nil or empty.
 </li>
 <li>
 <h4> int maxTokensToDisplay</h4>
 Defines the maximum number of tokens that will be displayed.
 Default value is infinite = NSNotFound.
 </li>
 <li>
 <h4> BOOL showsReflections</h4>
 Defines whether or not the view shows a pretty, Leopard-dock-like
 reflection of each token.
 Default value is NO.
 </li>
 <li>
 <h4>float backgroundWhiteness</h4>
 Defines the background color drawn in between the tokens.
 Uses grayscale from 0.0=black to 1.0=white.
 Default value is 1.0 (white)
 </li>
 <li>
 <h4> BOOL appendCountsToStrings</h4>
 Sets whether or not tokens will be drawn with their count appended in square brackets.
 For example, if YES, a token "MyToken" with count 5 will appear as "MyToken [5]". </li>
 It would look silly to set this to YES if setShowsCountsAsToolTips is also YES.
 Default value is NO.
 <li>
 <h4>float fixedFontSize</h4>
 Defines a "fixed" font size to be used from drawing all tokens.
 If this value is not 0.0, all tokens will be drawn with font size equal to this value.
 If this value is 0.0, variable font sizes, from minFontSize to maxFontSize will be used.
 Default value is 0.0 (use variable font sizes).
 </li>
 <li>
 <h4>float minFontSize</h4>
 Defines the smallest font size, used to draw the smallest-count tokens.
 However, this value is ignored if fixedFontSize == 0.0.
 </li>
 <li>
 <h4>float maxFontSize</h4>
 Defines the largest font size, used to draw the largest-count tokens.
 However, this value is ignored if fixedFontSize == 0.0.
 </li>
 <li>
 <h4>BOOL showsCountsAsToolTips</h4>
 Defines whether or not tokens will have tooltips that indicate their counts.
 It would look silly to set this to YES if setAppendCountsToStrings is also YES.
 Default value is NO.</li>
 <li>
 <h4>BOOL isEditable</h4>
 If YES,
 <ul>
	<li>The 'delete' key will delete selected tokens when the RPTokenControl is firstResponder</li>
    <li>New tokens can be typed in when the RPTokenControl is firstResponder.
    <li>New tokens can be dragged in as described in <a href="#draggingDestination" target="_blank">Drag Destination</a>.</li> 
 </ul>
 If NO, none of the above will work.
 </li>
 <li>
 <h4>NSString* linkDragType</h4> 
 The linkDragType is useful if you would like special behavior when objects of this
 externally-defined drag type are dragged onto the RPTokenControl.
 This behavior may  "link" the dragged object to the destination token,
 affecting the source instead of the destination, kind of a "reverse" drag.
 For example, if you set linkDragType to be a 'bookmark' type,
 and the tokens in your RPTokenControl represented available bookmark "tags",
 you could (in external code), add the destination token to the
 dragged bookmark's "tags", thus "tagging" the dragged bookmark.
 </li>
 <li>
 <h4>NSImage* dragImage</h4>
 Defines the cursor image that will be shown when a token is dragged.
 If not set, Cocoa uses a default image. </li>
 <li>
 <a name="ivars.delegate"></a>
 <h4>id delegate</h4> 
 If a linkDragType has been set, during a drag which includes a linkDragType
 into the RPTokenControl, RPTokenControl will, after testing that the delegate responds,
 send the following messages to the delegate:
 <ul>
 <li>-draggingEntered:</li> 
 <li>-draggingUpdated:</li>
 <li>-performDragOperation:</li> 
 <li>-draggingExited:
 </ul>
 For documentation of when these messages will be sent, their parameters and expected
 return values, see Cocoa's "NSDraggingDestination Protocol Reference" document.
 </li>
 </ul>
 <h3>BINDINGS</h3>
 RPTokenControl has the following bindings exposed:
 <ul>
 <li>value</li>  Bindings access to the property objectValue
 <li>enabled</li>
 <li>toolTip</li>
 <li>fixedFontSize</li>
</ul>
 <h3>TARGET-ACTION</h3>
 RPTokenControl will send an action to its target when its selection changes
 due to a mouseUp or mouseDown event.
 (Observing selectedTokens or selectedIndexSet is an alternative to this.)
 <h3>DRAGGING SOURCE</h3>
 RPTokenControl provides four pasteboard types to the dragging pasteboard.
 <ol>
 <li>NSStringPboardType: NSString of the last selected token</li>
 <li>NSTabularTextPboardType: tab-separated string of selected tokens</li>
 <li>RPTokenPboardType: same as NSString PboardType</li>
 <li>RPTabularTokenPboardType: same as NSTabularTextPboardType</li>
 </ol>
 Although the payload is the same as the first two types, the last two
 types are provided to distinguish drags from the RPTokenControl from
 drags of text from other sources.  This is in case the app wants to
 do something different when it receives "token" strings.
  
 Dragging a token always initiates a NSDragOperationCopy operation.
 Dragged tokens are never removed from the RPTokenControl
 <a name="draggingDestination"></a>
 <h3>DRAGGING DESTINATION</h3>
 If system is Mac OS 10.3, or if ivar isEditable=NO, RPTokenControl is not a dragging destination.
 Attempted drags will return NSDragOperationNone.

 If system if Mac OS 10.4 or later, and if ivar isEditable=YES,
 tokens or strings dragged into RPTokenControl will be added to tokens.
 They will not be selected.
 Drag destination supports only strings, not counts.
 New tokens dropped in will have a count of 1.

 If the pasteboard contains an object of the set linkDragType, it will takes precedence.
 Behavior will be only as described above in <a href="#ivars.delegate" target="_blank">delegate</a>.
 No token will be added, and other drag types on sender's the pasteboard will be ignored.
 <h3>VERSION HISTORY</h3>
 <ul>
 <li>Version 2.0.  20100127.  
 - Now requires Mac OS X 10.5 or later.
 - Known issue: Typing in tokens does not work propely.  I'm using it non-editable
   at this time.
 - Some bindings support has been added.
 - To be more of a drop-in replacement for NSTokenField, the attribute "tokens" has been changed to
   "objectValue".
 </li>
 <li>Version 1.2.  20100116.  
 - Instead of always changing the selection in response to mouseDown:, the selection is
   now changed in response to mouseDown: if the shift or cmd key is down, but instead
   in response to mouseUp: if the shift or cmd key is not down.  This is the way Apple's
   apps do it (I checked Safari's Show All Bookmarks and a Finder browser), and allows
   a drag of multiple items to be initiated immediately instead of requiring a wonky
   triple-click.
 - When the vertical scroller is not needed, the tag cloud content now increases its
 width slightly to cover the freed stripe on the right, and vice versa.
 </li>
 <li>Version 1.1.  20090730.  
 - No longer retains the delegate.&nbsp;  This was causing a retain cycle in my app, and
 I believe that not retaining the delegate would be more conventional Cocoa behavior.
 </li>
 <li>Version 1.0.2.  20080206.  
 - -setTokens now retains old value of _tokens until after triggering change notification
   to observer.  This was sometimes causing crashes in Tiger but not Leopard.
 - The ellipsis token is now better behaved.  When clicking the ellipsisToken, instead of
   being selected, the leftmost displayed token is scrolled off and, if there is room,
   the rightmost token which was truncated is scrolled in.  Scrolling can be activated
   in either direction by using the arrow keys when the end tag is selected.
 - Fixed bug in -keyDown which caused NSArray exception to be logged if down-arrow
   key was typed when no tokens were selected.
 - Fixed bug in -drawRect which caused focus ring to scroll with the RPTokenControl
   when enclosed in a scroll view.  Did this by replacing two dozen lines of very stupid
   code with three lines of smart code.
 </li>
 <li>Version 1.0.1.  20080102.  
 - Added hysteresis so that drag does not begin until significant mouse movement.
 </li>
 <li>Version 1.0.0.  20071226
 - Initial release.
 </li>
 </ul>
 <h3>AUTHOR</h3>
 RPTokenControl is an adaptation of Robert Pointon's <a href="http://www.fernlightning.com/doku.php?id=randd:tcloud:start">Tag Cloud NSView</a>. 
 It was adapted by Jerry Krinock jerry at ieee.org in San Jose, California USA.
 (I'm not afraid of more spam, but a bug in HeaderDoc does not allow at-sign to be used even if it is backslash-escaped as documented.) 
*/

/*
 If you are developing with the 10.5 SDK, MAC_OS_X_VERSION_MAX_ALLOWED = 1050, MAC_OS_X_VERSION_10_5 = 1050 and the following #if will be true.
 If you are developing with the 10.6 SDK, MAC_OS_X_VERSION_MAX_ALLOWED = 1060, MAC_OS_X_VERSION_10_5 = 1050 and the following #if will be false.
 */
#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5) 
@interface RPTokenControl : NSControl
#else
@interface RPTokenControl : NSControl <NSTextFieldDelegate>
#endif
{
	id m_objectValue ;
    int _maxTokensToDisplay ;
	int _firstTokenToDisplay ;
	int _showsReflections ;
	float _backgroundWhiteness ;
	int _lastSelectedIndex ;
	BOOL _appendCountsToStrings ;
	BOOL _showsCountsAsToolTips ;
	float _minFontSize ;
	float _maxFontSize ;
	CGFloat m_fixedFontSize ;
	BOOL _isEditable ;
	
	NSImage* _dragImage ;
	NSMutableArray* _framedTokens ;
	NSMutableArray* _truncatedTokens ;
	NSCharacterSet* m_disallowedCharacterSet ;
	NSCharacterSet* m_tokenizingCharacterSet ;
	unichar m_tokenizingCharacter ;
	NSString* m_noTokensPlaceholder ;
	NSString* m_noSelectionPlaceholder ;
	NSString* m_multipleValuesPlaceholder ;
	NSString* m_notApplicablePlaceholder ;
	id _delegate ;
	NSString* _linkDragType ;
	NSMutableIndexSet* _selectedIndexSet ;
	NSMutableString* _tokenBeingEdited ;
	int _indexOfFramedTokenBeingEdited ;
	NSTextField* _textField ;
	BOOL _isDoingLayout ;
	NSPoint _mouseDownPoint ; // for hysteresis in beginning drag
}

@property (retain) id objectValue ;
@property (retain) NSImage* dragImage ;
@property (retain) NSMutableString* tokenBeingEdited ;
@property (copy) NSString* linkDragType ;
@property (assign) id delegate ;
@property (retain) NSCharacterSet* disallowedCharacterSet ;
@property (retain) NSCharacterSet* tokenizingCharacterSet ;
@property (assign) unichar tokenizingCharacter ;
@property (copy) NSString* noTokensPlaceholder ;
@property (copy) NSString* noSelectionPlaceholder ;
@property (copy) NSString* multipleValuesPlaceholder ;
@property (copy) NSString* notApplicablePlaceholder ;
@property (assign) CGFloat fixedFontSize ;

/*!
 @brief    An NSArray of the tokens selected in the control view

 @details  tokenizingCharacter and tokenizingCharacterSet have an assymetrical relationship.
 Setting a tokenizingCharacter will set tokenizingCharacterSet to a new set
 containing that single character.  But setting tokenizingCharacterSet will not
 affect the value of tokenizingCharacter.  When parsing user input for tokenizing
 characters, RPTokenControl will always use the current value of tokenizingCharacterSet.
 
 @result   An array of NSStrings.  Each string is the text of a selected token.  Counts are not provided.
 */
- (NSArray*)selectedTokens ;

/*!
 @brief    getter for ivar selectedIndexSet
 @result   an immutable copy of selectedIndexSet
 */
- (NSIndexSet*)selectedIndexSet ;

/*!
 @brief    setter for ivar selectedIndexSet
 @details  Makes a mutable copy of the argument.
 Make sure that the range of the argument is within the range of tokens
 */
- (void)setSelectedIndexSet:(NSIndexSet*)newSelectedIndexSet ;

/*!
 @brief    setter for ivar maxTokensToDisplay
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 If not set, all tokens that fit will be displayed
 */
- (void)setMaxTokensToDisplay:(int)maxTokensToDisplay ;

/*!
 @brief    setter for the ivar showsReflections
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setShowsReflections:(BOOL)yn ;

/*!
 @brief    setter for ivar backgroundWhiteness
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setBackgroundWhiteness:(float)whiteness ;

/*!
 @brief    setter for ivar appendCountsToStrings
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setAppendCountsToStrings:(BOOL)yn ;

/*!
 @brief    setter for the ivar minFontSize
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setMinFontSize:(float)x ; // defaults to 11.0 if not set

/*!
 @brief    setter for the ivar maxFontSIze
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setMaxFontSize:(float)x ; // defaults to 40.0 if not set

/*!
 @brief    setter for the ivar showsCountsAsToolTips.
 @details  It would look silly to set this to YES if setAppendCountsToStrings is also YES.
 If not set, will default to NO.
 */
- (void)setShowsCountsAsToolTips:(BOOL)yn ;

/*!
 @brief    setter for ivar isEditable
 */
- (void)setEditable:(BOOL)yn ;


@end
