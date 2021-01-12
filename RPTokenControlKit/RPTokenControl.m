#import "RPTokenControl.h"
#import "RPBlackReflectionUtils.h"
#import "RPCountedToken.h"
#import "NSView+FocusRing.h"
#import "SSY+Countability.h"

NSString* const RPTokenControlUserDeletedTokensNotification = @"RPTokenControlUserDeletedTokensNotification" ;
NSString* const RPTokenControlUserDeletedTokensKey = @"RPTokenControlUserDeletedTokensKey" ;

id const SSYNoTokensMarker = @"SSYNoTokensMarker" ;
NSString* const RPTokenControlPasteboardTypeTokens = @"com.sheepsystems.RPTokenControl.tokens" ;
NSString* const RPTokenControlPasteboardTypeTabularTokens = @"com.sheepsystems.RPTokenControl.tabular-tokens" ;

NSRange SSMakeRangeIncludingEndIndexes(NSInteger b1, NSInteger b2) {
	NSInteger diff, location ;
	if (b2 > b1) {
		diff = b2 - b1 ;
		location = b1 ;
	}
	else {
		// This will also work if b2=b1
		diff = b1 - b2 ;
		location = b2 ;
	}
	
	return NSMakeRange(location, diff + 1) ;
}

@interface NSObject (ExtractStringsFromCollection)

/*!
 @brief    If the receiver is a collection, returns a set containing the string
 objects and the texts of the RPCountedToken objects in the collection, or an
 empty set if there are none such.

 @details  If the receiver is not a collection, returns nil.
*/
- (NSSet*) extractStrings ;

@end

@implementation NSObject (ExtractStringsFromCollection)

- (NSSet*)extractStrings {
	if (![self conformsToProtocol:@protocol(NSFastEnumeration)]) {
		return nil ;
	}
	
	NSMutableSet* strings = [[NSMutableSet alloc] init] ;
	Class countedTokenClass = [RPCountedToken class] ;
	Class stringClass = [NSString class] ;
	for (id object in (NSObject <NSFastEnumeration> *)self) {
		NSString* string = nil ;
		if ([object isKindOfClass:countedTokenClass]) {
			string = [(RPCountedToken*)object text] ;
		}
		else if ([object isKindOfClass:stringClass]) {
			string = (NSString*)object ;
		}
		
		if (string) {
			[strings addObject:string] ;
		}
		else {
			NSLog(@"Internal Error 152-9184 %@", object) ;
		}
	}
	
	NSSet* output = [strings copy] ;
#if !__has_feature(objc_arc)
	[strings release];
#endif
	
	return [output autorelease] ;
}

@end

@interface FramedToken : NSObject {
	RPCountedToken* _token ;
	NSRect _bounds ;
	float _fontsize ;
}
@end

#define TCFillColorAttributeName @"TCFillColorAttributeName"
#define TCStrokeColorAttributeName @"TCStrokeColorAttributeName"
#define TCCornerRadiusFactorAttributeName @"TCCornerRadiusFactorAttributeName"
#define TCWidthPaddingMultiplierAttributeName @"TCWidthPaddingMultiplierAttributeName"

@implementation FramedToken

float const tokenBoxTextInset = 2.0 ;

+ (NSFont*)fontOfSize:(float)fontSize {
	return [NSFont labelFontOfSize:fontSize] ;
}

+ (CGFloat)widthPaddingForHeight:(CGFloat)height
                        fontSize:(float)fontSize
              cornerRadiusFactor:(float)cornerRadiusFactor
          widthPaddingMultiplier:(float)widthPaddingMultiplier {
    CGFloat widthPadding = height * cornerRadiusFactor * widthPaddingMultiplier ;
    return widthPadding ;
}

+ (NSSize)boxSizeForToken:(RPCountedToken*)token
				 fontSize:(float)fontSize
       cornerRadiusFactor:(float)cornerRadiusFactor
   widthPaddingMultiplier:(float)widthPaddingMultiplier
			  appendCount:(BOOL)appendCount {
	NSDictionary *attr = [NSDictionary dictionaryWithObject:[self fontOfSize:fontSize]
													 forKey:NSFontAttributeName] ;				
	NSString *str = appendCount ? [token textWithCountAppended] : [token text] ;
	NSSize size = [str sizeWithAttributes:attr] ;
	// Add padding space around text
    CGFloat widthPadding = [self widthPaddingForHeight:size.height
                                              fontSize:fontSize
                                    cornerRadiusFactor:cornerRadiusFactor
                                widthPaddingMultiplier:widthPaddingMultiplier] ;
	size.width += (2*tokenBoxTextInset + widthPadding) ;
	size.height += 2*tokenBoxTextInset ;
	return size ;
}

- (id)initWithCountedToken:(RPCountedToken*)token
				  fontsize:(float)f
					bounds:(NSRect)b {
	if((self = [super init])) {
#if !__has_feature(objc_arc)
		_token = [token retain] ;
#endif
        _fontsize = f;
		_bounds = b;
	}
	return self;
}
- (void)dealloc {
#if !__has_feature(objc_arc)
	[_token release];
#endif

	[super dealloc];
}

- (void)setBounds:(NSRect)b {
	_bounds = b ;
}

- (NSString*)text {
	return [_token text] ;
}

- (NSInteger)count {
	return [_token count] ;
}

- (NSRect)bounds {
	return _bounds ;
}

- (float)topEdge {
	return _bounds.origin.y ;
}

- (float)bottomEdge {
	return _bounds.origin.y + _bounds.size.height ;
}

- (float)midX {
	return _bounds.origin.x + _bounds.size.width/2 ;
}

- (float)midY {
	return _bounds.origin.y + _bounds.size.height/2 ;
}

- (float)distanceFrom:(NSPoint)point {
	float answer ;
	if (NSPointInRect(point, [self bounds])) {
		answer = 0.0 ;
	}
	else {
		float dx = (point.x - [self midX]) ;
		float dy = (point.y - [self midY]) ;
		return sqrt(dx*dx + dy*dy) ;
	}
	
	return answer ;
}

- (float)fontsize {
	return _fontsize ;
}

- (NSString*)description {
	return [NSString stringWithFormat:
            @"bounds=%@; fontSize=%f; count=%ld; text=%@",
            NSStringFromRect([self bounds]),
            [self fontsize],
            (long)[self count],
            [self text]] ;
}

- (void)drawWithAttributes:(NSDictionary*)attr
			   appendCount:(BOOL)appendCount {
	NSRect rect = NSMakeRect(_bounds.origin.x, _bounds.origin.y, _bounds.size.width-3, _bounds.size.height-3) ;

    CGFloat cornerRadiusFactor = [[attr objectForKey:TCCornerRadiusFactorAttributeName] floatValue] ;
    CGFloat widthPaddingMultiplier = [[attr objectForKey:TCWidthPaddingMultiplierAttributeName] floatValue] ;
    CGFloat cornerRadius = rect.size.height*cornerRadiusFactor ;
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect
														  radius:cornerRadius] ;
    NSColor* color ;
	
	color = [attr objectForKey:TCFillColorAttributeName] ;
    if(color) {
		[color setFill] ; 
		[path fill] ;
	}    
	
    color = [attr objectForKey:TCStrokeColorAttributeName] ;
    if(color) {
        /*
         My outlines still look wider than the outlines in NSTokenField.
         NSBezierPath documentation says that to get the thinnest possible
         line, set line width to 0.0.  Debugging here, I see that the line
         width is 1.0, the default I presume.  So I'm going to set it to 0.0,
         then set it back to the old value after -stroke.  All of this seems to
         have no effect :(  But according to the documentation, it's the way to,
         maybe someday, get what we want.
         */
        CGFloat oldLineWidth = [path lineWidth] ;
        [path setLineWidth:0.0] ;
		[color setStroke] ;
		[path stroke] ;
        [path setLineWidth:oldLineWidth] ;
	}
    
	// Add font attribute to attr and draw the string
	attr = [NSMutableDictionary dictionaryWithDictionary:attr] ;
    [(NSMutableDictionary*)attr setObject:[FramedToken fontOfSize:_fontsize]
								   forKey:NSFontAttributeName] ;
    NSString* text = appendCount ? [_token textWithCountAppended] : [_token text] ;
    
    CGFloat widthPadding = [FramedToken widthPaddingForHeight:rect.size.height
                                                     fontSize:_fontsize
                                           cornerRadiusFactor:cornerRadiusFactor
                                       widthPaddingMultiplier:widthPaddingMultiplier] ;

	[text drawAtPoint:NSMakePoint(_bounds.origin.x + widthPadding/2, _bounds.origin.y+1)
	   withAttributes:attr];
}

- (RPCountedToken*)token {
	return _token ;
}

@end

//@interface NSSet (ConvertToRPCountedTokens)
//
//- (NSMutableArray*)copyAsMutableArrayOfCountedTokens ;
//
//@end
//
//@implementation NSSet (ConvertToRPCountedTokens) 
//
//- (NSMutableArray*)copyAsMutableArrayOfCountedTokens {
//	NSMutableArray* tokens = [[NSMutableArray alloc] init] ;
//	NSEnumerator* e = [self objectEnumerator] ;
//	id object ;
//	while ((object = [e nextObject])) {
//		NSInteger targetCount = [(NSCountedSet*)self countForObject:object] ;
//		
//		// Sort by count		
//		NSInteger i ;
//		for (i=0; i<[counts count]; i++) {
//			NSInteger currentCount = [[counts objectAtIndex:i] intValue] ;
//			if (targetCount <= currentCount) {
//				break ;
//			}
//		}
//		
//		
//		RPCountedToken* token = [[RPCountedToken alloc] initWithText:object
//														 count:targetCount] ;
//		[tokens insertObject:token atIndex:i] ;
//#if !__has_feature(objc_arc)
//      [token release];
//#endif
//	}
//	
//	return tokens ;
//}
//
//@end


@interface RPTokenControl (Private)

- (void)deselectAllIndexes;
- (void)invalidateLayout;
- (BOOL)isSelectedFramedToken:(FramedToken*)framedToken;
- (void)changeSelectionPerClickOnFramedToken:(FramedToken*)clickedFramedToken;
    
@end


@interface FramedTokenAccessibilityElement : NSAccessibilityElement <NSAccessibilityButton> {
    FramedToken* _framedToken;
}

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTokenControl:(RPTokenControl*)tokenControl
                         framedToken:(FramedToken*)framedToken;

/* `framedToken` is strong/retain because the framedToken objects are often
 destroyed and replaced with new ones (in -doLayout).  (I tested that this does
 not cause a retain cycle – all initted FramedToken objects are eventually
 deallocced. */
#if __has_feature(objc_arc)
@property (nonatomic, strong) FramedToken* framedToken;
#else
@property (nonatomic, retain) FramedToken* framedToken;
#endif

@property (nonatomic, weak) RPTokenControl* tokenControl;

@end


@implementation FramedTokenAccessibilityElement

- (FramedToken*)framedToken {
    return _framedToken;
}

- (void)setFramedToken:(FramedToken*)framedToken {
    _framedToken = framedToken;
}

- (instancetype)initWithTokenControl:(RPTokenControl*)tokenControl
                         framedToken:(FramedToken*)framedToken {
    self = [super init];
        if (self) {
            self.tokenControl = tokenControl;
            self.framedToken = framedToken;
#if !__has_feature(objc_arc)
            [framedToken retain];
#endif
        }
    return self;
}

- (void)dealloc {
#if !__has_feature(objc_arc)
    [_framedToken release];
#endif

    [super dealloc];
}

/* Per documentation, and Xcode warnings, this method must be implemented even
 though all it does is to invoke super. */
- (NSRect)accessibilityFrame {
    return [super accessibilityFrame];
}

/* Per documentation, and Xcode warnings, this method must be implemented even
 though all it does is to invoke super. */
- (id)accessibilityParent {
    return [super accessibilityParent];
}

- (NSString *)accessibilityLabel {
    NSString* selectionStatus;
    if ([self.tokenControl isSelectedFramedToken:self.framedToken]) {
        selectionStatus = [NSString stringWithFormat:
                           @", %@",
                           NSLocalizedString(@"selected", nil)];
    }
    else {
        selectionStatus = @"";
    }
    return [NSString stringWithFormat:
            NSLocalizedString(@"Tag named %@ with count %ld%@", nil),
            [self.framedToken text],
            [self.framedToken count],
            selectionStatus];
}

- (BOOL)accessibilityPerformPress {
    [self.tokenControl changeSelectionPerClickOnFramedToken:self.framedToken];
    return YES;
}

