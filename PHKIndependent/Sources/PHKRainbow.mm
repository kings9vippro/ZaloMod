#import "PHKRainbow.h"
#import <QuartzCore/QuartzCore.h>
#import "../Core/PHKCore.hpp"

static NSString * const PHKRainbowKey=@"dev.phananhkhoi.independent.rainbow";
static NSArray *PHKColorsAtOffset(NSUInteger shift){
    NSMutableArray *array=[NSMutableArray arrayWithCapacity:8];
    for(NSUInteger i=0;i<=7;i++){
        const auto rgb=phk::paletteAt(i+shift);
        [array addObject:(__bridge id)[UIColor colorWithRed:rgb.r/255.0
                green:rgb.g/255.0 blue:rgb.b/255.0 alpha:1].CGColor];
    }
    return array;
}
void PHKStyleRainbow(CAGradientLayer *layer, BOOL animate){
    if(!layer)return;
    NSArray *colors=PHKColorsAtOffset(0);
    layer.colors=colors;
    layer.startPoint=CGPointMake(0,0.5);
    layer.endPoint=CGPointMake(1,0.5);
    [layer removeAnimationForKey:@"phk-rainbow"];
    BOOL powerSave=NSProcessInfo.processInfo.lowPowerModeEnabled;
    if(!animate || UIAccessibilityIsReduceMotionEnabled() || powerSave)return;
    NSMutableArray *frames=[NSMutableArray arrayWithCapacity:8];
    for(NSUInteger i=0;i<=7;i++) [frames addObject:PHKColorsAtOffset(i)];
    CAKeyframeAnimation *cycle=[CAKeyframeAnimation animationWithKeyPath:@"colors"];
    cycle.values=frames;
    cycle.duration=8.5;
    cycle.calculationMode=kCAAnimationLinear;
    cycle.repeatCount=HUGE_VALF;
    cycle.removedOnCompletion=NO;
    [layer addAnimation:cycle forKey:@"phk-rainbow"];
}
@interface PHKRainbowBrand ()
@property(nonatomic,strong) CAGradientLayer *gradient;
@property(nonatomic,strong) CATextLayer *textMask;
@end
@implementation PHKRainbowBrand
- (instancetype)initWithFrame:(CGRect)frame{
    if((self=[super initWithFrame:frame])){
        self.layer.cornerRadius=12;
        self.layer.masksToBounds=YES;
        self.backgroundColor=[UIColor colorWithRed:.07 green:.08 blue:.11 alpha:.90];
        _gradient=[CAGradientLayer layer];
        _textMask=[CATextLayer layer];
        _textMask.contentsScale=UIScreen.mainScreen.scale;
        _textMask.alignmentMode=kCAAlignmentCenter;
        _textMask.truncationMode=kCATruncationEnd;
        _textMask.wrapped=NO;
        _textMask.string=[[NSAttributedString alloc] initWithString:@"Developer Phan Anh Khôi"
              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:11 weight:UIFontWeightSemibold],
                           NSForegroundColorAttributeName:UIColor.whiteColor}];
        _gradient.mask=_textMask;
        [self.layer addSublayer:_gradient];
        self.isAccessibilityElement=YES;
        self.accessibilityLabel=@"Developer Phan Anh Khôi";
        [self updateAppearance];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    [CATransaction begin];[CATransaction setDisableActions:YES];
    self.gradient.frame=self.bounds;
    self.textMask.frame=CGRectInset(self.bounds,3,4);
    [CATransaction commit];
}
- (void)updateAppearance{
    id setting=[NSUserDefaults.standardUserDefaults objectForKey:PHKRainbowKey];
    BOOL enabled=setting?[setting boolValue]:YES;
    BOOL shouldAnimate=enabled && self.window!=nil &&
         !UIAccessibilityIsReduceMotionEnabled() &&
         !NSProcessInfo.processInfo.lowPowerModeEnabled;
    if(shouldAnimate && ![self.gradient animationForKey:@"phk-rainbow"])
        PHKStyleRainbow(self.gradient,YES);
    else if(!shouldAnimate && [self.gradient animationForKey:@"phk-rainbow"])
        PHKStyleRainbow(self.gradient,NO);
    if(!enabled){
        NSInteger index=[NSUserDefaults.standardUserDefaults
                          integerForKey:@"dev.phananhkhoi.independent.accent"];
        const auto rgb=phk::paletteAt((std::uint64_t)MAX(0,index));
        id shade=(__bridge id)[UIColor colorWithRed:rgb.r/255.0
              green:rgb.g/255.0 blue:rgb.b/255.0 alpha:1].CGColor;
        self.gradient.colors=@[shade,shade];
    } else if(!shouldAnimate){
        self.gradient.colors=PHKColorsAtOffset(0);
    }
    [self setNeedsLayout];
}
- (void)didMoveToWindow{
    [super didMoveToWindow];
    [self updateAppearance];
}
@end
