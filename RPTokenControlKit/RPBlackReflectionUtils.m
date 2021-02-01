
// CoreGraphics gradient helpers
static void _linearColorBlendFunction(void *info, const CGFloat *in, CGFloat *out) {
    const float cut = 0.3;
    float b = (*in - cut)*1.0/(1.0-cut);
    b = (b < 0.0)?0.0:b*b;
    out[0] = 0.8;
    out[1] = 0.8;
    out[2] = 0.8;
    out[3] = b;
}
static const CGFloat domainAndRange[8] = {0.0, 1.0, 0.0, 1.0, 0.0, 1.0,0.0, 1.0};
static const CGFunctionCallbacks linearFunctionCallbacks = {0, &_linearColorBlendFunction, 0};


@implementation NSBezierPath(RoundedRectangle)
+ (NSBezierPath*)bezierPathWithRoundedRect:(NSRect)aRect radius:(float)radius {
   NSBezierPath* path = [self bezierPath];
   radius = MIN(radius, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
   NSRect rect = NSInsetRect(aRect, radius, radius);
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
   [path closePath];
   return path;
}

- (void)shadow {
    CGFunctionRef linearBlendFunctionRef = CGFunctionCreate(NULL, 1, domainAndRange, 4, domainAndRange, &linearFunctionCallbacks);
    CGContextRef currentContext = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(currentContext);
    CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    NSRect bounds = [self bounds];
    CGShadingRef myCGShading = CGShadingCreateAxial(colorspace, CGPointMake(0, NSMaxY(bounds)), CGPointMake(0, NSMinY(bounds)), linearBlendFunctionRef, NO, NO);
    [self addClip];
    CGContextDrawShading(currentContext, myCGShading);
    CGShadingRelease(myCGShading);
    CGColorSpaceRelease(colorspace);
    CGFunctionRelease(linearBlendFunctionRef);
    CGContextRestoreGState(currentContext);
}

@end
