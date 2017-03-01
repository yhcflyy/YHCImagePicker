//
//  AFFSPhotoPicker.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "AFFPhotoPickerManager.h"



@class AFFSPhotoPicker;
//@protocol AFFSPhotoPickerDeleagete <NSObject>
//
//@required
///**
// * 选择图片结果
// * @param  picker  选择器
// * @param  images  返回选择的图片
// 
// * @return
// */
////- (void)photoPicker:(AFFSPhotoPicker*)picker images:(NSArray<AFFDataPhotoInfo*>*)images;
////
////- (void)photoPickerDismiss:(AFFSPhotoPicker*)picker;
//
//@end

/**
 * 图片选择
 1.内部集成拍照、录像
 2.内部集成选择相册
 3.内部集成图片选择裁剪
 */
@interface AFFSPhotoPicker : UIViewController
@property (nonatomic,strong ) NSMutableArray *mArrData;
@property (nonatomic,strong ) NSMutableArray *mArrScope;


@property (nonatomic,assign ) NSInteger      maxSelCount;///< 最多选择几张，默认9张，仅图片多选有效。
@property (nonatomic,assign ) BOOL           isPickVideo;
@property (nonatomic,assign ) BOOL           isAllowMulSel;///< 是否允许多选，默认多选
@property (nonatomic,assign ) NSInteger      maxImageShowInPicker;///< 在picker快速选图中最多能显示几张图片
@property (nonatomic,strong ) NSMutableArray *arrSelect;///< 选中的图片
// 图片裁剪
@property (nonatomic, strong) NSString       *imagePath;///< 图片选择交互文件夹路径（外部赋值），默认为聊天消息路径

@property (nonatomic,copy) void(^sendBlock)(NSArray<AFFDataPhotoInfo*>*images);
@property (nonatomic,copy) void(^dismissBlock)();

@end


