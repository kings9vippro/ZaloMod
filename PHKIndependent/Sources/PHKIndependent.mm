#import "PHKIndependent.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <cmath>
#import "../Core/PHKCore.hpp"

static NSString * const kColorKey=@"dev.phananhkhoi.independent.accent";
static NSString * const kLanguageKey=@"dev.phananhkhoi.independent.language";
static NSString * const kDelayKey=@"dev.phananhkhoi.independent.delay";
static UIColor *PHKAccent(void){
    NSInteger index=[NSUserDefaults.standardUserDefaults integerForKey:kColorKey];
    const auto color=phk::paletteAt((std::uint64_t)MAX(0,index));
    return [UIColor colorWithRed:color.r/255.0 green:color.g/255.0 blue:color.b/255.0 alpha:1];
}
static BOOL PHKEnglish(void){
    return [[NSUserDefaults.standardUserDefaults stringForKey:kLanguageKey] isEqualToString:@"en"];
}
static NSString *PHKText(NSString *vi,NSString *en){return PHKEnglish()?en:vi;}
static UIFont *PHKFont(CGFloat size,UIFontWeight weight){
    return [UIFont systemFontOfSize:size weight:weight];
}
@class PHKDockCoordinator;

@interface PHKTabCell : UIControl
@property(nonatomic,strong) UIImageView *icon;
@property(nonatomic,strong) UILabel *label;
@property(nonatomic) NSInteger tabIndex;
- (void)configureName:(NSString *)name symbol:(NSString *)symbol selected:(BOOL)selected;
@end
@implementation PHKTabCell
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        self.layer.cornerRadius=20;
        _icon=[UIImageView new];
        _icon.contentMode=UIViewContentModeScaleAspectFit;
        _icon.translatesAutoresizingMaskIntoConstraints=NO;
        [self addSubview:_icon];
        _label=[UILabel new];
        _label.font=PHKFont(10,UIFontWeightMedium);
        _label.textAlignment=NSTextAlignmentCenter;
        _label.adjustsFontSizeToFitWidth=YES;
        _label.minimumScaleFactor=.82;
        _label.translatesAutoresizingMaskIntoConstraints=NO;
        [self addSubview:_label];
        [NSLayoutConstraint activateConstraints:@[
            [_icon.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_icon.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [_icon.widthAnchor constraintEqualToConstant:19],
            [_icon.heightAnchor constraintEqualToConstant:19],
            [_label.topAnchor constraintEqualToAnchor:_icon.bottomAnchor constant:2],
            [_label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:1],
            [_label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-1],
            [_label.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-2]
        ]];
    }
    return self;
}
- (void)configureName:(NSString *)name symbol:(NSString *)symbol selected:(BOOL)selected {
    _label.text=name;
    UIImageSymbolConfiguration *config=[UIImageSymbolConfiguration configurationWithPointSize:17
        weight:selected?UIImageSymbolWeightSemibold:UIImageSymbolWeightRegular];
    _icon.image=[[UIImage systemImageNamed:symbol] imageWithConfiguration:config];
    UIColor *ink=selected?PHKAccent():[UIColor colorWithWhite:1 alpha:.76];
    _icon.tintColor=ink;
    _label.textColor=ink;
    self.backgroundColor=selected?[PHKAccent() colorWithAlphaComponent:.18]:UIColor.clearColor;
    self.accessibilityLabel=name;
    self.accessibilityTraits=UIAccessibilityTraitButton | (selected?UIAccessibilityTraitSelected:0);
}
@end

