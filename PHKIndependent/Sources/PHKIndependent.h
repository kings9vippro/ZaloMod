#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Pure UIView/UITabBarController integration. No ZaloModVIP dependency.
FOUNDATION_EXPORT const char *PHKIndependentVersion(void);
FOUNDATION_EXPORT int PHKIndependentLoaded(void);
/// Opens an app-local settings panel; no private session access.
FOUNDATION_EXPORT void PHKIndependentShowMenu(void);
/// Renders a transparent-corner 512px PNG from an image the caller owns.
FOUNDATION_EXPORT NSData * _Nullable PHKIndependentStickerPNG(UIImage *source);
/// Only parses commands. A host application must supply a permitted reply image and send integration.
FOUNDATION_EXPORT NSInteger PHKIndependentParseCommand(NSString *command,BOOL hasRepliedImage);
/** Execute a LOCAL UI command provided explicitly by an authorized host.
    outSticker receives a PNG for a supplied reply photo; uploading is the host's job.
    This does not hook private chat messages or call zSticker AI. */
FOUNDATION_EXPORT NSString *PHKIndependentRunLocalCommand(
    NSString *command,UIImage * _Nullable repliedImage,
    NSData * _Nullable * _Nullable outSticker);

/// Opt-in delivery callback; requires an authorized host to supply the actual sending function.
FOUNDATION_EXPORT BOOL PHKIndependentSchedule(NSString *message,NSTimeInterval delay,void (^callback)(NSString *message));
NS_ASSUME_NONNULL_END
