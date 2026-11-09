#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach-o/getsect.h>
#import <mach-o/ldsyms.h>
#import "../Core/Preferences.hpp"

// PHK Standalone Kit: independent iOS UI; does not hook or imitate private Zalo features.
// If this dylib is linked by an authorized iOS host, its native panel can run with no other tweak.
static NSString * const PHKPrefix=@"dev.phananhkhoi.standalone.";
static UIColor *PHKColor(CGFloat red,CGFloat green,CGFloat blue) {
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}
static UIColor *PHKAccent(void){return PHKColor(.39,.86,.99);}
static UIColor *PHKGraphite(void){return PHKColor(.065,.085,.13);}
static UIImage *PHKEmbeddedImage(const char *section) {
    unsigned long size=0;
    const uint8_t *bytes=getsectiondata(&_mh_dylib_header,"__DATA",section,&size);
    if(!bytes || size<8)return nil;
    return [UIImage imageWithData:[NSData dataWithBytesNoCopy:(void *)bytes length:size freeWhenDone:NO]];
}
static BOOL PHKReadSetting(NSString *name,BOOL fallback) {
    NSUserDefaults *store=NSUserDefaults.standardUserDefaults;
    NSString *key=[PHKPrefix stringByAppendingString:name];
    return [store objectForKey:key] ? [store boolForKey:key] : fallback;
}
static void PHKWriteSetting(NSString *name,BOOL value) {
    [NSUserDefaults.standardUserDefaults setBool:value forKey:[PHKPrefix stringByAppendingString:name]];
}
@interface PHKStandalonePanel : UIViewController
@property(nonatomic,copy) dispatch_block_t onClose;
@end
@implementation PHKStandalonePanel {
    UIScrollView *_scroll;
    UIStackView *_cards;
    UILabel *_modeLabel;
}
- (UILabel *)label:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label=[UILabel new];label.text=text;label.font=[UIFont systemFontOfSize:size weight:weight];
    label.textColor=color;label.numberOfLines=0;return label;
}
- (void)addCard:(UIView *)view height:(CGFloat)height {
    view.backgroundColor=[UIColor colorWithWhite:1 alpha:.075];
    view.layer.cornerRadius=16;
    view.layer.borderWidth=.6;view.layer.borderColor=[UIColor colorWithWhite:1 alpha:.10].CGColor;
    [view.heightAnchor constraintGreaterThanOrEqualToConstant:height].active=YES;
    [_cards addArrangedSubview:view];
}
- (void)loadView {
    UIView *root=[UIView new];root.backgroundColor=[UIColor colorWithRed:.015 green:.027 blue:.05 alpha:.72];self.view=root;
    UIView *sheet=[UIView new];sheet.backgroundColor=PHKGraphite();sheet.layer.cornerRadius=26;
    sheet.layer.masksToBounds=YES;sheet.translatesAutoresizingMaskIntoConstraints=NO;[root addSubview:sheet];
    NSLayoutConstraint *idealWidth=[sheet.widthAnchor constraintEqualToAnchor:root.widthAnchor constant:-24];
    idealWidth.priority=UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        idealWidth,
        [sheet.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
        [sheet.centerYAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.centerYAnchor],
        [sheet.leadingAnchor constraintGreaterThanOrEqualToAnchor:root.leadingAnchor constant:12],
        [sheet.trailingAnchor constraintLessThanOrEqualToAnchor:root.trailingAnchor constant:-12],
        [sheet.widthAnchor constraintLessThanOrEqualToConstant:460],
        [sheet.heightAnchor constraintLessThanOrEqualToAnchor:root.safeAreaLayoutGuide.heightAnchor multiplier:.91],
        [sheet.heightAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.heightAnchor multiplier:.81]
    ]];
    UIImage *wall=PHKEmbeddedImage("__phkwall");
    if(wall){
        UIImageView *background=[[UIImageView alloc]initWithImage:wall];background.contentMode=UIViewContentModeScaleAspectFill;
        background.clipsToBounds=YES;background.translatesAutoresizingMaskIntoConstraints=NO;[sheet addSubview:background];
        [NSLayoutConstraint activateConstraints:@[
            [background.topAnchor constraintEqualToAnchor:sheet.topAnchor],
            [background.bottomAnchor constraintEqualToAnchor:sheet.bottomAnchor],
            [background.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor],
            [background.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor]
        ]];
        UIView *veil=[UIView new];veil.backgroundColor=[UIColor colorWithRed:.02 green:.035 blue:.066 alpha:.82];
        veil.translatesAutoresizingMaskIntoConstraints=NO;[sheet addSubview:veil];
        [NSLayoutConstraint activateConstraints:@[
            [veil.topAnchor constraintEqualToAnchor:sheet.topAnchor],
            [veil.bottomAnchor constraintEqualToAnchor:sheet.bottomAnchor],
            [veil.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor],
            [veil.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor]
        ]];
    }
    UIStackView *main=[UIStackView new];main.axis=UILayoutConstraintAxisVertical;main.spacing=14;
    main.translatesAutoresizingMaskIntoConstraints=NO;[sheet addSubview:main];
    [NSLayoutConstraint activateConstraints:@[
        [main.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor constant:18],
        [main.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor constant:-18],
        [main.topAnchor constraintEqualToAnchor:sheet.safeAreaLayoutGuide.topAnchor constant:16],
        [main.bottomAnchor constraintEqualToAnchor:sheet.safeAreaLayoutGuide.bottomAnchor constant:-16]
    ]];
    UIView *header=[UIView new];[header.heightAnchor constraintEqualToConstant:84].active=YES;
    [main addArrangedSubview:header];
    UIImageView *avatar=[[UIImageView alloc]initWithImage:PHKEmbeddedImage("__phkcar")];
    avatar.translatesAutoresizingMaskIntoConstraints=NO;avatar.layer.cornerRadius=25;avatar.clipsToBounds=YES;
    avatar.contentMode=UIViewContentModeScaleAspectFill;
    avatar.backgroundColor=PHKColor(.16,.26,.35);avatar.layer.borderWidth=1;avatar.layer.borderColor=PHKAccent().CGColor;
    [header addSubview:avatar];
    UILabel *title=[self label:@"Developer Phan Anh Khôi" size:17 weight:UIFontWeightBold color:UIColor.whiteColor];
    title.translatesAutoresizingMaskIntoConstraints=NO;[header addSubview:title];
    UILabel *subtitle=[self label:@"PHK CONTROL  ·  STANDALONE" size:10 weight:UIFontWeightSemibold color:PHKAccent()];
    subtitle.translatesAutoresizingMaskIntoConstraints=NO;[header addSubview:subtitle];
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];close.translatesAutoresizingMaskIntoConstraints=NO;
    [close setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    close.tintColor=UIColor.whiteColor;close.backgroundColor=[UIColor colorWithWhite:1 alpha:.1];close.layer.cornerRadius=17;
    [close addTarget:self action:@selector(closePressed) forControlEvents:UIControlEventTouchUpInside];[header addSubview:close];
    [NSLayoutConstraint activateConstraints:@[
        [avatar.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [avatar.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],
        [avatar.widthAnchor constraintEqualToConstant:50],[avatar.heightAnchor constraintEqualToConstant:50],
        [title.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:11],
        [title.trailingAnchor constraintEqualToAnchor:close.leadingAnchor constant:-5],
        [title.topAnchor constraintEqualToAnchor:header.topAnchor constant:12],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:7],
        [close.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [close.topAnchor constraintEqualToAnchor:header.topAnchor constant:9],
        [close.widthAnchor constraintEqualToConstant:34],[close.heightAnchor constraintEqualToConstant:34]
    ]];
    _scroll=[UIScrollView new];_scroll.showsVerticalScrollIndicator=NO;[main addArrangedSubview:_scroll];
    _cards=[UIStackView new];_cards.axis=UILayoutConstraintAxisVertical;_cards.spacing=10;
    _cards.translatesAutoresizingMaskIntoConstraints=NO;[_scroll addSubview:_cards];
    [NSLayoutConstraint activateConstraints:@[
        [_cards.leadingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.leadingAnchor],
        [_cards.trailingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.trailingAnchor],
        [_cards.topAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.topAnchor],
        [_cards.bottomAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.bottomAnchor],
        [_cards.widthAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.widthAnchor]
    ]];
    UILabel *heading=[self label:@"Điều khiển" size:21 weight:UIFontWeightBold color:UIColor.whiteColor];[_cards addArrangedSubview:heading];
    UILabel *caption=[self label:@"Cài đặt cục bộ hoạt động độc lập. Không yêu cầu cookie hay truy cập tài khoản." size:12 weight:UIFontWeightRegular color:[UIColor colorWithWhite:1 alpha:.62]];
    [_cards addArrangedSubview:caption];
    for(const auto &item:phk::kDefinitions)[self makeSetting:item];
    UILabel *heading2=[self label:@"Chẩn đoán" size:19 weight:UIFontWeightBold color:UIColor.whiteColor];[_cards addArrangedSubview:heading2];
    UIView *diagnostics=[UIView new];[self addCard:diagnostics height:122];
    UIStackView *status=[UIStackView new];status.axis=UILayoutConstraintAxisVertical;status.spacing=8;
    status.translatesAutoresizingMaskIntoConstraints=NO;[diagnostics addSubview:status];
    [NSLayoutConstraint activateConstraints:@[
        [status.leadingAnchor constraintEqualToAnchor:diagnostics.leadingAnchor constant:14],
        [status.trailingAnchor constraintEqualToAnchor:diagnostics.trailingAnchor constant:-14],
        [status.topAnchor constraintEqualToAnchor:diagnostics.topAnchor constant:14],
        [status.bottomAnchor constraintEqualToAnchor:diagnostics.bottomAnchor constant:-14]
    ]];
    [status addArrangedSubview:[self label:@"Dylib ARM64 · v1.0.0 · Đã nạp" size:13 weight:UIFontWeightSemibold color:PHKAccent()]];
    [status addArrangedSubview:[self label:@"Cử chỉ: chạm đồng thời ba ngón. Cài đặt chỉ tác động lên giao diện PHK, không thay thế hook của Zalo." size:12 weight:UIFontWeightRegular color:[UIColor colorWithWhite:1 alpha:.75]]];
    UILabel *fine=[self label:@"Không xuất cookie, không thu thập thông tin đăng nhập, không giả trạng thái xử lý máy chủ." size:10 weight:UIFontWeightRegular color:[UIColor colorWithWhite:1 alpha:.55]];
    [_cards addArrangedSubview:fine];
}
- (void)makeSetting:(const phk::Definition &)item {
    UIView *card=[UIView new];[self addCard:card height:66];
    UILabel *label=[self label:[NSString stringWithUTF8String:item.title] size:14 weight:UIFontWeightSemibold color:UIColor.whiteColor];
    label.translatesAutoresizingMaskIntoConstraints=NO;[card addSubview:label];
    UISwitch *toggle=[UISwitch new];toggle.translatesAutoresizingMaskIntoConstraints=NO;
    toggle.onTintColor=PHKAccent();
    NSString *key=[NSString stringWithUTF8String:item.key];
    toggle.on=PHKReadSetting(key,item.defaultValue);
    toggle.accessibilityLabel=label.text;
    objc_setAssociatedObject(toggle,@selector(toggled:),key,OBJC_ASSOCIATION_COPY_NONATOMIC);
    [toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];[card addSubview:toggle];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [label.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-8],
        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-13],
        [toggle.centerYAnchor constraintEqualToAnchor:card.centerYAnchor]
    ]];
}
- (void)toggled:(UISwitch *)sender {
    NSString *key=objc_getAssociatedObject(sender,@selector(toggled:));
    if(!phk::find(key.UTF8String))return;
    PHKWriteSetting(key,sender.on);
    if([key isEqualToString:@"haptics"] && sender.on){
        UIImpactFeedbackGenerator *gen=[[UIImpactFeedbackGenerator alloc]initWithStyle:UIImpactFeedbackStyleLight];
        [gen impactOccurred];
    }
}
- (void)closePressed {if(self.onClose)self.onClose();}
@end

