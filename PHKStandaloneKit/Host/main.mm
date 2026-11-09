#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
extern "C" const char *PHKStandaloneVersion(void);
extern "C" bool PHKStandaloneLoaded(void);
extern "C" void PHKStandaloneOpen(void);

@interface PHKHostViewController : UIViewController
@end
@implementation PHKHostViewController
- (void)loadView {
    UIView *root=[UIView new];root.backgroundColor=[UIColor colorWithRed:.034 green:.049 blue:.086 alpha:1];self.view=root;
    CAGradientLayer *gradient=[CAGradientLayer layer];
    gradient.colors=@[(__bridge id)[UIColor colorWithRed:.10 green:.16 blue:.26 alpha:1].CGColor,
                      (__bridge id)[UIColor colorWithRed:.025 green:.035 blue:.07 alpha:1].CGColor];
    gradient.startPoint=CGPointMake(0,0);gradient.endPoint=CGPointMake(1,1);
    [root.layer insertSublayer:gradient atIndex:0];
    gradient.frame=UIScreen.mainScreen.bounds;
    UILabel *caption=[UILabel new];caption.text=@"DEVELOPER PHAN ANH KHÔI";
    caption.font=[UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    caption.textColor=[UIColor colorWithRed:.38 green:.86 blue:1 alpha:1];
    caption.textAlignment=NSTextAlignmentCenter;
    caption.translatesAutoresizingMaskIntoConstraints=NO;[root addSubview:caption];
    UILabel *title=[UILabel new];title.text=@"PHK CONTROL";
    title.font=[UIFont systemFontOfSize:37 weight:UIFontWeightBold];title.textColor=UIColor.whiteColor;
    title.textAlignment=NSTextAlignmentCenter;title.translatesAutoresizingMaskIntoConstraints=NO;[root addSubview:title];
    UILabel *info=[UILabel new];info.text=@"Chạm đồng thời ba ngón tay để mở bảng điều khiển.\nHoặc sử dụng nút kiểm tra bên dưới.";
    info.numberOfLines=0;info.textAlignment=NSTextAlignmentCenter;info.font=[UIFont systemFontOfSize:15];
    info.textColor=[UIColor colorWithWhite:1 alpha:.68];info.translatesAutoresizingMaskIntoConstraints=NO;[root addSubview:info];
    UIButton *open=[UIButton buttonWithType:UIButtonTypeSystem];
    [open setTitle:@"Mở bảng điều khiển" forState:UIControlStateNormal];
    open.titleLabel.font=[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [open setTitleColor:[UIColor colorWithRed:.025 green:.035 blue:.07 alpha:1] forState:UIControlStateNormal];
    open.backgroundColor=[UIColor colorWithRed:.38 green:.86 blue:1 alpha:1];open.layer.cornerRadius=17;
    open.translatesAutoresizingMaskIntoConstraints=NO;[root addSubview:open];
    [open addTarget:self action:@selector(openPanel) forControlEvents:UIControlEventTouchUpInside];
    UILabel *status=[UILabel new];
    status.text=PHKStandaloneLoaded() ?
        [NSString stringWithFormat:@"Dynamic library linked • %s",PHKStandaloneVersion()] :
        @"Dynamic library did not initialize";
    status.font=[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
    status.textColor=[UIColor colorWithWhite:1 alpha:.57];
    status.translatesAutoresizingMaskIntoConstraints=NO;status.textAlignment=NSTextAlignmentCenter;[root addSubview:status];
    [NSLayoutConstraint activateConstraints:@[
        [title.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
        [title.centerYAnchor constraintEqualToAnchor:root.centerYAnchor constant:-75],
        [caption.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
        [caption.bottomAnchor constraintEqualToAnchor:title.topAnchor constant:-18],
        [info.leadingAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.leadingAnchor constant:24],
        [info.trailingAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.trailingAnchor constant:-24],
        [info.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:22],
        [open.leadingAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.leadingAnchor constant:24],
        [open.trailingAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.trailingAnchor constant:-24],
        [open.bottomAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.bottomAnchor constant:-74],
        [open.heightAnchor constraintEqualToConstant:56],
        [status.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:12],
        [status.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-12],
        [status.bottomAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.bottomAnchor constant:-20]
    ]];
}
- (void)openPanel { PHKStandaloneOpen(); }
@end

@interface PHKHostSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation PHKHostSceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    (void)session;(void)options;
    if(![scene isKindOfClass:[UIWindowScene class]])return;
    UIWindow *window=[[UIWindow alloc]initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController=[PHKHostViewController new];
    self.window=window;[window makeKeyAndVisible];
}
@end

@interface PHKHostAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation PHKHostAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)app;(void)options;return YES;
}
@end
int main(int argc,char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc,argv,nil,NSStringFromClass([PHKHostAppDelegate class]));
    }
}
