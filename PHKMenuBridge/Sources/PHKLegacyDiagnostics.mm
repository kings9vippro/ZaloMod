#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Reports ABI compatibility ONLY: no cookie access, no user data and no hook execution.
extern "C" __attribute__((visibility("default")))
NSDictionary<NSString *,id> *PHKLegacyCompatibilityReport(void) {
    Class controller=NSClassFromString(@"ZaloModViewController");
    NSArray<NSString *> *actions=@[
        @"toggleAntiUndo:",@"toggleBugOriginal:",@"toggleGhostSeen:",
        @"toggleHideTyping:",@"toggleAntiRain:",@"toggleChatBg:",
        @"toggleBlockZStyle:",@"toggleBugZLStyle:",@"toggleBugZBusiness:",
        @"toggleAdBlock:",@"toggleUnlimitedMedia:",@"toggleUnlockRBT:",
        @"toggleProfileMusic:"
    ];
    NSArray<NSString *> *readers=@[
        @"isAntiUndoEnabled",@"isBugOriginalEnabled",@"isGhostSeenEnabled",
        @"isHideTypingEnabled",@"isAntiRainEnabled",@"isChatBgEnabled",
        @"isBlockZStyleEnabled",@"isBugZLStyleEnabled",@"isBugZBusinessEnabled",
        @"isAdBlockEnabled",@"isUnlimitedMediaEnabled",@"isUnlockRBTEnabled",
        @"isProfileMusicEnabled"
    ];
    if(!controller) return @{@"classPresent":@NO, @"compatibleToggles":@0,
        @"totalToggles":@(actions.count), @"featureOperational":@NO};
    Class meta=object_getClass(controller);
    NSUInteger compatible=0;
    NSMutableArray *details=[NSMutableArray arrayWithCapacity:actions.count];
    for(NSUInteger i=0;i<actions.count;i++){
        Method a=class_getInstanceMethod(controller,NSSelectorFromString(actions[i]));
        Method b=class_getInstanceMethod(meta,NSSelectorFromString(readers[i]));
        BOOL setOK=NO,getOK=NO;
        if(a&&method_getNumberOfArguments(a)==3){
            char result[16]={0},arg[16]={0};
            method_getReturnType(a,result,sizeof(result));
            method_getArgumentType(a,2,arg,sizeof(arg));
            setOK=(result[0]=='v'&&arg[0]=='@');
        }
        if(b&&method_getNumberOfArguments(b)==2){
            char result[16]={0};
            method_getReturnType(b,result,sizeof(result));
            getOK=(result[0]=='B'||result[0]=='c');
        }
        BOOL good=setOK&&getOK;
        compatible+=(NSUInteger)good;
        [details addObject:@{@"name":actions[i],@"setterABI":@(setOK),
            @"readerABI":@(getOK),@"compatible":@(good)}];
    }
    return @{@"classPresent":@YES, @"compatibleToggles":@(compatible),
        @"totalToggles":@(actions.count),@"items":details,
        @"featureOperational":@NO,
        @"note":@"ABI verified; hook activation and server outcomes not tested"};
}