@interface PHKGlassDock : UIView <UIGestureRecognizerDelegate>
@property(nonatomic,weak) UITabBarController *host;
@property(nonatomic,strong) NSArray<PHKTabCell *> *cells;
@property(nonatomic,strong) UIVisualEffectView *material;
- (void)refresh;
- (void)updateLayoutForTabBar:(UITabBar *)tabBar;
@end
@implementation PHKGlassDock
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        self.backgroundColor=[UIColor colorWithWhite:.065 alpha:.9];
        self.layer.cornerRadius=27;
        self.layer.borderWidth=.7;
        self.layer.borderColor=[UIColor colorWithWhite:1 alpha:.18].CGColor;
        self.layer.shadowOpacity=.17;
        self.layer.shadowRadius=9;
        self.layer.shadowOffset=CGSizeMake(0,3);
        _material=[[UIVisualEffectView alloc]initWithEffect:
                   [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        _material.userInteractionEnabled=NO;
        _material.layer.cornerRadius=27;
        _material.clipsToBounds=YES;
        [self addSubview:_material];
        NSMutableArray *tabs=[NSMutableArray array];
        for(NSInteger i=0;i<phk::kTabCount;i++){
            PHKTabCell *cell=[PHKTabCell new];
            cell.tabIndex=i;
            [cell addTarget:self action:@selector(tapCell:)
                 forControlEvents:UIControlEventTouchUpInside];
            [tabs addObject:cell];
            [self addSubview:cell];
        }
        _cells=tabs;
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
        pan.minimumNumberOfTouches=1;
        pan.maximumNumberOfTouches=1;
        pan.cancelsTouchesInView=NO;
        pan.delegate=self;
        [self addGestureRecognizer:pan];
        [self refresh];
    }
    return self;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture
 shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    (void)gesture;(void)other;return YES;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _material.frame=self.bounds;
    CGFloat w=self.bounds.size.width-8;
    for(NSInteger i=0;i<_cells.count;i++){
        _cells[i].frame=CGRectMake(4+i*w/_cells.count,4,w/_cells.count,MAX(38,self.bounds.size.height-8));
    }
}
- (void)updateLayoutForTabBar:(UITabBar *)tabBar {
    CGFloat safe=MAX(0,tabBar.safeAreaInsets.bottom);
    CGFloat contentHeight=MAX(42,tabBar.bounds.size.height-safe);
    CGFloat wanted=MIN(53,contentHeight);
    CGRect frame=CGRectMake(10,MAX(0,(contentHeight-wanted)/2.0),
                            MAX(200,tabBar.bounds.size.width-20),wanted);
    if(!CGRectEqualToRect(self.frame,frame))self.frame=frame;
}
- (void)choose:(NSInteger)i {
    UITabBarController *controller=self.host;
    if(!controller || i<0 || i>=controller.viewControllers.count)return;
    if(controller.selectedIndex==i)return;
    controller.selectedIndex=i;
    if(!UIAccessibilityIsReduceMotionEnabled()){
        [[[UISelectionFeedbackGenerator alloc]init] selectionChanged];
        [UIView animateWithDuration:.26 delay:0 usingSpringWithDamping:.78
              initialSpringVelocity:.1 options:UIViewAnimationOptionAllowUserInteraction
              animations:^{[self refresh];} completion:nil];
    } else [self refresh];
}
- (void)tapCell:(PHKTabCell *)sender {[self choose:sender.tabIndex];}
- (void)pan:(UIPanGestureRecognizer *)gesture {
    if(gesture.state!=UIGestureRecognizerStateBegan &&
       gesture.state!=UIGestureRecognizerStateChanged &&
       gesture.state!=UIGestureRecognizerStateEnded)return;
    CGPoint value=[gesture locationInView:self];
    const int desired=phk::indexAt(value.x,self.bounds.size.width,(int)_cells.count);
    if(desired>=0)[self choose:desired];
}
- (void)refresh {
    static NSArray<NSString *> *vi,*en,*icons;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        vi=@[@"Tin nhắn",@"Danh bạ",@"Khám phá",@"Tường nhà",@"Cá nhân"];
        en=@[@"Chats",@"Contacts",@"Explore",@"Home",@"Profile"];
        icons=@[@"message.fill",@"person.crop.square",@"square.grid.2x2",
                @"house",@"person.crop.circle"];
    });
    NSInteger selected=self.host?self.host.selectedIndex:0;
    for(NSInteger i=0;i<_cells.count;i++)
        [_cells[i] configureName:(PHKEnglish()?en:vi)[i] symbol:icons[i] selected:i==selected];
}
@end

@interface PHKTripleTap : UITapGestureRecognizer
@end
@implementation PHKTripleTap
@end

@interface PHKDockCoordinator : NSObject
@property(nonatomic,weak) UITabBarController *target;
@property(nonatomic,strong) PHKGlassDock *dock;
@property(nonatomic,strong) UILabel *brand;
@property(nonatomic,strong) NSTimer *poller;
+ (instancetype)shared;
- (void)start;
- (void)scan;
- (void)showMenu;
- (void)refreshDock;
@end

