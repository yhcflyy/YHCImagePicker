//
//  AFFVCSPhotoBrowser.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/12.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFFPhotoModel.h"

@interface AFFVCSPhotoBrowser : UIViewController

@property (nonatomic, strong) NSMutableArray *mArrData;
@property (nonatomic, strong) NSMutableArray *mArrScope;
@property (nonatomic,assign ) NSInteger index;
@property (nonatomic, assign) NSInteger maxSelCount;
@property (nonatomic, strong) NSString      *imagePath;///< 图片选择交互文件夹路径（外部赋值），默认为聊天消息路径

@property (nonatomic,copy) void(^sendBlock)(NSArray<AFFDataPhotoInfo*> *arr);
@end
