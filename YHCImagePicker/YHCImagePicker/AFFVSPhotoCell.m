//
//  AFFVSPhotoPickerCell.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#define kCellMargin 2
#define CellNum SCREEN_WIDTH > 504 ? 7 : 4
#define kPhotoListCellWidth (SCREEN_WIDTH -((CellNum-1)*kCellMargin))/(CellNum)

#import "AFFVSPhotoCell.h"
#import "AFFPhotoPickerManager.h"

@interface AFFVSPhotoCell()

@property (nonatomic,weak) UIImageView *imgV;
@property (nonatomic,weak) UIView      *bottomView;
@property (nonatomic,weak) UILabel     *lblBytes;
@property (nonatomic,weak) UIImageView *imgVVideo;
@property (nonatomic,weak) UILabel     *lblDuration;
@property (nonatomic,weak) UIButton    *btnSelect;

@end

@implementation AFFVSPhotoCell
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self setupUI];
    }
    return self;
}

-(void)setupUI{
    UIImageView *imgV = [[UIImageView alloc]initWithFrame:self.bounds];
    imgV.contentMode = UIViewContentModeScaleAspectFill;
    imgV.clipsToBounds = YES;
    [self addSubview:imgV];
    self.imgV = imgV;
    
    UIButton *btnSelect = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.frame)-27, 0, 32, 32)];
    [btnSelect setImage:[UIImage imageNamed:@"ic_check_alpha_nor"] forState:UIControlStateNormal];
    [btnSelect setImage:[UIImage imageNamed:@"ic_check_blue_sel"] forState:UIControlStateSelected];
    [btnSelect addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnSelect];
    self.btnSelect = btnSelect;
    
    UIView *bottomView = [[UIView alloc]initWithFrame:
                          CGRectMake(0,CGRectGetHeight(self.frame)-20,CGRectGetWidth(self.frame),20)];
    bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self addSubview:bottomView];
    self.bottomView = bottomView;
    
    [self setImageView];
    [self setVideoView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(floatEffect:) name:@"PhotoPickercontentOffsetX" object:nil];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
//按钮悬浮效果
-(void)floatEffect:(NSNotification*)notify{
    NSNumber *num = (NSNumber*)notify.object;
    CGFloat offSetX = [num floatValue];
    CGFloat x = self.frame.origin.x;
    CGFloat width = CGRectGetWidth(self.frame);
    //根据坐标找到最后一个cell
    if(x < offSetX && x + width > offSetX){
        CGRect frame = [self.superview convertRect:self.frame toView:nil];
        CGFloat btnWidth = CGRectGetWidth(self.btnSelect.frame);
        CGFloat  x = SCREEN_WIDTH - frame.origin.x - CGRectGetWidth(self.btnSelect.frame);
        if(x >= 0){
            frame = self.btnSelect.frame;
            frame.origin.x = x;
            self.btnSelect.frame = frame;
        }else{
            self.btnSelect.frame = CGRectMake(0, 0, btnWidth, btnWidth);
        }
    }else{
        self.btnSelect.frame = CGRectMake(CGRectGetWidth(self.frame)-27, 0, 27, 27);
    }
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.imgV.frame = self.bounds;
    CGFloat btnWidth = CGRectGetWidth(self.btnSelect.frame);
    self.btnSelect.frame = CGRectMake(CGRectGetWidth(self.frame)-btnWidth, 0, btnWidth, btnWidth);
    self.bottomView.frame =  CGRectMake(0,CGRectGetHeight(self.frame)-20,CGRectGetWidth(self.frame),20);
    self.imgVVideo.frame = CGRectMake(CGRectGetWidth(self.bottomView.frame)-20, (CGRectGetHeight(self.bottomView.frame) - 9)/2, 15, 9);;
}

-(void)setImageView{
    UILabel *lblBytes = [[UILabel alloc]initWithFrame:self.bottomView.bounds];
    lblBytes.textColor = [UIColor whiteColor];
    lblBytes.textAlignment=NSTextAlignmentRight;
    lblBytes.font= [UIFont systemFontOfSize:14];
    [self.bottomView addSubview:lblBytes];
    self.lblBytes = lblBytes;
}

