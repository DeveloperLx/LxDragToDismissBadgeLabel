//
//  DeveloperLx
//  LxDragToDismissBadgeLabel.h
//

#import <UIKit/UIKit.h>
#define LX_UNAVAILABLE(msg) __attribute__((unavailable(msg)))   // forbidden use and report error.

@interface LxDragToDismissBadgeLabel : UILabel

- (instancetype)initWithCenter:(CGPoint)center radius:(CGFloat)radius;
@property (nonatomic,assign) CGPoint center;
@property (nonatomic,assign) CGFloat radius;
@property (nonatomic,assign) CGFloat maxStretchDistance;    //  default is 100.
@property (nonatomic,copy) void (^endDraggingAction)(CGPoint dragLocation, CGFloat dragDistance);
@property (nonatomic,copy) void (^dismissAction)(CGPoint dragLocation, CGFloat dragDistance);
@property (nonatomic,copy) void (^positionRecoveredAction)(void);

#pragma mark - Unavailable

- (instancetype)init LX_UNAVAILABLE("LxDragToDismissBadgeLabel must be initialized by initWithCenter:radius:");
- (instancetype)initWithFrame:(CGRect)frame LX_UNAVAILABLE("LxDragToDismissBadgeLabel must be initialized by initWithCenter:radius:");
- (instancetype)initWithCoder:(NSCoder *)aDecoder LX_UNAVAILABLE("LxDragToDismissBadgeLabel must be initialized by initWithCenter:radius:");

@property(nonatomic) NSInteger numberOfLines LX_UNAVAILABLE("LxDragToDismissBadgeLabel cannot change this property!");
@property(nonatomic) NSTextAlignment textAlignment LX_UNAVAILABLE("LxDragToDismissBadgeLabel cannot change this property!");

@end
