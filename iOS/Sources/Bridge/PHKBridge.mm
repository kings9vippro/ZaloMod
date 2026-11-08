#import "PHKBridge.h"
#include "../../../Core/Settings.hpp"
@implementation PHKCore
+ (NSInteger)normalizeTTLWithValue:(NSInteger)value unit:(NSInteger)unit {
    // Clamp before narrowing NSInteger (64-bit) to int.
    if (value <= 0) return 0;
    if (value > INT32_MAX) value = INT32_MAX;
    return phk::normalizeTTL(static_cast<int>(value), static_cast<int>(unit));
}
+ (NSString *)coreVersion {
    const auto version = phk::version();
    return [NSString stringWithUTF8String:version.c_str()];
}
@end
