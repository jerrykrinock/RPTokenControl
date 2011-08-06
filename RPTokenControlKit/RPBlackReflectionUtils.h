#import <Cocoa/Cocoa.h>

@interface NSBezierPath(RoundedRectangle)
/*
 * Returns a closed bezier path describing a rectangle with curved corners
 * The corner radius will be trimmed to not exceed half of the lesser rectangle dimension.
 * <http://www.cocoadev.com/index.pl?RoundedRectangles>
 */
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect) aRect radius:(float) radius;

- (void)shadow;
@end
