#import <UIKit/UIKit.h>
@interface PHKOverlayController : UIViewController
@property(nonatomic,weak) UIViewController *legacyPresenter;
- (instancetype)initWithCloseHandler:(dispatch_block_t)closeHandler;
@end
