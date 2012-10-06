#import "RPCountedToken.h"

@implementation RPCountedToken
- (id)initWithText:(NSString*)text
			 count:(NSInteger)count {
	if((self = [super init])) {
		_text = [text retain] ;
		_count = count ;
	}
	return self;
}

- (void)dealloc {
	[_text release] ;

	[super dealloc] ;
}

- (void)incCount {
	_count++ ;
}

- (NSString*)text {
	return _text ;
}

- (NSString*)textWithCountAppended {
	return [_text stringByAppendingFormat:@" [%ld]", (long)_count] ;
}

- (NSInteger)count {
	return _count;
}

- (BOOL)isEllipsisToken {
	return (_count == 0) ;
}

- (NSComparisonResult)textCompare:(RPCountedToken*)other {
	return [_text localizedCaseInsensitiveCompare:[other text]] ;
}

- (NSComparisonResult)countCompare:(RPCountedToken*)other {
	NSInteger count = [other count] ;
	// Note that if ivar count is nil, the local variable count will be 0
	// Therefore, this "just works" if tokens do not have the 'count' attribute.
	if(_count < count) {
		return NSOrderedDescending ;
	}
	else if (_count > count) {
		return NSOrderedAscending ;
	}
	
	return [self textCompare:other] ;
}

- (NSString*) description {
	return [NSString stringWithFormat:@"<RPCountedToken %p> _count=%ld _text=%@", self, (long)_count, _text] ;
}

+ (RPCountedToken*)ellipsisToken {
	unichar ellipsisChar = 0x2026 ;
	NSString* ellipsisString = [NSString stringWithCharacters:&ellipsisChar
													   length:1] ;
	RPCountedToken* instance = [[RPCountedToken alloc] initWithText:ellipsisString
														  count:0] ;
	return [instance autorelease] ;
}

- (BOOL)isEqual:(id)other {
	BOOL answer ;
	
	if ([other respondsToSelector:@selector(text)]) {
		answer = [[self text] isEqualToString:[(RPCountedToken*)other text]] ;
	}
	else if ([other isKindOfClass:[NSString class]]) {
		answer = [[self text] isEqualToString:other] ;
	}
	else {
		answer = NO ;
	}
	
	return answer ;
}

/*!
 @details  From documentation of -isEqual:
 If two objects are equal, they must have the same hash value.
 This last point is particularly important if you define isEqual:
 in a subclass and intend to put instances of that subclass into
 a collection. Make sure you also define hash in your subclass.
*/
- (NSUInteger)hash {
	return [[self text] hash] ;
}

@end