- (BOOL)isAccessibilityEnabled {
    return YES;
}

@end

// Constants for ivars used in -initWithCoder, encodeWithCoder:

NSString*  constKeyAppendCountsToStrings = @"appendCountsToStrings" ;
NSString*  constKeyShowsCountsAsToolTips = @"showsCountsAsToolTips" ;
NSString*  constKeyCanDeleteTags = @"canDeleteTags" ;
NSString*  constKeyIsDoingLayout = @"isDoingLayout" ;
NSString*  constKeyTokenizingCharacter = @"tokenizingCharacter" ;
NSString*  constKeyFirstTokenToDisplay = @"firstTokenToDisplay" ;
NSString*  constKeyFancyEffects = @"fancyEffects" ;
NSString*  constKeyDelegate = @"delegate" ;
NSString*  constKeyDragImage = @"dragImage" ;
NSString*  constKeyFramedTokens = @"framedTokens" ;
NSString*  constKeyTruncatedTokens = @"truncatedTokens" ;
NSString*  constKeyDisallowedCharacterSet = @"disallowedCharacterSet" ;
NSString*  constKeyTokenizingCharacterSet = @"tokenizingCharacterSet" ;
NSString*  constKeyReplacementString = @"replacementString" ;
NSString*  constKeyNoTokensPlaceholder = @"noTokensPlaceholder" ;
NSString*  constKeyNoSelectionPlaceholder = @"noSelectionPlaceholder" ;
NSString*  constKeyMultipleValuesPlaceholder = @"multipleValuesPlaceholder" ;
NSString*  constKeyNotApplicablePlaceholder = @"notApplicablePlaceholder" ;
NSString*  constKeyLinkDragType = @"linkDragType" ;
NSString*  constKeyTextField = @"textField" ;


@implementation RPTokenControl

#pragma mark * Constants

+ (void)initialize {
	[self exposeBinding:@"value"] ;
	[self exposeBinding:@"enabled"] ;
	[self exposeBinding:@"toolTip"] ;
	[self exposeBinding:@"fixedFontSize"] ;
	[self exposeBinding:@"cornerRadiusFactor"] ;
    [self exposeBinding:@"widthPaddingMultiplier"] ;
    [self exposeBinding:@"appendCountsToStrings"] ;
	[self exposeBinding:@"tokenColorScheme"] ;
	[self exposeBinding:@"fancyEffects"] ;
}

+ (NSSet*)keyPathsForValuesAffectingSelectedTokens {
	return [NSSet setWithObjects:
			@"selectedIndexSet",
			nil] ;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString*)key {
	BOOL automatic;
	
    if ([key isEqualToString:@"tokens"]) {
        // Because I want to only be observed when I've
		// confirmed that there was a substantiveChange.
		automatic = NO ;
    }
	else if ([key isEqualToString:@"selectedTokens"]) {
        automatic = NO ;
	}
	else {
        automatic = [super automaticallyNotifiesObserversForKey:key] ;
    }
    return automatic ;
}

- (float)defaultFontSize {
	return ([self fixedFontSize] == 0.0) ? _minFontSize : [self fixedFontSize] ;
}

- (float)fontSizeForToken:(RPCountedToken*)token
		   fromDictionary:(NSDictionary*)fontSizesForCounts {
	NSNumber* sizeObject = [fontSizesForCounts objectForKey:[NSNumber numberWithInteger:[token count]]] ;
	float size ;
	if (sizeObject != nil) {
		size = [sizeObject floatValue] ;
	}
	else {
		size = [self defaultFontSize] ;
	}
	
	return size ;
}

const float minGap = 2.0 ; // Used for both horizontal and vertical gap between framedTokens

#pragma mark * Accessors

@synthesize dragImage = _dragImage ;
@synthesize tokenBeingEdited = _tokenBeingEdited ;
@synthesize delegate = m_delegate ;
@synthesize disallowedCharacterSet = m_disallowedCharacterSet ;
@synthesize replacementString = m_replacementString ;
@synthesize tokenizingCharacterSet = m_tokenizingCharacterSet ;
@synthesize noTokensPlaceholder = m_noTokensPlaceholder ;
@synthesize noSelectionPlaceholder = m_noSelectionPlaceholder ;
@synthesize multipleValuesPlaceholder = m_multipleValuesPlaceholder ;
@synthesize notApplicablePlaceholder = m_notApplicablePlaceholder ;

/*!
 @brief    Returns the current -objectValue if it is a collection,
 or nil if it is a state marker.
*/
- (id)tokensCollection {
	id value = [self objectValue] ;
	if ([value respondsToSelector:@selector(count)]) {
		return value ;
	}
	else {
		// Must be a state marker
		return nil ;
	}
}

/*!
 @brief    Returns the current -objectValue, repackaged into an array
 if it is not, returning an empty array if there are no objects.
*/
- (NSArray*)tokensArray {
	id collection = [self tokensCollection] ;
	NSArray* answer ;	
	if (!collection) {
		answer = [NSArray array] ;
	}
	else if ([collection isKindOfClass:[NSArray class]]) {
		answer = collection ;
	}
	else {
		// Must be a set
		answer = [collection allObjects] ;
	}
	
	return answer ;
}

/*!
 @brief    Returns the current -objectValue, repackaged into an set
 if it is not, returning an empty set if there are no objects.
 */
- (NSSet*)tokensSet {
	id collection = [self tokensCollection] ;
	NSSet* answer ;	
	if (!collection) {
		answer = [NSSet set] ;
	}
	else if ([collection isKindOfClass:[NSSet class]]) {
		answer = collection ;
	}
	else {
		// Must be an array
		answer = [NSSet setWithArray:collection] ;
	}

	return answer ;
}

- (unichar)tokenizingCharacter {
	unichar tokenizingCharacter ;
	@synchronized(self) {
		tokenizingCharacter = m_tokenizingCharacter ; ;
	}
	return tokenizingCharacter ;
}

- (void)setTokenizingCharacter:(unichar)tokenizingCharacter {
	@synchronized(self) {
		[self setTokenizingCharacterSet:[NSCharacterSet characterSetWithRange:NSMakeRange(tokenizingCharacter, 1)]] ;
		m_tokenizingCharacter = tokenizingCharacter ;
	}
}

+ (NSSet*)keyPathsForValuesAffectingTokenizingCharacterSet {
	return [NSSet setWithObjects:
			@"tokenizingCharacter",
			nil] ;
}

+ (NSSet*)keyPathsForValuesAffectingValue {
	return [NSSet setWithObjects:
			@"objectValue",
			nil] ;
}

- (id)objectValue {
	id objectValue ;
	@synchronized(self) {
        objectValue = m_objectValue;
#if !__has_feature(objc_arc)
        [m_objectValue retain];
        [m_objectValue autorelease] ;
#endif
	}
	return objectValue ;
}

- (void)setObjectValue:(id)newTokens {
	if (!newTokens) {
		newTokens = SSYNoTokensMarker ;
	}
	
	BOOL isPlaceholder = ([newTokens extractStrings] == nil) ;
	
	BOOL substantiveChange ;
	id oldTokens ;
	
	@synchronized(self) {
		BOOL wasPlaceholder = ([m_objectValue extractStrings] == nil) ;

		if (isPlaceholder) {
			if (wasPlaceholder) {
				// is and was a placeholder
				substantiveChange = (newTokens != m_objectValue) ;
			}
			else {
				substantiveChange = YES ;
			}
		}
		else if (wasPlaceholder) {
			substantiveChange = YES ;
		}
		else {
			// is not and was not a placeholder
			substantiveChange = (
								 ((m_objectValue == nil) && (newTokens != nil))
								 ||
								 (![[m_objectValue extractStrings] isEqual:[newTokens extractStrings]])
								 ) ;	
		}			
		
		// If only some count(s) changed, but the strings remained the
		// same, we can keep the selection and layout, and do not trigger KVO
#if !__has_feature(objc_arc)
		[newTokens retain] ;
#endif
        if (substantiveChange) {
			[self willChangeValueForKey:@"objectValue"];
		}
		
		// Since oldTokens will be passed to the observer by
		// will/didChangeValueForKey, we can't release it until
		// after the notification has executed.  But, we'll
		// need a reference to do that.  So we now make
		// that reference:
		oldTokens = m_objectValue ;
		// before we change it:
		m_objectValue = newTokens ;
	}
	
    if (substantiveChange) {
		[self didChangeValueForKey:@"objectValue"];
	}
#if !__has_feature(objc_arc)
    // Now it is safe to do this:
	[oldTokens release];
#endif
	
	if (substantiveChange) {
		// String(s) changed
		[self deselectAllIndexes] ;
	}	
	
	[self invalidateLayout] ;
	[self setTokenBeingEdited:nil] ;
}

- (id)value {
	return [self objectValue] ;
}

- (void)setValue:(id)value {
	[self setObjectValue:value] ;
}

- (void)registerForDefaultDraggedTypes {
	[self registerForDraggedTypes:[NSArray arrayWithObjects:
								   NSStringPboardType,
								   NSTabularTextPboardType,
								   nil]] ;
}

- (NSString*)linkDragType {
	NSString* linkDragType ;
	@synchronized(self) {
		linkDragType = [[_linkDragType copy] autorelease] ; ;
	}
	return linkDragType ;
}

- (void)setLinkDragType:(NSString *)newLinkDragType {
#if !__has_feature(objc_arc)
    [newLinkDragType retain] ;
#endif
    @synchronized(self) {
#if !__has_feature(objc_arc)
		[_linkDragType release];
#endif
		_linkDragType = newLinkDragType ;
		if (_linkDragType != nil) {
			[self registerForDraggedTypes:[NSArray arrayWithObject:_linkDragType]] ;
		}
		else {
			[self unregisterDraggedTypes] ;
			[self registerForDefaultDraggedTypes] ;
		}
	}
}

- (NSTextField*)textField {
	if (_textField == nil) {
		_textField = [[NSTextField alloc] initWithFrame:[self frame]] ;
		// [self frame] is just to give it something.
		// It will be overwritten immediately, in -beginEditingNewTokenWithString:.
		[_textField setEnabled:YES] ;
		[_textField setEditable:YES] ;
		[_textField setBordered:NO] ;
		float fontSize = [self defaultFontSize] ;
		[_textField setFont:[FramedToken fontOfSize:fontSize]] ;
		[self addSubview:_textField] ;
		[_textField setDelegate:self] ;
	}
	
	return _textField ;
}

#pragma mark * Layout

const float halfRingWidth = 2.0 ;

- (NSMutableArray*)truncatedTokens {
	if (_truncatedTokens == nil) {
		_truncatedTokens = [[NSMutableArray alloc] init] ;
	}
	
	return _truncatedTokens ;
}

- (void)layoutLine:(NSArray*)line
				 y:(float)y
				 h:(float)h
			   gap:(float)gap
	focusRingFirst:(BOOL)focusRingFirst {
	float x = 1.0 ;
    if (focusRingFirst) {
		x += (halfRingWidth + tokenBoxTextInset) ;
	}
	y += 1.0;
	NSEnumerator *enumerator = [line objectEnumerator];
	FramedToken *layout;
	while (layout = [enumerator nextObject]) {
		NSRect bounds = [layout bounds];
		bounds.origin.x = x;
		bounds.origin.y = y + (h-bounds.size.height)/2;
		x += bounds.size.width + gap;
		[layout setBounds:bounds];
	}
}

