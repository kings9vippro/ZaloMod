#import "PHKComposerController.h"
#import "PHKMessageBridge.h"
#import <QuartzCore/QuartzCore.h>
#import <cmath>

@interface PHKComposerController () <UITextViewDelegate,UITextFieldDelegate>
@property(nonatomic,strong) UISegmentedControl *type;
@property(nonatomic,strong) UITextField *recipientField;
@property(nonatomic,strong) UITextView *messageView;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UILabel *delayText;
@property(nonatomic,strong) UISlider *delaySlider;
@property(nonatomic) CFTimeInterval lastHaptic;
@end

@implementation PHKComposerController
- (UILabel *)label:(NSString *)value size:(CGFloat)size {
    UILabel *result=[UILabel new];
    result.text=value;result.textColor=UIColor.whiteColor;
    result.font=[UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    result.numberOfLines=0;
    return result;
}
- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    button.backgroundColor=[UIColor colorWithWhite:1 alpha:.12];
    button.layer.cornerRadius=14;
    [button.heightAnchor constraintEqualToConstant:44].active=YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}
- (void)loadView {
    UIView *root=[UIView new];
    root.backgroundColor=[UIColor colorWithRed:.065 green:.075 blue:.105 alpha:1];
    self.view=root;
    UIScrollView *scroll=[UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints=NO;
    scroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    [root addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:root.trailingAnchor]
    ]];
    UIStackView *stack=[UIStackView new];
    stack.axis=UILayoutConstraintAxisVertical;stack.spacing=15;
    stack.translatesAutoresizingMaskIntoConstraints=NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:21],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-21],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:18],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-32],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-42]
    ]];
    [stack addArrangedSubview:[self label:@"Soạn tin nhắn · PHK" size:21]];
    UILabel *disclaimer=[self label:@"Chỉ gửi đến đích đã được ứng dụng chủ cấp quyền. Không đọc cookie hoặc tự lấy danh sách nhóm." size:12];
    disclaimer.textColor=[UIColor colorWithWhite:1 alpha:.67];
    [stack addArrangedSubview:disclaimer];
    self.type=[[UISegmentedControl alloc]initWithItems:@[@"Chat riêng",@"Nhóm"]];
    self.type.selectedSegmentIndex=0;
    [stack addArrangedSubview:self.type];
    self.recipientField=[UITextField new];
    self.recipientField.attributedPlaceholder=[[NSAttributedString alloc]
        initWithString:@"Chọn người nhận hoặc nhập ID đã được cấp quyền"
        attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1 alpha:.48]}];
    self.recipientField.textColor=UIColor.whiteColor;
    self.recipientField.font=[UIFont systemFontOfSize:14];
    self.recipientField.backgroundColor=[UIColor colorWithWhite:1 alpha:.11];
    self.recipientField.layer.cornerRadius=12;
    self.recipientField.delegate=self;
    self.recipientField.autocorrectionType=UITextAutocorrectionTypeNo;
    self.recipientField.autocapitalizationType=UITextAutocapitalizationTypeNone;
    self.recipientField.accessibilityLabel=@"ID người nhận";
    [self.recipientField.heightAnchor constraintEqualToConstant:46].active=YES;
    [stack addArrangedSubview:self.recipientField];
    [stack addArrangedSubview:[self button:@"Chọn từ danh sách hợp lệ" action:@selector(chooseRecipient)]];
    [stack addArrangedSubview:[self label:@"Nội dung" size:13]];
    self.messageView=[UITextView new];
    self.messageView.font=[UIFont systemFontOfSize:15];
    self.messageView.textColor=UIColor.whiteColor;
    self.messageView.backgroundColor=[UIColor colorWithWhite:1 alpha:.095];
    self.messageView.layer.cornerRadius=13;
    self.messageView.delegate=self;
    self.messageView.accessibilityLabel=@"Nội dung tin nhắn";
    self.messageView.textContainerInset=UIEdgeInsetsMake(11,10,10,10);
    [self.messageView.heightAnchor constraintEqualToConstant:120].active=YES;
    [stack addArrangedSubview:self.messageView];
    self.delayText=[self label:@"Delay: 3 giây" size:12];
    [stack addArrangedSubview:self.delayText];
    self.delaySlider=[UISlider new];
    self.delaySlider.minimumValue=1;
    self.delaySlider.maximumValue=60;
    float saved=[NSUserDefaults.standardUserDefaults floatForKey:
                    @"dev.phananhkhoi.independent.delay"];
    self.delaySlider.value=saved>=1&&saved<=60?saved:3;
    [self.delaySlider addTarget:self action:@selector(delayUpdated:)
               forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.delaySlider];
    [self delayUpdated:self.delaySlider];
    [stack addArrangedSubview:[self button:@"Xác nhận gửi một tin" action:@selector(sendOne)]];
    [stack addArrangedSubview:[self button:@"Hủy các tin đang chờ" action:@selector(cancelPending)]];
    self.status=[self label:PHKIndependentHasSender()?
       @"Đã kết nối bộ gửi. Hãy chọn người nhận được cấp quyền.":
       @"Chưa kết nối API gửi tin: thao tác gửi hiện bị khóa." size:12];
    self.status.textColor=[UIColor colorWithWhite:1 alpha:.76];
    [stack addArrangedSubview:self.status];
    UIButton *done=[self button:@"Đóng" action:@selector(close)];
    [stack addArrangedSubview:done];
}
- (void)delayUpdated:(UISlider *)sender {
    NSInteger rounded=MAX(1,MIN(60,(NSInteger)lround(sender.value)));
    self.delayText.text=[NSString stringWithFormat:@"Delay: %ld giây",(long)rounded];
    [NSUserDefaults.standardUserDefaults setInteger:rounded
       forKey:@"dev.phananhkhoi.independent.delay"];
}
- (void)chooseRecipient {
    NSArray<NSDictionary *> *available=PHKIndependentTargets();
    BOOL group=self.type.selectedSegmentIndex==1;
    UIAlertController *picker=[UIAlertController alertControllerWithTitle:
        group?@"Nhóm được cấp quyền":@"Chat riêng được cấp quyền"
        message:available.count?@"Chọn một đích được ứng dụng chủ cung cấp":
                                @"Chưa có danh sách người nhận. Không thể tự đọc danh bạ Zalo."
        preferredStyle:UIAlertControllerStyleActionSheet];
    NSUInteger added=0;
    for(NSDictionary *recipient in available){
        if([recipient[@"isGroup"] boolValue]!=group)continue;
        NSString *name=recipient[@"name"];
        NSString *identifier=recipient[@"id"];
        if(![identifier isKindOfClass:[NSString class]] ||
           ![name isKindOfClass:[NSString class]])continue;
        [picker addAction:[UIAlertAction actionWithTitle:name
            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                (void)action;self.recipientField.text=identifier;
            }]];
        if(++added>=25)break;
    }
    [picker addAction:[UIAlertAction actionWithTitle:@"Đóng"
        style:UIAlertActionStyleCancel handler:nil]];
    picker.popoverPresentationController.sourceView=self.view;
    picker.popoverPresentationController.sourceRect=
        CGRectMake(CGRectGetMidX(self.view.bounds),CGRectGetMidY(self.view.bounds),1,1);
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)sendOne {
    [self.view endEditing:YES];
    NSString *target=[self.recipientField.text
       stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *message=[self.messageView.text
       stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(target.length==0||message.length==0){
        self.status.text=@"Nhập đầy đủ đích đến và nội dung.";return;
    }
    __weak PHKComposerController *weakSelf=self;
    BOOL queued=PHKIndependentSendTo(target,self.type.selectedSegmentIndex==1,
        message,self.delaySlider.value,^(BOOL success,NSString *status){
            dispatch_async(dispatch_get_main_queue(),^{
                weakSelf.status.text=status;
                weakSelf.status.textColor=success?
                    [UIColor colorWithRed:.36 green:.89 blue:.72 alpha:1]:
                    [UIColor colorWithRed:1 green:.62 blue:.64 alpha:1];
            });
        });
    self.status.text=queued?@"Đã xếp một tin vào hàng chờ. Có thể hủy trước khi gửi.":
       @"Không gửi: chưa có kết nối hoặc người nhận không nằm trong danh sách được cấp quyền.";
}
- (void)cancelPending {
    PHKIndependentCancelPending();
    self.status.text=@"Đã hủy các lịch gửi chưa thực hiện.";
}
- (void)textViewDidChange:(UITextView *)textView {
    if(textView.text.length>1024){
        textView.text=[textView.text substringToIndex:1024];
    }
    CFTimeInterval now=CACurrentMediaTime();
    if(now-self.lastHaptic>=.12 && !NSProcessInfo.processInfo.lowPowerModeEnabled){
        self.lastHaptic=now;
        [[[UISelectionFeedbackGenerator alloc]init] selectionChanged];
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {
    [field resignFirstResponder];[self.messageView becomeFirstResponder];return YES;
}
- (void)close {[self dismissViewControllerAnimated:YES completion:nil];}
@end
