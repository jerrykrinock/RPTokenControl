#import <Cocoa/Cocoa.h>

extern id const SSYNoTokensMarker ;

#define RPTokenFancyEffectReflection 1
#define RPTokenFancyEffectShadow     2

enum RPTokenControlTokenColorScheme_enum {
    RPTokenControlTokenColorSchemeBlue,
    RPTokenControlTokenColorSchemeWhite
    } ;
typedef enum RPTokenControlTokenColorScheme_enum RPTokenControlTokenColorScheme ;

/*!
 @brief    RPTokenControl is a replacement for NSTokenField.
 It is geared toward looking presenting a nice-looking "Tag Cloud" for bookmarks.
 In that context, think "token" = "tag".
  @detail
 <h3>INHERITANCE</h3>
 RPTokenControl is a subclass of NSControl : NSView : NSObject
 <h3>SYSTEM REQUIREMENTS</h3>
 RPTokenControl requires Mac OS 10.7 or later.  It was originally written for
 macOS 10.3, though, so it still has some old-fashioned accessors, etc.
 <h3>KVC-COMPLIANT PROPERTIES</h3>
 The following properties may be set and observed using key-value coding,
 except those noted as read-only may be only observed.
 Accessor methods may also be available.
 <ul>
 <li>
 <h4>id objectValue</h4>
 The tokens displayed in the control.
 May be an NSArray, NSSet or NSCountedSet of strings, or an NSStateMarker.
 
 A token is composed of (1) text (a string) and, optionally, (2) a count.
 If  is an NSCountedSet, counts are evaluated with -countForObject:.
 In other collections, NSString objects have an implied count of 1.
 
 Note: NSCountedSet has some limitations.  For example, you cannot setCount:
 for an object.  The only way to set a members count to N is to add it N times.

 
 If objectValue is nil, the view will display the No Tokens placeholder.
 
 </li>
 <li>
 <h4>NSMutableIndexSet* selectedIndexSet</h4>
 Index set giving the indexes of tokens that are selected (highlighted) in the
 RPTokenControl.  "Safe" accessors which make immutable copies are available.
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
 <h4>NSCharacterSet* disallowedCharacterSet and replacementString</h4>
 If, while typing in a new token, the user enters a character from the disallowedCharacterSet, it will be replaced
 with the replacementString, and the System Alert will sound.  The user may continue typing after this happens.
 Note: Don't confuse disallowedCharacterSet with tokenizingCharacterSet.  During -awakeFromNib, replacmentString
 is set to @"_"
 </li>
 <li>
 <h4>NSString* placeholderString</h4>
 String which will be displayed if tokens is nil or empty.
 </li>
 <li>
 <h4> NSInteger maxTokensToDisplay</h4>
 Defines the maximum number of tokens that will be displayed.
 Default value is infinite = NSNotFound.
 </li>
 <li>
 <h4>BOOL fancyEffects</h4>
 Defines whether or not the view shows a pretty, Leopard-dock-like
 reflection of each token and/or a shadow.  Pass 0 for no fancy effects.
 For fancy effects, pass RPTokenFancyEffectReflection and/or
 RPTokenFancyEffectShadow.  They *or* bitwise (although that would definitely
 look pretty ridiculous nowadays.)
 </li>
 <li>
 <h4>RPTokenControlTokenColorScheme tokenColorScheme</h4>
 Determines whether the tokens are blue (like NSTokenField) or white.
 The default is RPTokenControlColorSchemeBlue.
 </li>
 <li>
 <h4>float backgroundWhiteness</h4>
 Defines the background color drawn in between the tokens.
 Uses grayscale from 0.0=black to 1.0=white.
 Default value is 1.0 (white)
 </li>
 <li>
 <h4>float cornerRadiusFactor</h4>
 Should be between 0.0 and 0.5.  0.0 means square corners. 0.5 means maximum
 roundness, like NSTokenField.  Value of 0.2 or less  allows tokens to be
 packed in as tightly as possible.  Larger values give more loose packing.
 Default value is 0.5.
 </li>
 <li>
 <h4>float widthPaddingMultiplier</h4>
 Should be > 1.0.  Indicates the width of the padding between the edge of
 each token and the text, on the left and right, as a multiple of the
 corner radius.  1.0 creates the smallest tokens.  3.0 makes roomy tokens,
 like NSTokenField.  The default value is 3.0.
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
 <h4>RPTokenControlEditability</h4>
 <table border="1" cellpadding="10" align="left">
 <tr>
 <td>Value</td>
 <td>The 'delete' key will delete selected tokens when the RPTokenControl is firstResponder</td>
 <td>New tokens can be typed in when the RPTokenControl is firstResponder.</td>
 <td>New tokens can be dragged in as described in <a href="#draggingDestination" target="_blank">Drag Destination</a>.</td>
 </tr>
 <tr>
 <td>RPTokenControlEditability0</td>
 <td>NO</td>
 <td>NO</td>
 <td>NO</td>
 </tr>
 <tr>
 <td>RPTokenControlEditability1</td>
 <td>YES</td>
 <td>NO</td>
 <td>NO</td>
 </tr>
 <tr>
 <td>RPTokenControlEditability2</td>
 <td>YES</td>
 <td>YES</td>
 <td>YES</td>
 </tr>
 </table>
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
 <h5>Dragging</h5>
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
 <h5>Renaming Tokens</h5>
 If the delegate responds to the RPTokenControlDelegate protocol optional method
 -tokenControl:renameToken:, a contextual menu item "Rename 'xxx'" will be 
 available when performing a secondary click on a token, and click that menu
 item will send a -tokenControl:renameToken: message to the delegate.
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
 <li>NSPasteboardTypeString: NSString of the last selected token</li>
 <li>NSTabularTextPboardType: tab-separated string of selected tokens</li>
 <li>RPTokenControlPasteboardTypeTokens: same as NSString PboardType</li>
 <li>RPTokenControlPasteboardTypeTabularTokens: same as NSTabularTextPboardType</li>
 </ol>
 Although the payload is the same as the first two types, the last two
 types are provided to distinguish drags from the RPTokenControl from
 drags of text from other sources.  This is in case the app wants to
 do something different when it receives "token" strings.
  
 Dragging a token always initiates a NSDragOperationCopy operation.
 Dragged tokens are never removed from the RPTokenControl
 <a name="draggingDestination"></a>
 <h3>DRAGGING DESTINATION</h3>
 If ivar isEditable=YES, tokens or strings dragged into RPTokenControl will be
 added to tokens.  They will not be selected.  Drag destination supports only
 strings, not counts.  New tokens dropped in will have a count of 1.

 If the pasteboard contains an object of the set linkDragType, it will takes
 precedence.  Behavior will be only as described above in 
 <a href="#ivars.delegate" target="_blank">delegate</a>. No token will be added,
 and other drag types on sender's the pasteboard will be ignored.

 <h3>VERSION HISTORY</h3>
 <ul>
 <li>Version 5.  20170523.
 - Added VoiceOver (accessibility) support
 - Now compiles with Automatic Reference Counting or not, instead of just not.
 </li>
 <li>Version 4.  20150304.
 - Fixed deprecations to 10.8+ Deployment Target
 - Now requires OS X 10.7 or later.
 </li>
<li>Version 3.1.  20131208.
 - Added -encodeWithCoder:, -initWithCoder:.  Thanks to crispinb for 
 noticing this.
 </li>
 <li>Version 3.0.  20130830.
 - Added parameters so that the tokens may be configured to look pretty much
 like the blue tokens in Apple's NSTokenField, and the property values which do
 this are now *default* .  Yes, folks: Shadows and reflections are not cool any
 more.  You can still get them, but you need to modify you code to set the new
 properties 'fancyEffects' and 'tokenColorScheme' accordingly.  Also,
 the property 'showsReflections' has been removed.  To replace it, use
 'fancyEffects'.
 </li>
 <li>Version 2.4.  20130514.
 - Fixed documentation (in this file) and demo project to reflect the fact that
 setting the objectValue of RPTokenControl to a set of RPCountedToken objects
 is no longer supported.
 - In demo project Build Settings, updated Build Settings to work in Xcode 4.
 Base SDK is now "Latest macOS", Architectures are now Xcode default instead
 of ppc + i386.
 </li>
 <li>Version 2.3.  20130415.
 - -keyDown: now forwards un-handled 'tab' key down events to super, as is
 proper.
 </li>
 <li>Version 2.2.  20121203.
 - Added a contextual menu to tokens, with items "Delete" and, optionally,
 "Rename".
 - If editability is < 2, receiving a key down event whose character is the
 first character of a token now causes the enclosing scroll view, if any,
 to scroll to the first such token.
 - 64-bit clean
 </li>
 <li>Version 2.1.  20120710.
 - Removed a -retain which could cause a crash.  See Note 20120629.
 </li>
 <li>Version 2.0.  20100127.  
 - Now requires macOS 10.5 or later.
 - Known issue: Typing in tokens does not work properly.  I'm using it
 non-editable at this time.
 - Some bindings support has been added.
 - To be more of a drop-in replacement for NSTokenField, the attribute "tokens" has been changed to
   "objectValue".
 </li>
 <li>Version 1.2.  20100116.  
 - Instead of always changing the selection in response to mouseDown:, the selection is
   now changed in response to mouseDown: if the shift or cmd key is down, but instead
   in response to mouseUp: if the shift or cmd key is not down.  This is the way Apple's
   apps do it (I checked Safari's Edit Bookmarks and a Finder browser), and allows
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

enum RPTokenControlEditability_enum {
    RPTokenControlEditability0,
    RPTokenControlEditability1,
    RPTokenControlEditability2
    } ;
typedef enum RPTokenControlEditability_enum RPTokenControlEditability ;

/*!
 @brief    Notification which is posted whenever the user deletes tokens
 by selecting them and hitting the 'delete' key
 @details  Note that this can only happen if you have set the receiver's
 editability to a value >= RPTokenControlEditability1.  The 'object'
 of the posted notification will be the affected RPTokenControl.  The 'userInfo'
 dictionary of the posted notification will contain one key,
 RPTokenControlUserDeletedTokensKey, whose value is an array of strings
 which are the deleted tokens.
 
 Note added 20121203: This notification nonsense is maybe very stupid.  I'm
 thinking that I should have instead declared a delegate method for deleting
 tokens from the data model, following the pattern which I have now used for
 renaming tokens.
 */