- (void)doLayout {
	if(_framedTokens != nil) {
		return ;
	}
	_framedTokens = [[NSMutableArray alloc] init];
	
	id tokens = [self tokensCollection] ;
	if (!tokens) {
		return ;
	}
	
	//order by occurance and get the top n
	NSInteger len = [(NSSet*)tokens count];
	
	NSMutableArray* myTokens = [[NSMutableArray alloc] init] ;
	NSEnumerator* e = [(NSSet*)tokens objectEnumerator] ;
	RPCountedToken* token ;
	RPCountedToken* countedTokenEditing = nil ;
	id object ;
	if ([tokens respondsToSelector:@selector(countForObject:)]) {
		// tokens is a NSCountedSet of NSStrings
		while ((object = [e nextObject])) {
			NSInteger targetCount = [(NSCountedSet*)tokens countForObject:object] ;
			// Sometimes, if a token is being edited, the above can return 0.
			// Maybe this is a bug in NSCountedSet.  How can the token of a count
			// be 0, if it exists in the set???  So, I fix that with this line:
			targetCount = MAX(targetCount, 1) ;

			token = [[RPCountedToken alloc] initWithText:object
												   count:targetCount] ;
			[myTokens addObject:token] ;
#if !__has_feature(objc_arc)
            [token release];
#endif
			
			if (object == [self tokenBeingEdited]) {
				countedTokenEditing = token ;
			}
		}
	}
	else {
		// tokens is an NSArray or NSSet of: NSStrings and/or RPCountedTokens
		while ((object = [e nextObject])) {
			if (![object isKindOfClass:[RPCountedToken class]]) {
				// object must be a string (or results are undefined!)
				token = [[RPCountedToken alloc] initWithText:object
													   count:1] ;
				[myTokens addObject:token] ;
#if !__has_feature(objc_arc)
				[token release];
#endif
			}
			else {
				token = object ;
				[myTokens addObject:token] ;
			}
			
			if (object == [self tokenBeingEdited]) {
				countedTokenEditing = token ;
			}				
		}
	}
	// Sort tokens by their counts
	NSArray* sortedTokens = [myTokens sortedArrayUsingSelector:@selector(countCompare:)] ;
#if !__has_feature(objc_arc)
	[myTokens release];
#endif
	
	// Truncate the sortedTokens array to _maxTokensToDisplay
	NSRange displayedTokenRange = NSMakeRange(_firstTokenToDisplay, (len<_maxTokensToDisplay) ? len : _maxTokensToDisplay) ;
	// If we've removed tokens from the beginning, this must reduce
	// the length of the displayed range correspondingly:
	displayedTokenRange.length -= _firstTokenToDisplay ;
	sortedTokens = [sortedTokens subarrayWithRange:displayedTokenRange] ;
	
	// Create a dictionary for converting token counts to font size, in 2 steps
	NSMutableDictionary *fontSizesForCounts = [[NSMutableDictionary alloc] init];
	// Step 1 of 2.  Create a dictionary of key=count and value=rank
	NSInteger lastCnt = 0;
	e = [sortedTokens objectEnumerator];
	NSInteger cnt;
	while ((cnt = [(RPCountedToken*)[e nextObject] count])) {
		if(cnt == lastCnt) {
			continue ;
		}
		lastCnt = cnt;
		[fontSizesForCounts setObject:[NSNumber numberWithInteger:[fontSizesForCounts count]]
							   forKey:[NSNumber numberWithInteger:cnt]];
	}
	// Dictionary values are now 'rank'.	
	// Step 2 of 2.  Replace each value, now 'rank', with a fontSize instead
	NSInteger weightMax = [fontSizesForCounts count] ;
	if(weightMax > 1) weightMax-- ;
	e = [[fontSizesForCounts allKeys] objectEnumerator] ;
	// Cannot use -keyEnumerator since we are going to mutate
	// fontSizesForCounts while enumerating through it
	NSNumber *key ;
	while (key = [e nextObject]) {
		float fontSize ;
		if ([self fixedFontSize] <= 0) {
			NSInteger weight = [[fontSizesForCounts objectForKey:key] intValue];
			float v = (weightMax-weight)*1.0/weightMax; // first=1.0, last = 0.0
			v = v*v; //non-linear curve so as to make the bigger ones even bigger
			fontSize = _minFontSize + v*(_maxFontSize-_minFontSize) ;
		}
		else {
			fontSize = [self fixedFontSize] ;
		}
		[fontSizesForCounts setObject:[NSNumber numberWithFloat:fontSize] forKey:key];
	}
	
	// Sort sortedTokens further, by their text this time
	sortedTokens = [sortedTokens sortedArrayUsingSelector:@selector(textCompare:)] ;
	
	// Format tokens
	float wholeWidth = [self frame].size.width ;
	float maxHeight = 0.0 ;
	NSPoint pt = NSMakePoint(0.0, minGap) ;
	// minGap here is to leave a little whitespace (or blackspace, as the case may be)
	// between the top of the view and the top of the first row of tokens
	e = [sortedTokens objectEnumerator];	
	id currentToken;
	NSMutableArray *currentLine = [[NSMutableArray alloc] init] ;
	// We would like to lay out each line of tokens as it is completed,
	// however we cannot quite do this because:
	//   (1) the last line is to be left-aligned instead of justified (spread).
	//   (2) If we have no enclosing scroll view the "last" line may have to be
	//     eliminated (truncated off) if it does not fit.
	//   (3) We don't know that until we find out how high its highest token is (maxHeight).
	// So, because of all this we have to store information about the
	// "previous" line, and wait until the end to lay out the last
	// line (which will be the currentLine) and the second-last line
	// (which will be the previousLine.
	NSArray* previousLine = nil ;
	float previousLineTokensWidth ;
	float previousLineY ;
	float previousLineMaxHeight ;
	NSScrollView* scrollView = [self enclosingScrollView] ;
	NSRect frame = [self frame] ;
	NSMutableArray* truncatedTokens = [self truncatedTokens] ;
	[truncatedTokens removeAllObjects] ;
	
	NSInteger i = 0 ;
	BOOL focusRingLeftOfFirstToken = NO ;
	_indexOfFramedTokenBeingEdited = NSNotFound ;
	while (currentToken = [e nextObject]) {
		float fontSize = [self fontSizeForToken:currentToken
								 fromDictionary:fontSizesForCounts] ;
		NSSize framedTokenSize = [FramedToken boxSizeForToken:currentToken
													 fontSize:fontSize
                                           cornerRadiusFactor:_cornerRadiusFactor
                                       widthPaddingMultiplier:_widthPaddingMultiplier
												  appendCount:_appendCountsToStrings] ;
		
		// If the first token is being edited, provide a little extra margin on the left
		// for the focus ring, because _textField will be set to a frame which is 
		// based on the frame of the FramedToken we are about to create.
		if ((i==0) && (currentToken == countedTokenEditing)) {
			focusRingLeftOfFirstToken = YES ;
		}
		
		if((pt.x+minGap+framedTokenSize.width > wholeWidth) && (pt.x > 0)) {
			// Horizontal overflow.  Put the currentToken on 'hold'.  It will
			// go into the ^next^ line.  Now, we do several finalization tasks
			// on the current line and the previous line...
			
			// Before dealing with the current line, we see if there was a 
			// ^previous^ line that needs to be finalized.
			if (previousLine) {
				// Since we have now overflowed into a ^new^ line, we know that
				// the ^previous^ line is ^not^ the last line, therefore we are 
				// now certain that it should be laid out with justification (spreading).
				// We now do that, adding the FramedTokens from previousLine, with
				// layout information, to _framedTokens.
				// The 'gap' is the amount of space between tokens.
				// In this case it is calculated to justify or "spread" the tokens.
				NSInteger nGaps = [previousLine count] - 1 ;
				float extraWidth = wholeWidth - previousLineTokensWidth ;
				float gap = minGap + extraWidth/nGaps ;
				[self layoutLine:previousLine
							   y:previousLineY
							   h:previousLineMaxHeight
							 gap:gap
				  focusRingFirst:focusRingLeftOfFirstToken] ;
				focusRingLeftOfFirstToken = NO ;
				[_framedTokens addObjectsFromArray:previousLine];
			}
			
			// If superview does not scroll, see if we can fit more tokens
			if ((scrollView==nil) && (pt.y + maxHeight > frame.size.height)) {
				// Vertical overflow in a non-scrolling view
				
				// Replace the proposed currentToken (which caused an overflow)
				// with an ellipsisToken
				[truncatedTokens addObject:currentToken] ;
				currentToken = [RPCountedToken ellipsisToken] ;
				fontSize = [self fontSizeForToken:currentToken
								   fromDictionary:fontSizesForCounts] ;
				
				framedTokenSize = [FramedToken boxSizeForToken:currentToken
													  fontSize:fontSize
                                            cornerRadiusFactor:_cornerRadiusFactor
                                        widthPaddingMultiplier:_widthPaddingMultiplier
												   appendCount:_appendCountsToStrings] ;
				
				// See if it fits now, and if not, remove tokens previously added
				// to currentLine until it does fit.
				while (pt.x+minGap+framedTokenSize.width > wholeWidth) {
					FramedToken* tokenToRemove = [currentLine lastObject] ;
					float reclaimedWidth = [tokenToRemove bounds].size.width + minGap ;
					if ([currentLine count] < 1) {
						// Should never happen but I'm not sure
						NSLog(@"Internal Error 638-4882") ;
						break ;
					}
					[currentLine removeLastObject] ;
					pt.x -= reclaimedWidth ;
				}
				
				// Add the ellipsisToken (now currentToken)
				FramedToken *framedToken = [[FramedToken alloc] initWithCountedToken:currentToken
																			fontsize:fontSize
																			  bounds:NSMakeRect(0, 0, framedTokenSize.width, framedTokenSize.height)];
				[currentLine addObject:framedToken] ;
#if !__has_feature(objc_arc)
				[framedToken release];
#endif
				
				break ;
			}
			
			previousLine = [[currentLine copy] autorelease] ;
			previousLineTokensWidth = pt.x ;
			previousLineY = pt.y ;
			previousLineMaxHeight = maxHeight ;
			// Clear everything out in preparation for next line
			float currentLineHeight = maxHeight + minGap ;
			// Note that this view uses a flipped y coordinate.
			// That makes it easier because now we can simply
			// increase y to move the next line down...
			pt.y += currentLineHeight ;
			// ... and no need to displace any of the previous lines.
			[currentLine removeAllObjects];
			maxHeight = 0.0;
			pt.x = 0;
		}
		FramedToken *framedToken = [[FramedToken alloc] initWithCountedToken:currentToken
																	fontsize:fontSize
																	  bounds:NSMakeRect(0, 0, framedTokenSize.width, framedTokenSize.height)];
		[currentLine addObject:framedToken] ;
#if !__has_feature(objc_arc)
		[framedToken release];
#endif
		
		if(pt.x > 0) {
			pt.x += minGap ;
		}
		pt.x += framedTokenSize.width;
		
		if(framedTokenSize.height > maxHeight) {
			maxHeight = framedTokenSize.height ;
		}
		
		if (currentToken == countedTokenEditing) {
			_indexOfFramedTokenBeingEdited = i ;
		}
		i++ ;
	}

#if !__has_feature(objc_arc)
	[fontSizesForCounts release];
#endif
	
	// Add any remaining tokens (which did not fit) to truncatedTokens
	while (currentToken = [e nextObject]) {
		[truncatedTokens addObject:currentToken] ;
	}
	
	// Lay out the second-last line.
	if ([previousLine count] > 0) {
		// gap is the amount of space between tokens.
		// In this case it is calculated for each line to justify or "spread" the tokens.
		NSInteger nGaps = [previousLine count] - 1 ;
		float extraWidth = wholeWidth - previousLineTokensWidth ;
		float gap = minGap + extraWidth/nGaps ;
		[self layoutLine:previousLine
					   y:previousLineY
					   h:previousLineMaxHeight
					 gap:gap
		  focusRingFirst:focusRingLeftOfFirstToken] ;
		focusRingLeftOfFirstToken = NO ;
		[_framedTokens addObjectsFromArray:previousLine];
	}
	
	// Lay out the last line.
	// This one is different because it is left-aligned instead of justified.
	// So, we use gap = minGap
	if ([currentLine count] > 0) {
		[self layoutLine:currentLine
					   y:pt.y
					   h:maxHeight
					 gap:minGap
		  focusRingFirst:focusRingLeftOfFirstToken] ;			
	}
	[_framedTokens addObjectsFromArray:currentLine] ;
#if !__has_feature(objc_arc)
	[currentLine release];
#endif
	
	// If in a scroll view, increase heght and add scroller if needed
	float requiredHeight = pt.y + maxHeight ;
	float scrollViewHeight = scrollView ? [scrollView frame].size.height : 0.0 ;
	// Must set the lockout here because -setHasVerticalScroller can invoke our -setFrameSize
	_isDoingLayout = YES ;
	if (scrollView == nil) {
		// No scroll view, so do not change the frame size
	}
	else if (requiredHeight > scrollViewHeight) {
		frame.size.height = requiredHeight ;
		[scrollView setHasVerticalScroller:YES] ;
	}
	else {
		frame.size.height = scrollViewHeight ;
		[scrollView setHasVerticalScroller:NO] ;
	}
	if (scrollView) {
        frame.size.width = [NSScrollView contentSizeForFrameSize:[scrollView frame].size
                                         horizontalScrollerClass:([scrollView hasHorizontalScroller] ? [NSScroller class] : nil)
                                           verticalScrollerClass:([scrollView hasVerticalScroller] ? [NSScroller class] : nil)
                                                      borderType:[scrollView borderType]
                                                     controlSize:NSRegularControlSize
                                                   scrollerStyle:NSScrollerStyleOverlay].width ;
	}
	[self setFrameSize:frame.size] ;
	_isDoingLayout = NO ;
	
	
	// Remove old toolTips
	// Remember this, because, -removeAllToolTips removes both
	// the view-wide toolTip and the rect toolTips.
	NSString* wholeViewToolTip = [self toolTip] ;
#if !__has_feature(objc_arc)
    [wholeViewToolTip retain];
#endif
	// Yes, it will crash if I don't retain it.
	[self removeAllToolTips] ;
	if (wholeViewToolTip != nil) {
		[self setToolTip:wholeViewToolTip] ;
#if !__has_feature(objc_arc)
		[wholeViewToolTip release];
#endif
	}
	// Add new toolTip rects
	{
		e = [_framedTokens objectEnumerator] ;
		FramedToken *framedToken ;
		while(framedToken = [e nextObject]) {
			[self addToolTipRect:[framedToken bounds]
						   owner:self
						userData:framedToken] ;
		}
	}
}

