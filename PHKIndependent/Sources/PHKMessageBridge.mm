#import "PHKMessageBridge.h"
#import "../Core/PHKCore.hpp"
#import <cmath>

static PHKSendHandler sSender=nil;
static NSArray<NSDictionary *> *sTargets=nil;
static NSUInteger sOutstanding=0;
static NSUInteger sGeneration=0;

static BOOL PHKIsValidDestination(NSDictionary *item){
    if(![item isKindOfClass:[NSDictionary class]])return NO;
    NSString *idValue=item[@"id"];
    NSString *name=item[@"name"];
    NSNumber *type=item[@"isGroup"];
    return [idValue isKindOfClass:[NSString class]] &&
        idValue.length>0 && idValue.length<=128 &&
        [name isKindOfClass:[NSString class]] && name.length>0 && name.length<=128 &&
        [type isKindOfClass:[NSNumber class]];
}
extern "C" __attribute__((visibility("default"))) void PHKIndependentRegisterSender(PHKSendHandler handler){
    if(!NSThread.isMainThread){
        dispatch_async(dispatch_get_main_queue(),^{PHKIndependentRegisterSender(handler);});
        return;
    }
    sSender=[handler copy];
}
extern "C" __attribute__((visibility("default"))) void PHKIndependentSetTargets(NSArray<NSDictionary *> *targets){
    if(!NSThread.isMainThread){
        NSArray *copy=[targets copy];
        dispatch_async(dispatch_get_main_queue(),^{PHKIndependentSetTargets(copy);});
        return;
    }
    NSMutableArray *allowed=[NSMutableArray arrayWithCapacity:MIN(50,targets.count)];
    NSMutableSet *seen=[NSMutableSet set];
    for(NSDictionary *item in targets){
        if(allowed.count>=50)break;
        if(!PHKIsValidDestination(item))continue;
        NSString *key=[NSString stringWithFormat:@"%@:%d",item[@"id"],[item[@"isGroup"] boolValue]];
        if([seen containsObject:key])continue;
        [seen addObject:key];
        [allowed addObject:@{@"id":[item[@"id"] copy],
                            @"name":[item[@"name"] copy],
                            @"isGroup":@([item[@"isGroup"] boolValue])}];
    }
    sTargets=[allowed copy];
}
extern "C" __attribute__((visibility("default"))) NSArray<NSDictionary *> *PHKIndependentTargets(void){
    if(NSThread.isMainThread)return sTargets?:@[];
    __block NSArray<NSDictionary *> *copy;
    dispatch_sync(dispatch_get_main_queue(),^{copy=sTargets?:@[];});
    return copy;
}
extern "C" __attribute__((visibility("default"))) BOOL PHKIndependentHasSender(void){
    if(NSThread.isMainThread)return sSender!=nil;
    __block BOOL ready=NO;
    dispatch_sync(dispatch_get_main_queue(),^{ready=sSender!=nil;});
    return ready;
}
extern "C" __attribute__((visibility("default"))) BOOL PHKIndependentSendTo(NSString *targetID,BOOL group,
       NSString *message,NSTimeInterval delay,PHKSendCompletion completion){
    if(!NSThread.isMainThread){
        __block BOOL queued=NO;
        dispatch_sync(dispatch_get_main_queue(),^{
            queued=PHKIndependentSendTo(targetID,group,message,delay,completion);
        });
        return queued;
    }
    if(!sSender || ![targetID isKindOfClass:[NSString class]] ||
       ![message isKindOfClass:[NSString class]] ||
       targetID.length==0 || targetID.length>128 ||
       message.length==0 || message.length>1024 ||
       !std::isfinite(delay) || delay<1 || delay>60)return NO;
    const auto milliseconds=(std::uint32_t)llround(delay*1000);
    if(!phk::validDelay(milliseconds,sOutstanding))return NO;
    BOOL isAllowed=NO;
    for(NSDictionary *entry in sTargets){
        if([entry[@"id"] isEqual:targetID] && [entry[@"isGroup"] boolValue]==group){
            isAllowed=YES;break;
        }
    }
    if(!isAllowed)return NO;
    const NSUInteger ticket=sGeneration;
    NSString *recipient=[targetID copy],*body=[message copy];
    PHKSendCompletion done=[completion copy];
    PHKSendHandler sender=[sSender copy];
    ++sOutstanding;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)milliseconds*1000000LL),
                   dispatch_get_main_queue(),^{
        if(ticket==sGeneration && sOutstanding>0)--sOutstanding;
        if(ticket!=sGeneration){
            if(done)done(NO,@"Đã hủy thao tác gửi.");
            return;
        }
        if(UIApplication.sharedApplication.applicationState!=UIApplicationStateActive){
            if(done)done(NO,@"Ứng dụng không ở tiền cảnh; không gửi.");
            return;
        }
        sender(recipient,group,body,^(BOOL success,NSString *status){
            if(done)done(success,[status isKindOfClass:[NSString class]]?status:
                 (success?@"Đã gửi theo xác nhận của ứng dụng chủ.":@"Ứng dụng chủ báo lỗi."));
        });
    });
    return YES;
}
extern "C" __attribute__((visibility("default"))) void PHKIndependentCancelPending(void){
    if(!NSThread.isMainThread){
        dispatch_async(dispatch_get_main_queue(),^{PHKIndependentCancelPending();});return;
    }
    ++sGeneration;
    sOutstanding=0;
}
