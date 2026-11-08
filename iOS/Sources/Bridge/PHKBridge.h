#import <Foundation/Foundation.h>
@interface PHKCore : NSObject
+ (NSInteger)normalizeTTLWithValue:(NSInteger)value unit:(NSInteger)unit;
+ (NSString * _Nonnull)coreVersion;
@end