- (void)invalidateLayout {
#if !__has_feature(objc_arc)
	[_framedTokens release];
#endif
	_framedTokens = nil;
	[self doLayout] ;
    self.needsDisplay = YES;
}


#pragma mark * Selection Management

- (NSIndexSet*)selectedIndexSet {
	return [[_selectedIndexSet copy] autorelease] ;
}


- (void)setSelectedIndexSet:(NSIndexSet*)newSelectedIndexSet {
#if !__has_feature(objc_arc)
	[_selectedIndexSet release];
#endif
	_selectedIndexSet = [newSelectedIndexSet copy] ;
}

- (NSIndexSet*)deselectedIndexesSet {
	// Too bad Apple doesn't provide a -minusSet method for NSIndexSet...
	NSMutableIndexSet* deselectedIndexesSet = [[NSMutableIndexSet alloc] init] ;
	NSInteger i ;
	id value = [self tokensCollection] ;
	for (i=0; i<[(NSSet*)value count]; i++) {
		if (![[self selectedIndexSet] containsIndex:i]) {
			[deselectedIndexesSet addIndex:i] ;
		}
	}
	
	NSIndexSet* output = [deselectedIndexesSet copy] ;
#if !__has_feature(objc_arc)
	[deselectedIndexesSet release];
#endif
	
	return [output autorelease] ;
}

- (void)selectIndex:(NSInteger)index {
    if (index != NSNotFound) {
        NSMutableIndexSet* selectedIndexSet = [[self selectedIndexSet] mutableCopy] ;
        if (![selectedIndexSet containsIndex:index]) {
            [selectedIndexSet addIndex:index] ;
            [self setSelectedIndexSet:selectedIndexSet] ;
            _lastSelectedIndex = index ;
            FramedToken* framedToken = [_framedTokens objectAtIndex:index] ;
            [self setNeedsDisplayInRect:[framedToken bounds]] ;
        }
#if !__has_feature(objc_arc)
        [selectedIndexSet release];
#endif
    }
}

- (void)deselectIndex:(NSInteger)index {
	NSMutableIndexSet* selectedIndexSet = [[self selectedIndexSet] mutableCopy] ;
	if ([selectedIndexSet containsIndex:index]) {
		[selectedIndexSet removeIndex:index] ;
		[self setSelectedIndexSet:selectedIndexSet] ;
		FramedToken* framedToken = [_framedTokens objectAtIndex:index] ;
		[self setNeedsDisplayInRect:[framedToken bounds]] ;
	}
#if !__has_feature(objc_arc)
	[selectedIndexSet release];
#endif
}

- (void)selectIndexesInRange:(NSRange)range {
	NSInteger lastIndexToSelect = range.location + range.length - 1;
	NSMutableIndexSet* selectedIndexSet = [[self selectedIndexSet] mutableCopy] ;
	if (![selectedIndexSet containsIndexesInRange:range]) {
		
		NSInteger firstIndexToSelect = range.location ;
		NSIndexSet* deselectedIndexesSet = [self deselectedIndexesSet] ;
		// Loop through those members of the deselectedIndexesSet
		// which intersect the 'range' of indexes to select
		// For each one found, select it and mark its box as needing display
		NSUInteger i = [deselectedIndexesSet indexGreaterThanOrEqualToIndex:firstIndexToSelect] ;
		while (i<=lastIndexToSelect) {
			[selectedIndexSet addIndex:i] ;
			FramedToken* token = [_framedTokens objectAtIndex:i] ;
			[self setNeedsDisplayInRect:[token bounds]] ;
			i = [deselectedIndexesSet indexGreaterThanIndex:i] ;
		}
		
		[self setSelectedIndexSet:selectedIndexSet] ;
	}
#if !__has_feature(objc_arc)
	[selectedIndexSet release];
#endif
	_lastSelectedIndex = lastIndexToSelect ;
}

- (void)deselectAllIndexes {
	//  Will only do something if >0 now selected
	NSMutableIndexSet* selectedIndexSet = [[self selectedIndexSet] mutableCopy] ;
	if ([selectedIndexSet count] > 0 ) {
		
		// Mark all which are now selected as needing display
		// since they will all be deselected
		NSUInteger i = [selectedIndexSet firstIndex] ;
		while ((i != NSNotFound)) {
			// If the last token was deleted, its index will still 
			// be in the selectedIndexSet, so we check that i
			// is not too big before proceeding.
			if (i < [_framedTokens count]) {
				FramedToken* token = [_framedTokens objectAtIndex:i] ;
				[self setNeedsDisplayInRect:[token bounds]] ;
			}
			i = [selectedIndexSet indexGreaterThanIndex:i] ;
		}
		
		[selectedIndexSet removeAllIndexes] ;		
		[self setSelectedIndexSet:selectedIndexSet] ;
	}
#if !__has_feature(objc_arc)
	[selectedIndexSet release];
#endif
	
	_lastSelectedIndex = NSNotFound ;
}

- (void)selectAllIndexes {
	id tokens = [self tokensCollection] ;
	//  Will only do something if all not now selected
	NSMutableIndexSet* selectedIndexSet = [[self selectedIndexSet] mutableCopy] ;
	if ([selectedIndexSet count] < [(NSSet*)tokens count]) {
		
		// Mark all which are now not selected as needing display
		// since they will all be selected
		NSIndexSet* deselectedIndexesSet = [self deselectedIndexesSet] ;
		NSUInteger i = [deselectedIndexesSet firstIndex] ;
		while ((i != NSNotFound)) {
			FramedToken* token = [_framedTokens objectAtIndex:i] ;
			[self setNeedsDisplayInRect:[token bounds]] ;
			i = [deselectedIndexesSet indexGreaterThanIndex:i] ;
		}
		
		[selectedIndexSet addIndexesInRange:NSMakeRange(0, [(NSSet*)tokens count])] ;		
		[self setSelectedIndexSet:selectedIndexSet] ;
	}
	_lastSelectedIndex = [selectedIndexSet lastIndex] ;

#if !__has_feature(objc_arc)
    [selectedIndexSet release];
#endif
}

- (void)setMaxTokensToDisplay:(NSInteger)maxTokensToDisplay {
    _maxTokensToDisplay = maxTokensToDisplay;
	[self deselectAllIndexes] ;
    [self invalidateLayout];
}

- (void)setFancyEffects:(NSInteger)fancyEffects {
    _fancyEffects = fancyEffects ;
    self.needsDisplay = YES;
}

- (void)setBackgroundWhiteness:(float)whiteness {
	_backgroundWhiteness = whiteness ;
    self.needsDisplay = YES;
}

- (void)setTokenColorScheme:(RPTokenControlTokenColorScheme)tokenColorScheme {
	_tokenColorScheme = tokenColorScheme ;
    self.needsDisplay = YES;
}

- (void)setCornerRadiusFactor:(float)cornerRadiusFactor {
	_cornerRadiusFactor = cornerRadiusFactor ;
    [self invalidateLayout];
    self.needsDisplay = YES;
}

- (void)setWidthPaddingMultiplier:(float)widthPaddingMultiplier {
	_widthPaddingMultiplier = widthPaddingMultiplier ;
    [self invalidateLayout];
    self.needsDisplay = YES;
}

- (void)setShowsCountsAsToolTips:(BOOL)yn {
    _showsCountsAsToolTips = yn ;
}

- (void)setAppendCountsToStrings:(BOOL)yn {
    _appendCountsToStrings = yn ;
    [self invalidateLayout];
    self.needsDisplay = YES;
}

- (RPTokenControlEditability)editability {
    return m_editablity ;
}

- (void)setEditability:(RPTokenControlEditability)editability {
    m_editablity = editability ;
	if (editability > RPTokenControlEditability1) {
		[self registerForDefaultDraggedTypes] ;
	}
	else {
		[self unregisterDraggedTypes] ;
		// Since the above clears all dragged types, we have to
		// re-register the custom type, if one has been set.
		NSString* linkDragType = [self linkDragType] ;
		if (linkDragType != nil) {
			[self registerForDraggedTypes:[NSArray arrayWithObject:linkDragType]] ;
		}
	}  
}

- (void)setMinFontSize:(float)x {
	_minFontSize = x ;
    [self invalidateLayout];
}

- (void)setMaxFontSize:(float)x {
	_maxFontSize = x ;
    [self invalidateLayout];
}

- (CGFloat)fixedFontSize {
	CGFloat fixedFontSize ;
	@synchronized(self) {
		fixedFontSize = m_fixedFontSize ; ;
	}
	return fixedFontSize ;
}

- (void)setFixedFontSize:(CGFloat)x {
	@synchronized(self) {
		m_fixedFontSize = x ;
	}
    [self invalidateLayout];
}

- (void)setFrameSize:(NSSize)size {
	[super setFrameSize:size];
	if (!_isDoingLayout) {
		[self invalidateLayout] ;
	}
	
}

#pragma mark * Select/Deselect Tokens

- (BOOL)isSelectedIndex:(NSInteger)index {
	BOOL isSelected = NO ;
	if (index != NSNotFound) {
		isSelected = [[self selectedIndexSet] containsIndex:index] ;
	}
	
	return isSelected ;
}

- (BOOL)isSelectedFramedToken:(FramedToken*)framedToken {
	NSInteger index = [_framedTokens indexOfObject:framedToken] ;
	return [self isSelectedIndex:index] ;
}

- (NSArray*)selectedTokens {
	NSEnumerator* e = [_framedTokens objectEnumerator] ;
	NSMutableArray* selectedTokens = [[NSMutableArray alloc] init] ;
	FramedToken* framedToken ;
	while ((framedToken = [e nextObject])) {
		if ([self isSelectedFramedToken:framedToken]) {
			[selectedTokens addObject:[framedToken text]] ;
		}
	}
	
	NSArray* output = [selectedTokens copy] ;
#if !__has_feature(objc_arc)
	[selectedTokens release];
#endif
	
	return [output autorelease] ;
}

#pragma mark * Typing In New Tokens

- (void)updateTextFieldFrame {
	// This method must be preceded by -invalidateLayout or -doLayout, in order
	// to update _indexOfFramedTokenBeingEdited.
	
	// If the token being edited overflows the view and is not being drawn
	// _indexOfFramedTokenBeingEdited will be NSNotFound.  In that case, we
	// do not update the text field frame.  It will just stay at the last
	// location and size that it was before the overflow occurred.
	if (_indexOfFramedTokenBeingEdited != NSNotFound) {
		FramedToken* framedTokenBeingEdited = [_framedTokens objectAtIndex:_indexOfFramedTokenBeingEdited] ;
		NSRect rect = [framedTokenBeingEdited bounds] ;
		// The next three lines tweak the rect of the NSTextField to kind of
		// match the FramedToken which it temporarily replaces.  I could give an
		// analysis of why the following three adjustments are correct by
		// noting their symmetry to those in -[FramedToken boxSizeForToken:::],
		// but they're not quite.  This has not yet been tested with font sizes
		// other than fixedFontSize = 11.0.
		rect.origin.y += 1.0 ;
		rect.size.width += 0.0 ; //(2*tokenBoxTextInset + ([framedTokenBeingEdited fontsize] * 0.25)) ;
		rect.origin.x -= 2*tokenBoxTextInset ;
		rect.size.height -= 2*tokenBoxTextInset ;
		NSTextField* textField = [self textField] ;
		[textField setFrame:rect] ;
	}
}	

