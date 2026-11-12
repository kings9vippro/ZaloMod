#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

/// Read-only runtime compatibility inventory. Never accesses account data,
/// message content, cookies, authentication headers or hidden API endpoints.
static BOOL PHKProbeForeground(UIView *view) {
    return view && view.window && !view.hidden && view.alpha > .02;
}
static NSDictionary *PHKProbeControllerTree(UIViewController *controller, NSUInteger depth){
    if(!controller || depth>8)return @{};
    NSMutableArray *children=[NSMutableArray array];
    NSArray<UIViewController *> *direct=controller.childViewControllers;
    NSUInteger limit=MIN((NSUInteger)direct.count,10);
    for(NSUInteger i=0;i<limit;i++){
        NSDictionary *node=PHKProbeControllerTree(direct[i],depth+1);
        if(node.count)[children addObject:node];
    }
    NSString *name=NSStringFromClass(controller.class) ?: @"Unknown";
    NSMutableDictionary *entry=[@{@"class":name,@"childCount":@(direct.count)}
                                 mutableCopy];
    if(children.count)entry[@"children"]=children;
    if([controller isKindOfClass:[UITabBarController class]]){
        UITabBarController *tabs=(UITabBarController *)controller;
        entry[@"tabCount"]=@(tabs.tabBar.items.count);
        entry[@"selectedTab"]=@(tabs.selectedIndex);
    }
    return entry;
}
static void PHKProbeViews(UIView *root, NSMutableDictionary *seen,
                          NSMutableArray *activeInputs,NSUInteger *budget){
    if(!root || !budget || *budget==0)return;
    --*budget;
    NSString *name=NSStringFromClass(root.class) ?: @"Unknown";
    NSNumber *prev=seen[name] ?: @0;
    seen[name]=@(prev.integerValue+1);
    if([root isKindOfClass:[UITextField class]] ||
       [root isKindOfClass:[UITextView class]]){
        if(root.isFirstResponder && PHKProbeForeground(root)){
            NSMutableArray *parents=[NSMutableArray array];
            for(UIView *node=root;node && parents.count<12;node=node.superview)
                [parents addObject:NSStringFromClass(node.class) ?: @"Unknown"];
            [activeInputs addObject:@{@"type":name,@"superviews":parents}];
        }
    }
    NSUInteger maxChildren=MIN((NSUInteger)root.subviews.count,200);
    for(NSUInteger i=0;i<maxChildren;i++)
        PHKProbeViews(root.subviews[i],seen,activeInputs,budget);
}
extern "C" __attribute__((visibility("default")))
NSString *PHKIndependentRuntimeProbe(void){
    if(!NSThread.isMainThread){
        __block NSString *value=nil;
        dispatch_sync(dispatch_get_main_queue(),^{value=PHKIndependentRuntimeProbe();});
        return value ?: @"{}";
    }
    NSDictionary *bundle=NSBundle.mainBundle.infoDictionary?:@{};
    NSMutableArray *frameworks=[NSMutableArray array];
    NSMutableDictionary *knownClasses=[NSMutableDictionary dictionary];
    NSArray *interesting=@[@"KBChatInputComponentView",@"ZAInputView",
        @"ZACustomInputView",@"ZinstantInputView",@"ZaloModViewController",
        @"ZaloFloatingButton",@"UITabBarController"];
    for(NSString *name in interesting)
        knownClasses[name]=@(NSClassFromString(name)!=Nil);

    for(uint32_t i=0;i<_dyld_image_count() && i<4096;i++){
        const char *cname=_dyld_get_image_name(i);
        if(!cname)continue;
        NSString *name=[[NSString stringWithUTF8String:cname] lastPathComponent];
        if([name containsString:@"PHK"]||[name containsString:@"ZaloMod"])
            [frameworks addObject:name];
    }
    NSMutableArray *scenes=[NSMutableArray array];
    NSMutableDictionary *views=[NSMutableDictionary dictionary];
    NSMutableArray *activeInputs=[NSMutableArray array];
    NSUInteger budget=1000;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:[UIWindowScene class]])continue;
        UIWindowScene *windowScene=(UIWindowScene *)scene;
        for(UIWindow *window in windowScene.windows){
            if(window.hidden || window.windowLevel!=UIWindowLevelNormal)continue;
            [scenes addObject:@{
                @"keyWindow":@(window.isKeyWindow),
                @"viewControllerTree":PHKProbeControllerTree(window.rootViewController,0)
            }];
            PHKProbeViews(window,views,activeInputs,&budget);
        }
    }
    NSArray *sorted=[views keysSortedByValueUsingComparator:
        ^NSComparisonResult(NSNumber *a,NSNumber *b){return [b compare:a];}];
    NSMutableArray *topClasses=[NSMutableArray array];
    for(NSString *name in sorted){
        if(topClasses.count>=80)break;
        [topClasses addObject:@{@"class":name,@"count":views[name]}];
    }
    NSMutableDictionary *report=[@{
        @"PHKRuntimeProbe":@"1",
        @"appBundleID":bundle[@"CFBundleIdentifier"]?:@"",
        @"appBuild":bundle[@"CFBundleVersion"]?:@"",
        @"appVersion":bundle[@"CFBundleShortVersionString"]?:@"",
        @"loadedRelevantLibraries":frameworks,
        @"knownClasses":knownClasses,
        @"foregroundScenes":scenes,
        @"visibleViewTypes":topClasses,
        @"activeComposerHierarchy":activeInputs,
        @"viewsInspected":@(1000-budget),
        @"includesAccountTokens":@NO,
        @"notes":@"Runtime structure only. No method offsets, hook invocation, or server-side feature success is asserted."
    } mutableCopy];
    NSError *error=nil;
    NSData *json=[NSJSONSerialization dataWithJSONObject:report
                options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys
                error:&error];
    return json?[[NSString alloc]initWithData:json encoding:NSUTF8StringEncoding]:
        (error.localizedDescription ?: @"{}");
}