extern NSString* const RPTokenControlUserDeletedTokensNotification ;
extern NSString* const RPTokenControlUserDeletedTokensKey ;

@class RPTokenControl ;

@protocol RPTokenControlDelegate <NSObject>

- (void)tokenControl:(RPTokenControl*)control
         renameToken:(NSString*)token ;

/*!
 @brief    Returns a localized title of a contextual menu item which deletes one
 or more tokens
 @details  Typically, returns, for example, "Delete 'Foo'" if there is only one
 token proposed to be deleted, or "Delete 5 Tags" if more than one.
 
 If the delegate does not implement this method, a default, English menu
 item title will appear in the contextual menu.
 @param    count  The number of tokens which will be deleted if the user clicks
 the subject menu item
 @param    tokenName  If count is 1, the name of the item which may be deleted.
 Otherwise, an arbitrary string which should be ignored.
 */
- (NSString*)menuItemTitleToDeleteTokenControl:(RPTokenControl*)tokenControl
                                         count:(NSInteger)count
                                     tokenName:(NSString*)tokenName ;

@end

@interface RPTokenControl : NSControl <
NSTextFieldDelegate,
NSDraggingSource,
NSPasteboardWriting,
NSAccessibilityGroup
> {
    id m_objectValue ;
    NSInteger _maxTokensToDisplay ;
    NSInteger _firstTokenToDisplay ;
    NSInteger _fancyEffects ;
    float _backgroundWhiteness ;
    NSInteger _tokenColorScheme ;
    float _cornerRadiusFactor ;
    float _widthPaddingMultiplier ;
    NSInteger _lastSelectedIndex ;
    BOOL _appendCountsToStrings ;
    BOOL _showsCountsAsToolTips ;
    float _minFontSize ;
    float _maxFontSize ;
    CGFloat m_fixedFontSize ;
    RPTokenControlEditability m_editablity ;
    BOOL m_canDeleteTags ;
    NSArray* _accessibilityChildren;


    NSImage* _dragImage ;
    NSMutableArray* _framedTokens ;
    NSMutableArray* _truncatedTokens ;
    NSCharacterSet* m_disallowedCharacterSet ;
    NSString* m_replacementString ;
    NSCharacterSet* m_tokenizingCharacterSet ;
    unichar m_tokenizingCharacter ;
    NSString* m_noTokensPlaceholder ;
    NSString* m_noSelectionPlaceholder ;
    NSString* m_multipleValuesPlaceholder ;
    NSString* m_notApplicablePlaceholder ;
    NSObject <RPTokenControlDelegate> * m_delegate ;
    NSString* _linkDragType ;
    NSMutableIndexSet* _selectedIndexSet ;
    NSMutableString* _tokenBeingEdited ;
    NSInteger _indexOfFramedTokenBeingEdited ;
    NSTextField* _textField ;
    BOOL _isDoingLayout ;
    NSPoint _mouseDownPoint ; // for hysteresis in beginning drag
}