- (void)beginEditingNewTokenWithString:(NSString*)string {
	// Ordinarily, string is one character, the first character typed.
	id newTokens ;
	if ([m_objectValue respondsToSelector:@selector(mutableCopy)]) {
		newTokens = [m_objectValue mutableCopy] ;
	}
	else {
		newTokens = [[NSMutableArray alloc] init] ;
	}

	NSMutableString* mutableString = [string mutableCopy] ;
	[newTokens addObject:mutableString] ;
	[self setTokenBeingEdited:mutableString] ;
#if !__has_feature(objc_arc)
	[mutableString release];
#endif
	// We set the ivar directly here to avoid triggering KVO
#if !__has_feature(objc_arc)
	[m_objectValue release];
#endif
	m_objectValue = newTokens ;
	[self deselectAllIndexes] ;
	[self invalidateLayout] ;
	
	NSTextField* textField = [self textField] ;
	[textField setStringValue:mutableString] ;
	[[self window] makeFirstResponder:textField] ;
	// The next step is to deselect the text (one character) and
	// move the insertion point to the end.  NSTextField does not
	// have any methods to do this, but the field editor does:
	NSText* fieldEditor = [[self window] fieldEditor:NO
										   forObject:textField] ;
	[fieldEditor setSelectedRange:NSMakeRange(1,0)] ;
	// Note that the insertion point is always set to the ^end^
	// of the selectedRange.
	
	[textField setHidden:NO] ;
	
	[self updateTextFieldFrame] ;
}

-  (void)controlTextDidChange:(NSNotification*)notification {
	NSTextField* textField = [self textField] ;
	NSString* newText = [[self textField] stringValue] ;

	// Check for tokenizing character
	NSInteger lastIndex = [newText length] - 1 ;
	if (lastIndex >= 0) {
		unichar newChar = [newText characterAtIndex:lastIndex] ;
		if ([[self tokenizingCharacterSet] characterIsMember:newChar]) {
			// Found tokenizing character.  End it.
			[textField setStringValue:[newText substringToIndex:lastIndex]] ;
			[self controlTextDidEndEditing:[NSNotification notificationWithName:@"RPTokenControlTextDidChange"
                                                                         object:nil]] ;
		}
	}

	// Check for disallowed character
	NSCharacterSet* disallowedCharacterSet = [self disallowedCharacterSet] ;
	if (disallowedCharacterSet != nil) {
		NSInteger badCharLocation = [newText rangeOfCharacterFromSet:disallowedCharacterSet].location ;
		// Since we check this every time a character is entered, there
		// should only be one bad character at most
		if (badCharLocation != NSNotFound) {
			NSMutableString* fixedToken = [newText mutableCopy] ;
			[fixedToken replaceCharactersInRange:NSMakeRange(badCharLocation,1)
									  withString:[self replacementString]] ;
			[textField setStringValue:fixedToken] ;
			newText = [fixedToken autorelease] ;
			NSBeep() ;	
		}
	}
	[[self tokenBeingEdited] setString:newText] ;
	[self invalidateLayout] ;
	[self updateTextFieldFrame] ;
}

-  (void)controlTextDidEndEditing:(NSNotification*)notification {
	NSTextField* textField = [self textField] ;
	[textField setHidden:YES] ;
	
	// Finalize this token:
	// Make the new token immutable and trigger automatic KVO for observers of tokens.
	id tokens = [self tokensCollection] ;
	if (!tokens) {
		return ;
	}
	
	NSString* tokenEditing = [self tokenBeingEdited] ;
	// This method seems to get invoked when you just click on the field.
	// Not sure why.  It's Cocoa.
	// Exceptions will be raised in what follows if tokenEditing == nil,
	// so we guard against that
	if (!tokenEditing) {
		return ;
	}

	[tokens removeObject:tokenEditing] ;
	NSString* newToken = [tokenEditing copy] ;
	[tokens addObject:newToken] ;
#if !__has_feature(objc_arc)
	[newToken release];
#endif
#if !__has_feature(objc_arc)
	[m_objectValue release];
#endif
    // Next line is so that substantiveChange will be detected
	m_objectValue = nil ;
	// Now, we trigger KVO
	[self setObjectValue:tokens] ;
	// The following line was commented out in BookMacster 1.11.6.
	// I can't figure out why the hell it was in there, but I see no need
	// for it, and indeed it causes a crash.
	//	[tokens release] ;  // Note 20120629
	[[self window] makeFirstResponder:self] ;
}

#pragma mark * Mouse Handling

- (NSInteger)indexOfTokenClosestToPoint:(NSPoint)pt
					 excludeToken:(FramedToken*)excludedToken
			excludeHigherNotLower:(BOOL)excludeHigherNotLower {
	// The last argument says whether to exclude tokens that
	// are ^higher^ than excludedToken, or exclude tokens that
	// are ^lower^ than excludedToken.
	NSInteger index = NSNotFound ;
	
	if (
		(pt.y >= 0.0)
		&& (pt.y <= [self frame].size.height)
		&& (pt.x >= 0.0)
		&& (pt.x <= [self frame].size.width)
		) {	
		FramedToken* framedToken ;
		float distance = 0.0 ;
		NSInteger direction = excludeHigherNotLower ? +1 : -1 ;
		float yLimit = direction * [excludedToken midY] ;
		NSInteger nTokens = [_framedTokens count] ;
		
		NSMutableArray* distances = [[NSMutableArray alloc] initWithCapacity:nTokens] ;
		NSInteger i ;
		for (i=0; i<nTokens; i++) {
			framedToken = [_framedTokens objectAtIndex:i] ;
			if ((framedToken == excludedToken) || ([framedToken midY]*direction < yLimit)) {
				distance = FLT_MAX ;
			}
			else {
				distance = [framedToken distanceFrom:pt] ;
			}
			
			if (distance == 0.0) {
				// pt is inside this token.  That's our answer
				// This will not always happen
				break ;
			}
			else {
				[distances addObject:[NSNumber numberWithFloat:distance]] ;
			}
		}
		
		if (distance == 0.0) {
			// pt is inside a token
			index = i ;
		}
		else {
			// pt is not inside any token, must search for minimum
			float minDistance = FLT_MAX ;
			for (i=0; i<nTokens; i++) {
				distance = [[distances objectAtIndex:i] floatValue] ;
				if (distance < minDistance) {
					index = i ;
					minDistance = distance ;
				}
			}
		}

#if !__has_feature(objc_arc)
		[distances release];
#endif
	}
	
	return index ;
}

- (FramedToken*)tokenAtPoint:(NSPoint)pt {
	FramedToken* token = nil ;
	NSEnumerator *enumerator = [_framedTokens objectEnumerator] ;
	FramedToken *framedToken;
	while(framedToken = [enumerator nextObject]) {
		if(NSPointInRect(pt, [framedToken bounds])) { 
			token = framedToken ;
			break ;
		}
	}
	
	return token ;
}

- (void)scrollFramedTokenToVisible:(FramedToken *)framedToken {
    if (framedToken != nil) {
        NSRect bounds = [framedToken bounds] ;
        [self scrollRectToVisible:bounds] ;
    }
}

- (void)scrollIndexToVisible:(NSInteger)index {
	if (index < [_framedTokens count]) {
		NSScrollView* scrollView = [self enclosingScrollView] ;
		if (scrollView != nil) {
			FramedToken* framedToken = [_framedTokens objectAtIndex:index] ;
			[self scrollFramedTokenToVisible:framedToken];
		}
	}
}


- (BOOL)ellipsisTokenIsDisplayed {
	BOOL answer = NO ;
	id lastFramedToken = [_framedTokens lastObject] ;
	if (lastFramedToken != nil) {
		if ([(RPCountedToken*)[lastFramedToken token] isEllipsisToken]) {
			answer = YES ;
		}
	}
	return answer ;
}


// The following method is invoked for
//		mouse clicks
//      arrow-key actions
//		drags of linkDragType objects into the view.
- (void)changeSelectionPerUserActionAtIndex:(NSInteger)index {
	
	NSInteger nNonEllipsisFramedTokens = [_framedTokens count] ;
	if ([self ellipsisTokenIsDisplayed]) {
		nNonEllipsisFramedTokens-- ;
	}
	
	BOOL canSelect = NO ;
	if (index < 0) {
		if (_firstTokenToDisplay > 0) {
			_firstTokenToDisplay-- ;
			[self invalidateLayout] ;
		}
		else {
			NSBeep() ;
		}
	}
	else if (index >= nNonEllipsisFramedTokens) {
		
		if ([[self truncatedTokens] count] > 0) {
			_firstTokenToDisplay++ ;
			[self invalidateLayout] ;
			// Note that the above action may change whether
			// or not an ellipsisToken is displayed
			index = [_framedTokens count] - 1 ;
			// If the last token is an ellipsisToken, decrement
			// the index to select the prior token instead
			if ([self ellipsisTokenIsDisplayed]) {
				index-- ;
			}	
			canSelect = YES ;
		}
		else {
			canSelect = NO ;
			NSBeep() ;
		}
	}
	else {
		canSelect = YES ;
	}
	
	if (canSelect) {
		NSUInteger modifierFlags = [[NSApp currentEvent] modifierFlags] ;
		BOOL shiftKeyDown = ((modifierFlags & NSShiftKeyMask) != 0) ;
		BOOL cmdKeyDown = ((modifierFlags & NSCommandKeyMask) != 0) ;
		if (index != NSNotFound) {
			if (cmdKeyDown) {
				if ([self isSelectedIndex:index]) {
					// Deselect  it
					[self deselectIndex:index] ;
				}
				else {
					// Select it
					[self selectIndex:index] ;
				}
			}
			else if (shiftKeyDown) {
				// Extend selection to include clicked token
				if (_lastSelectedIndex != NSNotFound) {
					// Add the acted-on token and all contiguous with last selected index
					NSRange range = SSMakeRangeIncludingEndIndexes(index, _lastSelectedIndex) ;
					[self selectIndexesInRange:range] ;
				}
				else {
					// Just add the acted-on token
					[self selectIndex:index] ;
				}
				// Remember this one for next extension of selection
				_lastSelectedIndex = index ;
				
			}
			else {
				// A token was acted on with no modifier key down
				[self deselectAllIndexes] ;
				[self selectIndex:index] ;
			}
		}			
		[self scrollIndexToVisible:index] ;
	}
	
}

/*
 Returns YES if any tokens were selected and deleted
 */
- (BOOL)deleteSelectedTokens {
    BOOL didDelete = NO ;
    if ([[self selectedIndexSet] count] > 0) {
        // Get the tokensToDelete from _framedTokens and selectedIndexSet
        NSArray* framedTokensToDelete = [_framedTokens objectsAtIndexes:[self selectedIndexSet]] ;
        NSArray* stringsToDelete = [framedTokensToDelete valueForKey:@"text"] ;
        NSMutableSet* tokensToDelete = nil ;
        if ([self tokensSet]) {
            tokensToDelete = [[self tokensSet] mutableCopy] ;
            [tokensToDelete intersectSet:[NSSet setWithArray:stringsToDelete]] ;
            
            // Remove the tokensToDelete from m_tokens
            id tokens = [self tokensCollection] ;
            if (tokens) {
                id newTokens = [tokens mutableCopy] ;
                // Missing colon after removeObjectsInArray in next line was
                // added in BookMacster 1.17.
                if ([tokens respondsToSelector:@selector(removeObjectsInArray:)]) {
                    // Must be an NSMutableArray
                    [newTokens removeObjectsInArray:[tokensToDelete allObjects]] ;
                }
                else if ([newTokens respondsToSelector:@selector(minusSet:)]) {
                    // Must be an NSMutableSet
                    // I tried [newTokens minusSet:tokensToDelete] here.  But
                    // the effect of that is to only reduce the count of the
                    // target token by 1.  The following is needed to reduce
                    // the count to 0 and eliminate it entirely…
                    for (NSString* string in tokensToDelete) {
                        NSInteger nToRemove = [newTokens countForObject:string] ;
                        for (NSInteger i=0; i<nToRemove; i++) {
                            [newTokens removeObject:string] ;
                        }
                    }
                }
                
                NSSet* deletedTokens = [NSSet setWithSet:tokensToDelete] ;
                NSDictionary* userInfo = [NSDictionary dictionaryWithObject:deletedTokens
                                                                     forKey:RPTokenControlUserDeletedTokensKey] ;
                [[NSNotificationCenter defaultCenter] postNotificationName:RPTokenControlUserDeletedTokensNotification
                                                                    object:self
                                                                  userInfo:userInfo] ;
                
                // Invoke the KVC-compliant setter
                [self setObjectValue:newTokens] ;
#if !__has_feature(objc_arc)
                [newTokens release];
#endif
                
                // Deselect the selected tokens
                [self deselectAllIndexes] ;
                [self invalidateLayout] ;
                
                [[self window] makeFirstResponder:self] ;
            }
            
            didDelete = ([tokensToDelete count] > 0) ;
        }
        else {
            // Must be a state marker.  Nothing to delete.
        }
#if !__has_feature(objc_arc)
        [tokensToDelete release];
#endif
    }

    return didDelete ;
}

