#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "PHKOverlayController.h"
#import "PHKLegacyAdapter.h"

@interface PHKMenuCoordinator : NSObject
@property(nonatomic,strong) UIWindow *overlayWindow;
@property(nonatomic,weak) UIWindow *previousKeyWindow;
+ (instancetype)shared;
- (void)install;
- (void)open;
- (void)close;
@end

@interface PHKFourFingerRecognizer : UITapGestureRecognizer
@end
@implementation PHKFourFingerRecognizer
@end

static void PHKNoFloatingShow(id self,SEL command){(void)self;(void)command;}
static UIViewController *PHKTopController(UIViewController *base){
    UIViewController *top=base;
    while(top.presentedViewController)top=top.presentedViewController;
    if([top isKindOfClass:[UINavigationController class]]){
        UINavigationController *nav=(UINavigationController *)top;
        if(nav.visibleViewController)top=nav.visibleViewController;
    }
    return top;
}

@implementation PHKMenuCoordinator
+ (instancetype)shared {
    static PHKMenuCoordinator *obj;static dispatch_once_t once;
    dispatch_once(&once,^{obj=[PHKMenuCoordinator new];});return obj;
}
- (void)install {
    NSAssert([NSThread isMainThread],@"Must install gestures on main thread");
    if(@available(iOS 13.0,*)){
        for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
            if(![scene isKindOfClass:[UIWindowScene class]])continue;
            for(UIWindow *w in ((UIWindowScene *)scene).windows)[self attachToWindow:w];
        }
    }else{
        for(UIWindow *w in UIApplication.sharedApplication.windows)[self attachToWindow:w];
    }
    [PHKLegacyAdapter.shared hideFloatingButtonIfPresent];
    // Stop the legacy orb being recreated. Does not interfere with original menu actions.
    static BOOL replaced=NO;
    if(!replaced){
        Class c=NSClassFromString(@"ZaloFloatingButton");Method m=class_getInstanceMethod(c,NSSelectorFromString(@"show"));
        if(m){method_setImplementation(m,(IMP)PHKNoFloatingShow);replaced=YES;}
    }
}
- (void)attachToWindow:(UIWindow *)window {
    if(!window||window==self.overlayWindow||window.hidden||window.windowLevel!=UIWindowLevelNormal)return;
    for(UIGestureRecognizer *g in window.gestureRecognizers){if([g isKindOfClass:[PHKFourFingerRecognizer class]])return;}
    PHKFourFingerRecognizer *tap=[[PHKFourFingerRecognizer alloc]initWithTarget:self action:@selector(fourFingerTapped:)];
    tap.numberOfTouchesRequired=4;tap.numberOfTapsRequired=1;
    tap.cancelsTouchesInView=NO;tap.delaysTouchesBegan=NO;tap.delaysTouchesEnded=NO;
    [window addGestureRecognizer:tap];
}
- (void)fourFingerTapped:(UIGestureRecognizer *)gesture {
    if(gesture.state==UIGestureRecognizerStateRecognized)[self open];
}
- (UIWindow *)appWindow {
    if(@available(iOS 13.0,*)){
        for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
            if(![scene isKindOfClass:[UIWindowScene class]]||scene.activationState!=UISceneActivationStateForegroundActive)continue;
            for(UIWindow *w in ((UIWindowScene *)scene).windows)if(w.isKeyWindow && w!=self.overlayWindow)return w;
            for(UIWindow *w in ((UIWindowScene *)scene).windows)if(!w.hidden && w.windowLevel==UIWindowLevelNormal && w!=self.overlayWindow)return w;
        }
    }
    return UIApplication.sharedApplication.keyWindow;
}
- (void)open {
    if(self.overlayWindow || ![NSThread isMainThread])return;
    UIWindow *underlying=[self appWindow];
    if(!underlying)return;
    self.previousKeyWindow=underlying;
    UIWindow *overlay=nil;
    if(@available(iOS 13.0,*)){
        if(underlying.windowScene)overlay=[[UIWindow alloc]initWithWindowScene:underlying.windowScene];
    }
    if(!overlay)overlay=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];
    overlay.windowLevel=UIWindowLevelAlert-2;
    __weak typeof(self) weakSelf=self;
    PHKOverlayController *panel=[[PHKOverlayController alloc]initWithCloseHandler:^{[weakSelf close];}];
    panel.legacyPresenter=PHKTopController(underlying.rootViewController);
    overlay.rootViewController=panel;
    self.overlayWindow=overlay;
    [overlay makeKeyAndVisible];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,panel.view);
}
- (void)close {
    if(!self.overlayWindow)return;
    self.overlayWindow.hidden=YES;
    self.overlayWindow.rootViewController=nil;
    self.overlayWindow=nil;
    [self.previousKeyWindow makeKeyWindow];
    self.previousKeyWindow=nil;
}
@end

__attribute__((constructor)) static void PHKLoadOverlay(void){
    // No UIKit work before UIApplication is ready.
    dispatch_async(dispatch_get_main_queue(), ^{
        PHKMenuCoordinator *c=[PHKMenuCoordinator shared];
        NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
        for(NSString *event in @[UIApplicationDidBecomeActiveNotification,UIWindowDidBecomeVisibleNotification]){
            [center addObserverForName:event object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *n){
                (void)n;[c install];
            }];
        }
        [c install];
    });
}
