#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
#ifdef __cplusplus
extern "C" {
#endif
typedef void (^PHKSendCompletion)(BOOL success,NSString *status);
typedef void (^PHKSendHandler)(NSString *recipientID,BOOL group,NSString *message,PHKSendCompletion completion);
/// Explicit integration contract for an app owned or authorized by the user.
/// No private chat API interception, session extraction, or automatic group enumeration.
FOUNDATION_EXPORT void PHKIndependentRegisterSender(PHKSendHandler _Nullable handler);
/// Allowed destinations: dictionaries with keys "id" (NSString), "name" (NSString), "isGroup" (NSNumber).
FOUNDATION_EXPORT void PHKIndependentSetTargets(NSArray<NSDictionary *> * _Nullable targets);
FOUNDATION_EXPORT NSArray<NSDictionary *> *PHKIndependentTargets(void);
FOUNDATION_EXPORT BOOL PHKIndependentHasSender(void);
/// Schedules one opt-in message with a 1-60s delay; false means not queued.
FOUNDATION_EXPORT BOOL PHKIndependentSendTo(NSString *targetID,BOOL group,
    NSString *message,NSTimeInterval delay,PHKSendCompletion _Nullable completion);
FOUNDATION_EXPORT void PHKIndependentCancelPending(void);
#ifdef __cplusplus
}
#endif
NS_ASSUME_NONNULL_END
