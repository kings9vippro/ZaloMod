#import "PHKOverlayController.h"
#import "PHKLegacyAdapter.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static UIColor *PHKInk(void){return [UIColor colorWithRed:0.035 green:0.055 blue:0.095 alpha:1];}
static UIColor *PHKBlue(void){return [UIColor colorWithRed:0.34 green:0.85 blue:0.99 alpha:1];}
static UIColor *PHKMuted(void){return [UIColor colorWithRed:0.72 green:0.79 blue:0.86 alpha:1];}
static UIFont *PHKFont(CGFloat size,UIFontWeight weight){return [UIFont systemFontOfSize:size weight:weight];}
static UIImage *PHKImage(NSString *name) {
    NSString *base=[[NSBundle mainBundle] pathForResource:@"PHKMenuResources" ofType:@"bundle" inDirectory:@"Frameworks"];
    if(!base)base=[[NSBundle mainBundle] pathForResource:@"PHKMenuResources" ofType:@"bundle"];
    NSString *path=[base stringByAppendingPathComponent:name];
    return path ? [UIImage imageWithContentsOfFile:path]:nil;
}
@interface PHKOverlayController () <UITextFieldDelegate, UIGestureRecognizerDelegate>
@property(nonatomic,copy) dispatch_block_t onClose;
@property(nonatomic,strong) UIView *sheet;
@property(nonatomic,strong) UIStackView *content;
@property(nonatomic,strong) UIStackView *chips;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,copy) NSString *selected;
@property(nonatomic,strong) NSMutableDictionary<NSString *,UITextField *> *fields;
@property(nonatomic,strong) UISegmentedControl *ttlUnit;
@property(nonatomic,strong) UILabel *actionFeedback;
@end
@implementation PHKOverlayController
- (instancetype)initWithCloseHandler:(dispatch_block_t)closeHandler {
    if((self=[super initWithNibName:nil bundle:nil])){
        _onClose=[closeHandler copy];_selected=@"Tin nhắn";_fields=[NSMutableDictionary dictionary];
        self.modalPresentationStyle=UIModalPresentationOverFullScreen;
    }return self;
}
- (UILabel *)label:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *v=[UILabel new];v.text=text;v.textColor=color;v.font=PHKFont(size,weight);
    v.numberOfLines=0;v.adjustsFontForContentSizeCategory=YES;return v;
}
- (UIView *)card {
    UIView *v=[UIView new];v.backgroundColor=[UIColor colorWithWhite:1 alpha:0.085];
    v.layer.cornerRadius=16;v.layer.borderWidth=.65;
    v.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.11].CGColor;
    return v;
}
- (UIButton *)button:(NSString *)title system:(NSString *)symbol {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    b.tintColor=[UIColor whiteColor];b.titleLabel.font=PHKFont(14,UIFontWeightSemibold);
    [b setTitle:title forState:UIControlStateNormal];
    if(@available(iOS 13.0,*)){
       b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
       if(symbol.length)[b setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
    }
    b.backgroundColor=[UIColor colorWithRed:.14 green:.21 blue:.32 alpha:.95];
    b.layer.cornerRadius=13;
    return b;
}
- (void)loadView {
    UIView *root=[UIView new];root.backgroundColor=[UIColor colorWithWhite:0 alpha:.67];self.view=root;
    UITapGestureRecognizer *outside=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closePressed)];
    outside.cancelsTouchesInView=NO;outside.delegate=self;[root addGestureRecognizer:outside];
    UIView *sheet=[UIView new];self.sheet=sheet;sheet.translatesAutoresizingMaskIntoConstraints=NO;
    sheet.layer.cornerRadius=27;sheet.layer.masksToBounds=YES;sheet.backgroundColor=PHKInk();
    [root addSubview:sheet];
    UILayoutGuide *safe=root.safeAreaLayoutGuide;
    NSLayoutConstraint *preferredWidth=[sheet.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-16];
    preferredWidth.priority=UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [sheet.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [sheet.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor],
        [sheet.widthAnchor constraintLessThanOrEqualToConstant:510],
        [sheet.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:8],
        [sheet.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-8],
        preferredWidth,
        [sheet.heightAnchor constraintEqualToAnchor:safe.heightAnchor multiplier:.90]
    ]];
    UIImageView *wall=[[UIImageView alloc]initWithImage:PHKImage(@"MenuWallpaper.jpg")];
    wall.translatesAutoresizingMaskIntoConstraints=NO;wall.contentMode=UIViewContentModeScaleAspectFill;
    wall.clipsToBounds=YES;[sheet addSubview:wall];
    UIView *shade=[UIView new];shade.translatesAutoresizingMaskIntoConstraints=NO;
    shade.backgroundColor=[UIColor colorWithRed:.025 green:.036 blue:.066 alpha:.84];[sheet addSubview:shade];
    [NSLayoutConstraint activateConstraints:@[
        [wall.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor],
        [wall.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor],
        [wall.topAnchor constraintEqualToAnchor:sheet.topAnchor],
        [wall.bottomAnchor constraintEqualToAnchor:sheet.bottomAnchor],
        [shade.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor],
        [shade.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor],
        [shade.topAnchor constraintEqualToAnchor:sheet.topAnchor],
        [shade.bottomAnchor constraintEqualToAnchor:sheet.bottomAnchor]
    ]];
    UIStackView *vertical=[UIStackView new];vertical.axis=UILayoutConstraintAxisVertical;
    vertical.spacing=14;vertical.translatesAutoresizingMaskIntoConstraints=NO;[sheet addSubview:vertical];
    [NSLayoutConstraint activateConstraints:@[
        [vertical.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor constant:16],
        [vertical.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor constant:-16],
        [vertical.topAnchor constraintEqualToAnchor:sheet.safeAreaLayoutGuide.topAnchor constant:16],
        [vertical.bottomAnchor constraintEqualToAnchor:sheet.safeAreaLayoutGuide.bottomAnchor constant:-15]
    ]];
    UIView *hero=[UIView new];hero.translatesAutoresizingMaskIntoConstraints=NO;
    [hero.heightAnchor constraintEqualToConstant:112].active=YES;[vertical addArrangedSubview:hero];
    UIImageView *avatar=[[UIImageView alloc]initWithImage:PHKImage(@"AdminCar.jpg")];
    avatar.translatesAutoresizingMaskIntoConstraints=NO;avatar.contentMode=UIViewContentModeScaleAspectFill;
    avatar.clipsToBounds=YES;avatar.layer.cornerRadius=29;avatar.layer.borderWidth=2;
    avatar.layer.borderColor=PHKBlue().CGColor;[hero addSubview:avatar];
    [NSLayoutConstraint activateConstraints:@[
      [avatar.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:2],
      [avatar.topAnchor constraintEqualToAnchor:hero.topAnchor constant:9],
      [avatar.widthAnchor constraintEqualToConstant:58],
      [avatar.heightAnchor constraintEqualToConstant:58]
    ]];
    UILabel *name=[self label:@"Developer Phan Anh Khôi" size:19 weight:UIFontWeightBold color:UIColor.whiteColor];
    name.translatesAutoresizingMaskIntoConstraints=NO;[hero addSubview:name];
    UILabel *sub=[self label:@"Bảng điều khiển • giao diện mới" size:12 weight:UIFontWeightMedium color:PHKMuted()];
    sub.translatesAutoresizingMaskIntoConstraints=NO;[hero addSubview:sub];
    [NSLayoutConstraint activateConstraints:@[
      [name.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:12],
      [name.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-38],
      [name.topAnchor constraintEqualToAnchor:hero.topAnchor constant:13],
      [sub.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],
      [sub.trailingAnchor constraintEqualToAnchor:name.trailingAnchor],
      [sub.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:5]
    ]];
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];close.translatesAutoresizingMaskIntoConstraints=NO;
    [close setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    close.tintColor=UIColor.whiteColor;close.backgroundColor=[UIColor colorWithWhite:1 alpha:.12];
    close.layer.cornerRadius=17;[close addTarget:self action:@selector(closePressed) forControlEvents:UIControlEventTouchUpInside];
    [hero addSubview:close];[NSLayoutConstraint activateConstraints:@[
        [close.topAnchor constraintEqualToAnchor:hero.topAnchor constant:6],
        [close.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-3],
        [close.widthAnchor constraintEqualToConstant:34],
        [close.heightAnchor constraintEqualToConstant:34]
    ]];
    UILabel *status=[self label:@"" size:11 weight:UIFontWeightMedium color:PHKBlue()];
    self.status=status;status.translatesAutoresizingMaskIntoConstraints=NO;[hero addSubview:status];
    [NSLayoutConstraint activateConstraints:@[
        [status.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:3],
        [status.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-4],
        [status.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:-2]
    ]];
    UIScrollView *tabScroll=[UIScrollView new];tabScroll.translatesAutoresizingMaskIntoConstraints=NO;
    tabScroll.showsHorizontalScrollIndicator=NO;tabScroll.alwaysBounceHorizontal=YES;
    [tabScroll.heightAnchor constraintEqualToConstant:43].active=YES;[vertical addArrangedSubview:tabScroll];
    UIStackView *chips=[UIStackView new];chips.axis=UILayoutConstraintAxisHorizontal;
    chips.alignment=UIStackViewAlignmentFill;chips.spacing=8;chips.translatesAutoresizingMaskIntoConstraints=NO;
    self.chips=chips;[tabScroll addSubview:chips];
    [NSLayoutConstraint activateConstraints:@[
        [chips.leadingAnchor constraintEqualToAnchor:tabScroll.contentLayoutGuide.leadingAnchor],
        [chips.trailingAnchor constraintEqualToAnchor:tabScroll.contentLayoutGuide.trailingAnchor],
        [chips.topAnchor constraintEqualToAnchor:tabScroll.contentLayoutGuide.topAnchor],
        [chips.bottomAnchor constraintEqualToAnchor:tabScroll.contentLayoutGuide.bottomAnchor],
        [chips.heightAnchor constraintEqualToAnchor:tabScroll.frameLayoutGuide.heightAnchor]
    ]];
    UIScrollView *scroll=[UIScrollView new];scroll.showsVerticalScrollIndicator=NO;
    scroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;
    [vertical addArrangedSubview:scroll];
    UIStackView *content=[UIStackView new];content.axis=UILayoutConstraintAxisVertical;content.spacing=10;
    content.translatesAutoresizingMaskIntoConstraints=NO;self.content=content;
    [scroll addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];
    UIView *foot=[UIView new];foot.translatesAutoresizingMaskIntoConstraints=NO;
    [foot.heightAnchor constraintEqualToConstant:56].active=YES;[vertical addArrangedSubview:foot];
    UIButton *old=[self button:@"Toàn bộ chức năng gốc" system:@"square.stack.3d.up"];
    old.translatesAutoresizingMaskIntoConstraints=NO;
    [old addTarget:self action:@selector(openOriginalPressed) forControlEvents:UIControlEventTouchUpInside];
    [foot addSubview:old];
    [NSLayoutConstraint activateConstraints:@[
        [old.leadingAnchor constraintEqualToAnchor:foot.leadingAnchor],
        [old.trailingAnchor constraintEqualToAnchor:foot.trailingAnchor],
        [old.topAnchor constraintEqualToAnchor:foot.topAnchor],
        [old.heightAnchor constraintEqualToConstant:48]
    ]];
    [self refreshStatus];[self buildChips];[self rebuildContent];
}
- (void)viewDidAppear:(BOOL)animated{[super viewDidAppear:animated];[self refreshStatus];}
- (void)refreshStatus {
    BOOL avail=PHKLegacyAdapter.shared.isAvailable;
    self.status.text=avail ? [NSString stringWithFormat:@"● Đã tìm thấy dylib gốc  •  %@",PHKLegacyAdapter.shared.accountDescription ?: @"Phiên hiện tại"] : @"● Không thấy dylib gốc  •  chế độ giao diện";
    self.status.textColor=avail?PHKBlue():[UIColor colorWithRed:1 green:.75 blue:.38 alpha:1];
}
- (NSArray<NSString *> *)categories {
    return @[@"Tin nhắn",@"Font & Màu",@"Giao diện",@"ZBusiness",@"Media",@"Nhóm",@"Bot",@"Công cụ"];
}
- (void)buildChips {
    for (UIView *old in self.chips.arrangedSubviews){[self.chips removeArrangedSubview:old];[old removeFromSuperview];}
    for (NSString *category in [self categories]) {
        UIButton *b=[self button:category system:@""];
        b.accessibilityLabel=category;
        [b addTarget:self action:@selector(selectChip:) forControlEvents:UIControlEventTouchUpInside];
        BOOL selected=[self.selected isEqualToString:category];
        b.backgroundColor=selected?PHKBlue():[UIColor colorWithWhite:1 alpha:.12];
        [b setTitleColor:selected?PHKInk():UIColor.whiteColor forState:UIControlStateNormal];
        [self.chips addArrangedSubview:b];
    }
}
- (void)selectChip:(UIButton *)sender {
    self.selected=sender.currentTitle?:@"Tin nhắn";
    [self.view endEditing:YES];[self.fields removeAllObjects];
    [self buildChips];[self rebuildContent];
}
- (void)addHeader:(NSString *)title desc:(NSString *)desc {
    UIStackView *s=[UIStackView new];s.axis=UILayoutConstraintAxisVertical;s.spacing=5;
    [s addArrangedSubview:[self label:title size:21 weight:UIFontWeightBold color:UIColor.whiteColor]];
    [s addArrangedSubview:[self label:desc size:12 weight:UIFontWeightRegular color:PHKMuted()]];
    [self.content addArrangedSubview:s];
}
- (void)addToggle:(NSString *)title detail:(NSString *)detail action:(NSString *)action reader:(NSString *)reader {
    UIView *card=[self card];[card.heightAnchor constraintGreaterThanOrEqualToConstant:78].active=YES;
    UIStackView *row=[UIStackView new];row.axis=UILayoutConstraintAxisHorizontal;
    row.spacing=10;row.alignment=UIStackViewAlignmentCenter;row.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:row];[NSLayoutConstraint activateConstraints:@[
        [row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [row.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [row.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12]
    ]];
    UIStackView *copy=[UIStackView new];copy.axis=UILayoutConstraintAxisVertical;copy.spacing=5;
    [copy addArrangedSubview:[self label:title size:14 weight:UIFontWeightSemibold color:UIColor.whiteColor]];
    [copy addArrangedSubview:[self label:detail size:11 weight:UIFontWeightRegular color:PHKMuted()]];
    [row addArrangedSubview:copy];
    UISwitch *toggle=[UISwitch new];toggle.onTintColor=PHKBlue();toggle.accessibilityLabel=title;
    toggle.on=[PHKLegacyAdapter.shared readFlag:reader];
    toggle.enabled=PHKLegacyAdapter.shared.isAvailable;
    toggle.accessibilityValue=toggle.on?@"Bật":@"Tắt";
    objc_setAssociatedObject(toggle,@selector(togglePressed:),action,OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(toggle,@selector(readFlagForToggle:),reader,OBJC_ASSOCIATION_COPY_NONATOMIC);
    [toggle addTarget:self action:@selector(togglePressed:) forControlEvents:UIControlEventValueChanged];
    [row addArrangedSubview:toggle];[self.content addArrangedSubview:card];
}
- (void)togglePressed:(UISwitch *)sender {
    NSString *action=objc_getAssociatedObject(sender,@selector(togglePressed:));
    NSString *reader=objc_getAssociatedObject(sender,@selector(readFlagForToggle:));
    BOOL accepted=[PHKLegacyAdapter.shared applyToggle:action sender:sender];
    if(!accepted){sender.on=!sender.on;[self feedback:@"Thiếu phương thức xử lý của bản gốc."];return;}
    // Reflect verified setting from the existing dylib; never claim server acknowledgement.
    sender.on=[PHKLegacyAdapter.shared readFlag:reader];
    [self feedback:@"Đã đồng bộ thiết lập với dylib gốc."];
}
- (void)readFlagForToggle:(id)sender{(void)sender;}
- (void)addAction:(NSString *)title detail:(NSString *)detail selector:(NSString *)selector {
    UIView *card=[self card];UIStackView *v=[UIStackView new];v.axis=UILayoutConstraintAxisVertical;
    v.spacing=9;v.translatesAutoresizingMaskIntoConstraints=NO;[card addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [v.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [v.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
        [v.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:13],
        [v.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-13]]];
    [v addArrangedSubview:[self label:detail size:12 weight:UIFontWeightRegular color:PHKMuted()]];
    UIButton *b=[self button:title system:@"arrow.right"];
    b.accessibilityLabel=title;
    objc_setAssociatedObject(b,@selector(actionPressed:),selector,OBJC_ASSOCIATION_COPY_NONATOMIC);
    [b addTarget:self action:@selector(actionPressed:) forControlEvents:UIControlEventTouchUpInside];
    [v addArrangedSubview:b];[self.content addArrangedSubview:card];
}
- (UITextField *)addField:(NSString *)name hint:(NSString *)hint secure:(BOOL)secure {
    UITextField *tf=[UITextField new];tf.font=PHKFont(15,UIFontWeightRegular);
    tf.textColor=UIColor.whiteColor;tf.attributedPlaceholder=[[NSAttributedString alloc]initWithString:hint attributes:@{NSForegroundColorAttributeName:PHKMuted()}];
    tf.backgroundColor=[UIColor colorWithWhite:1 alpha:.10];tf.layer.cornerRadius=13;
    tf.layer.borderWidth=.5;tf.layer.borderColor=[UIColor colorWithWhite:1 alpha:.1].CGColor;
    tf.delegate=self;tf.returnKeyType=UIReturnKeyDone;tf.secureTextEntry=secure;
    UIView *spacer=[[UIView alloc]initWithFrame:CGRectMake(0,0,13,10)];tf.leftView=spacer;tf.leftViewMode=UITextFieldViewModeAlways;
    [tf.heightAnchor constraintEqualToConstant:46].active=YES;tf.accessibilityLabel=name;
    [self.content addArrangedSubview:tf];self.fields[name]=tf;
    return tf;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{[textField resignFirstResponder];return YES;}
- (void)addOptionGallery:(NSString *)kind {
    NSArray<UIButton *> *options=[PHKLegacyAdapter.shared legacyOptions:kind];
    if(!options.count){[self addAction:[kind isEqualToString:@"font"]?@"Tùy chỉnh font trong bảng gốc":@"Tùy chỉnh màu trong bảng gốc" detail:@"Chưa đọc được nút lựa chọn; mở đầy đủ phần cài đặt gốc." selector:@"legacy"];return;}
    for(UIButton *origin in options){
        NSString *title=[origin titleForState:UIControlStateNormal]?:[origin titleForState:UIControlStateSelected]?:@"Tùy chọn";
        UIButton *b=[self button:title system:@"paintbrush"];
        // Original buttons preserve their tags and other metadata; don't fake them.
        objc_setAssociatedObject(b,@selector(optionPressed:),origin,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(b,@selector(optionType:),kind,OBJC_ASSOCIATION_COPY_NONATOMIC);
        [b addTarget:self action:@selector(optionPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.content addArrangedSubview:b];
    }
}
- (void)optionType:(id)sender{(void)sender;}
- (void)optionPressed:(UIButton *)sender {
    UIButton *original=objc_getAssociatedObject(sender,@selector(optionPressed:));
    NSString *kind=objc_getAssociatedObject(sender,@selector(optionType:));
    BOOL ok=[PHKLegacyAdapter.shared applyLegacyOption:original kind:kind];
    [self feedback:ok?@"Đã chuyển lựa chọn sang bộ xử lý font/màu gốc.":@"Không thể áp dụng lựa chọn trên phiên bản hiện tại."];
}
- (void)addActionFields:(NSString *)button selector:(NSString *)selector fieldKeys:(NSArray<NSString *> *)keys {
    for(NSString *key in keys)[self addField:key hint:key secure:NO];
    [self addAction:button detail:@"Thao tác sử dụng logic cũ; kết quả cần xác nhận ở ứng dụng." selector:selector];
}
- (void)rebuildContent {
    for(UIView *old in self.content.arrangedSubviews){[self.content removeArrangedSubview:old];[old removeFromSuperview];}
    [self.fields removeAllObjects];
    if([self.selected isEqual:@"Tin nhắn"]){
        [self addHeader:@"Tin nhắn" desc:@"Các chế độ đã có, đọc trạng thái trực tiếp từ thư viện cũ."];
        [self addToggle:@"Chống thu hồi" detail:@"Giữ hiển thị nội dung khi bị thu hồi (phụ thuộc hook)." action:@"toggleAntiUndo:" reader:@"isAntiUndoEnabled"];
        [self addToggle:@"Ảnh gốc HD" detail:@"Yêu cầu chất lượng ảnh gốc, máy chủ vẫn có quyền giới hạn." action:@"toggleBugOriginal:" reader:@"isBugOriginalEnabled"];
        [self addToggle:@"Ẩn đã xem" detail:@"Điều chỉnh sự kiện báo đã đọc." action:@"toggleGhostSeen:" reader:@"isGhostSeenEnabled"];
        [self addToggle:@"Ẩn đang nhập" detail:@"Điều chỉnh sự kiện đang gõ." action:@"toggleHideTyping:" reader:@"isHideTypingEnabled"];
        [self addToggle:@"Giảm hiệu ứng" detail:@"Hạn chế hiệu ứng mưa chữ và sticker." action:@"toggleAntiRain:" reader:@"isAntiRainEnabled"];
        [self addHeader:@"TTL tự hủy" desc:@"Nhập giá trị, chọn đơn vị rồi chuyển cho bộ xử lý TTL gốc."];
        UISegmentedControl *seg=[[UISegmentedControl alloc]initWithItems:@[@"Giây",@"Giờ",@"Ngày"]];
        seg.selectedSegmentIndex=0;seg.selectedSegmentTintColor=PHKBlue();seg.backgroundColor=[UIColor colorWithWhite:1 alpha:.2];
        [seg.heightAnchor constraintEqualToConstant:39].active=YES;self.ttlUnit=seg;
        [self.content addArrangedSubview:seg];
        UITextField *ttl=[self addField:@"ttl" hint:@"Ví dụ: 30" secure:NO];ttl.keyboardType=UIKeyboardTypeNumberPad;
        [self addAction:@"Áp dụng TTL" detail:@"Kiểm tra đầu vào, giới hạn tối đa 30 ngày để tránh tràn số." selector:@"ttl"];
    }else if([self.selected isEqual:@"Font & Màu"]){
        [self addHeader:@"Font & Màu" desc:@"Hiển thị tùy chọn gốc trong danh sách mới, không đoán chỉ số nút."];
        [self addOptionGallery:@"font"];
        [self addHeader:@"Màu chữ" desc:@"Áp dụng qua phương thức gốc, giữ nguyên tag của nút."];
        [self addOptionGallery:@"color"];
        [self addField:@"fontSize" hint:@"Kích thước chữ (10–60)" secure:NO].keyboardType=UIKeyboardTypeNumberPad;
        [self addAction:@"Áp dụng kích thước" detail:@"Tác động vào cài đặt font của bản cũ." selector:@"fontSize"];
    }else if([self.selected isEqual:@"Giao diện"]){
        [self addHeader:@"Giao diện" desc:@"Cài đặt nền chat và bố cục."];
        [self addToggle:@"Ảnh nền chat tùy chỉnh" detail:@"Bật/tắt ảnh nền khi vào hội thoại." action:@"toggleChatBg:" reader:@"isChatBgEnabled"];
        [self addAction:@"Chọn ảnh nền" detail:@"Mở bộ chọn ảnh đang có trong dylib gốc." selector:@"actionPickChatBackground"];
        [self addAction:@"Xóa ảnh nền" detail:@"Chuyển lệnh xóa ảnh nền sang bộ xử lý gốc." selector:@"actionRemoveChatBackground"];
    }else if([self.selected isEqual:@"ZBusiness"]){
        [self addHeader:@"ZBusiness & zStyle" desc:@"Các tùy chọn phía thiết bị không tương đương quyền máy chủ."];
        [self addToggle:@"Nhãn doanh nghiệp (client)" detail:@"Chỉ can thiệp phần hiển thị ở thiết bị." action:@"toggleBugZBusiness:" reader:@"isBugZBusinessEnabled"];
        [self addToggle:@"Ẩn gợi ý zStyle" detail:@"Thay đổi popup và banner trong ứng dụng." action:@"toggleBlockZStyle:" reader:@"isBlockZStyleEnabled"];
        [self addToggle:@"Tùy chọn zStyle" detail:@"Giữ hành vi do dylib gốc cung cấp." action:@"toggleBugZLStyle:" reader:@"isBugZLStyleEnabled"];
        [self addToggle:@"Chặn quảng cáo" detail:@"Phụ thuộc khả năng hook các vị trí quảng cáo." action:@"toggleAdBlock:" reader:@"isAdBlockEnabled"];
        [self addToggle:@"Giới hạn media" detail:@"Thay đổi kiểm tra phía client; không vượt được giới hạn máy chủ." action:@"toggleUnlimitedMedia:" reader:@"isUnlimitedMediaEnabled"];
        [self addToggle:@"Tùy chọn nhạc chuông" detail:@"Tùy thuộc API và quyền thực tế." action:@"toggleUnlockRBT:" reader:@"isUnlockRBTEnabled"];
    }else if([self.selected isEqual:@"Media"]){
        [self addHeader:@"Nhạc & hồ sơ" desc:@"Giữ các thao tác profile music và chọn tệp từ thư viện cũ."];
        [self addToggle:@"Nhạc trên hồ sơ" detail:@"Bật/tắt giao diện nhạc trên trang cá nhân." action:@"toggleProfileMusic:" reader:@"isProfileMusicEnabled"];
        [self addAction:@"Chọn MP3" detail:@"Chọn tệp qua document picker của ứng dụng gốc." selector:@"actionPickProfileMP3"];
        [self addField:@"txtSongName" hint:@"Tên bài hát" secure:NO];
        [self addField:@"txtArtistName" hint:@"Tên nghệ sĩ" secure:NO];
        [self addAction:@"Lưu thông tin bài hát" detail:@"Đồng bộ vào các trường dữ liệu của menu gốc." selector:@"songInfo"];
        [self addAction:@"Thử phát / dừng" detail:@"Điều khiển trình phát hiện có." selector:@"actionToggleTestPlay"];
    }else if([self.selected isEqual:@"Nhóm"]){
        [self addHeader:@"Nhóm & tin nhắn" desc:@"Các hành động có thể chỉ phát notification nội bộ; xác minh kết quả sau khi gửi."];
        [self addField:@"txtTargetId" hint:@"UID / ID hội thoại" secure:NO];
        [self addField:@"txtMessageContent" hint:@"Nội dung tin nhắn" secure:NO];
        [self addAction:@"Gửi tin nhắn" detail:@"Chuyển thông tin vào phương thức gửi của bản cũ." selector:@"actionSendMessage"];
        [self addField:@"txtGroupLinkOrId" hint:@"Link hoặc ID nhóm" secure:NO];
        [self addAction:@"Tham gia nhóm" detail:@"Không báo thành công khi mới phát sự kiện." selector:@"actionJoinGroup"];
        [self addField:@"txtKickUid" hint:@"UID cần loại khỏi nhóm" secure:NO];
        [self addAction:@"Loại thành viên" detail:@"Cần quyền quản trị và xác nhận thực tế." selector:@"actionKickMember"];
        [self addAction:@"Rời nhóm" detail:@"Yêu cầu xử lý trong phiên ứng dụng hiện hành." selector:@"actionLeaveGroup"];
    }else if([self.selected isEqual:@"Bot"]){
        [self addHeader:@"Bot native" desc:@"Điều khiển phiên bot gốc; không khẳng định hỗ trợ nhiều tài khoản."];
        [self addAction:@"Làm mới thông tin" detail:@"Đọc trạng thái bot và tài khoản trong phiên hiện hành." selector:@"botRefreshAccountInfo"];
        [self addAction:@"Khởi động bot" detail:@"Bật bot hiện có, không tạo thêm tiến trình nền." selector:@"actionStartBot"];
        [self addAction:@"Dừng bot" detail:@"Tắt bot hiện có." selector:@"actionStopBot"];
        [self addField:@"prefix" hint:@"Prefix: ! / . #" secure:NO];
        [self addAction:@"Lưu prefix" detail:@"Chấp nhận một trong bốn ký tự: ! / . #" selector:@"prefix"];
        [self addAction:@"Danh sách lệnh gốc" detail:@"Xem đầy đủ hướng dẫn lệnh và tuỳ chọn nâng cao trong menu gốc." selector:@"legacy"];
    }else if([self.selected isEqual:@"Công cụ"]){
        [self addHeader:@"Công cụ" desc:@"Thông tin chẩn đoán minh bạch và tiện ích nâng cao."];
        [self addAction:@"Xem mô phỏng khóa tài khoản" detail:@"Chỉ là màn hình mô phỏng, không thay đổi trạng thái tài khoản." selector:@"actionPreviewLockedAccount"];
        [self addAction:@"Mở toàn bộ menu gốc" detail:@"Đường dự phòng để không mất các tính năng chưa ánh xạ." selector:@"legacy"];
        [self addHeader:@"Cử chỉ mở menu" desc:@"Chạm một lần bằng bốn ngón tay trên màn hình chính. Không cần nút nổi."];
        [self addHeader:@"Bảo vệ phiên" desc:@"Không tự động đọc cookie; tính năng xuất cấu hình nhạy cảm chỉ có ở menu gốc, cần thận trọng."];
    }
    UILabel *feedback=[self label:@"" size:12 weight:UIFontWeightMedium color:PHKBlue()];
    self.actionFeedback=feedback;[self.content addArrangedSubview:feedback];
}
- (void)feedback:(NSString *)message {
    self.actionFeedback.text=message;UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,message);
    [self refreshStatus];
}
- (void)actionPressed:(UIButton *)sender {
    NSString *s=objc_getAssociatedObject(sender,@selector(actionPressed:));
    if([s isEqualToString:@"legacy"]){[self openOriginalPressed];return;}
    if([s isEqualToString:@"ttl"]){
        BOOL ok=[PHKLegacyAdapter.shared applyTTL:self.fields[@"ttl"].text unit:self.ttlUnit.selectedSegmentIndex];
        [self feedback:ok?@"Thiết lập TTL đã được chuyển cho dylib gốc.":@"TTL không hợp lệ hoặc không có trường điều khiển gốc."];return;
    }
    if([s isEqualToString:@"fontSize"]){
        BOOL ok=[PHKLegacyAdapter.shared applyFontSize:self.fields[@"fontSize"].text];
        [self feedback:ok?@"Đã áp dụng font size trong bộ xử lý gốc.":@"Chỉ chấp nhận kích thước 10–60; kiểm tra tương thích."];return;
    }
    if([s isEqualToString:@"prefix"]){
        BOOL ok=[PHKLegacyAdapter.shared applyBotPrefix:self.fields[@"prefix"].text];
        [self feedback:ok?@"Đã chuyển prefix cho bot gốc.":@"Prefix không hợp lệ hoặc thiếu thư viện gốc."];return;
    }
    if([s isEqualToString:@"songInfo"]){
        BOOL a=[PHKLegacyAdapter.shared setLegacyText:self.fields[@"txtSongName"].text field:@"txtSongName"];
        BOOL b=[PHKLegacyAdapter.shared setLegacyText:self.fields[@"txtArtistName"].text field:@"txtArtistName"];
        [self feedback:(a&&b)?@"Đã đồng bộ nội dung vào các trường gốc.":@"Không tìm thấy trường gốc."];return;
    }
    if([@[@"actionSendMessage",@"actionJoinGroup",@"actionKickMember",@"actionLeaveGroup"] containsObject:s]){
        for(NSString *key in @[@"txtTargetId",@"txtMessageContent",@"txtGroupLinkOrId",@"txtKickUid"]){
            UITextField *field=self.fields[key];if(field)[PHKLegacyAdapter.shared setLegacyText:field.text field:key];
        }
    }
    BOOL ok=[PHKLegacyAdapter.shared applyAction:s];
    [self feedback:ok?@"Đã gọi xử lý gốc. Hãy kiểm tra kết quả thực tế.":@"Không tìm thấy phương thức trong dylib gốc."];
}
- (void)openOriginalPressed {
    // Save presenting controller before closing the overlay.
    UIViewController *presenter=self.legacyPresenter;
    dispatch_block_t close=self.onClose; if(close)close();
    dispatch_async(dispatch_get_main_queue(), ^{if(presenter)[PHKLegacyAdapter.shared openOriginalMenuFrom:presenter];});
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    (void)gesture;
    UIView *v=touch.view;
    while(v){if(v==self.sheet)return NO;v=v.superview;}
    return YES;
}
- (void)closePressed {if(self.onClose)self.onClose();}
@end
