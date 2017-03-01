//
//  AFFVCPhotoGroupList.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//
/**
 *  相册列表
 */
#import <UIKit/UIKit.h>
#import "AFFPhotoModel.h"

@interface AFFVCPhotoGroupList : UIViewController
@property (nonatomic,assign ) BOOL          isPickVideo;
@property (nonatomic, assign) NSInteger     maxSelCount;
@property (nonatomic, strong) NSString      *imagePath;///< 图片选择交互文件夹路径（外部赋值），默认为聊天消息路径
@property (nonatomic,assign ) BOOL                     isAllowMulSel;///< 是否允许多选，默认多选
@property (nonatomic, strong) NSMutableArray *mArrData;///< 图片选择交互文件夹路径（外部赋值），默认为聊天消息路径


@property (nonatomic,copy) void(^sendBlock)(NSArray<AFFDataPhotoInfo*> *arr);

@end


/**
 * 相册列表cell
 */
@interface AFFVPhotoGroupListCell : UITableViewCell
@property(nonatomic,strong) AFFAlbumModel *model;
@end
