#import "PHKBridge.h"
#include "../../../Core/Settings.hpp"
#include <cstdint>

@implementation PHKCore
+ (NSInteger)normalizeTTLWithValue:(NSInteger)value unit:(NSInteger)unit {
    if (value <= 0) return 0;
    if (value > INT32_MAX) value = INT32_MAX;
    if (unit < 0 || unit > 2) return 0;
    return phk::normalizeTTL(static_cast<int>(value), static_cast<int>(unit));
}
+ (NSInteger)nextTabIndexWithCurrent:(NSInteger)current count:(NSInteger)count dragPoints:(double)dragPoints {
    if (count < 1 || count > 32) return 0;
    const NSInteger bounded = MIN(MAX(current, 0), count - 1);
    return phk::nextTabIndex(static_cast<int>(bounded), static_cast<int>(count), dragPoints);
}
+ (NSString *)coreVersion {
    const auto version = phk::version();
    return [NSString stringWithUTF8String:version.c_str()];
}
@end