@property (retain) NSImage* dragImage ;
@property (retain) NSMutableString* tokenBeingEdited ;
@property (copy) NSString* linkDragType ;
@property (assign) NSObject <RPTokenControlDelegate> * delegate ;
@property (retain) NSCharacterSet* disallowedCharacterSet ;
@property (copy) NSString* replacementString ;
@property (retain) NSCharacterSet* tokenizingCharacterSet ;
@property (assign) unichar tokenizingCharacter ;
@property (copy) NSString* noTokensPlaceholder ;
@property (copy) NSString* noSelectionPlaceholder ;
@property (copy) NSString* multipleValuesPlaceholder ;
@property (copy) NSString* notApplicablePlaceholder ;
@property (assign) CGFloat fixedFontSize ;
@property (assign) RPTokenControlEditability editability ;

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
- (void)setMaxTokensToDisplay:(NSInteger)maxTokensToDisplay ;

/*!
 @brief    setter for the ivar fancyEffects
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setFancyEffects:(NSInteger)fancyEffects ;

/*!
 @brief    setter for ivar backgroundWhiteness
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setBackgroundWhiteness:(float)whiteness ;

/*!
 @brief    setter for ivar tokenColorScheme
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setTokenColorScheme:(RPTokenControlTokenColorScheme)tokenColorScheme ;

/*!
 @brief    setter for ivar cornerRadiusFactor
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setCornerRadiusFactor:(float)whiteness ;

/*!
 @brief    setter for ivar widthPaddingMultiplier
 @details  Invoking this method will recalculate the receiver's layout
 and mark the receiver with -setNeedsDisplay.
 */
- (void)setWidthPaddingMultiplier:(float)widthPaddingMultiplier ;

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
 @brief    setter for ivar editability
 */
- (void)setEditability:(RPTokenControlEditability)editability ;


@end