@interface PHKCompactPanel : UIViewController <UIDocumentPickerDelegate>
@property(nonatomic,copy) dispatch_block_t dismissed;
@property(nonatomic,weak) PHKDockCoordinator *owner;
@property(nonatomic,strong) UILabel *subtitle;
@property(nonatomic,strong) UILabel *delayLabel;
@property(nonatomic,strong) UIStackView *paletteRow;
- (void)refresh;
@end

@implementation PHKCompactPanel
- (UILabel *)label:(NSString *)value size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *l=[UILabel new];l.text=value;l.textColor=color;l.font=PHKFont(size,weight);
    l.numberOfLines=0;return l;
}
- (UIButton *)action:(NSString *)title selector:(SEL)selector {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font=PHKFont(14,UIFontWeightSemibold);
    b.backgroundColor=[UIColor colorWithWhite:1 alpha:.10];
    b.layer.cornerRadius=14;
    [b.heightAnchor constraintEqualToConstant:45].active=YES;
    [b addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (void)loadView {
    UIView *root=[UIView new];root.backgroundColor=[UIColor colorWithWhite:0 alpha:.57];
    self.view=root;
    UIVisualEffectView *panel=[[UIVisualEffectView alloc]initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    panel.layer.cornerRadius=25;panel.clipsToBounds=YES;
    panel.translatesAutoresizingMaskIntoConstraints=NO;
    [root addSubview:panel];
    [NSLayoutConstraint activateConstraints:@[
        [panel.centerXAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.centerXAnchor],
        [panel.centerYAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.centerYAnchor],
        [panel.leadingAnchor constraintGreaterThanOrEqualToAnchor:root.leadingAnchor constant:12],
        [panel.trailingAnchor constraintLessThanOrEqualToAnchor:root.trailingAnchor constant:-12],
        [panel.widthAnchor constraintLessThanOrEqualToConstant:430],
        [panel.widthAnchor constraintEqualToAnchor:root.widthAnchor constant:-24]
    ]];
    UIStackView *stack=[UIStackView new];
    stack.axis=UILayoutConstraintAxisVertical;stack.spacing=13;
    stack.translatesAutoresizingMaskIntoConstraints=NO;
    [panel.contentView addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:panel.contentView.topAnchor constant:21],
        [stack.leadingAnchor constraintEqualToAnchor:panel.contentView.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:panel.contentView.trailingAnchor constant:-18],
        [stack.bottomAnchor constraintEqualToAnchor:panel.contentView.bottomAnchor constant:-19]
    ]];
    [stack addArrangedSubview:[self label:@"Zalo" size:23 weight:UIFontWeightBold color:UIColor.whiteColor]];
    [stack addArrangedSubview:[self label:@"Developer Phan Anh Khôi" size:12
                                   weight:UIFontWeightSemibold color:PHKAccent()]];
    _subtitle=[self label:@"" size:12 weight:UIFontWeightRegular
                    color:[UIColor colorWithWhite:1 alpha:.75]];
    [stack addArrangedSubview:_subtitle];
    [stack addArrangedSubview:[self label:PHKText(@"7 màu chuẩn",@"7 curated colors") size:12
                                   weight:UIFontWeightSemibold color:UIColor.whiteColor]];
    UIStackView *palette=[UIStackView new];
    palette.axis=UILayoutConstraintAxisHorizontal;
    palette.distribution=UIStackViewDistributionFillEqually;
    palette.spacing=7;
    _paletteRow=palette;
    for(int i=0;i<7;i++){
        const auto color=phk::paletteAt(i);
        UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
        b.tag=i;b.backgroundColor=[UIColor colorWithRed:color.r/255.0
           green:color.g/255.0 blue:color.b/255.0 alpha:1];
        b.layer.cornerRadius=17;
        b.layer.borderColor=UIColor.whiteColor.CGColor;
        b.accessibilityLabel=[NSString stringWithFormat:@"Color %d",i+1];
        [b.heightAnchor constraintEqualToConstant:34].active=YES;
        [b addTarget:self action:@selector(pickColor:) forControlEvents:UIControlEventTouchUpInside];
        [palette addArrangedSubview:b];
    }
    [stack addArrangedSubview:palette];
    [stack addArrangedSubview:[self action:PHKText(@"Màu ngẫu nhiên đẹp",@"Random curated color")
                                     selector:@selector(randomColor)]];
    UISegmentedControl *language=[[UISegmentedControl alloc]initWithItems:@[@"VN",@"EN"]];
    language.selectedSegmentIndex=PHKEnglish()?1:0;
    [language addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:language];
    _delayLabel=[self label:@"" size:12 weight:UIFontWeightMedium color:UIColor.whiteColor];
    [stack addArrangedSubview:_delayLabel];
    UISlider *delay=[UISlider new];delay.minimumValue=1;delay.maximumValue=60;
    float current=[NSUserDefaults.standardUserDefaults floatForKey:kDelayKey];
    delay.value=current>=1&&current<=60?current:3;
    delay.tintColor=PHKAccent();
    [delay addTarget:self action:@selector(delayChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:delay];
    [stack addArrangedSubview:[self action:PHKText(@"Chọn ảnh → PNG sticker",@"Image → PNG sticker")
                                     selector:@selector(pickSticker)]];
    [stack addArrangedSubview:[self action:PHKText(@"Đóng",@"Close") selector:@selector(close)]];
    [self refresh];
}
- (void)refresh {
    BOOL ready=self.owner.target!=nil;
    self.subtitle.text=ready?
        PHKText(@"5 tab UIKit · vuốt trên thanh điều hướng",
                @"5 UIKit tabs · drag across the dock"):
        PHKText(@"Chưa tìm thấy thanh UITabBarController 5 tab",
                @"No five-tab UITabBarController found");
    float value=[NSUserDefaults.standardUserDefaults floatForKey:kDelayKey];
    if(value<1)value=3;
    self.delayLabel.text=[NSString stringWithFormat:@"%@: %.0f s  ·  %@",
        PHKText(@"Delay gửi thử",@"Opt-in delay"),value,
        PHKText(@"chỉ dùng khi host kết nối API hợp lệ",@"requires authorized host callback")];
    NSInteger selected=[NSUserDefaults.standardUserDefaults integerForKey:kColorKey];
    for(UIButton *button in self.paletteRow.arrangedSubviews)
        button.layer.borderWidth=(button.tag==selected)?2.5:0;
}
- (void)pickColor:(UIButton *)button {
    [NSUserDefaults.standardUserDefaults setInteger:button.tag forKey:kColorKey];
    [self.owner refreshDock];[self refresh];
}
- (void)randomColor {
    NSInteger current=[NSUserDefaults.standardUserDefaults integerForKey:kColorKey];
    NSInteger next=(current+1+arc4random_uniform(6))%7;
    [NSUserDefaults.standardUserDefaults setInteger:next forKey:kColorKey];
    [self.owner refreshDock];[self refresh];
}
- (void)languageChanged:(UISegmentedControl *)sender {
    [NSUserDefaults.standardUserDefaults setObject:sender.selectedSegmentIndex==1?@"en":@"vi"
                                            forKey:kLanguageKey];
    [self.owner refreshDock];
    [self refresh];
}
- (void)delayChanged:(UISlider *)slider {
    NSUInteger seconds=MAX(1,MIN(60,(NSUInteger)lroundf(slider.value)));
    [NSUserDefaults.standardUserDefaults setFloat:(float)seconds forKey:kDelayKey];
    [self refresh];
}
- (void)pickSticker {
    UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc]
        initWithDocumentTypes:@[@"public.image"] inMode:UIDocumentPickerModeImport];
    picker.delegate=self;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    NSURL *url=urls.firstObject;if(!url)return;
    BOOL scoped=[url startAccessingSecurityScopedResource];
    NSData *data=[NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
    if(scoped)[url stopAccessingSecurityScopedResource];
    if(data.length==0||data.length>12*1024*1024)return;
    UIImage *image=[UIImage imageWithData:data];
    NSData *png=PHKIndependentStickerPNG(image);
    if(!png)return;
    NSString *file=[NSTemporaryDirectory() stringByAppendingPathComponent:@"PHKSticker.png"];
    if(![png writeToFile:file atomically:YES])return;
    UIActivityViewController *share=[[UIActivityViewController alloc]
        initWithActivityItems:@[[NSURL fileURLWithPath:file]] applicationActivities:nil];
    share.popoverPresentationController.sourceView=self.view;
    [self presentViewController:share animated:YES completion:nil];
}
- (void)close {
    [self dismissViewControllerAnimated:YES completion:self.dismissed];
}
@end

static UITabBarController *PHKLocateTab(UIViewController *candidate,int depth) {
    if(!candidate || depth>12)return nil;
    if([candidate isKindOfClass:[UITabBarController class]]){
        UITabBarController *tabs=(UITabBarController *)candidate;
        if(tabs.viewControllers.count==phk::kTabCount && tabs.tabBar.items.count==phk::kTabCount)
            return tabs;
    }
    UIViewController *presented=candidate.presentedViewController;
    if(presented){
        UITabBarController *value=PHKLocateTab(presented,depth+1);if(value)return value;
    }
    if([candidate isKindOfClass:[UINavigationController class]]){
        for(UIViewController *child in ((UINavigationController *)candidate).viewControllers){
            UITabBarController *value=PHKLocateTab(child,depth+1);if(value)return value;
        }
    }
    for(UIViewController *child in candidate.childViewControllers){
        if(child==candidate)continue;
        UITabBarController *value=PHKLocateTab(child,depth+1);if(value)return value;
    }
    return nil;
}
@implementation PHKDockCoordinator
+ (instancetype)shared {
    static PHKDockCoordinator *instance;static dispatch_once_t once;
    dispatch_once(&once,^{instance=[PHKDockCoordinator new];});
    return instance;
}
- (void)start {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self start];});return;}
    if(self.poller)return;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(scan)
        name:UIApplicationDidBecomeActiveNotification object:nil];
    self.poller=[NSTimer scheduledTimerWithTimeInterval:1.8 target:self
         selector:@selector(scan) userInfo:nil repeats:YES];
    [self scan];
}
- (void)scan {
    if(!NSThread.isMainThread)return;
    if(UIApplication.sharedApplication.applicationState==UIApplicationStateBackground)return;
    UITabBarController *chosen=nil;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:[UIWindowScene class]] ||
           scene.activationState!=UISceneActivationStateForegroundActive)continue;
        for(UIWindow *window in ((UIWindowScene *)scene).windows){
            if(window.hidden || window.windowLevel!=UIWindowLevelNormal)continue;
            BOOL hasTriple=NO;
            for(UIGestureRecognizer *gesture in window.gestureRecognizers)
                if([gesture isKindOfClass:[PHKTripleTap class]]){hasTriple=YES;break;}
            if(!hasTriple){
                PHKTripleTap *tap=[[PHKTripleTap alloc]initWithTarget:self action:@selector(threeFingers:)];
                tap.numberOfTouchesRequired=3;
                tap.cancelsTouchesInView=NO;
                [window addGestureRecognizer:tap];
            }
            if(!chosen)chosen=PHKLocateTab(window.rootViewController,0);
        }
    }
    if(!chosen || chosen.tabBar.hidden){
        if(self.dock)self.dock.hidden=YES;
        return;
    }
    if(chosen!=self.target || !self.dock){
        [self.dock removeFromSuperview];
        [self.brand removeFromSuperview];
        self.target=chosen;
        self.dock=[PHKGlassDock new];
        self.dock.host=chosen;
        [chosen.tabBar addSubview:self.dock];
        UILabel *badge=[UILabel new];
        badge.text=@"Developer Phan Anh Khôi";
        badge.textColor=UIColor.whiteColor;
        badge.font=PHKFont(10,UIFontWeightSemibold);
        badge.backgroundColor=[UIColor colorWithRed:.18 green:.43 blue:.93 alpha:.9];
        badge.textAlignment=NSTextAlignmentCenter;
        badge.layer.cornerRadius=13;
        badge.clipsToBounds=YES;
        badge.userInteractionEnabled=YES;
        UITapGestureRecognizer *open=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMenu)];
        [badge addGestureRecognizer:open];
        [chosen.view addSubview:badge];
        self.brand=badge;
    }
    self.dock.hidden=NO;
    [self.dock updateLayoutForTabBar:chosen.tabBar];
    [chosen.tabBar bringSubviewToFront:self.dock];
    self.brand.frame=CGRectMake(MAX(0,(chosen.view.bounds.size.width-196)/2),
         chosen.view.safeAreaInsets.top+2,196,26);
    [self.dock refresh];
}
- (void)threeFingers:(UITapGestureRecognizer *)gesture {
    if(gesture.state==UIGestureRecognizerStateRecognized)[self showMenu];
}
- (void)showMenu {
    if(!NSThread.isMainThread){
        dispatch_async(dispatch_get_main_queue(),^{[self showMenu];});return;
    }
    UITabBarController *tab=self.target;
    UIViewController *presenter=tab;
    if(!presenter){
        for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
            if(![scene isKindOfClass:[UIWindowScene class]])continue;
            for(UIWindow *window in ((UIWindowScene *)scene).windows)
                if(window.isKeyWindow){presenter=window.rootViewController;break;}
            if(presenter)break;
        }
    }
    if(!presenter)return;
    while(presenter.presentedViewController){
        if([presenter.presentedViewController isKindOfClass:[PHKCompactPanel class]])return;
        presenter=presenter.presentedViewController;
    }
    PHKCompactPanel *panel=[PHKCompactPanel new];
    panel.owner=self;
    panel.modalPresentationStyle=UIModalPresentationOverFullScreen;
    [presenter presentViewController:panel animated:NO completion:nil];
}
- (void)refreshDock {[self.dock refresh];}
@end

