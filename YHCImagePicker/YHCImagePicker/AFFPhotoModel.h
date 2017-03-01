//
//  AFFPhotoModel.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define kPhotoListCellWidth (SCREEN_WIDTH -((CellNum-1)*kCellMargin))/(CellNum)
#define kNavigationBar_Height 44.0f
#define kStatusBar_Height 20.0f
#define kHeight_FullScreenWith(heightof320)    ((SCREEN_WIDTH*heightof320)/320.0f)
#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]


static NSString *reuseCellIdentifier = @"cellIdentifier";


typedef enum : NSUInteger {
    AFFAssetMediaType_Photo = 0,
    AFFAssetMediaType_LivePhoto,
    AFFAssetMediaType_Video,
    AFFAssetMediaType_Audio
} AFFAssetMediaType;


@interface AFFPhotoModel : NSObject

@property (nonatomic,assign   ) BOOL              selected;///<是否被选中
@property (nonatomic,assign   ) BOOL              isRaw;///<是否是原图
@property (nonatomic,strong   ) id                asset;///<iOS7及一下是ALAsset,iOS8及以上是PHAsset
@property (nonatomic, assign  ) NSUInteger        byteLen;///<原图的大小
@property (nonatomic, assign  ) AFFAssetMediaType type;///<资源类型
@property (nonatomic, copy    ) NSString          *timeLength;///<视频的长度
@property (nonatomic,assign   ) CGSize            size;///<图片的长宽
@property (nonatomic,assign   ) NSUInteger        duration;///<视频的时长
/// 用一个PHAsset/ALAsset实例，初始化一个照片模型
+ (instancetype)modelWithAsset:(id)asset type:(AFFAssetMediaType)type;
+ (instancetype)modelWithAsset:(id)asset type:(AFFAssetMediaType)type duration:(NSUInteger)duration;

@end

/**
 *  相册模型
 */
@interface AFFAlbumModel : NSObject

@property (nonatomic, strong) NSString   *name;///< 相册名称
@property (nonatomic, assign) NSInteger  count;///< 相册总共的图片数
@property (nonatomic, strong) id         result;///< PHFetchResult<PHAsset> 或 ALAssetsGroup<ALAsset>

@property (nonatomic, strong) NSArray    *models;///<全部照片
@property (nonatomic, strong) NSArray    *selectedModels;///<选中的照片
@property (nonatomic, assign) NSUInteger selectedCount;///<选中的照片数量

@end


/**
 * 导出模型
 */
@interface AFFDataPhotoInfo : NSObject

@property (nonatomic, strong) NSString     *md5;///< 唯一标示
@property (nonatomic, strong) NSString     *fullPath;///< 图片的完整路径
@property (nonatomic, strong) UIImage      *thumb;///< 缩略图
@property (nonatomic, assign) BOOL         isRaw;
@property (nonatomic, strong) id           asset;///< PHAsset或ALAsset
@property (nonatomic, assign) NSUInteger   length;///<图片的字节长度
@property (nonatomic, assign) NSUInteger duration;    ///< 视频时长

@end
