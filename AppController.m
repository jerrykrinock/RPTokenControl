#import "AppController.h"
#import "RPTokenControl.h"
#import "RPCountedToken.h"

@implementation AppController

- (IBAction)tokenTypeChanged:(id)sender {
	_tokenType = [sender selectedTag] ;
	[self textDidChange:nil] ;
}

- (IBAction)selectionChanged:(id)sender {
    NSLog(@"%@ has sent an action", sender) ;
}

- (void)awakeFromNib {
	[source setDelegate:self] ;
    
    [[source window] setDelegate:self] ; //catch close
    
    [self textDidChange:nil] ;
	
//	These are set in InterfaceBuilder
//	[tokenControl setTarget:self] ;
//	[tokenControl setAction:@selector(selectionChanged:)] ;
	
	[tokensArrayController bind:@"contentArray"
					 toObject:tokenControl
				  withKeyPath:@"selectedTokens"
					  options:nil] ;
}

- (void)windowWillClose:(NSNotification *)notification {
	[NSApp terminate:self];
}

- (void)textDidChange:(NSNotification *)note {
    BOOL useCounts = (_tokenType == 0) ;
	
	NSMutableDictionary *stats = [[NSMutableDictionary alloc] init];
	// stats will be loaded with key=text, value=RPCountedToken.
	// Note that the 'text' is also an ivar in RPCountedToken.
	// In the end, we extract an array of only the values (RPCountedTokens)
	// and set in the tokenControl.
	NSString *text = [source string];
    NSScanner *scan = [[NSScanner alloc] initWithString:text];
	NSCharacterSet* alphaChars = [NSCharacterSet alphanumericCharacterSet];
	[scan scanUpToCharactersFromSet:alphaChars intoString:nil];
	while(![scan isAtEnd]) {
		NSString *tokenText = nil;
		[scan scanCharactersFromSet:alphaChars intoString:&tokenText];
        tokenText = [tokenText lowercaseString];
		id entry = [stats objectForKey:tokenText];
		if(!entry) { 
			if (useCounts) {
				entry = [[RPCountedToken alloc] initWithText:tokenText
													   count:0] ; 
			}
			else {
				entry = [tokenText retain] ;
			}
			[stats setObject:entry forKey:tokenText] ;
            [entry release] ;
		}
		if ([entry respondsToSelector:@selector(incCount)]) {
			// RPCountedTokens do, NSStrings do not
			[entry incCount] ;
		}
		
		[scan scanUpToCharactersFromSet:alphaChars intoString:nil];
	}
    [tokenControl setObjectValue:[stats allValues]];
	[scan release] ;
    [stats release];
}

@end
