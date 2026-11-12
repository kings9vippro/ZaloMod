#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <QuartzCore/QuartzCore.h>
#import "../Core/PHKCore.hpp"

// Local-only appearance for recognized Zalo chat composer containers.
// Recognition is version gated and must be verified on an actual device.
extern "C" void PHKIndependentShowMenu(void);
extern "C" NSString *PHKIndependentRunLocalCommand(
    NSString *command, UIImage *repliedImage, NSData **outSticker);
static BOOL PHKSupportedInput(UIView *view) {
    if(![NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"] isEqual:@"260901802"] ||
       !view.window || !view.isFirstResponder)return NO;
    if([view isKindOfClass:UITextView.class]){
        UITextView *v=(UITextView *)view;
        if(!v.editable || v.secureTextEntry || v.markedTextRange)return NO;
    } else if([view isKindOfClass:UITextField.class]){
        UITextField *v=(UITextField *)view;
        if(!v.enabled || v.secureTextEntry || v.markedTextRange)return NO;
    } else return NO;
    NSArray<NSString *> *containers=@[@"KBChatInputComponentView",@"ZAInputView",
        @"ZACustomInputView",@"ZinstantInputView"];
    for(UIView *node=view;node;node=node.superview){
        NSString *name=NSStringFromClass(node.class);
        for(NSString *candidate in containers)
            if([name isEqualToString:candidate] || [name hasSuffix:[@"." stringByAppendingString:candidate]])return YES;
    }
    return NO;
}
@interface PHKInputAppearance : NSObject
@property(nonatomic,weak) UIView *activeInput;
@property(nonatomic,weak) UIView *lastCommandInput;
@property(nonatomic) BOOL commandShown;
@property(nonatomic) BOOL applying;
@end
@implementation PHKInputAppearance
- (void)changed:(NSNotification *)notification {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self changed:notification];});return;}
    if(self.applying)return;
    id object=notification.object;
    UIView *input=([object isKindOfClass:UITextView.class] || [object isKindOfClass:UITextField.class])?object:self.activeInput;
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
    self.applying=YES;
    NSString *text=nil;
    if([input isKindOfClass:UITextView.class]){
        UITextView *v=(UITextView *)input;
        if(![v.textColor isEqual:color])v.textColor=color;
        if(![v.font isEqual:font])v.font=font;
        NSMutableDictionary *attributes=[v.typingAttributes mutableCopy]?:[NSMutableDictionary new];
        attributes[NSFontAttributeName]=font;attributes[NSForegroundColorAttributeName]=color;
        v.typingAttributes=attributes;
        text=v.text;
    } else {
        UITextField *v=(UITextField *)input;
        if(![v.textColor isEqual:color])v.textColor=color;
        if(![v.font isEqual:font])v.font=font;
        text=v.text;
    }
    input.tintColor=color;
    self.applying=NO;
    if(self.lastCommandInput!=input){self.lastCommandInput=input;self.commandShown=NO;}
    // Only exact, known local commands are intercepted. Never intercept
    // sticker replies or ordinary messages; those require a real host API.
    NSString *trimmed=[text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    const char *bytes=trimmed.UTF8String;
    const auto parsed=bytes?phk::parseCommandDetailed(bytes,false):
        phk::ParsedCommand{phk::Command::none,0};
    BOOL validLocal=(parsed.kind==phk::Command::menu ||
                     parsed.kind==phk::Command::colorRandom ||
                     parsed.kind==phk::Command::colorIndex ||
                     parsed.kind==phk::Command::fontSize ||
                     parsed.kind==phk::Command::setDelay);
    if(!validLocal){self.commandShown=NO;return;}
    if(self.commandShown)return;
    self.commandShown=YES;
    // Cancel the literal command before it could be accidentally sent
    // as a Zalo chat message. Re-entrant editor notifications are ignored.
    self.applying=YES;
    if([input isKindOfClass:[UITextView class]]){
        UITextView *editor=(UITextView *)input;
        if(editor.markedTextRange==nil){
            editor.text=@"";
            [NSNotificationCenter.defaultCenter postNotificationName:
                UITextViewTextDidChangeNotification object:editor];
        }
    } else if([input isKindOfClass:[UITextField class]]){
        UITextField *editor=(UITextField *)input;
        if(editor.markedTextRange==nil){
            editor.text=@"";
            [editor sendActionsForControlEvents:UIControlEventEditingChanged];
        }
    }
    self.applying=NO;
    NSString *message=PHKIndependentRunLocalCommand(trimmed,nil,NULL);
    if(message.length)UIAccessibilityPostNotification(
        UIAccessibilityAnnouncementNotification,message);
    // Re-evaluate the active editor immediately after a font/color command.
    if(parsed.kind==phk::Command::colorIndex ||
       parsed.kind==phk::Command::colorRandom ||
       parsed.kind==phk::Command::fontSize)
        dispatch_async(dispatch_get_main_queue(),^{
            [self changed:[NSNotification notificationWithName:
                NSUserDefaultsDidChangeNotification object:input]];
        });
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
        for(NSString *name in @[UITextViewTextDidBeginEditingNotification,UITextViewTextDidChangeNotification,UITextFieldTextDidBeginEditingNotification,UITextFieldTextDidChangeNotification,NSUserDefaultsDidChangeNotification])
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