- (void)changeSelectionPerUserActionAtFramedToken:(FramedToken*)framedToken {
	[self changeSelectionPerUserActionAtIndex:[_framedTokens indexOfObject:framedToken]] ;
}

/* This method only gets the navigation keystrokes, deletes, and the first
 keystroke of a new tag.  After the first keystroke, the field editor
 takes over, and code in controlTextDidChange: gets the result. */
- (void)keyDown:(NSEvent*)event {
    BOOL didHandle = NO ;
	NSString *s = [event charactersIgnoringModifiers] ;
	unichar keyChar = 0 ;
	if ([s length] == 1) {
		keyChar = [s characterAtIndex:0] ;
		if (
			(keyChar == NSLeftArrowFunctionKey) 
			|| (keyChar == NSRightArrowFunctionKey)
			|| (keyChar == NSUpArrowFunctionKey)
			|| (keyChar == NSDownArrowFunctionKey)
			) {
			// User has typed one of the four arrow keys
			// Change or extend the selection
			
			NSObject <SSYCountability> * tokens = [self tokensCollection] ;
			if (!tokens) {
				NSBeep() ;
				return ;
			}
			
			FramedToken* lastSelectedToken ;
			NSPoint target ;
			float margin ;
			
			// If necessary, switch _lastSelectedIndex to match the
			// direction in which the user is headed
			NSIndexSet* selectedIndexSet = [self selectedIndexSet] ;
			if (
				(keyChar == NSLeftArrowFunctionKey) 
				|| (keyChar == NSUpArrowFunctionKey)
				) {			
				// User is heading up
				_lastSelectedIndex = [selectedIndexSet firstIndex] ;
				if (_lastSelectedIndex != NSNotFound) {
					lastSelectedToken = [_framedTokens objectAtIndex:_lastSelectedIndex] ;
				}
				else {
					lastSelectedToken = [_framedTokens lastObject] ;
				}
			}
			else {
				// User is heading down
				_lastSelectedIndex = [selectedIndexSet lastIndex] ;
				if (_lastSelectedIndex != NSNotFound) {
					lastSelectedToken = [_framedTokens objectAtIndex:_lastSelectedIndex] ;
				}
				else if ([_framedTokens count] > 0) {
					lastSelectedToken = [_framedTokens objectAtIndex:0] ;
				}
				else {
					lastSelectedToken = nil ;
				}
			}
			
			NSInteger index = NSNotFound ;
			switch(keyChar) {
				case NSLeftArrowFunctionKey:
					if (_lastSelectedIndex == NSNotFound) {
						index = [tokens count] - 1 ;
					}
					else {
						index = _lastSelectedIndex - 1 ;
					}						
					break ;
					case NSRightArrowFunctionKey: 
					if (_lastSelectedIndex == NSNotFound) {
						index = 0 ;
					}
					else {
						index = _lastSelectedIndex + 1 ;
					}
					
					break ;
					case NSUpArrowFunctionKey:
					case NSDownArrowFunctionKey:
					// Up and down arrow keys are much more complicated...
					margin = minGap + MAX([self fixedFontSize], _minFontSize) / 2 ;
					if (keyChar==NSUpArrowFunctionKey) {
						target.y = [lastSelectedToken topEdge] - margin ;
					}
					else {
						target.y = [lastSelectedToken bottomEdge] + margin ;
					}
					
					target.x = [lastSelectedToken midX] ;
					index = [self indexOfTokenClosestToPoint:target
												excludeToken:lastSelectedToken
									   excludeHigherNotLower:(keyChar==NSDownArrowFunctionKey)] ;
					break ;
			}
			[self changeSelectionPerUserActionAtIndex:index] ;
            
            didHandle = YES ;
		}
		else if (keyChar == '\e') { // the 0x1b ASCII 'escape'
			// User has clicked the 'escape' key
			[self deselectAllIndexes] ;
            didHandle = YES ;
		}
		else if (
                 ([self editability] >= RPTokenControlEditability1)
                 &&
                 (keyChar == NSDeleteCharacter)) {
            BOOL didDelete = [self deleteSelectedTokens] ;            
            if (!didDelete) {
                [self beginEditingNewTokenWithString:s] ;
            }
            didHandle = YES ;
        }
		else if ([self editability] >= RPTokenControlEditability2) {
            [self beginEditingNewTokenWithString:s] ;
            didHandle = YES ;
		}
        else if ([s length] > 0) {
            // This section added in RPTokenControl verison 2.2  (BookMacster 1.12.6)
            if (([self enclosingScrollView] != nil) && (keyChar != NSTabCharacter)) {
                NSArray* candidates = [self selectedTokens] ;
                if ([candidates count] < 1) {
                    candidates = [self tokensArray] ;
                }
                
                // Now, the actual work of finding all existing, matching tags
                NSMutableSet* mutableSet = [[NSMutableSet alloc] init] ;
                [mutableSet addObjectsFromArray:candidates] ;
                
                NSString* prefix = [s substringToIndex:1] ;
                NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", prefix] ;
                [mutableSet filterUsingPredicate:predicate] ;
                NSArray* filteredCandididates = [mutableSet allObjects] ;
#if !__has_feature(objc_arc)
                [mutableSet release];
#endif
                filteredCandididates = [filteredCandididates sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] ;
                if ([filteredCandididates count] > 0) {
                    NSString* firstCandidate = [filteredCandididates objectAtIndex:0] ;
                    for (FramedToken* framedToken in _framedTokens) {
                        if ([[framedToken text] isEqualToString:firstCandidate]) {
                            [self scrollFramedTokenToVisible:framedToken] ;
                            break ;
                        }
                    }
                }
                didHandle = YES ;
                }
        }
	}
	else if ([self editability] > RPTokenControlEditability2) {
		[self beginEditingNewTokenWithString:s] ;
        didHandle = YES ;
	}
    
    // Added in verion 2.3 (BookMacster 1.14.4)
    if (!didHandle) {
        [super keyDown:event] ;
    }
}

- (IBAction)selectAll:(id)sender {
	[self selectAllIndexes] ;
}


// I'm not sure if this does any good for anything
- (BOOL)acceptsFirstResponder {
	return [self isEnabled] ;
}

- (void)changeSelectionPerClickOnFramedToken:(FramedToken*)clickedFramedToken {
    NSUInteger modifierFlags = [[NSApp currentEvent] modifierFlags] ;
    BOOL cmdKeyDown = ((modifierFlags & NSCommandKeyMask) != 0) ;
    if (clickedFramedToken) {
        [self changeSelectionPerUserActionAtFramedToken:clickedFramedToken] ;
    }
    else if (!cmdKeyDown) {
        [self deselectAllIndexes] ;
    }
    else {
        // cmdKeyDown but no token clicked
        // do nothing
    }

    [self sendAction:[self action]
                  to:[self target]] ;
}

- (void)changeSelectionPerMouseEvent:(NSEvent*)event {
	if ([self isEnabled]) {
		NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil] ;
		_mouseDownPoint = pt ;
		FramedToken* clickedFramedToken = [self tokenAtPoint:pt] ;
        [self changeSelectionPerClickOnFramedToken:clickedFramedToken];
    }
}

- (void)mouseDown:(NSEvent*)event {
	[[self window] makeFirstResponder:self] ;
	
    [self changeSelectionPerMouseEvent:event] ;

	// Note that we do not invoke super.  If we do, then we do not 
	// get -mouseDragged: or -mouseDown:.
	// Alastair Houghton explains it thus:
	//    ...the default behaviour is probably to track the mouse until mouse up, but only if -enabled is YES.
	//    I can't say I've noticed this before myself, because I don't tend to forward -mouseDown: to super
	//     where super is a plain NSView.	
}

- (void)mouseUp:(NSEvent*)event {	
}

- (NSDragOperation)      draggingSession:(NSDraggingSession *)session
   sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    NSDragOperation answer ;
    switch(context) {
        case NSDraggingContextOutsideApplication:
        case NSDraggingContextWithinApplication:
        default:
            answer = NSDragOperationCopy ;
            break;
    }
    
    return answer ;
}

- (BOOL)pointHasOvercomeHysteresis:(NSPoint)point {
	float hysteresis = [self defaultFontSize]/2 ;
	if (fabs(point.y - _mouseDownPoint.y) > hysteresis) {
		return YES ;
	}
	if (fabs(point.x - _mouseDownPoint.x) > hysteresis) {
		return YES ;
	}
	
	return NO ;
}

- (void)mouseDragged:(NSEvent *)event {
	NSImage* dragImage = [self dragImage] ;
	if (dragImage) {
		NSPoint pt = [self convertPoint:[event locationInWindow] fromView:self] ;
		if ([self pointHasOvercomeHysteresis:pt]) {
			NSArray* selectedTokens = [self selectedTokens] ;
			if ([selectedTokens count] > 0) {
				NSString* tabSeparatedTokens = [selectedTokens componentsJoinedByString:@"\t"] ;
				NSString* token1 = [selectedTokens objectAtIndex:0] ;
				NSPasteboard *pboard ;
				pboard = [NSPasteboard pasteboardWithName:NSDragPboard] ;
				[pboard declareTypes:[NSArray arrayWithObjects:
									  RPTokenControlPasteboardTypeTokens,
									  RPTokenControlPasteboardTypeTabularTokens,
									  NSStringPboardType,
									  NSTabularTextPboardType, nil]
							   owner:self] ;
				[pboard setString:token1
						  forType:RPTokenControlPasteboardTypeTokens] ;
				[pboard setString:tabSeparatedTokens
						  forType:RPTokenControlPasteboardTypeTabularTokens] ;
				[pboard setString:token1
						  forType:NSStringPboardType] ;
				[pboard setString:tabSeparatedTokens
						  forType:NSTabularTextPboardType] ;
				NSSize dragOffset = NSMakeSize(0.0, 0.0);

                [[self window] dragImage:[self dragImage]
                                      at:pt
                                  offset:dragOffset
                                   event:event
                              pasteboard:pboard
                                  source:self
                               slideBack:YES] ;
			}
		}
	}
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return [NSArray arrayWithObjects:
            RPTokenControlPasteboardTypeTokens,
            RPTokenControlPasteboardTypeTabularTokens,
            NSPasteboardTypeString,      // actually public.utf8-plain-text
            NSPasteboardTypeTabularText, // actually public.utf8-tab-separated-values-text
            nil] ;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    NSPasteboard* pboard = [NSPasteboard pasteboardWithName:NSDragPboard] ;
    id answer = [pboard propertyListForType:type] ;
    if (!answer) {
        answer = [pboard stringForType:type] ;
    }
    return answer ;
}

#pragma mark * Superclass Overrides (Basic Infrastructure)

// Because this NSControl does not have an NSActionCell, the
// following voodoo is needed to give it a cellClass.   Otherwise,
// its -setTarget and -setAction, or any such connection in 
// Interface Builder, will be ignored and -target and -action
// will always return nil.
+ (Class) cellClass {
    return [NSActionCell class];
}

- (NSString *)view:(NSView *)view
  stringForToolTip:(NSToolTipTag)token
			 point:(NSPoint)pos
		  userData:(void *)userData {
	NSString* answer ;
	FramedToken *framedToken = (FramedToken*)userData;
	NSInteger count = [framedToken count] ;
	if (count == 0) {
		// Wants toolTip for the special ellipsisToken
		NSString* key = _appendCountsToStrings ? @"textWithCountAppended" : @"text" ;
		NSArray* truncatedTokenStrings = [[self truncatedTokens] valueForKey:key] ;
		answer = [truncatedTokenStrings componentsJoinedByString:@"\n"] ;
	}
	else if (_showsCountsAsToolTips) {
		answer = [NSString stringWithFormat:@"%ld", (long)count] ;
	}
	else {
		// Return the regular view-wide toolTip, which is set by -setToolTip:
		answer =  [self toolTip] ;
	}
	
	return answer ;
}

