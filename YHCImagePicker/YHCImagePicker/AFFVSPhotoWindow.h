//
//  AFFVSPhotoWindow.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/14.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFFSPhotoPicker.h"

@class AFFVSPhotoWindow;
@protocol AFFVSPhotoWindowDelegate <NSObject>

@required
/**
 *  发送出来的图片数组,数组为空或nil表示取消槽子
 *
 *  @param pickerWindow window
 *  @param images 图片数组
 */
- (void)photoWindowSendImages:(AFFVSPhotoWindow*)pickerWindow images:(NSArray<AFFDataPhotoInfo*>*)images;

@end

@interface AFFVSPhotoWindow : UIWindow


@property (nonatomic,assign ) id<AFFVSPhotoWindowDelegate> delegate;
@property (nonatomic,assign ) NSInteger                maxSelCount;///< 最多选择几张，默认9张，仅图片多选有效。
@property (nonatomic,assign ) BOOL                     isPickVideo;///< 是否是选择视频，默认NO，即默认是选择图片
@property (nonatomic,assign ) BOOL                     isAllowMulSel;///< 是否允许多选，默认多选
// 图片裁剪
@property (nonatomic,strong ) NSString                 *imagePath;///< 图片选择交互文件夹路径（外部赋值），默认为聊天消息路径
@property (nonatomic, assign) NSInteger                maxImageShowInPicker;///< 在picker快速选图中最多能显示几张图片,默认是30张

-(void)dismiss;
/**
 *  picker Window的初始化方法，圈子之类的情况必须使用这个方式创建
 *
 *  @param cutType     裁剪类型
 *  @param isPickVideo 是否选择视频
 *  @param maxSelect   最多能选择的个数
 *  @param imagePath   图片的保存路径
 *  @param isCleanFolder   是否清理图片目录,如果传NO需要在外部清空文件夹
 *
 *  @return 实例
 */
-(instancetype)initWithCutType:(BOOL)isPickVideo
                     maxSelect:(NSInteger)maxSelect
                     imagePath:(NSString*)imagePath
                 isAllowMulSel:(BOOL)isAllowMulSel
                 isCleanFolder:(BOOL)isCleanFolder;

-(instancetype)initWithCutType:(BOOL)isPickVideo
                     maxSelect:(NSInteger)maxSelect
                     imagePath:(NSString*)imagePath
                   selectedArr:(NSArray*)selectedArr
                 isAllowMulSel:(BOOL)isAllowMulSel
                 isCleanFolder:(BOOL)isCleanFolder;

/**
 * lsb 聊天、普通选择图片用；其他控制可同属属性设置，初始化方法要简单，有必要的可重载其他参数
 * @param  isPickVideo  是否选择视频
 * @param  maxSelect  最大选择张数
 
 * @return
 */
-(instancetype)initWithType:(BOOL)isPickVideo
                  maxSelect:(NSInteger)maxSelect;

/**
 *  默认会删除临时文件夹
 *
 *  @return
 */
-(instancetype)init;
/**
 *  清空文件夹
 *
 *  @param path 传nil或空则清空默认目录
 */
+(BOOL)cleanFolder:(NSString*)path;
@end
