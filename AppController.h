#import <Cocoa/Cocoa.h>

@class RPTokenControl;

@interface AppController : NSObject {
    IBOutlet NSTextView *source;
    IBOutlet RPTokenControl *tokenControl ;
	IBOutlet NSArrayController* tokensArrayController ;
	
	int _tokenType ; // 0=RPCountedToken*, 1=NSString*
}

- (IBAction)tokenTypeChanged:(id)sender;
- (IBAction)selectionChanged:(id)sender;

@end
