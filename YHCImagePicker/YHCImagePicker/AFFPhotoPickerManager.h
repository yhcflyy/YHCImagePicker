//
//  AFFPhotoPickerManager.h
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AFFPhotoModel.h"

@interface AFFPhotoPickerManager : NSObject

@property (nonatomic, strong) PHCachingImageManager *cachingImageManager;
/// 对照片排序，按修改时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
@property (nonatomic, assign) BOOL           sortAscendingByModificationDate;
@property (nonatomic, assign) NSInteger      maxSelect;
@property (nonatomic, strong) NSMutableArray *arrSelect;///<选中的图片

+(AFFPhotoPickerManager*)shareManager;

/**
 *  获取相册是否授权
 *
 *  @return 返回YES，如果得到了授权
 */
- (BOOL)authorizationStatusAuthorized;


/**
 *  获取相册列表
 *
 *  @param allowPickingVideo 是选择视频还是图片
 *  @param allowPickingImage 是否允许选择图片
 *  @param completion        block
 */
- (void)getAllAlbums:(BOOL)isPickVideo completion:(void (^)(NSArray<AFFAlbumModel *> *models))completion;

/**
 *  从相册列表中筛选出默认的相册
 *
 *  @param isPickVideo 是选择视频还是图片
 *  @param block       block
 */
- (void)getDefalutAlbum:(BOOL)isPickVideo block:(void(^)(AFFAlbumModel* model))block;

/**
 *  从相册中获取Asset
 *
 *  @param result     相册
 *  @param isPickVideo 是选择视频还是图片
 *  @param completion block
 */
-(void)getAssetsFromResult:(id)result isPickVideo:(BOOL)isPickVideo max:(NSInteger)max block:(void (^)(NSArray<AFFPhotoModel *> *models))block;

/**
 *  获取相册封面图片
 *
 *  @param model 相册模型
 *  @param block block
 */
- (void)getPostImageWithAlbumModel:(AFFAlbumModel *)model block:(void (^)(UIImage *postImage))block;

/**
 *  获取一定宽度的图片
 *
 *  @param asset asset
 *  @param block block
 *
 *  @return
 */
- (PHImageRequestID)getPhotoWithAsset:(id)asset block:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))block;


/**
 *  获取缩略图，不处理超高超长图
 *
 *  @param asset asset
 *  @param block 回调
 */
-(void)getThumbWithAsset:(id)asset photoWidth:(CGFloat)photoWidth block:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))block;
/**
 *  获取指定宽度的图片
 *
 *  @param asset      asset
 *  @param photoWidth 图片宽度
 *  @param block      block
 *
 *  @return id
 */
- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth block:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))block;

/**
 *  获取原图
 *
 *  @param asset asset
 *  @param block block
 */
- (void)getOriginalPhotoWithAsset:(id)asset block:(void (^)(UIImage *photo,NSDictionary *info))block;

/**
 *  获取视频
 *
 *  @param asset 资源
 *  @param block block
 */
- (void)getVideoWithAsset:(id)asset block:(void (^)(AVPlayerItem *item,NSDictionary *info))block;


/**
 *  更具字节数获取大小字符串
 *
 *  @param dataLength 字节长度
 *
 *  @return 字符串
 */
- (NSString *)getBytesFromDataLength:(NSInteger)dataLength;

/**
 *  判断asset在本地是否存在
 *
 *  @param asset 资源
 *  @param block 回调
 */
-(void)isAssetExistinLocal:(id)asset block:(void(^)(BOOL isExist))block;
/**
 *  将秒数格式化成时间格式
 *
 *  @param duration 秒数
 *
 *  @return 时间字符
 */
- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration;

/**
 *  获取资源的字节大小
 *
 *  @param asset 资源asset
 *
 *  @return 大小
 */
-(void)getAssetLength:(AFFPhotoModel*)photoModel block:(void(^)(AFFPhotoModel *model))block;

/**
 *  获取资源的类型
 *
 *  @param asset asset
 *
 *  @return 类型
 */
-(AFFAssetMediaType)getAssetType:(id)asset;

/**
 *  将AFFPhotoModel类型的图片存入指定的文件夹
 *
 *  @param path     文件夹路径
 *  @param models   要处理的数组
 *  @param complete 完成回调
 */
-(void)putImageInFolder:(NSString*)path array:(NSArray<AFFPhotoModel*>*)array complete:(void(^)(NSArray<AFFDataPhotoInfo*>*outArray))complete;

+(NSString*)getImageFolder;
+(NSString*)getVideoFolder;

/**
 *  导出视频
 *
 *  @param asset      asset资源
 *  @param completion 回调
 */
- (void)getVideoOutputPathWithAsset:(id)asset savePath:(NSString*)savePath block:(void (^)(AFFDataPhotoInfo *photo))block;
/**
 *  通过image获得data
 *
 *  @param image 图片
 *
 *  @return data数组
 */
+(NSData*)getImageData:(UIImage*)image;

/**
 *  创建文件夹
 *
 *  @param path 文件夹路径
 *
 *  @return 成功返回YES，失败返回NO
 */
+(BOOL)createFolder:(NSString*)path;

/**
 *  删除文件夹
 *
 *  @param path 文件夹路径
 *
 *  @return 成功返回YES，失败返回NO
 */
+(BOOL)deleteForder:(NSString*)path;

/**
 *  删除文件夹的文件
 *
 *  @param path 文件夹路径
 *
 *  @return 成功返回YES，失败返回NO
 */
+(BOOL)deleteFiles:(NSString*)path;


-(void)showInView:(UIView*)view info:(NSString*)info;

-(void)showLoadingInView:(UIView*)view;

-(void)removeLodingView;

+(BOOL)isAssetEqual:(id)asset1 asset2:(id)asset2;

@end










