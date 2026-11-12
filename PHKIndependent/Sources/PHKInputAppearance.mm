#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <QuartzCore/QuartzCore.h>
#import "../Core/PHKCore.hpp"

// Only style editable UIKit text within input containers found in build 260901802.
// No executable offsets, message interception, or transport-format claims.
static BOOL PHKSupportedInput(UITextView *view) {
    if(![NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"] isEqual:@"260901802"] ||
       !view.editable || !view.window || view.markedTextRange)return NO;
    for(UIView *node=view;node;node=node.superview){
        NSString *name=NSStringFromClass(node.class);
        if([@[@"KBChatInputComponentView",@"ZAInputView",@"ZACustomInputView"] containsObject:name])return YES;
    }
    return NO;
}
@interface PHKInputAppearance : NSObject
@property(nonatomic,weak) UITextView *activeInput;
@end
@implementation PHKInputAppearance
- (void)changed:(NSNotification *)notification {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self changed:notification];});return;}
    UITextView *input=[notification.object isKindOfClass:UITextView.class]?notification.object:self.activeInput;
    if(!input || !PHKSupportedInput(input))return;
    self.activeInput=input;
    NSUserDefaults *settings=NSUserDefaults.standardUserDefaults;
    NSInteger points=[settings integerForKey:@"dev.phananhkhoi.independent.fontSize"];
    if(points<10 || points>18)points=16;
    auto rgb=phk::paletteAt(MAX(0,[settings integerForKey:@"dev.phananhkhoi.independent.accent"]));
    UIColor *color=[UIColor colorWithRed:rgb.r/255.0 green:rgb.g/255.0 blue:rgb.b/255.0 alpha:1];
    UIFont *font=[UIFont systemFontOfSize:points];
    NSInteger style=[settings integerForKey:@"dev.phananhkhoi.independent.fontStyle"];
    if(style==1 || style==2){
        UIFontDescriptor *descriptor=[font.fontDescriptor fontDescriptorWithDesign:
            style==1?UIFontDescriptorSystemDesignRounded:UIFontDescriptorSystemDesignSerif];
        if(descriptor)font=[UIFont fontWithDescriptor:descriptor size:points];
    }
    // typingAttributes preserves existing rich content and avoids rewriting IME text.
    NSMutableDictionary *attributes=[input.typingAttributes mutableCopy]?:[NSMutableDictionary new];
    attributes[NSFontAttributeName]=font;attributes[NSForegroundColorAttributeName]=color;
    input.typingAttributes=attributes;
    input.tintColor=color;
}
@end

// A passive recognizer draws feedback and fails immediately; never consumes touches.
@interface PHKTouchFeedback : UIGestureRecognizer
@end
@implementation PHKTouchFeedback
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if(!UIAccessibilityIsReduceMotionEnabled() && !NSProcessInfo.processInfo.lowPowerModeEnabled){
        UIView *host=self.view;
        if(host.layer.sublayers.count<100){
            CGPoint p=[touches.anyObject locationInView:host];
            CAShapeLayer *ring=[CAShapeLayer layer];
            ring.path=[UIBezierPath bezierPathWithOvalInRect:CGRectMake(-12,-12,24,24)].CGPath;
            ring.position=p;ring.fillColor=UIColor.clearColor.CGColor;
            ring.strokeColor=[UIColor.systemTealColor colorWithAlphaComponent:.55].CGColor;ring.lineWidth=1.5;
            [host.layer addSublayer:ring];
            CABasicAnimation *fade=[CABasicAnimation animationWithKeyPath:@"opacity"];
            fade.fromValue=@.7;fade.toValue=@0;
            CABasicAnimation *scale=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
            scale.fromValue=@.4;scale.toValue=@1.8;
            CAAnimationGroup *group=[CAAnimationGroup animation];group.animations=@[fade,scale];group.duration=.32;
            ring.opacity=0;[ring addAnimation:group forKey:@"touch"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,400*NSEC_PER_MSEC),dispatch_get_main_queue(),^{[ring removeFromSuperlayer];});
        }
    }
    self.state=UIGestureRecognizerStateFailed;
}
@end

__attribute__((constructor)) static void PHKInstallInputAppearance(void){
    dispatch_async(dispatch_get_main_queue(),^{
        static PHKInputAppearance *appearance=[PHKInputAppearance new];
        NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
        for(NSString *name in @[UITextViewTextDidBeginEditingNotification,UITextViewTextDidChangeNotification,NSUserDefaultsDidChangeNotification])
            [center addObserver:appearance selector:@selector(changed:) name:name object:nil];
        [center addObserverForName:UIWindowDidBecomeKeyNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note){
            UIWindow *window=note.object;
            if(![window isKindOfClass:UIWindow.class] || window.windowLevel!=UIWindowLevelNormal)return;
            for(UIGestureRecognizer *gesture in window.gestureRecognizers)if([gesture isKindOfClass:PHKTouchFeedback.class])return;
            PHKTouchFeedback *feedback=[PHKTouchFeedback new];feedback.cancelsTouchesInView=NO;
            feedback.delaysTouchesBegan=NO;feedback.delaysTouchesEnded=NO;
            [window addGestureRecognizer:feedback];
        }];
    });
}