- (void)initCommon {
    [self setObjectValue:SSYNoTokensMarker] ;
    NSMutableIndexSet* set = [[NSMutableIndexSet alloc] init] ;
    [self setSelectedIndexSet:set] ;
#if !__has_feature(objc_arc)
    [set release];
#endif
    [self setEditability:RPTokenControlEditability1] ;
    
    [self setMaxTokensToDisplay:NSNotFound] ;
    [self setMinFontSize:11.0] ;
    [self setMaxFontSize:40.0] ;
    [self setFixedFontSize:0.0] ;
    [self setBackgroundWhiteness:1.0] ;
    [self setTokenColorScheme:RPTokenControlTokenColorSchemeBlue] ;
    [self setCornerRadiusFactor:0.5] ;
    [self setWidthPaddingMultiplier:3.0] ;
}

- (id) initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self != nil) {
		[self initCommon];
	}
	
	return self ;
}

// Although NSResponder::NSControl subclasses can sometimes get away with not implementing these
// two methods, not so if the control is used in SSYAlert, because SSYAlert will encode it when
// adding to its configurations stack.

// @encode(type_spec) is a compiler directive that returns a character string that encodes
//    the type structure of type_spec.  It can be used as the first argument of can be used as
//    the first argument of encodeValueOfObjCType:at:

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder] ;
    
	[coder encodeBool:_appendCountsToStrings forKey:constKeyAppendCountsToStrings] ;
	[coder encodeBool:_showsCountsAsToolTips forKey:constKeyShowsCountsAsToolTips] ;
    [coder encodeBool:m_canDeleteTags forKey:constKeyCanDeleteTags] ;
	[coder encodeBool:_isDoingLayout forKey:constKeyIsDoingLayout] ;
	[coder encodeBytes:(const uint8_t*)&m_tokenizingCharacter length:sizeof(unichar) forKey:constKeyTokenizingCharacter] ;
	[coder encodeInteger:_firstTokenToDisplay forKey:constKeyFirstTokenToDisplay] ;
	[coder encodeInteger:_fancyEffects forKey:constKeyFancyEffects] ;
	[coder encodeObject:m_delegate forKey:constKeyDelegate] ;
	[coder encodeObject:_dragImage forKey:constKeyDragImage] ;
	[coder encodeObject:_framedTokens forKey:constKeyFramedTokens] ;
	[coder encodeObject:_truncatedTokens forKey:constKeyTruncatedTokens] ;
	[coder encodeObject:m_disallowedCharacterSet forKey:constKeyDisallowedCharacterSet] ;
	[coder encodeObject:m_tokenizingCharacterSet forKey:constKeyTokenizingCharacterSet] ;
	[coder encodeObject:m_replacementString forKey:constKeyReplacementString] ;
	[coder encodeObject:m_noTokensPlaceholder forKey:constKeyNoTokensPlaceholder] ;
	[coder encodeObject:m_noSelectionPlaceholder forKey:constKeyNoSelectionPlaceholder] ;
	[coder encodeObject:m_multipleValuesPlaceholder forKey:constKeyMultipleValuesPlaceholder] ;
	[coder encodeObject:m_notApplicablePlaceholder forKey:constKeyNotApplicablePlaceholder] ;
	[coder encodeObject:_linkDragType forKey:constKeyLinkDragType] ;
	[coder encodeObject:_textField forKey:constKeyTextField] ;
}

- (id)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder] ;
	
    if (self) {
        NSUInteger betterBeLengthOfUnichar = 2 ;
        _appendCountsToStrings = [coder decodeBoolForKey:constKeyAppendCountsToStrings] ;
        _showsCountsAsToolTips = [coder decodeBoolForKey:constKeyShowsCountsAsToolTips] ;
        m_canDeleteTags = [coder decodeBoolForKey:constKeyCanDeleteTags] ;
        _isDoingLayout = [coder decodeBoolForKey:constKeyIsDoingLayout] ;
        m_tokenizingCharacter = (unichar)[coder decodeBytesForKey:constKeyTokenizingCharacter returnedLength:&betterBeLengthOfUnichar] ;
        _firstTokenToDisplay = [coder decodeIntegerForKey:constKeyFirstTokenToDisplay] ;
        _fancyEffects = [coder decodeIntegerForKey:constKeyFancyEffects] ;
        m_delegate = [coder decodeObjectForKey:constKeyDelegate];
        _dragImage = [coder decodeObjectForKey:constKeyDragImage];
        _framedTokens = [coder decodeObjectForKey:constKeyFramedTokens];
        _truncatedTokens = [coder decodeObjectForKey:constKeyTruncatedTokens];
        m_disallowedCharacterSet = [coder decodeObjectForKey:constKeyDisallowedCharacterSet];
        m_tokenizingCharacterSet = [coder decodeObjectForKey:constKeyTokenizingCharacterSet];
        m_replacementString = [coder decodeObjectForKey:constKeyReplacementString];
        m_noTokensPlaceholder = [coder decodeObjectForKey:constKeyNoTokensPlaceholder];
        m_noSelectionPlaceholder = [coder decodeObjectForKey:constKeyNoSelectionPlaceholder];
        m_multipleValuesPlaceholder = [coder decodeObjectForKey:constKeyMultipleValuesPlaceholder];
        m_notApplicablePlaceholder = [coder decodeObjectForKey:constKeyNotApplicablePlaceholder];
        _linkDragType = [coder decodeObjectForKey:constKeyLinkDragType];
        _textField = [coder decodeObjectForKey:constKeyTextField];
#if !__has_feature(objc_arc)
        [m_delegate retain];
        [_dragImage retain];
        [_framedTokens retain];
        [_truncatedTokens retain];
        [m_disallowedCharacterSet retain];
        [m_tokenizingCharacterSet retain];
        [m_replacementString retain];
        [m_noTokensPlaceholder retain];
        [m_noSelectionPlaceholder retain];
        [m_multipleValuesPlaceholder retain];
        [m_notApplicablePlaceholder retain];
        [_linkDragType retain];
        [_textField retain];
#endif
        [self initCommon] ;
    }
	return self ;
}

- (void)dealloc {
#if !__has_feature(objc_arc)
	[_dragImage release] ;
	[_linkDragType release] ;
	[_tokenBeingEdited release] ;
	[m_disallowedCharacterSet release] ;
	[m_replacementString release] ;
	[m_tokenizingCharacterSet release] ;
	[m_noTokensPlaceholder release] ;
	[m_noSelectionPlaceholder release] ;
	[m_multipleValuesPlaceholder release] ;
	[m_notApplicablePlaceholder release] ;
	[_selectedIndexSet release] ;
	[_textField release] ;
	[_framedTokens release] ;
	[_truncatedTokens release] ;
	[m_objectValue release] ;
    [_accessibilityChildren release];
#endif

	[super dealloc] ;
}

- (void)awakeFromNib {
	[self sendActionOn:NSLeftMouseDownMask] ;
	// We need to  that because the default for an NSControl
	// seems to be "left mouse UP".  We want DOWN.
	
	[self setReplacementString:@"_"] ;
}

- (BOOL)isFlipped {
	// I believe that Robert decided to use a flipped y-coordinate because this
	// makes the -doLayout method easier, because you start laying in tokens from
	// the top.
	return YES ;
}

- (void)drawRect:(NSRect)rect {	
    if(_backgroundWhiteness < 1.0) {
        [[NSColor colorWithCalibratedWhite:_backgroundWhiteness alpha:1.0] set];
        NSRectFill(rect);
    }
   	
 	if ([_framedTokens count] > 0) {
		CGContextRef context = NULL;
        if ((_fancyEffects & RPTokenFancyEffectShadow) != 0) {
            context = [[NSGraphicsContext currentContext] graphicsPort];
            CGContextSaveGState(context);
            CGSize cgshOffset = {2.0, -2.0};
            CGContextSetShadow(context, cgshOffset, 1.0);
            CGContextBeginTransparencyLayer(context, NULL);
        }
        
        NSColor* fillColor = nil ;
        NSColor* outlineColor = nil ;

        // Create attrDeselected, attributes for deselected tokens
        switch (_tokenColorScheme) {
            case RPTokenControlTokenColorSchemeBlue:
                fillColor = [NSColor colorWithCalibratedRed:214.0/255 green:224.0/255 blue:246.0/255 alpha:1.0] ;
                outlineColor = [NSColor colorWithCalibratedRed:147.0/255 green:173.0/255 blue:231.0/255 alpha:1.0] ;
                break ;
            case RPTokenControlTokenColorSchemeWhite:
                fillColor = [NSColor whiteColor] ;
                outlineColor = nil ;
                break ;
        }
		NSDictionary *attrDeselected = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithFloat:_cornerRadiusFactor], TCCornerRadiusFactorAttributeName,
                                        [NSNumber numberWithFloat:_widthPaddingMultiplier], TCWidthPaddingMultiplierAttributeName,
                                        fillColor, TCFillColorAttributeName,
                                        outlineColor, TCStrokeColorAttributeName,  // may be nil
										nil] ;

		// Create attrSelected, attributes for selected tokens
		NSShadow *shadow = nil ;
        if ((_fancyEffects & RPTokenFancyEffectShadow) != 0) {
            // This appears to add a slight shadow to the text (characters)
            // I guess it complements the shadow under the token.
            // Why did Robert apply it to attrSelected and not attrDeselected?
            shadow = [[NSShadow alloc] init];
            [shadow setShadowOffset:NSMakeSize(2.0, -2.0)];
            [shadow setShadowBlurRadius:2.0];
        }
        switch (_tokenColorScheme) {
            case RPTokenControlTokenColorSchemeBlue:
                fillColor = [NSColor colorWithCalibratedRed:72.0/255 green:116.0/255 blue:231.0/255 alpha:1.0] ;
                break ;
            case RPTokenControlTokenColorSchemeWhite:
                fillColor = [NSColor selectedTextBackgroundColor] ;
                break ;
        }
		NSDictionary *attrSelected = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSColor whiteColor], NSForegroundColorAttributeName,
                                      [NSNumber numberWithFloat:_cornerRadiusFactor], TCCornerRadiusFactorAttributeName,
                                      [NSNumber numberWithFloat:_widthPaddingMultiplier], TCWidthPaddingMultiplierAttributeName,
									  fillColor, TCFillColorAttributeName,
                                      // Deselected token does not have an outline, so TCStrokeColorAttributeName is omitted.
                                      shadow, NSShadowAttributeName,  // may be nil
									  nil] ;
#if !__has_feature(objc_arc)
		[shadow release];
#endif
        
		// Draw tokens that need to be drawn
        NSInteger i = 0 ;
		for (i=0; i<[_framedTokens count]; i++) {
			FramedToken *framedToken = [_framedTokens objectAtIndex:i] ;
			NSRect bounds = [framedToken bounds];
            if(!NSIntersectsRect(rect, bounds)) {
				// This framedToken is not in the rect to be drawn; move on to next one
				continue ;
			}
			else if (i == _indexOfFramedTokenBeingEdited) {
				// Don't draw the token if it is currently being obscured
				// by our _textField for editing.
				continue ;
			}
			if([self isSelectedFramedToken:framedToken]) {
				[framedToken drawWithAttributes:attrSelected
									appendCount:_appendCountsToStrings];
			}
			else {
				[framedToken drawWithAttributes:attrDeselected
									appendCount:_appendCountsToStrings] ;
			}
			
            if ((_fancyEffects & RPTokenFancyEffectReflection) != 0) {
				NSRect ref = NSMakeRect(bounds.origin.x+1, bounds.origin.y+1, bounds.size.width-3, bounds.size.height-3);
                ref.origin.y += 2 + ref.size.height;   
                if(NSIntersectsRect(rect, ref)) {
                    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:ref radius:ref.size.height*0.2];
                    [path shadow] ;  
                }
            }
        }
		
        if(context) {
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);	
        }
	}
	else {
		NSString* string = nil;
		id value = [self objectValue] ;
		if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
			// value is an empty collection.  That's OK.
			// Leave string = nil ;
		}
		else if (value == SSYNoTokensMarker) {
			string = [self noTokensPlaceholder] ;
		}
		else if (value == NSNoSelectionMarker) {
			string = [self noSelectionPlaceholder] ;
		}
		else if (value == NSMultipleValuesMarker) {
			string = [self multipleValuesPlaceholder] ;
		}
		else if (value == NSNotApplicableMarker) {
			string = [self notApplicablePlaceholder] ;
		}
		else {
			NSLog(@"Internal Error 189-1847 %@", value) ;
		}
		
		if (string != nil) {
			float fontSize = [self defaultFontSize] ;
			NSFont* font = [FramedToken fontOfSize:fontSize] ;
			float notUsed ;
			float whiteness = modff(_backgroundWhiteness + 0.5, &notUsed) ;
			NSColor* color = [NSColor colorWithCalibratedWhite:whiteness
														 alpha:1.0] ;
			NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
										font, NSFontAttributeName,
										color, NSForegroundColorAttributeName,
										nil] ;
			NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:string
																				   attributes:attributes] ;
			NSRect rect = [self frame] ;
			rect.origin = NSMakePoint(fontSize * .25 + tokenBoxTextInset, tokenBoxTextInset) ;
			[attributedString drawInRect:rect] ;
