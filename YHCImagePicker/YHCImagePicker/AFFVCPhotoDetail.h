//
//  AFFVCPhotoDetail.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//
/**
 *  指定相册的相片列表
 */
#import <UIKit/UIKit.h>
#import "AFFPhotoModel.h"
#import "AFFVSPhotoCell.h"

@interface AFFVCPhotoDetail : UIViewController

@property (nonatomic,strong) NSMutableArray *mArrData;
@property (nonatomic,strong) NSMutableArray *mArrScope;
@property (nonatomic,strong ) AFFAlbumModel  *album;
@property (nonatomic,assign ) BOOL           isPickVideo;
@property (nonatomic, assign) NSInteger      maxSelCount;
@property (nonatomic, strong) NSString       *imagePath;///< 图片选择交互文件夹路径（外部赋值），默认为聊天消息路径
@property (nonatomic,assign ) BOOL           isAllowMulSel;///< 是否允许多选，默认多选
@property (nonatomic,copy) void(^sendBlock)(NSArray<AFFDataPhotoInfo*> *arr);
@property (nonatomic,copy) void(^dismissBlock)();

@end


@interface AFFVPhotoDetailFooter : UICollectionReusableView

@property(nonatomic,strong) UILabel *lblCount;

@end
