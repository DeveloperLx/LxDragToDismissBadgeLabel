//
//  DeveloperLx
//  LxDragToDismissBadgeLabel.m
//

#import "LxDragToDismissBadgeLabel.h"

static CGFloat const DECREASE_FACTOR = 0.004;
static CGFloat const VIBRATE_ANGLE_FREQUENCY = 2 * M_PI * 16;
static CGFloat const DAMP_FACTOR = 0.01;

@implementation LxDragToDismissBadgeLabel
{
    UIView * _placeholderView;
    CAShapeLayer * _dragTrackShapeLayer;
    NSTimeInterval _endDraggingTimestamp;
    CADisplayLink * _displayLink;
}
@synthesize center = _center,radius = _radius;

- (instancetype)initWithCenter:(CGPoint)center radius:(CGFloat)radius
{
    NSAssert(radius > 0, @"BadgeLabel: Radius must be greater than 0.");
    
    if (self = [super init]) {
        
        _center = center;
        _radius = radius;
        
        self.frame = CGRectMake(center.x - radius, center.y - radius, 2 * radius, 2 * radius);
        self.layer.cornerRadius = radius;
        self.layer.masksToBounds = YES;
        super.numberOfLines = 1;
        super.textAlignment = NSTextAlignmentCenter;
        self.backgroundColor = [UIColor redColor];
        self.textColor = [UIColor whiteColor];
        
        self.userInteractionEnabled = YES;
        UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureRecognizerTriggerd:)];
        [self addGestureRecognizer:pan];
        
        self.maxStretchDistance = 100;
    }
    return self;
}

- (void)setCenter:(CGPoint)center
{
    if (!CGPointEqualToPoint(_center, center)) {
        self.frame = CGRectMake(center.x - self.frame.size.width/2, center.y - self.frame.size.height/2, self.frame.size.width, self.frame.size.height);
        _center = center;
    }
}

- (CGPoint)center
{
    return _center;
}

- (void)setRadius:(CGFloat)radius
{
    if (_radius != radius) {
        self.frame = CGRectMake(self.center.x + _radius - radius, self.center.y - radius, self.frame.size.width - 2 * _radius + 2 * radius, 2 * radius);
        _radius = radius;
    }
}

- (CGFloat)radius
{
    return _radius;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    CGSize textTotalSize = [self textRectForBounds:CGRectMake(0, 0, CGFLOAT_MAX, 2 * self.radius) limitedToNumberOfLines:super.numberOfLines].size;
    textTotalSize.width = MAX(textTotalSize.width + (2 - sqrt(2)) * self.radius, 2 * self.radius);
    textTotalSize.height = 2 * self.radius;
    self.frame = CGRectMake(self.center.x - textTotalSize.width/2, self.center.y - self.radius, textTotalSize.width, 2 * self.radius);
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    CGSize textTotalSize = [self textRectForBounds:CGRectMake(0, 0, CGFLOAT_MAX, 2 * self.radius) limitedToNumberOfLines:super.numberOfLines].size;
    textTotalSize.width = MAX(textTotalSize.width + (2 - sqrt(2)) * self.radius, 2 * self.radius);
    textTotalSize.height = 2 * self.radius;
    self.frame = CGRectMake(self.center.x - textTotalSize.width/2, self.center.y - self.radius, textTotalSize.width, 2 * self.radius);
}

#pragma mark - Drag effection

- (void)panGestureRecognizerTriggerd:(UIPanGestureRecognizer *)pan
{
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_displayLink invalidate];
            _displayLink = nil;
            
            if (_placeholderView == nil) {
                _placeholderView = [[UIView alloc]initWithFrame:self.frame];
                _placeholderView.backgroundColor = [UIColor clearColor];
                _placeholderView.layer.masksToBounds = YES;
                [self.superview insertSubview:_placeholderView belowSubview:self];
            }
            
            _placeholderView.backgroundColor = self.backgroundColor;
            _placeholderView.frame = CGRectMake(self.center.x - self.radius, self.center.y - self.radius, 2 * self.radius, 2 * self.radius);
            _placeholderView.layer.cornerRadius = self.radius;
            
            if (_dragTrackShapeLayer == nil) {
                _dragTrackShapeLayer = [[CAShapeLayer alloc]init];
            }
            _dragTrackShapeLayer.strokeColor = self.backgroundColor.CGColor;
            _dragTrackShapeLayer.fillColor = self.backgroundColor.CGColor;
            _dragTrackShapeLayer.lineWidth = 1;
            _dragTrackShapeLayer.lineCap = kCALineCapRound;
            [self.superview.layer insertSublayer:_dragTrackShapeLayer below:self.layer];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            self.center = [pan locationInView:self.superview];
            [self drawDragTrack];
        }
            break;
        default:
        {
            CGPoint panLocation = [pan locationInView:self.superview];
            CGFloat dragDistance = [self distanceBetweenPoint1:_placeholderView.center andPoint2:panLocation];
         
            if (self.endDraggingAction) {
                self.endDraggingAction(panLocation, dragDistance);
            }
            
            if (dragDistance > self.maxStretchDistance && self.dismissAction) {
                self.dismissAction(panLocation, dragDistance);
                [_placeholderView removeFromSuperview];
                _placeholderView = nil;
                [_dragTrackShapeLayer removeFromSuperlayer];
                _dragTrackShapeLayer = nil;
                [self removeFromSuperview];
            }
            else {
                _endDraggingTimestamp = [[NSDate date]timeIntervalSince1970];
                
                _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkEvent:)];
                [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            }
        }
            break;
    }
}

