#import "RPCountedToken.h"

@implementation RPCountedToken
- (id)initWithText:(NSString*)text
			 count:(int)count {
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
	return [_text stringByAppendingFormat:@" [%d]", _count] ;
}

- (int)count {
	return _count;
}

- (BOOL)isEllipsisToken {
	return (_count == 0) ;
}

- (NSComparisonResult)textCompare:(RPCountedToken*)other {
	return [_text localizedCaseInsensitiveCompare:[other text]] ;
}

- (NSComparisonResult)countCompare:(RPCountedToken*)other {
	int count = [other count] ;
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
	return [NSString stringWithFormat:@"<RPCountedToken %x> _count=%d _text=%@", self, _count, _text] ;
}

+ (RPCountedToken*)ellipsisToken {
	unichar ellipsisChar = 0x2026 ;
	NSString* ellipsisString = [NSString stringWithCharacters:&ellipsisChar
													   length:1] ;
	RPCountedToken* instance = [[RPCountedToken alloc] initWithText:ellipsisString
														  count:0] ;
	return [instance autorelease] ;
}

@end

