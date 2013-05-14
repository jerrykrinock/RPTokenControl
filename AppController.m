#import "AppController.h"
#import "RPTokenControl.h"
#import "RPCountedToken.h"

@implementation AppController

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
	NSCountedSet *words = [[NSCountedSet alloc] init];
	NSString *text = [source string];
    NSScanner *scan = [[NSScanner alloc] initWithString:text];
	NSCharacterSet* alphaChars = [NSCharacterSet alphanumericCharacterSet];
	[scan scanUpToCharactersFromSet:alphaChars intoString:nil];
	while(![scan isAtEnd]) {
		NSString *word = nil;
		[scan scanCharactersFromSet:alphaChars intoString:&word];
        word = [word lowercaseString];
        [words addObject:word] ;
		[scan scanUpToCharactersFromSet:alphaChars intoString:nil];
	}
    [tokenControl setObjectValue:words];
	[scan release] ;
    [words release];
}

@end