extern "C" __attribute__((visibility("default"))) const char *PHKIndependentVersion(void){return "1.0.0";}
extern "C" __attribute__((visibility("default"))) int PHKIndependentLoaded(void){return 1;}
extern "C" __attribute__((visibility("default"))) void PHKIndependentShowMenu(void){
    [[PHKDockCoordinator shared] showMenu];
}
extern "C" __attribute__((visibility("default")))
NSData *PHKIndependentStickerPNG(UIImage *source){
    if(![source isKindOfClass:[UIImage class]] || source.size.width<=0 || source.size.height<=0)return nil;
    const CGSize size=CGSizeMake(512,512);
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat defaultFormat];
    format.opaque=NO;
    format.scale=1;
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithSize:size format:format];
    return [renderer PNGDataWithActions:^(UIGraphicsImageRendererContext *ctx){
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0,512,512) cornerRadius:66] addClip];
        CGFloat factor=MAX(512/source.size.width,512/source.size.height);
        CGFloat w=source.size.width*factor,h=source.size.height*factor;
        [source drawInRect:CGRectMake((512-w)/2,(512-h)/2,w,h)];
        (void)ctx;
    }];
}
extern "C" __attribute__((visibility("default")))
NSInteger PHKIndependentParseCommand(NSString *command,BOOL hasRepliedImage){
    if(![command isKindOfClass:[NSString class]])return (NSInteger)phk::Command::none;
    const char *value=command.UTF8String;
    if(!value)return (NSInteger)phk::Command::none;
    return (NSInteger)phk::parseCommand(value,hasRepliedImage);
}
extern "C" __attribute__((visibility("default")))
BOOL PHKIndependentSchedule(NSString *message,NSTimeInterval delay,void (^callback)(NSString *)){
    if(![message isKindOfClass:[NSString class]] || message.length==0 ||
       message.length>1024 || !callback || !std::isfinite(delay) || delay<1 || delay>60)return NO;
    static NSUInteger pending=0;
    __block BOOL accepted=NO;
    void (^work)(void)=^{
        const auto milliseconds=(std::uint32_t)llround(delay*1000.0);
        if(!phk::validDelay(milliseconds,pending))return;
        pending++;
        NSString *copy=[message copy];
        void (^send)(NSString *)=[callback copy];
        accepted=YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)milliseconds*1000000LL),
                       dispatch_get_main_queue(),^{
            if(pending>0)pending--;
            if(UIApplication.sharedApplication.applicationState==UIApplicationStateActive)
                send(copy);
        });
    };
    if(NSThread.isMainThread)work();else dispatch_sync(dispatch_get_main_queue(),work);
    return accepted;
}
__attribute__((constructor)) static void PHKIndependentBootstrap(void){
    dispatch_async(dispatch_get_main_queue(),^{[[PHKDockCoordinator shared] start];});
}
