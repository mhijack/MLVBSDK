/**
 * Module: TCAnchorToolbarView
 *
 * Function: 工具栏
 */

#import "TCAnchorToolbarView.h"
#import "TCMsgListTableView.h"
#import "TCMsgBarrageView.h"
#import "UIView+Additions.h"
#import <UIImageView+WebCache.h>
#import "UIImage+Additions.h"
#import "UIView+CustomAutoLayout.h"
#import "TCGlobalConfig.h"
#import "TCAccountMgrModel.h"
#import "V8HorizontalPickerView.h"
#import "ColorMacro.h"
#import "TCUtil.h"
#import "HUDHelper.h"
#import "TCConfig.h"

#if POD_PITU
//#import "MCCameraDynamicView.h"

//@interface TCAnchorToolbarView () <MCCameraDynamicDelegate>
//
//@end
#endif

@implementation TCAnchorToolbarView
{
    TCShowLiveTopView     *_topView;
    TCPushShowResultView  *_resultView;
    TCAudienceListTableView *_audienceTableView;
    TCMsgListTableView    *_msgTableView;
    TCMsgBarrageView *_bulletViewOne;
    TCMsgBarrageView *_bulletViewTwo;

    TCRoomInfo            *_liveInfo;
    UIView                *_msgInputView;
    UITextField           *_msgInputFeild;
    UIButton              *_closeBtn;
    CGPoint               _touchBeginLocation;
    CGPoint               _touchPrevLocation;
    BOOL                  _bulletBtnIsOn;
    
    UIAlertView           *_closeAlert;
    UIAlertView           *_closeErrAlert;
    UIAlertView           *_closeErrRstAlert;

    UILabel               *_labAudioEffect;
    UILabel               *_labVolumeForVoice;
    UISlider              *_sldVolumeForVoice;
    UILabel               *_labVolumeForBGM;
    UISlider              *_sldVolumeForBGM;
    UILabel               *_labPositionForBGM;
    UISlider              *_sldPositionForBGM;
    UILabel               *_labPitchForBGM;
    UISlider              *_sldPitchForBGM;
    
    UIButton              *_btnSelectBGM;
    UIButton              *_btnStopBGM;
    
    UIView                *_vBGMPanel;
    UIView                *_vAudioEffectPanel;
    
    NSMutableArray*         _audioEffectArry;
    NSMutableArray*         _audioEffectViewArry;
    NSInteger              _audioEffectSelectedType;
    
    NSMutableArray*         _audioEffectArry2;     // 变声
    NSMutableArray*         _audioEffectViewArry2;
    NSInteger              _audioEffectSelectedType2;
    
    BOOL                  _isTouchMusicPanel;
    
    BOOL                  _viewsHidden;
    NSMutableArray        *_heartAnimationPoints;
	
#if POD_PITU
#else
#endif
//    NSMutableArray *_greenArray;
    
//    NSInteger    _filterType;
//    NSInteger    _greenIndex;
//    NSMutableArray *_filterArray;
    
    UITapGestureRecognizer *_tap;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLogout:) name:logoutNotification object:nil];
        _tap =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickScreen:)];
        [self addGestureRecognizer:_tap];
        
        _audioEffectArry = [NSMutableArray arrayWithObjects:@"原声", @"KTV", @"房间", @"会堂", @"低沉", @"洪亮", @"金属", @"磁性", nil];
        _audioEffectViewArry = [NSMutableArray arrayWithCapacity:_audioEffectArry.count];
        _audioEffectSelectedType = 0;
        
        _audioEffectArry2 = [NSMutableArray arrayWithObjects:@"原声", @"熊孩子", @"萝莉", @"大叔", @"重金属", @"感冒", @"外国人", @"困兽", @"死肥仔", @"强电流", @"重机械", @"空灵", nil];
        _audioEffectViewArry2 = [NSMutableArray arrayWithCapacity:_audioEffectArry2.count];
        _audioEffectSelectedType2 = 0;
        
       [self initUI];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setButtonHidden:(BOOL)buttonHidden {
    _btnChat.hidden = buttonHidden;
    _btnCamera.hidden = buttonHidden;
    _btnBeauty.hidden = buttonHidden;
    _btnLog.hidden = buttonHidden;
    _btnTorch.hidden = buttonHidden;
    _btnMusic.hidden = buttonHidden;
    _closeBtn.hidden = buttonHidden;
}

- (void)setLiveInfo:(TCRoomInfo *)liveInfo {
    _liveInfo = liveInfo;
    
    //topview,展示主播头像，在线人数及点赞
    int statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    _topView = [[TCShowLiveTopView alloc] initWithFrame:CGRectMake(5, statusBarHeight + 5, 110, 35) isHost:YES hostNickName:_liveInfo.userinfo.nickname
                                          audienceCount:_liveInfo.viewercount likeCount:_liveInfo.likecount hostFaceUrl:_liveInfo.userinfo.headpic];
    [self addSubview:_topView];
    [_topView startLive];
    
    //观众列表
    CGFloat audience_width = self.width - 25 - _topView.right;
    _audienceTableView = [[TCAudienceListTableView alloc] initWithFrame:CGRectMake(_topView.right + 10 +audience_width / 2 - IMAGE_SIZE / 2 ,_topView.center.y -  audience_width / 2, _topView.height, audience_width) style:UITableViewStyleGrouped liveInfo:_liveInfo];
    _audienceTableView.transform = CGAffineTransformMakeRotation(- M_PI/2);
    [self addSubview:_audienceTableView];
}

