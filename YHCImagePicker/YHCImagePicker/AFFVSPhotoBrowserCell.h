//
//  AFFVSPhotoBrowserCell.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/12.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFFPhotoModel.h"

@interface AFFVSPhotoBrowserCell : UICollectionViewCell

@property(nonatomic,strong)AFFPhotoModel *photoModel;

-(void)setCellImageNil;

@property(nonatomic,copy) void(^tapBlock)();
@end


@interface AFFVSPhotoBrowserVideoCell : UICollectionViewCell

@property(nonatomic,strong)AFFPhotoModel *photoModel;
@property(nonatomic,copy) void(^tapBlock)();
@property(nonatomic,copy) void(^hideBlock)();

@end
