//
//  AFFVSPhotoPickerCell.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFFPhotoModel.h"

@interface AFFVSPhotoCell : UICollectionViewCell

@property(nonatomic,strong)AFFPhotoModel *photoModel;
@property(nonatomic,copy) void(^btnSelectBlock)(AFFPhotoModel *photoModel,AFFVSPhotoCell *cell);
-(void)setBtnClick:(BOOL)select model:(AFFPhotoModel*)photoModel;
/**
 *  隐藏选择按钮
 */

-(void)refreshCell:(AFFPhotoModel*)photoModel isFormPicker:(BOOL)isFormPicker;

-(void)hideBtn;

@end
