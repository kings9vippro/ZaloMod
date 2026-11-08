#import "PHKLegacyAdapter.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "../Core/PHKValidation.hpp"

// Calls only allowlisted selectors found in the original user's binary.
// Does not read, export, log, transmit or store login cookies.
static NSSet<NSString *> *PHKToggleAllowlist(void) {
    static NSSet *s; static dispatch_once_t once;
    dispatch_once(&once, ^{s=[NSSet setWithArray:@[
        @"toggleAntiUndo:",@"toggleBugOriginal:",@"toggleGhostSeen:",@"toggleHideTyping:",
        @"toggleAntiRain:",@"toggleChatBg:",@"toggleBlockZStyle:",@"toggleBugZLStyle:",
        @"toggleBugZBusiness:",@"toggleAdBlock:",@"toggleUnlimitedMedia:",
        @"toggleUnlockRBT:",@"toggleProfileMusic:"]];});
    return s;
}
static NSSet<NSString *> *PHKActionAllowlist(void) {
    static NSSet *s; static dispatch_once_t once;
    dispatch_once(&once, ^{s=[NSSet setWithArray:@[
        @"actionPickChatBackground",@"actionRemoveChatBackground",@"actionPickProfileMP3",
        @"actionToggleTestPlay",@"actionApplyFontSize",@"actionSendMessage",@"actionJoinGroup",
        @"actionKickMember",@"actionLeaveGroup",@"botRefreshAccountInfo",
        @"actionStartBot",@"actionStopBot",@"actionPreviewLockedAccount"]];});
    return s;
}
// Guard Objective-C message sends against ABI signature changes across releases.
static BOOL PHKHasMethod(Class klass, SEL selector, unsigned arguments, char resultType, BOOL objectArgument) {
    if (!klass || !selector) return NO;
    Method method=class_getInstanceMethod(klass,selector);
    if(!method || method_getNumberOfArguments(method)!=arguments)return NO;
    if(resultType){
        char result[32]={0};method_getReturnType(method,result,sizeof(result));
        if(result[0]!=resultType && !(resultType=='B' && result[0]=='c'))return NO;
    }
    if(objectArgument){
        char argument[32]={0};method_getArgumentType(method,2,argument,sizeof(argument));
        if(argument[0]!='@')return NO;
    }
    return YES;
}
static id PHKInstance(void) {
    Class type=NSClassFromString(@"ZaloModViewController");
    SEL shared=NSSelectorFromString(@"sharedInstance");
    if (!type || !PHKHasMethod(object_getClass(type),shared,2,'@',NO))return nil;
    return ((id(*)(id,SEL))objc_msgSend)(type,shared);
}
static void PHKLoadLegacyUI(id instance) {
    if (instance && [instance isKindOfClass:[UIViewController class]]){
        (void)((UIView *(*)(id,SEL))objc_msgSend)(instance,@selector(view));
    }
}
static BOOL PHKWriteTextField(id instance,NSString *prop,NSString *value) {
    SEL read=NSSelectorFromString(prop);
    if (!instance||!PHKHasMethod(object_getClass(instance),read,2,'@',NO))return NO;
    id field=((id(*)(id,SEL))objc_msgSend)(instance,read);
    if (![field isKindOfClass:[UITextField class]])return NO;
    ((UITextField *)field).text=value;
    [((UITextField *)field) sendActionsForControlEvents:UIControlEventEditingChanged];
    return YES;
}
@implementation PHKLegacyAdapter
+ (instancetype)shared {static PHKLegacyAdapter *obj;static dispatch_once_t t;dispatch_once(&t,^{obj=[PHKLegacyAdapter new];});return obj;}
- (BOOL)isAvailable {return PHKInstance()!=nil;}
- (BOOL)canToggle:(NSString *)actionName reader:(NSString *)selectorName {
    if (![PHKToggleAllowlist() containsObject:actionName])return NO;
    id instance=PHKInstance();Class type=NSClassFromString(@"ZaloModViewController");
    SEL action=NSSelectorFromString(actionName),reader=NSSelectorFromString(selectorName);
    return instance && type &&
        PHKHasMethod(object_getClass(instance),action,3,'v',YES) &&
        PHKHasMethod(object_getClass(type),reader,2,'B',NO);
}
- (BOOL)readFlag:(NSString *)selectorName {
    static NSSet *allowed; static dispatch_once_t once;
    dispatch_once(&once, ^{allowed=[NSSet setWithArray:@[
        @"isAntiUndoEnabled",@"isBugOriginalEnabled",@"isGhostSeenEnabled",
        @"isHideTypingEnabled",@"isAntiRainEnabled",@"isChatBgEnabled",
        @"isBlockZStyleEnabled",@"isBugZLStyleEnabled",@"isBugZBusinessEnabled",
        @"isAdBlockEnabled",@"isUnlimitedMediaEnabled",@"isUnlockRBTEnabled",
        @"isProfileMusicEnabled",@"isBotRunning"]];});
    if (![allowed containsObject:selectorName])return NO;
    Class c=NSClassFromString(@"ZaloModViewController");SEL s=NSSelectorFromString(selectorName);
    if(!PHKHasMethod(object_getClass(c),s,2,'B',NO))return NO;
    return ((BOOL(*)(id,SEL))objc_msgSend)(c,s);
}
- (BOOL)applyToggle:(NSString *)actionName sender:(UISwitch *)sender {
    if (![PHKToggleAllowlist() containsObject:actionName])return NO;
    id vc=PHKInstance();SEL s=NSSelectorFromString(actionName);
    if(!vc || !PHKHasMethod(object_getClass(vc),s,3,'v',YES))return NO;
    PHKLoadLegacyUI(vc);
    ((void(*)(id,SEL,id))objc_msgSend)(vc,s,sender);return YES;
}
- (BOOL)applyAction:(NSString *)actionName {
    if(![PHKActionAllowlist() containsObject:actionName])return NO;
    id vc=PHKInstance();SEL s=NSSelectorFromString(actionName);
    if(!vc||!PHKHasMethod(object_getClass(vc),s,2,0,NO))return NO;
    PHKLoadLegacyUI(vc);
    ((void(*)(id,SEL))objc_msgSend)(vc,s);return YES;
}
- (BOOL)setLegacyText:(NSString *)value field:(NSString *)field {
    NSSet *allowed=[NSSet setWithArray:@[@"txtTargetId",@"txtMessageContent",@"txtGroupLinkOrId",@"txtKickUid",@"txtBanUid",@"txtSongName",@"txtArtistName"]];
    if(![allowed containsObject:field])return NO;
    id vc=PHKInstance(); PHKLoadLegacyUI(vc);
    return PHKWriteTextField(vc,field,value ?: @"");
}
- (BOOL)applyTTL:(NSString *)value unit:(NSInteger)unit {
    std::int64_t milli=0;
    if (!phk::validTTL((value?:@"").UTF8String,(int)unit,&milli))return NO;
    id vc=PHKInstance();PHKLoadLegacyUI(vc);
    if(!PHKWriteTextField(vc,@"txtTTLValue",value))return NO;
    SEL getter=NSSelectorFromString(@"ttlSegment");
    if (![vc respondsToSelector:getter])return NO;
    id seg=((id(*)(id,SEL))objc_msgSend)(vc,getter);
    if (![seg isKindOfClass:[UISegmentedControl class]])return NO;
    ((UISegmentedControl *)seg).selectedSegmentIndex=unit+1; // original segments: Off, Seconds, Hours, Days
    SEL changed=NSSelectorFromString(@"ttlUnitChanged:");
    if([vc respondsToSelector:changed])((void(*)(id,SEL,id))objc_msgSend)(vc,changed,seg);
    SEL apply=NSSelectorFromString(@"actionApplyTTL");
    if(![vc respondsToSelector:apply])return NO;
    ((void(*)(id,SEL))objc_msgSend)(vc,apply);
    return YES;
}
- (BOOL)applyBotPrefix:(NSString *)value {
    if(!phk::validPrefix((value?:@"").UTF8String))return NO;
    id vc=PHKInstance();PHKLoadLegacyUI(vc);
    if(!PHKWriteTextField(vc,@"txtBotPrefix",value))return NO;
    SEL apply=NSSelectorFromString(@"actionApplyBotPrefix");
    if(![vc respondsToSelector:apply])return NO;
    ((void(*)(id,SEL))objc_msgSend)(vc,apply);return YES;
}
- (NSArray<UIButton *> *)legacyOptions:(NSString *)kind {
    if(![@[@"font",@"color"] containsObject:kind])return @[];
    id vc=PHKInstance();PHKLoadLegacyUI(vc);
    SEL getter=NSSelectorFromString([kind isEqualToString:@"font"]?@"fontButtons":@"colorButtons");
    if(!vc||![vc respondsToSelector:getter])return @[];
    id original=((id(*)(id,SEL))objc_msgSend)(vc,getter);
    if(![original isKindOfClass:[NSArray class]])return @[];
    NSMutableArray *out=[NSMutableArray new];
    for(id x in original)if([x isKindOfClass:[UIButton class]])[out addObject:x];
    return out;
}
- (BOOL)applyLegacyOption:(UIButton *)button kind:(NSString *)kind {
    if (!button||![@[@"font",@"color"] containsObject:kind])return NO;
    id vc=PHKInstance();SEL sel=NSSelectorFromString([kind isEqualToString:@"font"]?@"fontButtonTapped:":@"colorButtonClicked:");
    if(!vc||![vc respondsToSelector:sel])return NO;
    ((void(*)(id,SEL,id))objc_msgSend)(vc,sel,button);return YES;
}
- (BOOL)applyFontSize:(NSString *)value {
    NSInteger size=value.integerValue;
    if(size<10||size>60||![value isEqualToString:[NSString stringWithFormat:@"%ld",(long)size]])return NO;
    id vc=PHKInstance();PHKLoadLegacyUI(vc);
    if(!PHKWriteTextField(vc,@"txtFontSize",value))return NO;
    SEL apply=NSSelectorFromString(@"actionApplyFontSize");
    if(![vc respondsToSelector:apply])return NO;
    ((void(*)(id,SEL))objc_msgSend)(vc,apply);return YES;
}
- (NSString *)accountDescription {
    id vc=PHKInstance();if(!vc)return nil;
    SEL a=NSSelectorFromString(@"botSelfName");
    if(![vc respondsToSelector:a])return @"Phiên hiện tại";
    id name=((id(*)(id,SEL))objc_msgSend)(vc,a);
    return [name isKindOfClass:[NSString class]] && [name length] ? name : @"Phiên hiện tại";
}
- (void)openOriginalMenuFrom:(UIViewController *)presenter {
    id vc=PHKInstance();SEL s=NSSelectorFromString(@"showMenuFromViewController:");
    if(vc&&[vc respondsToSelector:s])((void(*)(id,SEL,id))objc_msgSend)(vc,s,presenter);
}
- (void)hideFloatingButtonIfPresent {
    Class c=NSClassFromString(@"ZaloFloatingButton");SEL shared=NSSelectorFromString(@"sharedInstance");
    if (!c||![c respondsToSelector:shared])return;
    id b=((id(*)(id,SEL))objc_msgSend)(c,shared);
    SEL hide=NSSelectorFromString(@"hide");
    if (b&&[b respondsToSelector:hide])((void(*)(id,SEL))objc_msgSend)(b,hide);
}
@end
