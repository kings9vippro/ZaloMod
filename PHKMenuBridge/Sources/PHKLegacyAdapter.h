#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface PHKLegacyAdapter : NSObject
+ (instancetype)shared;
- (BOOL)isAvailable;
- (BOOL)readFlag:(NSString *)selectorName;
- (BOOL)applyToggle:(NSString *)actionName sender:(UISwitch *)sender;
- (BOOL)applyAction:(NSString *)actionName;
- (BOOL)setLegacyText:(NSString *)value field:(NSString *)field;
- (BOOL)applyTTL:(NSString *)value unit:(NSInteger)unit;
- (BOOL)applyBotPrefix:(NSString *)value;
- (NSArray<UIButton *> *)legacyOptions:(NSString *)kind;
- (BOOL)applyLegacyOption:(UIButton *)button kind:(NSString *)kind;
- (BOOL)applyFontSize:(NSString *)value;
- (nullable NSString *)accountDescription;
- (void)openOriginalMenuFrom:(UIViewController *)presenter;
- (void)hideFloatingButtonIfPresent;
@end
NS_ASSUME_NONNULL_END