@interface PHKStandaloneGesture : UITapGestureRecognizer <UIGestureRecognizerDelegate>
@end
@implementation PHKStandaloneGesture
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    (void)gesture;(void)other;return YES;
}
@end

@interface PHKStandaloneCoordinator : NSObject
@property(nonatomic,strong) UIWindow *panelWindow;
@property(nonatomic,weak) UIWindow *priorKeyWindow;
+ (instancetype)shared;
- (void)install;
- (void)show;
- (void)dismiss;
@end
@implementation PHKStandaloneCoordinator
+ (instancetype)shared {
    static PHKStandaloneCoordinator *instance;static dispatch_once_t once;
    dispatch_once(&once,^{instance=[PHKStandaloneCoordinator new];});return instance;
}
- (UIWindow *)hostWindow {
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:[UIWindowScene class]] || scene.activationState!=UISceneActivationStateForegroundActive)continue;
        for(UIWindow *win in ((UIWindowScene *)scene).windows){
            if(win==self.panelWindow || win.hidden || win.windowLevel!=UIWindowLevelNormal)continue;
            if(win.isKeyWindow)return win;
        }
        for(UIWindow *win in ((UIWindowScene *)scene).windows)
            if(win!=self.panelWindow && !win.hidden && win.windowLevel==UIWindowLevelNormal)return win;
    }
    return nil;
}
- (void)install {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self install];});return;}
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:[UIWindowScene class]])continue;
        for(UIWindow *window in ((UIWindowScene *)scene).windows){
            if(window==self.panelWindow || window.hidden || window.windowLevel!=UIWindowLevelNormal)continue;
            BOOL exists=NO;
            for(UIGestureRecognizer *item in window.gestureRecognizers)
                if([item isKindOfClass:[PHKStandaloneGesture class]]){exists=YES;break;}
            if(exists)continue;
            PHKStandaloneGesture *tap=[[PHKStandaloneGesture alloc]initWithTarget:self action:@selector(handleTap:)];
            tap.numberOfTouchesRequired=3;tap.numberOfTapsRequired=1;tap.cancelsTouchesInView=NO;
            tap.delegate=tap;
            [window addGestureRecognizer:tap];
        }
    }
}
- (void)handleTap:(UIGestureRecognizer *)gesture {
    if(gesture.state==UIGestureRecognizerStateRecognized)[self show];
}
- (void)show {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self show];});return;}
    if(self.panelWindow)return;
    UIWindow *host=[self hostWindow];if(!host)return;
    self.priorKeyWindow=host;
    UIWindow *panel=[[UIWindow alloc]initWithWindowScene:host.windowScene];
    panel.windowLevel=UIWindowLevelAlert-3;
    __weak typeof(self) weakSelf=self;
    PHKStandalonePanel *controller=[PHKStandalonePanel new];
    controller.onClose=^{[weakSelf dismiss];};
    panel.rootViewController=controller;self.panelWindow=panel;
    [panel makeKeyAndVisible];
}
- (void)dismiss {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self dismiss];});return;}
    UIWindow *panel=self.panelWindow;if(!panel)return;
    panel.hidden=YES;panel.rootViewController=nil;self.panelWindow=nil;
    [self.priorKeyWindow makeKeyWindow];self.priorKeyWindow=nil;
}
@end
extern "C" __attribute__((visibility("default"))) const char *PHKStandaloneVersion(void){return "1.0.0";}
extern "C" __attribute__((visibility("default"))) bool PHKStandaloneLoaded(void){return true;}
extern "C" __attribute__((visibility("default"))) void PHKStandaloneOpen(void) {
    dispatch_async(dispatch_get_main_queue(), ^{[[PHKStandaloneCoordinator shared] show];});
}
__attribute__((constructor)) static void PHKStandaloneInit(void) {
    NSLog(@"[PHKStandalone] loaded, host integration required for runtime activation");
    dispatch_async(dispatch_get_main_queue(), ^{
        PHKStandaloneCoordinator *coordinator=[PHKStandaloneCoordinator shared];
        for(NSString *event in @[UIApplicationDidBecomeActiveNotification,UIWindowDidBecomeVisibleNotification]){
            [NSNotificationCenter.defaultCenter addObserverForName:event object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *n){
                (void)n;[coordinator install];
            }];
        }
        [coordinator install];
    });
}