- (void)displayLinkEvent:(CADisplayLink *)displayLink
{
    NSTimeInterval timeIntervalSinceEndDragging = [[NSDate date]timeIntervalSince1970] - _endDraggingTimestamp;
    
    CGFloat decayFactor = pow(M_E, -DAMP_FACTOR * timeIntervalSinceEndDragging);
    if (decayFactor < 0.01) {
        self.center = _placeholderView.center;
        [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_displayLink invalidate];
        _displayLink = nil;
        [_placeholderView removeFromSuperview];
        _placeholderView = nil;
        [_dragTrackShapeLayer removeFromSuperlayer];
        _dragTrackShapeLayer = nil;
        if (self.positionRecoveredAction) {
            self.positionRecoveredAction();
        }
        return;
    }
    
    CGFloat remainVectorDx = self.center.x - _placeholderView.center.x;
    CGFloat remainVectorDy = self.center.y - _placeholderView.center.y;
    remainVectorDx = remainVectorDx * decayFactor * cos(VIBRATE_ANGLE_FREQUENCY * timeIntervalSinceEndDragging);
    remainVectorDy = remainVectorDy * decayFactor * cos(VIBRATE_ANGLE_FREQUENCY * timeIntervalSinceEndDragging);
    
    self.center = CGPointMake(_placeholderView.center.x + remainVectorDx, _placeholderView.center.y + remainVectorDy);
    
    [self drawDragTrack];
}

- (void)drawDragTrack
{
    CGFloat dragDistance = [self distanceBetweenPoint1:_placeholderView.center andPoint2:self.center];
    
    if (dragDistance > self.maxStretchDistance && self.dismissAction) {
        _placeholderView.hidden = YES;
        _dragTrackShapeLayer.path = nil;
        return;
    }
    _placeholderView.hidden = NO;
    
    CGFloat newPlaceholderViewRadius = [self placeHolderCircleRadiusAccordingDragDistance:dragDistance];
    _placeholderView.layer.cornerRadius = newPlaceholderViewRadius;
    _placeholderView.frame = CGRectMake(_placeholderView.center.x - newPlaceholderViewRadius, _placeholderView.center.y - newPlaceholderViewRadius, 2 * newPlaceholderViewRadius, 2 * newPlaceholderViewRadius);
    
    CGPoint controlPoint = [self centerPointOfPoint1:_placeholderView.center andPoint2:self.center];
    
    CGPoint startPoint1 = [self postiveCutPointOnCircleCenter:_placeholderView.center radius:newPlaceholderViewRadius - 0.5 outerPoint:controlPoint];
    CGPoint startPoint2 = [self negativeCutPointOnCircleCenter:_placeholderView.center radius:newPlaceholderViewRadius - 0.5 outerPoint:controlPoint];
    CGPoint endPoint1 = [self postiveCutPointOnCircleCenter:self.center radius:newPlaceholderViewRadius outerPoint:controlPoint];
    CGPoint endPoint2 = [self negativeCutPointOnCircleCenter:self.center radius:newPlaceholderViewRadius outerPoint:controlPoint];
    
    CGPoint bezier1StartPoint = CGPointZero;
    CGPoint bezier2StartPoint = CGPointZero;
    CGPoint bezier1EndPoint = CGPointZero;
    CGPoint bezier2EndPoint = CGPointZero;
    
    if (self.center.x >= _placeholderView.center.x) {
        bezier1StartPoint = startPoint1;
        bezier1EndPoint = endPoint1;
        bezier2StartPoint = startPoint2;
        bezier2EndPoint = endPoint2;
    }
    else {
        bezier1StartPoint = startPoint2;
        bezier1EndPoint = endPoint2;
        bezier2StartPoint = startPoint1;
        bezier2EndPoint = endPoint1;
    }

    UIBezierPath * path = [UIBezierPath bezierPath];
    [path moveToPoint:bezier1StartPoint];
    [path addQuadCurveToPoint:bezier1EndPoint controlPoint:controlPoint];
    [path addLineToPoint:bezier2EndPoint];
    [path addQuadCurveToPoint:bezier2StartPoint controlPoint:controlPoint];
    [path addLineToPoint:bezier1StartPoint];
    
    _dragTrackShapeLayer.path = nil;
    _dragTrackShapeLayer.path = path.CGPath;
}

