#import <Foundation/Foundation.h>
@interface PHKCore : NSObject
+ (NSInteger)normalizeTTLWithValue:(NSInteger)value unit:(NSInteger)unit;
+ (NSInteger)nextTabIndexWithCurrent:(NSInteger)current count:(NSInteger)count dragPoints:(double)dragPoints;
+ (NSString * _Nonnull)coreVersion;
@end
