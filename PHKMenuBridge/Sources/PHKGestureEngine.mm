#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "PHKLegacyAdapter.h"
#import "../Core/PHKTouchTracker.hpp"
// Independent event-level fallback. System touch events pass through unchanged.
@interface PHKGestureEngine : NSObject
+ (instancetype)shared;
- (void)install;
- (void)consumeEvent:(UIEvent *)event;
@end
static void (*PHKOriginalSendEvent)(id,SEL,UIEvent*)=nullptr;
static BOOL PHKHookInstalled=NO,PHKBadgeDisplayed=NO,PHKOrbDisabled=NO;
static CFTimeInterval PHKLastOrbCheck=0;
static void PHKSuppressShow(id obj,SEL sel){(void)obj;(void)sel;}
static void PHKInterceptSendEvent(id object,SEL command,UIEvent *event){
    if(PHKOriginalSendEvent)PHKOriginalSendEvent(object,command,event);
    if(event && [NSThread isMainThread] && event.type==UIEventTypeTouches)
        [[PHKGestureEngine shared] consumeEvent:event];
}
@implementation PHKGestureEngine {
    phk::FourFingerTap _state;
    BOOL _openScheduled;
}
+ (instancetype)shared {
    static PHKGestureEngine *instance;
    static dispatch_once_t once;
    dispatch_once(&once,^{instance=[PHKGestureEngine new];});return instance;
}
- (void)suppressOldOrb {
    Class klass=NSClassFromString(@"ZaloFloatingButton");
    if(!klass)return;
    [PHKLegacyAdapter.shared hideFloatingButtonIfPresent];
    if(PHKOrbDisabled)return;
    Method method=class_getInstanceMethod(klass,NSSelectorFromString(@"show"));
    if(!method || method_getNumberOfArguments(method)!=2)return;
    char result[8]={0};method_getReturnType(method,result,sizeof(result));
    if(result[0]!='v')return;
    method_setImplementation(method,(IMP)PHKSuppressShow);PHKOrbDisabled=YES;
}
- (UIWindow *)foregroundWindow {
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:[UIWindowScene class]] || scene.activationState!=UISceneActivationStateForegroundActive)continue;
        for(UIWindow *w in ((UIWindowScene*)scene).windows)
            if(w.isKeyWindow && !w.hidden && w.windowLevel==UIWindowLevelNormal)return w;
        for(UIWindow *w in ((UIWindowScene*)scene).windows)
            if(!w.hidden && w.windowLevel==UIWindowLevelNormal)return w;
    }
    return nil;
}
- (void)briefLoadIndicator {
    if(PHKBadgeDisplayed || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive)return;
    UIWindow *window=[self foregroundWindow];if(!window)return;
    PHKBadgeDisplayed=YES;
    UILabel *badge=[UILabel new];badge.text=@"PHK MENU 3.0  ·  CHẠM 4 NGÓN";
    badge.textAlignment=NSTextAlignmentCenter;
    badge.font=[UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    badge.textColor=UIColor.whiteColor;
    badge.backgroundColor=[UIColor colorWithRed:.08 green:.13 blue:.23 alpha:.94];
    badge.layer.cornerRadius=15;badge.clipsToBounds=YES;badge.layer.borderWidth=.6;
    badge.layer.borderColor=[UIColor colorWithRed:.36 green:.82 blue:1 alpha:.7].CGColor;
    badge.alpha=0;badge.userInteractionEnabled=NO;badge.translatesAutoresizingMaskIntoConstraints=NO;
    [window addSubview:badge];
    [NSLayoutConstraint activateConstraints:@[
        [badge.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
        [badge.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:12],
        [badge.widthAnchor constraintEqualToConstant:255],
        [badge.heightAnchor constraintEqualToConstant:31]
    ]];
    [UIView animateWithDuration:.18 animations:^{badge.alpha=1;} completion:^(BOOL finished){
        (void)finished;
        [UIView animateWithDuration:.28 delay:2.0 options:0 animations:^{badge.alpha=0;}
            completion:^(BOOL done){(void)done;[badge removeFromSuperview];}];
    }];
}
- (void)install {
    if(![NSThread isMainThread]){dispatch_async(dispatch_get_main_queue(),^{[self install];});return;}
    if(!PHKHookInstalled){
        Method method=class_getInstanceMethod([UIApplication class],@selector(sendEvent:));
        char type[8]={0};if(method)method_getReturnType(method,type,sizeof(type));
        if(method && method_getNumberOfArguments(method)==3 && type[0]=='v'){
            IMP previous=method_setImplementation(method,(IMP)PHKInterceptSendEvent);
            if(previous && previous!=(IMP)PHKInterceptSendEvent){
                PHKOriginalSendEvent=(void (*)(id,SEL,UIEvent*))previous;
                PHKHookInstalled=YES;
            }
        }
    }
    [self suppressOldOrb];[self briefLoadIndicator];
}
- (void)consumeEvent:(UIEvent *)event {
    for(UITouch *touch in event.allTouches){
        UIWindow *window=touch.window;
        if(!window || window.windowLevel!=UIWindowLevelNormal)continue;
        phk::TouchPhase phase;
        switch(touch.phase){
            case UITouchPhaseBegan:phase=phk::TouchPhase::began;break;
            case UITouchPhaseMoved:phase=phk::TouchPhase::moved;break;
            case UITouchPhaseEnded:phase=phk::TouchPhase::ended;break;
            case UITouchPhaseCancelled:phase=phk::TouchPhase::cancelled;break;
            default:continue;
        }
        CGPoint p=[touch locationInView:window];
        std::uintptr_t identifier=(std::uintptr_t)(__bridge void*)touch;
        if(_state.feed(identifier,phase,touch.timestamp,p.x,p.y) && !_openScheduled){
            _openScheduled=YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_openScheduled=NO;
                Class coordinatorClass=NSClassFromString(@"PHKMenuCoordinator");
                SEL shared=NSSelectorFromString(@"shared");
                if(coordinatorClass && [coordinatorClass respondsToSelector:shared]){
                    id coordinator=((id(*)(id,SEL))objc_msgSend)(coordinatorClass,shared);
                    SEL open=NSSelectorFromString(@"open");
                    if(coordinator && [coordinator respondsToSelector:open])
                        ((void(*)(id,SEL))objc_msgSend)(coordinator,open);
                }
            });
        }
    }
    CFTimeInterval now=CACurrentMediaTime();
    if(!PHKOrbDisabled && now-PHKLastOrbCheck>=2.0){
        PHKLastOrbCheck=now;[self suppressOldOrb];
    }
}
@end
__attribute__((constructor)) static void PHKGestureEngineLoaded(void){
    NSLog(@"[PHKMenuBridge 3.0] Gesture engine loaded");
    dispatch_async(dispatch_get_main_queue(), ^{
        PHKGestureEngine *engine=[PHKGestureEngine shared];
        for(NSString *event in @[UIApplicationDidBecomeActiveNotification,UIWindowDidBecomeVisibleNotification]){
            [NSNotificationCenter.defaultCenter addObserverForName:event object:nil queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note){(void)note;[engine install];}];
        }
        [engine install];
        for(int i=1;i<=4;i++)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(i*1.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[engine install];});
    });
}