- (void)initUI {
    int   icon_size = BOTTOM_BTN_ICON_WIDTH;
    float startSpace = 15;
#if ENABLE_LOG
    float icon_count = 7;
#else
    float icon_count = 6;
#endif
    CGFloat bottomOffset = 0;
    if (@available(iOS 11, *)) {
        bottomOffset = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    }
    float icon_center_y = self.height - icon_size/2 - startSpace - bottomOffset;
    float icon_center_interval = (self.width - 2*startSpace - icon_size)/(icon_count - 1);
    float first_icon_center_x = startSpace + icon_size/2;

    
    //聊天
    _btnChat = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnChat.center = CGPointMake(first_icon_center_x, icon_center_y);
    _btnChat.bounds = CGRectMake(0, 0, icon_size, icon_size);
    [_btnChat setImage:[UIImage imageNamed:@"comment"] forState:UIControlStateNormal];
    [_btnChat addTarget:self action:@selector(clickChat:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnChat];
    
    //开启闪关灯按钮
    _btnTorch = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnTorch.center = CGPointMake(first_icon_center_x + icon_center_interval, icon_center_y);
    _btnTorch.bounds = CGRectMake(0, 0, icon_size, icon_size);
    [_btnTorch setImage:[UIImage imageNamed:@"flash"] forState:UIControlStateNormal];
    [_btnTorch addTarget:self action:@selector(clickTorch:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnTorch];
    
    //前置后置摄像头切换
    _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnCamera.center = CGPointMake(first_icon_center_x + icon_center_interval*2, icon_center_y);
    _btnCamera.bounds = CGRectMake(0, 0, icon_size, icon_size);
    [_btnCamera setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [_btnCamera addTarget:self action:@selector(clickCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnCamera];
    
    //美颜开关按钮
    _btnBeauty = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnBeauty.center = CGPointMake(first_icon_center_x + icon_center_interval*3, icon_center_y);
    _btnBeauty.bounds = CGRectMake(0, 0, icon_size, icon_size);
    [_btnBeauty setImage:[UIImage imageNamed:@"beauty"] forState:UIControlStateNormal];
    [_btnBeauty addTarget:self action:@selector(clickBeauty:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnBeauty];
    
    //音乐按钮
    _btnMusic = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnMusic.center = CGPointMake(first_icon_center_x + icon_center_interval*4, icon_center_y);
    _btnMusic.bounds = CGRectMake(0, 0, icon_size, icon_size);
    [_btnMusic setImage:[UIImage imageNamed:@"music_icon"] forState:UIControlStateNormal];
    [_btnMusic addTarget:self action:@selector(clickMusic:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnMusic];
    
#if ENABLE_LOG
    //log显示或隐藏
    _btnLog = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnLog.center = CGPointMake(first_icon_center_x + icon_center_interval*5, icon_center_y);
    _btnLog.bounds = CGRectMake(0, 0, icon_size, icon_size);
    [_btnLog setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
    [_btnLog addTarget:self action:@selector(clickLog:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnLog];
#endif
    
    //退出VC
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
#if ENABLE_LOG
    _closeBtn.center = CGPointMake(first_icon_center_x + icon_center_interval*6, icon_center_y);
#else
    _closeBtn.center = CGPointMake(first_icon_center_x + icon_center_interval*5, icon_center_y);
#endif
    _closeBtn.bounds = CGRectMake(0, 0, icon_size, icon_size);
    [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(closeVC) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_closeBtn];

    //弹幕
    _msgTableView = [[TCMsgListTableView alloc] initWithFrame:CGRectMake(15, _btnChat.top - MSG_TABLEVIEW_HEIGHT - MSG_TABLEVIEW_BOTTOM_SPACE, MSG_TABLEVIEW_WIDTH, MSG_TABLEVIEW_HEIGHT) style:UITableViewStyleGrouped];
    [self addSubview:_msgTableView];
    
    _bulletViewOne = [[TCMsgBarrageView alloc]initWithFrame:CGRectMake(0,_msgTableView.top - MSG_UI_SPACE - MSG_BULLETVIEW_HEIGHT, SCREEN_WIDTH, MSG_BULLETVIEW_HEIGHT)];
    [self addSubview:_bulletViewOne];
    
    _bulletViewTwo = [[TCMsgBarrageView alloc]initWithFrame:CGRectMake(0, _bulletViewOne.top - MSG_BULLETVIEW_HEIGHT, SCREEN_WIDTH, MSG_BULLETVIEW_HEIGHT)];
    [self addSubview:_bulletViewTwo];
    
    
    //输入框
    _msgInputView = [[UIView alloc] initWithFrame:CGRectMake(0, self.height, self.width, MSG_TEXT_SEND_VIEW_HEIGHT )];
    _msgInputView.backgroundColor = [UIColor clearColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _msgInputView.width, _msgInputView.height)];
    imageView.image = [UIImage imageNamed:@"input_comment"];
    
    UIButton *bulletBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    bulletBtn.frame = CGRectMake(10, (_msgInputView.height - MSG_TEXT_SEND_FEILD_HEIGHT)/2, MSG_TEXT_SEND_BULLET_BTN_WIDTH, MSG_TEXT_SEND_FEILD_HEIGHT);
    [bulletBtn setImage:[UIImage imageNamed:@"Switch_OFF"] forState:UIControlStateNormal];
    [bulletBtn setImage:[UIImage imageNamed:@"Switch_ON"] forState:UIControlStateSelected];
    [bulletBtn addTarget:self action:@selector(clickBullet:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sendBtn.frame = CGRectMake(self.width - 15 - MSG_TEXT_SEND_BTN_WIDTH, (_msgInputView.height - MSG_TEXT_SEND_FEILD_HEIGHT)/2, MSG_TEXT_SEND_BTN_WIDTH, MSG_TEXT_SEND_FEILD_HEIGHT);
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [sendBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [sendBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
    [sendBtn setBackgroundColor:[UIColor clearColor]];
    [sendBtn addTarget:self action:@selector(clickSend) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *msgInputFeildLine1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vertical_line"]];
    msgInputFeildLine1.frame = CGRectMake(bulletBtn.right + 10, sendBtn.y, 1, MSG_TEXT_SEND_FEILD_HEIGHT);
    
    UIImageView *msgInputFeildLine2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vertical_line"]];
    msgInputFeildLine2.frame = CGRectMake(sendBtn.left - 10, sendBtn.y, 1, MSG_TEXT_SEND_FEILD_HEIGHT);
    
    _msgInputFeild = [[UITextField alloc] initWithFrame:CGRectMake(msgInputFeildLine1.right + 10,sendBtn.y,msgInputFeildLine2.left - msgInputFeildLine1.right - 20,MSG_TEXT_SEND_FEILD_HEIGHT)];
    _msgInputFeild.backgroundColor = [UIColor clearColor];
    _msgInputFeild.returnKeyType = UIReturnKeySend;
    _msgInputFeild.placeholder = @"和大家说点什么吧";
    _msgInputFeild.delegate = self;
    _msgInputFeild.textColor = [UIColor blackColor];
    _msgInputFeild.font = [UIFont systemFontOfSize:14];
    
    
    [_msgInputView addSubview:imageView];
    [_msgInputView addSubview:_msgInputFeild];
    [_msgInputView addSubview:bulletBtn];
    [_msgInputView addSubview:sendBtn];
    [_msgInputView addSubview:msgInputFeildLine1];
    [_msgInputView addSubview:msgInputFeildLine2];
    [self addSubview:_msgInputView];
    
    CGFloat height = [TCBeautyPanel getHeight] + bottomOffset;
    TCBeautyPanelTheme *theme = [[TCBeautyPanelTheme alloc] init];

    UIColor *cyanColor = [UIColor colorWithRed:11.f/255.f
                                         green:204.f/255.f
                                          blue:172.f/255.f
                                         alpha:1.0];
    theme.beautyPanelSelectionColor = cyanColor;
    theme.beautyPanelMenuSelectionBackgroundImage = [UIImage imageNamed:@"beauty_selection_bg"];
    theme.sliderThumbImage = [UIImage imageNamed:@"slider"];
    theme.sliderValueColor = theme.beautyPanelSelectionColor;
    theme.sliderMinColor = cyanColor;

    _vBeauty = [[TCBeautyPanel  alloc] initWithFrame:CGRectMake(0, self.height-height,
                                                                self.width, height)
                                               theme:theme
                                     actionPerformer:nil];
    _vBeauty.bottomOffset = bottomOffset;

    _vBeauty.hidden = YES;
    [self addSubview: _vBeauty];
    
    
    //********************
    // 音乐
    TCASKitTheme* asTheme = [[TCASKitTheme alloc] init];
    asTheme.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
    _vMusicPanel = [[AudioEffectSettingView alloc] initWithType:AudioEffectSettingViewDefault theme:asTheme];
    [_vMusicPanel hide];
    //***
    //BGM
    _vBGMPanel = [[UIView alloc] init];
    _vBGMPanel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];//[UIColor lightTextColor];
    
    _btnSelectBGM = [[UIButton alloc] init];
    _btnSelectBGM.titleLabel.font = [UIFont systemFontOfSize:12.f];
    _btnSelectBGM.layer.borderColor = UIColorFromRGB(0x0ACCAC).CGColor;
    [_btnSelectBGM.layer setMasksToBounds:YES];
    [_btnSelectBGM.layer setCornerRadius:6];
    [_btnSelectBGM.layer setBorderWidth:1.0];
    [_btnSelectBGM setTitle:@"伴奏" forState:UIControlStateNormal];
    [_btnSelectBGM setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
    [_btnSelectBGM addTarget:self action:@selector(clickMusicSelect:) forControlEvents:UIControlEventTouchUpInside];
    
    _btnStopBGM = [[UIButton alloc] init];
    _btnStopBGM.titleLabel.font = [UIFont systemFontOfSize:12.f];
    _btnStopBGM.layer.borderColor = UIColorFromRGB(0x0ACCAC).CGColor;;
    [_btnStopBGM setTitle:@"结束" forState:UIControlStateNormal];
    [_btnStopBGM.layer setMasksToBounds:YES];
    [_btnStopBGM.layer setCornerRadius:6];
    [_btnStopBGM.layer setBorderWidth:1.0];
    [_btnStopBGM setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
    [_btnStopBGM addTarget:self action:@selector(clickMusicClose:) forControlEvents:UIControlEventTouchUpInside];
    
    //***
    //音效
    _vAudioEffectPanel = [[UIView alloc] init];
    _vAudioEffectPanel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    
    _labPitchForBGM = [[UILabel alloc] init];
    [_labPitchForBGM setText:@"伴奏音调"];
    [_labPitchForBGM setFont:[UIFont systemFontOfSize:12.f]];
    _labPitchForBGM.textColor = UIColorFromRGB(0x0ACCAC);
    
    _sldPitchForBGM = [[UISlider alloc] init];
    _sldPitchForBGM.minimumValue = 0;
    _sldPitchForBGM.maximumValue = 200;
    _sldPitchForBGM.value = 100;
    [_sldPitchForBGM setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sldPitchForBGM setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sldPitchForBGM setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    _sldPitchForBGM.tag = 6;
    [_sldPitchForBGM addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    
    _labVolumeForBGM = [[UILabel alloc] init];
    [_labVolumeForBGM setText:@"伴奏音量"];
    [_labVolumeForBGM setFont:[UIFont systemFontOfSize:12.f]];
    _labVolumeForBGM.textColor = UIColorFromRGB(0x0ACCAC);
    //    [_labVolumeForBGM sizeToFit];
    
    _sldVolumeForBGM = [[UISlider alloc] init];
    _sldVolumeForBGM.minimumValue = 0;
    _sldVolumeForBGM.maximumValue = 200;
    _sldVolumeForBGM.value = 100;
    [_sldVolumeForBGM setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sldVolumeForBGM setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sldVolumeForBGM setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    _sldVolumeForBGM.tag = 4;
    [_sldVolumeForBGM addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    
    _labVolumeForVoice = [[UILabel alloc] init];
    [_labVolumeForVoice setText:@"人声音量"];
    [_labVolumeForVoice setFont:[UIFont systemFontOfSize:12.f]];
    _labVolumeForVoice.textColor = UIColorFromRGB(0x0ACCAC);
    //    [_labVolumeForVoice sizeToFit];
    
    _sldVolumeForVoice = [[UISlider alloc] init];
    _sldVolumeForVoice.minimumValue = 0;
    _sldVolumeForVoice.maximumValue = 200;
    _sldVolumeForVoice.value = 100;
    [_sldVolumeForVoice setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sldVolumeForVoice setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sldVolumeForVoice setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    _sldVolumeForVoice.tag = 5;
    [_sldVolumeForVoice addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    
    _labPositionForBGM = [[UILabel alloc] init];
    [_labPositionForBGM setText:@"伴奏快进"];
    [_labPositionForBGM setFont:[UIFont systemFontOfSize:12.f]];
    _labPositionForBGM.textColor = UIColorFromRGB(0x0ACCAC);
    
    _sldPositionForBGM = [[UISlider alloc] init];
    _sldPositionForBGM.minimumValue = 0.f;
    _sldPositionForBGM.maximumValue = 1.f;
    _sldPositionForBGM.value = 0.f;
    _sldPositionForBGM.continuous = NO;
    [_sldPositionForBGM setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sldPositionForBGM setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sldPositionForBGM setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    _sldPositionForBGM.tag = 7;
    [_sldPositionForBGM addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    
    
    for (int i=0; i<_audioEffectArry.count; ++i) {
        UIButton *btn = [[UIButton alloc] init];
        btn.titleLabel.font = [UIFont systemFontOfSize:12.f];
        [btn setTitle:[_audioEffectArry objectAtIndex:i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
        [btn.layer setMasksToBounds:YES];
        [btn.layer setCornerRadius:btn.height/2];
        [btn addTarget:self action:@selector(selectEffect:) forControlEvents:UIControlEventTouchUpInside];
        [_audioEffectViewArry addObject:btn];
        btn.tag = i;
    }
    
    for (int i=0; i<_audioEffectArry2.count; ++i) {
        UIButton *btn = [[UIButton alloc] init];
        btn.titleLabel.font = [UIFont systemFontOfSize:12.f];
        [btn setTitle:[_audioEffectArry2 objectAtIndex:i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
        [btn.layer setMasksToBounds:YES];
        [btn.layer setCornerRadius:btn.height/2];
        [btn addTarget:self action:@selector(selectEffect2:) forControlEvents:UIControlEventTouchUpInside];
        [_audioEffectViewArry2 addObject:btn];
        btn.tag = i;
    }
    
    _labAudioEffect = [[UILabel alloc] init];
    _labAudioEffect.textAlignment = NSTextAlignmentCenter;
    _labAudioEffect.font = [UIFont systemFontOfSize:16];
    [_labAudioEffect setText:@"音效调节"];
    _labAudioEffect.backgroundColor = [UIColor whiteColor];
    _labAudioEffect.textColor = UIColorFromRGB(0x0ACCAC);
    
    //***
    //add view
    [_vAudioEffectPanel addSubview:_labAudioEffect];
    for (int i=0; i<_audioEffectViewArry.count; ++i) {
        [_vAudioEffectPanel addSubview:[_audioEffectViewArry objectAtIndex:i]];
    }
    for (int i=0; i<_audioEffectViewArry2.count; ++i) {
        [_vAudioEffectPanel addSubview:[_audioEffectViewArry2 objectAtIndex:i]];
    }
    [_vAudioEffectPanel addSubview:_labVolumeForVoice];
    [_vAudioEffectPanel addSubview:_sldVolumeForVoice];
    [_vAudioEffectPanel addSubview:_labVolumeForBGM];
    [_vAudioEffectPanel addSubview:_sldVolumeForBGM];
    [_vAudioEffectPanel addSubview:_labPositionForBGM];
    [_vAudioEffectPanel addSubview:_sldPositionForBGM];
    [_vAudioEffectPanel addSubview:_labPitchForBGM];
    [_vAudioEffectPanel addSubview:_sldPitchForBGM];
    
    [_vBGMPanel addSubview:_btnSelectBGM];
    [_vBGMPanel addSubview:_btnStopBGM];
    
    [self addSubview:_vMusicPanel];
    
    //***
    //音乐 layout
    [_vMusicPanel sizeWith:CGSizeMake(self.width, 526 + bottomOffset)];
    [_vMusicPanel alignParentTopWithMargin:self.height-_vMusicPanel.height];
    [_vMusicPanel alignParentLeftWithMargin:0];
    
    //BMG layout
    [_btnSelectBGM sizeWith:CGSizeMake(50, 20)];
    [_btnSelectBGM alignParentTopWithMargin:10];
    [_btnSelectBGM alignParentLeftWithMargin:15];
    
    [_btnStopBGM sizeWith:CGSizeMake(50, 20)];
    [_btnStopBGM alignParentTopWithMargin:10];
    [_btnStopBGM layoutToRightOf:_btnSelectBGM margin:15];
    
    // 音效 layout
    [_labPitchForBGM sizeWith:CGSizeMake(60, 20)];
    [_labPitchForBGM alignParentTopWithMargin:20];
    [_labPitchForBGM alignParentLeftWithMargin:15];
    
    [_sldPitchForBGM sizeWith:CGSizeMake(270, 20)];
    [_sldPitchForBGM alignParentTopWithMargin:20];
    [_sldPitchForBGM alignParentLeftWithMargin:90];
    
    [_labPositionForBGM sizeWith:CGSizeMake(60, 20)];
    [_labPositionForBGM layoutBelow:_labPitchForBGM margin:15];
    [_labPositionForBGM alignParentLeftWithMargin:15];
    
    [_sldPositionForBGM sizeWith:CGSizeMake(270, 20)];
    [_sldPositionForBGM layoutBelow:_sldPitchForBGM margin:15];
    [_sldPositionForBGM alignParentLeftWithMargin:90];
    
    [_labVolumeForBGM sizeWith:CGSizeMake(60, 20)];
    [_labVolumeForBGM layoutBelow:_labPositionForBGM margin:15];
    [_labVolumeForBGM alignParentLeftWithMargin:15];
    
    [_sldVolumeForBGM sizeWith:CGSizeMake(270, 20)];
    [_sldVolumeForBGM layoutBelow:_sldPositionForBGM margin:15];
    [_sldVolumeForBGM alignParentLeftWithMargin:90];
    
    [_labVolumeForVoice sizeWith:CGSizeMake(60, 20)];
    [_labVolumeForVoice layoutBelow:_labVolumeForBGM margin:15];
    [_labVolumeForVoice alignParentLeftWithMargin:15];
    
    [_sldVolumeForVoice sizeWith:CGSizeMake(270, 20)];
    [_sldVolumeForVoice layoutBelow:_sldVolumeForBGM margin:15];
    [_sldVolumeForVoice alignParentLeftWithMargin:90];
    
    
    
    // 混响
    for (int i=0; i<_audioEffectViewArry.count; ++i) {
        UIButton *btn = (UIButton *)[_audioEffectViewArry objectAtIndex:i];
        [btn sizeWith:CGSizeMake(40,40)];
        [btn layoutBelow:_labVolumeForVoice margin:20];
        float margin = 15 + (btn.width + (self.width-(_audioEffectViewArry.count*btn.width + 30))/(_audioEffectViewArry.count-1))*i;
        [btn alignParentLeftWithMargin:margin];
    }

    // 变声
    for (int i=0; i<_audioEffectViewArry2.count; ++i) {
        // 声音效果，每行放置6个
        int rowNum = i / 6;
        UIButton *btn = (UIButton *)[_audioEffectViewArry2 objectAtIndex:i];
        [btn sizeWith:CGSizeMake(40,40)];
        [btn layoutBelow:_labVolumeForVoice margin:65 + 45*rowNum];
        float margin = 15 + (btn.width + (self.width-(6*btn.width + 30))/(6-1))*(i % 6);
        [btn alignParentLeftWithMargin:margin];
    }
    
    [_labAudioEffect sizeWith:CGSizeMake(self.width, 50)];
    [_labAudioEffect layoutBelow:[_audioEffectViewArry2 objectAtIndex:1] margin:50];
    [_labAudioEffect alignParentLeftWithMargin:0];
    
    //********************
    
    
    //LOG UI
    _cover = [[UIView alloc]init];
    _cover.frame  = CGRectMake(10.0f, 55 + 2*icon_size, self.width - 20, self.height - 75 - 3 * icon_size);
    _cover.backgroundColor = [UIColor whiteColor];
    _cover.alpha  = 0.5;
    _cover.hidden = YES;
    [self addSubview:_cover];
    
    [self addSubview:_vBeauty]; // log挡住了美颜
}

- (void)selectBeauty:(UIButton *)button {
    switch (button.tag) {
        case 0:
        {
            _vBeauty.frame = CGRectMake(0, self.height-170, self.width, 170);
        }
            break;
        case 1:
        {
        }
            break;
        case 2: {
        }
            break;
        case 3: {
        }
        default:
            break;
    }
}

- (void)selectEffect:(UIButton *)button {
    for (int i=0; i<_audioEffectViewArry.count; ++i) {
        UIButton *btn = (UIButton *)[_audioEffectViewArry objectAtIndex:i];
        btn.selected = NO;
        [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
    }
    button.selected = YES;
    [button setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
    
    _audioEffectSelectedType = button.tag;
    
    if (self.delegate) [self.delegate selectEffect:_audioEffectSelectedType];
}

- (void)selectEffect2:(UIButton *)button {
    for (int i=0; i<_audioEffectViewArry2.count; ++i) {
        UIButton *btn = (UIButton *)[_audioEffectViewArry2 objectAtIndex:i];
        btn.selected = NO;
        [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
    }
    button.selected = YES;
    [button setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
    
    _audioEffectSelectedType2 = button.tag;
    
    if (self.delegate) [self.delegate selectEffect2:_audioEffectSelectedType2];
}

- (void)bulletMsg:(TCMsgModel *)msgModel {
    [_msgTableView bulletNewMsg:msgModel];
    if (msgModel.msgType == TCMsgModelType_DanmaMsg) {
        if ([self getLocation:_bulletViewOne] >= [self getLocation:_bulletViewTwo]) {
            [_bulletViewTwo bulletNewMsg:msgModel];
        }else{
            [_bulletViewOne bulletNewMsg:msgModel];
        }
    }
    
    if (msgModel.msgType == TCMsgModelType_MemberEnterRoom || msgModel.msgType == TCMsgModelType_MemberQuitRoom) {
        [_audienceTableView refreshAudienceList:msgModel];
    }
}

- (CGFloat)getLocation:(TCMsgBarrageView *)bulletView {
    UIView *view = bulletView.lastAnimateView;
    CGRect rect = [view.layer.presentationLayer frame];
    return rect.origin.x + rect.size.width;
}

- (void)clickBullet:(UIButton *)btn {
    _bulletBtnIsOn = !_bulletBtnIsOn;
    btn.selected = _bulletBtnIsOn;
}

- (void)clickChat:(UIButton *)button {
    [_msgInputFeild becomeFirstResponder];
}

- (void)clickSend {
    [self textFieldShouldReturn:_msgInputFeild];
}


- (void)showLikeHeart {
    int x = (_btnLog.frame.origin.x + _closeBtn.frame.origin.x) / 2;
    CGRect rect = CGRectMake(x, _closeBtn.frame.origin.y, _closeBtn.frame.size.width, _closeBtn.frame.size.height);
    [self showLikeHeartStartRect:rect];
}

- (void)showLikeHeartStartRect:(CGRect)frame {
    {
        // 星星动画频率限制
        static TCFrequeControl *freqControl = nil;
        if (freqControl == nil) {
            freqControl = [[TCFrequeControl alloc] initWithCounts:10 andSeconds:1];
        }
        
        if (![freqControl canTrigger]) {
            return;
        }
    }

    
    if (_viewsHidden) {
        return;
    }
    UIImageView *imageView = [[UIImageView alloc ] initWithFrame:frame];
    imageView.image = [[UIImage imageNamed:@"img_like"] imageWithTintColor:[UIColor randomFlatDarkColor]];
    [self.superview addSubview:imageView];
    imageView.alpha = 0;
    
    
    [imageView.layer addAnimation:[self hearAnimationFrom:frame] forKey:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [imageView removeFromSuperview];
    });
}

- (CAAnimation *)hearAnimationFrom:(CGRect)frame {
    //位置
    CAKeyframeAnimation *animation=[CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.beginTime = 0.5;
    animation.duration = 2.5;
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount= 0;
    animation.calculationMode = kCAAnimationCubicPaced;
    
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGPoint point0 = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
    
    CGPathMoveToPoint(curvedPath, NULL, point0.x, point0.y);
    
    if (!_heartAnimationPoints) {
        _heartAnimationPoints = [[NSMutableArray alloc] init];
    }
    if ([_heartAnimationPoints count] < 40) {
        float x11 = point0.x - arc4random() % 30 + 30;
        float y11 = frame.origin.y - arc4random() % 60 ;
        float x1 = point0.x - arc4random() % 15 + 15;
        float y1 = frame.origin.y - arc4random() % 60 - 30;
        CGPoint point1 = CGPointMake(x11, y11);
        CGPoint point2 = CGPointMake(x1, y1);
        
        int conffset2 = self.superview.bounds.size.width * 0.2;
        int conffset21 = self.superview.bounds.size.width * 0.1;
        float x2 = point0.x - arc4random() % conffset2 + conffset2;
        float y2 = arc4random() % 30 + 240;
        float x21 = point0.x - arc4random() % conffset21  + conffset21;
        float y21 = (y2 + y1) / 2 + arc4random() % 30 - 30;
        CGPoint point3 = CGPointMake(x21, y21);
        CGPoint point4 = CGPointMake(x2, y2);
        
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point1]];
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point2]];
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point3]];
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point4]];
    }
    
    // 从_heartAnimationPoints中随机选取一组point
    int idx = arc4random() % ([_heartAnimationPoints count]/4);
    CGPoint p1 = [[_heartAnimationPoints objectAtIndex:4*idx] CGPointValue];
    CGPoint p2 = [[_heartAnimationPoints objectAtIndex:4*idx+1] CGPointValue];
    CGPoint p3 = [[_heartAnimationPoints objectAtIndex:4*idx+2] CGPointValue];
    CGPoint p4 = [[_heartAnimationPoints objectAtIndex:4*idx+3] CGPointValue];
    CGPathAddQuadCurveToPoint(curvedPath, NULL, p1.x, p1.y, p2.x, p2.y);
    CGPathAddQuadCurveToPoint(curvedPath, NULL, p3.x, p3.y, p4.x, p4.y);

    
    animation.path = curvedPath;
    
    CGPathRelease(curvedPath);
    
    //透明度变化
    CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnim.fromValue = [NSNumber numberWithFloat:1.0];
    opacityAnim.toValue = [NSNumber numberWithFloat:0];
    opacityAnim.removedOnCompletion = NO;
    opacityAnim.beginTime = 0;
    opacityAnim.duration = 3;
    
    //比例
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    //        int scale = arc4random() % 5 + 5;
    scaleAnim.fromValue = [NSNumber numberWithFloat:.0];//[NSNumber numberWithFloat:((float)scale / 10)];
    scaleAnim.toValue = [NSNumber numberWithFloat:1];
    scaleAnim.removedOnCompletion = NO;
    scaleAnim.fillMode = kCAFillModeForwards;
    scaleAnim.duration = .5;
    
    CAAnimationGroup *animGroup = [CAAnimationGroup animation];
    animGroup.animations = [NSArray arrayWithObjects: scaleAnim,opacityAnim,animation, nil];
    animGroup.duration = 3;
    
    return animGroup;
}

- (BOOL)isAlreadyInAudienceList:(TCMsgModel *)model {
    return [_audienceTableView isAlreadyInAudienceList:model];
}

//监听键盘高度变化
- (void)keyboardFrameDidChange:(NSNotification*)notice {
    NSDictionary * userInfo = notice.userInfo;
    NSValue * endFrameValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endFrame = endFrameValue.CGRectValue;
    [UIView animateWithDuration:0.25 animations:^{
        if (endFrame.origin.y == self.height) {
            self->_msgInputView.y =  endFrame.origin.y;
        }else{
            self->_msgInputView.y =  endFrame.origin.y - _msgInputView.height;
        }
    }];
}

// 监听登出消息
- (void)onLogout:(NSNotification*)notice {
    [self closeInternal];
}

#pragma mark TCAnchorToolbarDelegate
- (void)closeVC {
    _closeAlert = [[UIAlertView alloc] initWithTitle:nil message:kTipsMsgStopPush  delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [_closeAlert show];
}

- (void)closeVCWithError:(NSString *)msg Alert:(BOOL)isAlert Result:(BOOL)isShowResult {
    if (isAlert) {
        if (isShowResult) {
            _closeErrRstAlert = [[UIAlertView alloc] initWithTitle:nil message:msg  delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [_closeErrRstAlert show];
        } else {
            _closeErrAlert = [[UIAlertView alloc] initWithTitle:nil message:msg  delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [_closeErrAlert show];
        }
    } else {
        [[HUDHelper sharedInstance] tipMessage:msg];
        [self closeInternal];
    }
}

- (void)enableMix:(BOOL)disable {
    [_btnMusic setEnabled:disable];
    
    _vMusicPanel.hidden = YES;
}

- (void)closeInternal {
    [_topView pauseLive];
    [_bulletViewOne stopAnimation];
    [_bulletViewTwo stopAnimation];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self.delegate) [self.delegate closeRTMP];
    if(self.delegate) [self.delegate closeVC];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ( (buttonIndex == 1 && alertView == _closeAlert)
        || (buttonIndex == 0 && alertView == _closeErrAlert)
        || (buttonIndex == 0 && alertView == _closeErrRstAlert)) {
        if (self.delegate) {
            [_topView pauseLive];
            [_bulletViewOne stopAnimation];
            [_bulletViewTwo stopAnimation];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
           
            [self.delegate closeRTMP];
            
            if (alertView == _closeAlert || alertView == _closeErrRstAlert) {
                // 直播过程中退出时展示统计信息
                __weak __typeof(self) weakSelf = self;
                _resultView = [[TCPushShowResultView alloc] initWithFrame:self.bounds resultData:_topView backHomepage:^{
                    [weakSelf.delegate closeVC];
                }];
            } else if (alertView == _closeErrAlert) {
                [self.delegate closeVC];
            }
            
            [self addSubview:_resultView];
        }
    }
}

- (void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer {
    [_msgInputFeild resignFirstResponder];
    if (self.delegate) {
        [self.delegate clickScreen:gestureRecognizer];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {

    if (_vBeauty.hidden == NO && CGRectContainsPoint(_vBeauty.frame, point)) {
        [self removeGestureRecognizer:_tap];
    }
    
    if (_vMusicPanel.hidden == NO && CGRectContainsPoint(_vMusicPanel.frame, point)) {
        [self removeGestureRecognizer:_tap];
    }
    
    return YES;
}


- (void)clickCamera:(UIButton *)button {
    if (self.delegate) [self.delegate clickCamera:button];
}

- (void)clickBeauty:(UIButton *)button {
    if (self.delegate) [self.delegate clickBeauty:button];
}

- (void)clickMusic:(UIButton *)button {
    [self selectEffect:[_audioEffectViewArry objectAtIndex:_audioEffectSelectedType]];
    [self selectEffect2:[_audioEffectViewArry2 objectAtIndex:_audioEffectSelectedType2]];
    if (self.delegate) [self.delegate clickMusic:button];
}

- (void)clickMusicSelect:(UIButton *)button {
    if (self.delegate) [self.delegate clickMusicSelect:button];
}

- (void)clickMusicClose:(UIButton *)button {
    if (self.delegate) [self.delegate clickMusicClose:button];
}

- (void)clickTorch:(UIButton *)button {
    if (self.delegate) [self.delegate clickTorch:button];
}

- (void)clickLog:(UIButton *)button {
    if (self.delegate) [self.delegate clickLog:button];
}

- (void)sliderValueChange:(UISlider*)slider {
    if (self.delegate) [self.delegate sliderValueChange:slider];
}

- (void)sliderValueChangeEx:(UISlider *)slider {
    if (self.delegate) [self.delegate sliderValueChangeEx:slider];
}

- (void)motionTmplSelected:(NSString *)materialID {
    if ([self.delegate respondsToSelector:@selector(motionTmplSelected:)]) {
        [self.delegate motionTmplSelected:materialID];
    }
}

- (void)handleIMMessage:(IMUserAble *)info msgText:(NSString *)msgText
{
    switch (info.cmdType) {
        case TCMsgModelType_NormalMsg: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userName = [info imUserName];
            msgModel.userMsg  =  msgText;
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_NormalMsg;
            [self bulletMsg:msgModel];
            break;
        }
            
        case TCMsgModelType_MemberEnterRoom: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userId = info.imUserId;
            msgModel.userName = info.imUserName;
            msgModel.userMsg  =  @"加入直播";
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_MemberEnterRoom;
            
            //收到新增观众消息，判断只有没在观众列表中，数量才需要增加1
            if (![self isAlreadyInAudienceList:msgModel])
            {
                [_topView onUserEnterLiveRoom];
            }
            [self bulletMsg:msgModel];
            
            break;
        }

        case TCMsgModelType_MemberQuitRoom: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userId = info.imUserId;
            msgModel.userName = info.imUserName;
            msgModel.userMsg  =  @"退出直播";
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_MemberQuitRoom;
            
            [self bulletMsg:msgModel];
            [_topView onUserExitLiveRoom];
            
            break;
        }
            
        case TCMsgModelType_Praise: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userName = [info imUserName];
            msgModel.userMsg  =  @"点了个赞";
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_Praise;
            
            [self bulletMsg:msgModel];
            [self showLikeHeart];
            [_topView onUserSendLikeMessage];
            break;
        }
            
        case TCMsgModelType_DanmaMsg: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userName = [info imUserName];
            msgModel.userMsg  =  msgText;
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_DanmaMsg;
            
            [self bulletMsg:msgModel];

            break;
        }
            
        default:
            break;
    }
}

- (void)triggeValue {

}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _msgInputFeild.text = @"";
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    _msgInputFeild.text = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSString *textMsg = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (textMsg.length <= 0) {
        textField.text = @"";
        [HUDHelper alert:@"消息不能为空"];
        return YES;
    }
    
    TCUserProfileData  *profile = [[TCUserProfileModel sharedInstance] getUserProfile];
    TCMsgModel *msgModel = [[TCMsgModel alloc] init];
    msgModel.userName = @"我";
    msgModel.userMsg  =  textMsg;
    msgModel.userHeadImageUrl = profile.faceURL;
    
    if (_bulletBtnIsOn) {
        msgModel.msgType  = TCMsgModelType_DanmaMsg;
        [[MLVBLiveRoom sharedInstance] sendRoomCustomMsg:[@(TCMsgModelType_DanmaMsg) stringValue] msg:textMsg completion:nil];
    }else{
        msgModel.msgType = TCMsgModelType_NormalMsg;
        [[MLVBLiveRoom sharedInstance] sendRoomTextMsg:textMsg completion:nil];
    }

    [self bulletMsg:msgModel];
    [_msgInputFeild resignFirstResponder];
    return YES;
}

#pragma mark - 滑动隐藏界面UI

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    _touchBeginLocation = [touch locationInView:self];
    _touchPrevLocation = _touchBeginLocation;
    
    if (CGRectContainsPoint(_vMusicPanel.frame, _touchBeginLocation)) {
        _isTouchMusicPanel = YES;
    } else {
        _isTouchMusicPanel = NO;
    }
    if (_vBeauty.hidden == NO) {
        _vBeauty.hidden = YES;
        [self setButtonHidden:NO];
        [self addGestureRecognizer:_tap];
    }
    if (_vMusicPanel.hidden == NO && !_isTouchMusicPanel) {
        [_vMusicPanel hide];
        [self addGestureRecognizer:_tap];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:self];
    
    if (!_isTouchMusicPanel) {
        [self endMove:location.x - _touchBeginLocation.x];
    }
    else {
        _isTouchMusicPanel = NO;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:self];
    CGPoint prevLocation = [touch previousLocationInView:self];
    
    // 拖动音乐浮窗
    if (_isTouchMusicPanel) {
        CGRect frame = _vMusicPanel.frame;
        CGPoint newOriginPoint = CGPointMake(frame.origin.x + location.x - prevLocation.x, frame.origin.y + location.y - prevLocation.y);

        if (10 <= newOriginPoint.x && newOriginPoint.x + frame.size.width <= SCREEN_WIDTH - 10
            && 50 <= newOriginPoint.y && newOriginPoint.y + frame.size.height <= SCREEN_HEIGHT - 30) {
            frame.origin = newOriginPoint;
            [_vMusicPanel setFrame:frame];
        }
    }
}

- (void)endMove:(CGFloat)moveX {
    [UIView animateWithDuration:0.2 animations:^{
        if(moveX > 10){
            for (UIView *view in self.subviews) {
                if (![view isEqual:self->_closeBtn] && ![view isEqual:self->_resultView]) {
                    CGRect rect = view.frame;
                    if (rect.origin.x >= 0 && rect.origin.x < SCREEN_WIDTH) {
                        rect = CGRectOffset(rect, self.width, 0);
                        view.frame = rect;
                        [self resetViewAlpha:view];
                    }
                }
            }
        }else if(moveX < -10){
            for (UIView *view in self.subviews) {
                if (![view isEqual:self->_closeBtn] && ![view isEqual:self->_resultView]) {
                    CGRect rect = view.frame;
                    if (rect.origin.x >= SCREEN_WIDTH) {
                        rect = CGRectOffset(rect, -self.width, 0);
                        view.frame = rect;
                        [self resetViewAlpha:view];
                    }
                    
                }
            }
        }
    }];
}

- (void)resetViewAlpha:(UIView *)view {
    CGRect rect = view.frame;
    if (rect.origin.x  >= SCREEN_WIDTH || rect.origin.x < 0) {
        view.alpha = 0;
        _viewsHidden = YES;
    }else{
        view.alpha = 1;
        _viewsHidden = NO;
    }
    if (view == _cover)
        _cover.alpha = 0.5;
}
@end


@implementation TCPushShowResultView
{
    UILabel  *_titleLabel;
    UILabel  *_durationLabel;
    UILabel  *_durationTipLabel;
    UILabel  *_viewerCountLabel;
    UILabel  *_viewerCountTipLabel;
    UILabel  *_praiseLabel;
    UILabel  *_praiseTipLabel;
    UIButton *_backBtn;
    
    ShowResultComplete _backHomepage;
    TCShowLiveTopView *_resultData;
}

- (instancetype)initWithFrame:(CGRect)frame resultData:(TCShowLiveTopView *)resultData backHomepage:(ShowResultComplete)backHomepage {
    if (self = [super initWithFrame:frame]) {
        _resultData = resultData;
        _backHomepage = backHomepage;
        
        [self initUI];
        [_backBtn addTarget:self action:@selector(clickBackBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)initUI {
    int duration = (int)[_resultData getLiveDuration];
    int hour = duration / 3600;
    int min = (duration - hour * 3600) / 60;
    int sec = duration - hour * 3600 - min * 60;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [_titleLabel setTextColor:[UIColor colorWithRed:10/255.0 green:204/255.0 blue:172/255.0 alpha:1]];
    [_titleLabel setText:@"直播结束啦!"];
    [self addSubview:_titleLabel];
    
    
    _durationLabel = [[UILabel alloc] init];
    _durationLabel.textAlignment = NSTextAlignmentCenter;
    _durationLabel.font = [UIFont boldSystemFontOfSize:20];
    _durationLabel.textColor = [UIColor whiteColor];
    [_durationLabel setText:[NSString stringWithFormat:@"%02d:%02d:%02d", hour, min, sec]];
    [self addSubview:_durationLabel];
    
    _durationTipLabel = [[UILabel alloc] init];
    _durationTipLabel.textAlignment = NSTextAlignmentCenter;
    _durationTipLabel.font = [UIFont boldSystemFontOfSize:14];
    _durationTipLabel.textColor = [UIColor whiteColor];
    [_durationTipLabel setText:[NSString stringWithFormat:@"直播时长"]];
    [self addSubview:_durationTipLabel];
    
    
    _viewerCountLabel = [[UILabel alloc] init];
    _viewerCountLabel.textAlignment = NSTextAlignmentCenter;
    _viewerCountLabel.font = [UIFont boldSystemFontOfSize:20];
    _viewerCountLabel.textColor = [UIColor whiteColor];
    [_viewerCountLabel setText:[NSString stringWithFormat:@"%ld", [_resultData getTotalViewerCount]]];
    [self addSubview:_viewerCountLabel];
    
    _viewerCountTipLabel = [[UILabel alloc] init];
    _viewerCountTipLabel.textAlignment = NSTextAlignmentCenter;
    _viewerCountTipLabel.font = [UIFont boldSystemFontOfSize:14];
    _viewerCountTipLabel.textColor = [UIColor whiteColor];
    [_viewerCountTipLabel setText:[NSString stringWithFormat:@"观看人数"]];
    [self addSubview:_viewerCountTipLabel];
    
    
    _praiseLabel = [[UILabel alloc] init];
    _praiseLabel.textAlignment = NSTextAlignmentCenter;
    _praiseLabel.font = [UIFont boldSystemFontOfSize:20];
    _praiseLabel.textColor = [UIColor whiteColor];
    [_praiseLabel setText:[NSString stringWithFormat:@"%ld\n", [_resultData getLikeCount]]];
    [self addSubview:_praiseLabel];
    
    _praiseTipLabel = [[UILabel alloc] init];
    _praiseTipLabel.textAlignment = NSTextAlignmentCenter;
    _praiseTipLabel.font = [UIFont boldSystemFontOfSize:14];
    _praiseTipLabel.textColor = [UIColor whiteColor];
    [_praiseTipLabel setText:[NSString stringWithFormat:@"获赞数量"]];
    [self addSubview:_praiseTipLabel];
    
    
    _backBtn = [[UIButton alloc] init];
    [_backBtn setBackgroundImage:[UIImage imageNamed:@"btn_back_to_main"] forState:UIControlStateNormal];
    _backBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [_backBtn setTitle:@"返回首页" forState:UIControlStateNormal];
    [_backBtn setTitleColor:[UIColor colorWithRed:10/255.0 green:204/255.0 blue:172/255.0 alpha:1] forState:UIControlStateNormal];
    [self addSubview:_backBtn];
    
    [self relayout];
}

- (void)relayout {
    CGRect rect = self.bounds;
    
    [_titleLabel sizeWith:CGSizeMake(rect.size.width, 24)];
    [_titleLabel alignParentTopWithMargin:125];
    
    [_durationLabel sizeWith:CGSizeMake(rect.size.width, 15)];
    [_durationLabel layoutBelow:_titleLabel margin:55];
    [_durationTipLabel sizeWith:CGSizeMake(rect.size.width, 14)];
    [_durationTipLabel layoutBelow:_durationLabel margin:7];
    
    [_viewerCountLabel sizeWith:CGSizeMake(rect.size.width, 15)];
    [_viewerCountLabel layoutBelow:_durationTipLabel margin:35];
    [_viewerCountTipLabel sizeWith:CGSizeMake(rect.size.width, 14)];
    [_viewerCountTipLabel layoutBelow:_viewerCountLabel margin:7];
    
    [_praiseLabel sizeWith:CGSizeMake(rect.size.width, 15)];
    [_praiseLabel layoutBelow:_viewerCountTipLabel margin:35];
    [_praiseTipLabel sizeWith:CGSizeMake(rect.size.width, 14)];
    [_praiseTipLabel layoutBelow:_praiseLabel margin:7];
    
    [_backBtn sizeWith:CGSizeMake(225, 35)];
    [_backBtn layoutParentHorizontalCenter];
    [_backBtn layoutBelow:_praiseTipLabel margin:52.5];
    
    [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.9]];
}

- (void)clickBackBtn {
    _backHomepage();
}

@end