-(void)setVideoView{
    CGRect frame = self.bottomView.bounds;
    frame.size.width = CGRectGetWidth(self.bottomView.bounds)/2;
    UILabel *lblDuration = [[UILabel alloc]initWithFrame:frame];
    lblDuration.textColor = [UIColor whiteColor];
    lblDuration.textAlignment=NSTextAlignmentLeft;
    lblDuration.font= [UIFont systemFontOfSize:14];
    [self.bottomView addSubview:lblDuration];
    self.lblDuration = lblDuration;
    
    frame = CGRectMake(CGRectGetWidth(self.bottomView.frame)-20, (CGRectGetHeight(self.bottomView.frame) - 9)/2, 15, 9);
    UIImageView *imgVVideo = [[UIImageView alloc]initWithFrame:frame];
    imgVVideo.contentMode = UIViewContentModeScaleAspectFit;
    imgVVideo.image = [UIImage imageNamed:@"ic_chat_video_sign"];
    [self.bottomView addSubview:imgVVideo];
    self.imgVVideo = imgVVideo;
}

-(void)hideVideoView{
    self.lblDuration.hidden = YES;
    self.imgVVideo.hidden = YES;
    self.lblBytes.hidden = NO;
}

-(void)hideImageView{
    self.lblDuration.hidden = NO;
    self.imgVVideo.hidden = NO;
    self.lblBytes.hidden = YES;
}

-(void)refreshCell:(AFFPhotoModel*)photoModel isFormPicker:(BOOL)isFormPicker{
    [self layoutSubviews];
    _photoModel = photoModel;

    __weak typeof(self) weakSelf = self;
    self.btnSelect.selected = self.photoModel.selected;
    AFFAssetMediaType type = [[AFFPhotoPickerManager shareManager] getAssetType:photoModel.asset];
    if(type == AFFAssetMediaType_Video){
        [self hideImageView];
        self.bottomView.hidden = NO;
        if(photoModel.selected){
            weakSelf.lblDuration.text = photoModel.timeLength;
        }else{
            weakSelf.lblDuration.hidden = YES;
        }
    }else if (type == AFFAssetMediaType_Photo){
        [self hideVideoView];
        if(photoModel.isRaw && photoModel.selected){
            self.bottomView.hidden = NO;
            [[AFFPhotoPickerManager shareManager] getAssetLength:photoModel block:^(AFFPhotoModel *model) {
                weakSelf.lblBytes.text = [[AFFPhotoPickerManager shareManager] getBytesFromDataLength:model.byteLen];
            }];
        }else{
            self.bottomView.hidden = YES;
        }
    }
    if(isFormPicker){
        CGFloat scale = 1.5;
        [[AFFPhotoPickerManager shareManager] getPhotoWithAsset:photoModel.asset photoWidth:kPhotoListCellWidth*scale block:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            weakSelf.imgV.image = photo;
        }];
    }else{
        [[AFFPhotoPickerManager shareManager] getThumbWithAsset:photoModel.asset photoWidth:kPhotoListCellWidth block:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            weakSelf.imgV.image = photo;
        }];
    }
}

-(void)btnClick{
    if(self.btnSelectBlock){
        self.btnSelectBlock(self.photoModel,self);
    }
}
-(void)setBtnClick:(BOOL)select model:(AFFPhotoModel*)photoModel{
    if(select){
        self.btnSelect.transform=CGAffineTransformMakeScale(0.1, 0.1);
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:1 options:UIViewAnimationOptionCurveLinear animations:^{
            self.btnSelect.transform=CGAffineTransformMakeScale(1, 1);
        } completion:nil];
        if(photoModel.type == AFFAssetMediaType_Video){
            self.bottomView.hidden = NO;
            self.lblDuration.hidden = NO;
            self.lblDuration.text = photoModel.timeLength;
        }else if(photoModel.type == AFFAssetMediaType_Photo){
            if(photoModel.isRaw == YES){
                self.bottomView.hidden = NO;
                self.lblBytes.hidden = NO;
            }else{
                self.bottomView.hidden = YES;
            }
        }
    }else{
        if(photoModel.type == AFFAssetMediaType_Video){
            self.bottomView.hidden = NO;
            self.lblDuration.hidden = YES;
        }else{
            self.bottomView.hidden = YES;
        }
    }
    self.btnSelect.selected = select;
}

-(void)hideBtn{
    self.btnSelect.hidden = YES;
}

@end