- (CGPoint)postiveCutPointOnCircleCenter:(CGPoint)circleCenter radius:(CGFloat)circleRadius outerPoint:(CGPoint)outerPoint
{
    NSAssert(circleRadius >= 0, @"Parameter circleRadius must be greater than or equal to 0.");  //
    
    CGPoint postiveCutPoint = CGPointZero;
    
    CGFloat distance = [self distanceBetweenPoint1:circleCenter andPoint2:outerPoint];
    CGFloat lineThroughCircleCenterAndOuterPointObliqueAngle = [self obliqueAngleOfLineWhichThroughPoint1:circleCenter andPoint2:outerPoint];
    
    if (distance <= circleRadius) {
        if (lineThroughCircleCenterAndOuterPointObliqueAngle == M_PI/2) {
            postiveCutPoint = CGPointMake(circleCenter.x - circleRadius, circleCenter.y);
        }
        else {
            postiveCutPoint = CGPointMake(circleCenter.x + circleRadius * cos(lineThroughCircleCenterAndOuterPointObliqueAngle - M_PI/2), circleCenter.y + circleRadius * sin(lineThroughCircleCenterAndOuterPointObliqueAngle - M_PI/2));
        }
        return outerPoint;
    }
    else {
        CGFloat cutAngle = asin(circleRadius/distance);
        postiveCutPoint = CGPointMake(circleCenter.x + circleRadius * cos(lineThroughCircleCenterAndOuterPointObliqueAngle + cutAngle - M_PI/2), circleCenter.y + circleRadius * sin(lineThroughCircleCenterAndOuterPointObliqueAngle + cutAngle - M_PI/2));
    }
    
    return postiveCutPoint;
}

- (CGPoint)negativeCutPointOnCircleCenter:(CGPoint)circleCenter radius:(CGFloat)circleRadius outerPoint:(CGPoint)outerPoint
{
    NSAssert(circleRadius >= 0, @"Parameter circleRadius must be greater than or equal to 0.");  //
    
    CGPoint negativeCutPoint = CGPointZero;
    
    CGFloat distance = [self distanceBetweenPoint1:circleCenter andPoint2:outerPoint];
    CGFloat lineThroughCircleCenterAndOuterPointObliqueAngle = [self obliqueAngleOfLineWhichThroughPoint1:circleCenter andPoint2:outerPoint];
    
    if (distance <= circleRadius) {
        if (lineThroughCircleCenterAndOuterPointObliqueAngle == M_PI/2) {
            negativeCutPoint = CGPointMake(circleCenter.x + circleRadius, circleCenter.y);
        }
        else {
            negativeCutPoint = CGPointMake(circleCenter.x + circleRadius * cos(lineThroughCircleCenterAndOuterPointObliqueAngle + M_PI/2), circleCenter.y + circleRadius * sin(lineThroughCircleCenterAndOuterPointObliqueAngle + M_PI/2));
        }
    }
    else {
        CGFloat cutAngle = asin(circleRadius/distance);
        negativeCutPoint = CGPointMake(circleCenter.x + circleRadius * cos(lineThroughCircleCenterAndOuterPointObliqueAngle - cutAngle + M_PI/2), circleCenter.y + circleRadius * sin(lineThroughCircleCenterAndOuterPointObliqueAngle - cutAngle + M_PI/2));
    }
    
    return negativeCutPoint;
}

- (CGPoint)centerPointOfPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    return CGPointMake((point1.x + point2.x)/2, (point1.y + point2.y)/2);
}

- (CGFloat)distanceBetweenPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    return sqrt((point2.x - point1.x) * (point2.x - point1.x) + (point2.y - point1.y) * (point2.y - point1.y));
}

- (CGFloat)slopeOfLineWhichThroughPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    if (point1.x == point2.x) {
        return -CGFLOAT_MAX;
    }
    else {
        return (point2.y - point1.y)/(point2.x - point1.x);
    }
}

- (CGFloat)obliqueAngleOfLineWhichThroughPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2
{    
    if (point1.x == point2.x) {
        if (point2.y >= point1.y) {
            return M_PI / 2;
        }
        else {
            return M_PI * 3 / 2;
        }
    }
    else {
        return atan([self slopeOfLineWhichThroughPoint1:point1 andPoint2:point2]);
    }
}

- (CGFloat)placeHolderCircleRadiusAccordingDragDistance:(CGFloat)dragDistance
{
    return self.radius * pow(M_E, -DECREASE_FACTOR * dragDistance);
}

@end