#if !__has_feature(objc_arc)
			[attributedString release];
#endif
		}												
	}
	
	
	// Draw focus ring if we are firstResponder
	if ([[self window] firstResponder] == self) {
        // The following line was deleted for the BkmkMgrs 1.22.29 experiment
		[self drawFocusRing] ;
    }
}

#pragma mark * NSDraggingDestination Protocol Methods

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard* pboard = [sender draggingPasteboard] ;
	NSArray* types = [pboard types] ;
	NSDragOperation operation = NSDragOperationNone ;
	// Test this because registeredDraggedTypes is not supported in Mac OS 10.3
	if ([self respondsToSelector:@selector(registeredDraggedTypes)]) {
		NSString* linkDragType = [self linkDragType] ;
		BOOL tryDefaultTypes = YES ;
		if (linkDragType != nil) {
			if ([types containsObject:linkDragType]) {
				id delegate = [self delegate] ;
				if ([delegate respondsToSelector:@selector(draggingEntered:)]) {
					operation = [delegate draggingEntered:sender] ;
				}
				else {
					operation = NSDragOperationCopy ;
				}
				tryDefaultTypes = NO ;
			}
		}
		
		if (tryDefaultTypes) {
			NSEnumerator* e = [[self registeredDraggedTypes] objectEnumerator] ;
			NSString* type ;
			while ((type = [e nextObject])) {
				if ([types containsObject:type]) {
					operation = NSDragOperationCopy ;
					break ;
				}
			}
		}
	}
	
	return operation ;
}

- (BOOL)wantsPeriodicDraggingUpdates {
	// Updates every time the mouse moves will be sufficient.
	return NO ;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	NSPoint locationInWindow = [sender draggingLocation] ;
	NSPoint locationInSelf = [self convertPoint:locationInWindow
									   fromView:nil] ;  // nil => convert from window coordinates
	FramedToken* token = [self tokenAtPoint:locationInSelf] ;
	if (token) {
		// Select, or extend selection
		[self changeSelectionPerUserActionAtFramedToken:token] ;
	}
	
	if ([[self selectedTokens] count] > 0) {
		id delegate = [self delegate] ;
		if ([delegate respondsToSelector:@selector(draggingUpdated:)]) {
			return [delegate draggingUpdated:sender] ;
		}
		else {
			return YES ;
		}
	}
	
    NSPasteboard* pboard = [sender draggingPasteboard] ;
	NSArray* types = [pboard types] ;
	NSDragOperation operation = NSDragOperationNone ;
	// Test this because registeredDraggedTypes is not supported in Mac OS 10.3
	if ([self respondsToSelector:@selector(registeredDraggedTypes)]) {
		NSString* linkDragType = [self linkDragType] ;
		BOOL tryDefaultTypes = YES ;
		if (linkDragType != nil) {
			if ([types containsObject:linkDragType]) {
				id delegate = [self delegate] ;
				if ([delegate respondsToSelector:@selector(draggingUpdated:)]) {
					operation = [delegate draggingUpdated:sender] ;
				}
				else {
					operation = NSDragOperationCopy ;
				}
				tryDefaultTypes = NO ;
			}
		}
		
		if (tryDefaultTypes) {
			NSEnumerator* e = [[self registeredDraggedTypes] objectEnumerator] ;
			NSString* type ;
			while ((type = [e nextObject])) {
				if ([types containsObject:type]) {
					operation = NSDragOperationCopy ;
					break ;
				}
			}
		}
	}
	
	return operation ;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
	// Since we would have previously cancelled the drag if we didn't
	// like it in draggingEntered, we simply
	return YES ;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
	
    pboard = [sender draggingPasteboard];
    BOOL ok = NO ;
	NSArray* newTokens = nil ;
	NSString* linkDragType = [self linkDragType] ;
	
	if ((linkDragType != nil) && ([[pboard types] containsObject:linkDragType])) {
		id delegate = [self delegate] ;
		if ([delegate respondsToSelector:@selector(performDragOperation:)]) {
			ok = [delegate performDragOperation:sender] ;
		}
		else {
			ok = NO ;
		}
	}
	else if ( [[pboard types] containsObject:NSTabularTextPboardType] ) {
        NSString* tokenString = [pboard stringForType:NSTabularTextPboardType] ;
		newTokens = [tokenString componentsSeparatedByString:@"\t"] ;
		ok = YES ;
    }
	else if ( [[pboard types] containsObject:NSStringPboardType] ) {
        NSString* newToken = [pboard stringForType:NSStringPboardType] ;
		newTokens = [NSArray arrayWithObject:newToken] ;
		ok = YES ;
    }
	
	if (newTokens != nil) {
		NSMutableSet* tokens = [[self tokensSet] mutableCopy] ;
		[tokens unionSet:[NSSet setWithArray:newTokens]] ;
		[self setObjectValue:tokens] ;
#if !__has_feature(objc_arc)
		[tokens release];
#endif
		ok = YES ;
	}		
	
    return ok ;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	id delegate = [self delegate] ;
	if ([delegate respondsToSelector:@selector(draggingExited:)]) {
		[delegate draggingExited:sender] ;
	}
}


#pragma mark Contextual Menu Support

- (IBAction)deleteSelectedTokens:(NSMenuItem*)sender {
    [self deleteSelectedTokens] ;
}

- (IBAction)renameSelectedToken:(NSMenuItem*)sender {
    RPCountedToken* token = [sender representedObject] ;
    [(NSObject <RPTokenControlDelegate> *)[self delegate] tokenControl:self
                                                   renameToken:[token text]] ;
}

- (NSString*)menuItemTitleToDeleteTokenControl:(RPTokenControl*)tokenControl
                                         count:(NSInteger)count
                                     tokenName:(NSString*)tokenName {
    NSString *title;
    NSString* subject ;
    if (count < 2) {
        subject = [NSString stringWithFormat:
                   @"'%@'",
                   tokenName] ;
    }
    else {
        subject = [NSString stringWithFormat:
                   @"%ld tokens",
                   (long)count] ;
    }
    title = [NSString stringWithFormat:
             @"Delete %@",
             subject] ;

    return title ;
}

- (void)updateSelectionForEvent:(NSEvent*)event {
    // The following section is to give expected behavior when user performs
    // a secondary click on an item without selecting it first.
    NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil] ;
    _mouseDownPoint = pt ;
    FramedToken* clickedFramedToken = [self tokenAtPoint:pt] ;
    RPCountedToken* countedToken = [clickedFramedToken token] ;
    if ([[self selectedTokens] indexOfObject:countedToken] == NSNotFound) {
        NSInteger index = [_framedTokens indexOfObject:clickedFramedToken] ;
        [self deselectAllIndexes] ;
        [self selectIndex:index] ;
    }
}

- (NSMenu*)menuForEvent:(NSEvent *)event {
    [self updateSelectionForEvent:event] ;
    
    NSMenu* menu ;
	if ([self isEnabled]) {

		NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil] ;
		_mouseDownPoint = pt ;
		FramedToken* clickedFramedToken = [self tokenAtPoint:pt] ;
        if (clickedFramedToken) {
            RPCountedToken* countedToken = [clickedFramedToken token] ;
            menu = [[[NSMenu alloc] init] autorelease] ;
            
            NSMenuItem* menuItem ;
            NSString* title ;
            
            // Menu item for "Delete"
            NSInteger count = MAX([[self selectedTokens] count], 1) ;
            NSString* clickedTokenName = [countedToken text] ;
            if ([[self delegate] respondsToSelector:@selector(menuItemTitleToDeleteTokenControl:count:tokenName:)]) {
                title = [(id <RPTokenControlDelegate>)[self delegate] menuItemTitleToDeleteTokenControl:self
                                                                                                  count:count
                                                                                              tokenName:clickedTokenName] ;
            }
            else {
                title = [self menuItemTitleToDeleteTokenControl:self
                                                          count:count
                                                      tokenName:clickedTokenName] ;
            }
            
            menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                        initWithTitle:title
                        action:@selector(deleteSelectedTokens:)
                        keyEquivalent:@""] ;
            [menuItem setTarget:self] ;
            [menuItem setRepresentedObject:event] ;
            [menu addItem:menuItem] ;
#if !__has_feature(objc_arc)
            [menuItem release];
#endif
            
            // Menu item for "Rename"
            if ([[self delegate] respondsToSelector:@selector(tokenControl:renameToken:)]) {
                title = [NSString stringWithFormat:
                         @"Rename '%@'",
                         [countedToken text]] ;
                menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                            initWithTitle:title
                            action:@selector(renameSelectedToken:)
                            keyEquivalent:@""] ;
                [menuItem setTarget:self] ;
                [menuItem setRepresentedObject:countedToken] ;
                [menu addItem:menuItem] ;
#if !__has_feature(objc_arc)
                [menuItem release];
#endif
            }
        }
        else {
            NSBeep() ;
            menu = nil ;
        }
    }
    else {
        menu = [super menuForEvent:event] ;
    }

    return menu ;
}

- (NSArray*)accessibilityChildren {
    /* For explanation of why we go through the trouble of storing this array
     in a ivar (_accessibilityChildren), and carefully re-use prior children
     instead of just re-creating the whole array from scratch each time this
     method runs, which would be a lot less code, read this:
     https://stackoverflow.com/questions/43986641/macos-accessibility-groups */
    NSMutableSet* extraChildren = [[NSMutableSet setWithArray:_accessibilityChildren] mutableCopy];
    NSMutableSet* missingChildren = [NSMutableSet new];
    for (FramedToken* framedToken in _framedTokens) {
        BOOL alreadyExists = NO;
        for (FramedTokenAccessibilityElement* child in _accessibilityChildren) {
            if (framedToken == child.framedToken) {
                [extraChildren removeObject:child];
                alreadyExists = YES;
                break;
            }
        }

        if (!alreadyExists) {
            FramedTokenAccessibilityElement* child = [[FramedTokenAccessibilityElement alloc] initWithTokenControl:self
                                                                                                       framedToken:framedToken];
            child.accessibilityParent = self;
            NSRect frame = [framedToken bounds];
            /* It seems like, since self is assigned to the child's
             accessibilityParent, Cocoa should be smart enough to ask parent if
             it -isFlipped and do the flipping for us.  However, testing in
             macOS 10.12, we find that, without the following flip, the black
             VoiceOver rectangles begin from the bottom of the RPTokenControl
             instead of from the top.  Am I missing something? */
            if (self.isFlipped) {
                frame.origin.y = self.frame.size.height - frame.origin.y - frame.size.height;
            }
            child.accessibilityFrameInParentSpace = frame;

            [missingChildren addObject:child];
#if !__has_feature(objc_arc)
            [child release];
#endif
        }
    }

    if ((extraChildren.count > 0) || (missingChildren.count > 0)) {
        NSMutableArray* accessibilityChildren;
        if (_accessibilityChildren) {
            accessibilityChildren = [_accessibilityChildren mutableCopy];
        } else {
            accessibilityChildren = [NSMutableArray new];
        }

        for (FramedTokenAccessibilityElement* child in extraChildren) {
            [accessibilityChildren removeObject:child];
        }
        for (FramedTokenAccessibilityElement* child in missingChildren) {
            [accessibilityChildren addObject:child];
        }
#if !__has_feature(objc_arc)
        [_accessibilityChildren release];
#endif
        _accessibilityChildren = [accessibilityChildren copy];
#if !__has_feature(objc_arc)
        [accessibilityChildren release];
#endif
    }
#if !__has_feature(objc_arc)
    [extraChildren release];
    [missingChildren release];
#endif


    return _accessibilityChildren;
}



@end
