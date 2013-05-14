#import <Cocoa/Cocoa.h>

@class RPTokenControl;

@interface AppController : NSObject
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
<NSTextViewDelegate, NSWindowDelegate>
#endif
{
    IBOutlet NSTextView *source;
    IBOutlet RPTokenControl *tokenControl ;
	IBOutlet NSArrayController* tokensArrayController ;
}

- (IBAction)selectionChanged:(id)sender;

@end
