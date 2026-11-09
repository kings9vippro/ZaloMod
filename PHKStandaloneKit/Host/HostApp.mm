#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
extern "C" const char *PHKStandaloneVersion(void);
extern "C" bool PHKStandaloneLoaded(void);
extern "C" void PHKStandaloneOpen(void);

@interface PHKHostRootController : UIViewController
@end
@implementation PHKHostRootController
- (void)loadView {
    UIView *background=[UIView new];background.backgroundColor=[UIColor colorWithRed:.045 green:.065 blue:.10 alpha:1];self.view=background;
    UIStackView *stack=[UIStackView new];stack.translatesAutoresizingMaskIntoConstraints=NO;
    stack.axis=UILayoutConstraintAxisVertical;stack.spacing=19;stack.alignment=UIStackViewAlignmentCenter;
    [background addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:background.safeAreaLayoutGuide.leadingAnchor constant:23],
        [stack.trailingAnchor constraintEqualToAnchor:background.safeAreaLayoutGuide.trailingAnchor constant:-23],
        [stack.centerYAnchor constraintEqualToAnchor:background.safeAreaLayoutGuide.centerYAnchor]
    ]];
    UILabel *title=[UILabel new];title.text=@"PHK STANDALONE";title.font=[UIFont systemFontOfSize:27 weight:UIFontWeightBold];
    title.textColor=[UIColor colorWithRed:.39 green:.86 blue:.99 alpha:1];
    [stack addArrangedSubview:title];
    UILabel *description=[UILabel new];
    description.text=@"Kiểm thử thư viện iOS độc lập.\nChạm đồng thời ba ngón hoặc nhấn nút bên dưới.";
    description.numberOfLines=0;description.textAlignment=NSTextAlignmentCenter;
    description.font=[UIFont systemFontOfSize:14];description.textColor=[UIColor colorWithWhite:1 alpha:.78];
    [stack addArrangedSubview:description];
    UIButton *open=[UIButton buttonWithType:UIButtonTypeSystem];[open setTitle:@"MỞ BẢNG ĐIỀU KHIỂN" forState:UIControlStateNormal];
    open.titleLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    open.backgroundColor=[UIColor colorWithRed:.35 green:.82 blue:.97 alpha:1];
    [open setTitleColor:[UIColor colorWithRed:.04 green:.06 blue:.10 alpha:1] forState:UIControlStateNormal];
    open.layer.cornerRadius=16;[open.heightAnchor constraintEqualToConstant:52].active=YES;
    [open.widthAnchor constraintEqualToConstant:290].active=YES;[stack addArrangedSubview:open];
    [open addTarget:self action:@selector(openPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *status=[UILabel new];
    status.text=[NSString stringWithFormat:@"Phiên bản dylib: %s · %@",PHKStandaloneVersion(),
                 PHKStandaloneLoaded()?@"ĐÃ NẠP":@"KHÔNG TẢI ĐƯỢC"];
    status.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    status.textColor=[UIColor colorWithWhite:1 alpha:.62];[stack addArrangedSubview:status];
}
- (void)openPressed {PHKStandaloneOpen();}
@end

@interface PHKHostSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation PHKHostSceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    (void)session;(void)options;
    if(![scene isKindOfClass:[UIWindowScene class]])return;
    UIWindow *window=[[UIWindow alloc]initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController=[PHKHostRootController new];self.window=window;
    [window makeKeyAndVisible];
}
@end

@interface PHKHostAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation PHKHostAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)app configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    (void)app;(void)options;
    return [UISceneConfiguration configurationWithName:@"Default Configuration" sessionRole:session.role];
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc,argv,nil,NSStringFromClass(PHKHostAppDelegate.class));
    }
}
