//
//  AFFPhotoPickerManager.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#define FileHashDefaultChunkSizeForReadingData 1024*8

#import "AFFPhotoPickerManager.h"
#import <CommonCrypto/CommonDigest.h>

@interface AFFPhotoPickerManager()

@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@property (nonatomic,strong ) UILabel         *alert;
@property (nonatomic,strong ) UIImageView     *imgV;
@property (nonatomic,strong ) UIView          *bgView;
@end

@implementation AFFPhotoPickerManager

static CGFloat AFFPhotoScreenScale;


+(AFFPhotoPickerManager*)shareManager{
    static AFFPhotoPickerManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self.class alloc]init];
        manager.cachingImageManager = [[PHCachingImageManager alloc]init];
        manager.cachingImageManager.allowsCachingHighQualityImages = NO;
        AFFPhotoScreenScale = 2.0;
        if (SCREEN_WIDTH > 700) {
            AFFPhotoScreenScale = 1.5;
        }
    });
    return manager;
}

- (ALAssetsLibrary *)assetLibrary {
    if (_assetLibrary == nil) _assetLibrary = [[ALAssetsLibrary alloc] init];
    return _assetLibrary;
}

/**
 *  获取相册是否授权
 *
 *  @return 返回YES，如果得到了授权
 */
- (BOOL)authorizationStatusAuthorized {
    if (IOS_VERSION < 8.0) {
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) return YES;
    } else {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) return YES;
    }
    return NO;
}


/**
 *  获取相册列表
 *
 *  @param allowPickingVideo 是选择视频还是图片
 *  @param allowPickingImage 是否允许选择图片
 *  @param completion        block
 */
- (void)getAllAlbums:(BOOL)isPickVideo completion:(void (^)(NSArray<AFFAlbumModel *> *models))completion{
    NSMutableArray *albumArr = [NSMutableArray array];
    if(IOS_VERSION < 8.0){
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                if (completion && albumArr.count > 0) completion(albumArr);
            }
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"] || [name isEqualToString:@"所有照片"] || [name isEqualToString:@"All Photos"]) {
                [albumArr insertObject:[self modelWithResult:group name:name isPickVideo:isPickVideo] atIndex:0];
            } else if ([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我的照片流"]) {
                if (albumArr.count) {
                    [albumArr insertObject:[self modelWithResult:group name:name isPickVideo:isPickVideo] atIndex:1];
                } else {
                    [albumArr addObject:[self modelWithResult:group name:name isPickVideo:isPickVideo]];
                }
            } else {
                [albumArr addObject:[self modelWithResult:group name:name isPickVideo:isPickVideo]];
            }
        } failureBlock:nil];
    }else{
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if(isPickVideo){
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                                PHAssetMediaTypeVideo];
        }else{
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        }
        
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:!self.sortAscendingByModificationDate]];
        
        PHAssetCollectionSubtype smartAlbumSubtype =    PHAssetCollectionSubtypeSmartAlbumUserLibrary |
        PHAssetCollectionSubtypeSmartAlbumRecentlyAdded |
        PHAssetCollectionSubtypeSmartAlbumVideos;
        // For iOS 9, We need to show ScreenShots Album && SelfPortraits Album
        if (IOS_VERSION >= 9.0) {
            smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary |
            PHAssetCollectionSubtypeSmartAlbumRecentlyAdded |
            PHAssetCollectionSubtypeSmartAlbumScreenshots |
            PHAssetCollectionSubtypeSmartAlbumSelfPortraits |
            PHAssetCollectionSubtypeSmartAlbumVideos;
        }
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:smartAlbumSubtype options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle containsString:@"Deleted"] || [collection.localizedTitle isEqualToString:@"最近删除"]) continue;
            if ([collection.localizedTitle isEqualToString:@"Camera Roll"] || [collection.localizedTitle isEqualToString:@"相机胶卷"] || [collection.localizedTitle isEqualToString:@"所有照片"] || [collection.localizedTitle isEqualToString:@"All Photos"]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle isPickVideo:isPickVideo] atIndex:0];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle isPickVideo:isPickVideo]];
            }
        }
        
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular | PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        for (PHAssetCollection *collection in albums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle isEqualToString:@"My Photo Stream"] || [collection.localizedTitle isEqualToString:@"我的照片流"]) {
                if (albumArr.count) {
                    [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle isPickVideo:isPickVideo] atIndex:1];
                } else {
                    [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle isPickVideo:isPickVideo]];
                }
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle isPickVideo:isPickVideo]];
            }
        }
        if (completion && albumArr.count > 0) completion(albumArr);
    }
}

/**
 *  从相册列表中筛选出默认的相册
 *
 *  @param isPickVideo 是选择视频还是图片
 *  @param block       block
 */
- (void)getDefalutAlbum:(BOOL)isPickVideo block:(void(^)(AFFAlbumModel* model))block{
    [[self.class shareManager] getAllAlbums:isPickVideo completion:^(NSArray<AFFAlbumModel *> *models) {
        AFFAlbumModel *findModel = nil;
        for (AFFAlbumModel *model in models) {
            if([model.name isEqualToString:@"相机胶卷"]){
                findModel = model;
                break;
            }
        }
        if(!findModel && models.count > 0){
            findModel = [models firstObject];
        }
        if(block) block(findModel);
    }];
}



/**
 *  从相册中获取Asset
 *
 *  @param result     相册
 *  @param completion block
 */
-(void)getAssetsFromResult:(id)result isPickVideo:(BOOL)isPickVideo max:(NSInteger)max block:(void (^)(NSArray<AFFPhotoModel *> *models))block{
    NSMutableArray *photoArr = [NSMutableArray array];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        [fetchResult enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PHAsset *asset = (PHAsset *)obj;
            AFFAssetMediaType type = AFFAssetMediaType_Photo;
            if (asset.mediaType == PHAssetMediaTypeVideo)
                type = AFFAssetMediaType_Video;
            else if (asset.mediaType == PHAssetMediaTypeAudio)
                type = AFFAssetMediaType_Audio;
            else if (asset.mediaType == PHAssetMediaTypeImage) {
                if (IOS_VERSION >= 9.0) {
                    if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = AFFAssetMediaType_LivePhoto;
                }
            }
            if (isPickVideo == NO && type == AFFAssetMediaType_Video) return;
            if (isPickVideo && type == AFFAssetMediaType_Photo) return;
            if(photoArr.count >= max) return;
            [photoArr addObject:[AFFPhotoModel modelWithAsset:asset type:type duration:asset.duration]];
        }];
        if (block) block(photoArr);
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        if(isPickVideo){
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        }else{
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        ALAssetsGroupEnumerationResultsBlock resultBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop)  {
            if (result == nil) {
                if (block) block(photoArr);
            }
            if(photoArr.count >= max) return;
            AFFAssetMediaType type;
            if (isPickVideo){
                type = AFFAssetMediaType_Video;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                [photoArr addObject:[AFFPhotoModel modelWithAsset:result type:type duration:duration]];
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = AFFAssetMediaType_Video;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                [photoArr addObject:[AFFPhotoModel modelWithAsset:result type:type duration:duration]];
            } else {
                type = AFFAssetMediaType_Photo;
                [photoArr addObject:[AFFPhotoModel modelWithAsset:result type:type]];
            }
        };
        if (!self.sortAscendingByModificationDate) {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (resultBlock) { resultBlock(result,index,stop); }
            }];
        } else {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (resultBlock) { resultBlock(result,index,stop); }
            }];
        }
    }
}

/**
 *  获取指定宽度的图片
 *
 *  @param asset      asset
 *  @param photoWidth 图片宽度
 *  @param block      block
 *
 *  @return id
 */
- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth block:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))block{
    
    CGSize size;
    if([asset isKindOfClass:[ALAsset class]]){
        size = ((ALAsset*)asset).defaultRepresentation.dimensions;
    }else if ([asset isKindOfClass:[PHAsset class]]){
        size = CGSizeMake(((PHAsset*)asset).pixelWidth, ((PHAsset*)asset).pixelHeight);
    }
    CGFloat scale = size.width / size.height;
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        CGSize imageSize;
        PHAsset *phAsset = (PHAsset *)asset;
        if(scale > 3 || scale < 0.33){
            imageSize = CGSizeMake(size.width/2, size.height/2);
        }else{
            CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
            CGFloat pixelWidth = photoWidth * AFFPhotoScreenScale;
            CGFloat pixelHeight = photoWidth / aspectRatio;
            imageSize = CGSizeMake(pixelWidth, pixelHeight);
        }
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.networkAccessAllowed = NO;
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
//                result = [UIImage fixOrientation:result];
                if (block) block(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            }
        }];
        return imageRequestID;
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
            CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;
            UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:assetRep.scale orientation:UIImageOrientationUp];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) block(thumbnailImage,nil,YES);
                
                if (photoWidth == SCREEN_WIDTH*AFFPhotoScreenScale) {
                    dispatch_async(dispatch_get_global_queue(0,0), ^{
                        CGImageRef fullScrennImageRef = nil;
                        UIImage *fullScrennImage = nil;
                        CGFloat scale = assetRep.dimensions.width / assetRep.dimensions.height;
                        //超宽或超长图，需要使用原图
                        if(scale > 3 || scale < 0.333){
                            fullScrennImageRef = [assetRep fullResolutionImage];
                            fullScrennImage=[UIImage imageWithCGImage:fullScrennImageRef scale:assetRep.scale orientation:(UIImageOrientation)assetRep.orientation];
                        }else{
                            fullScrennImageRef = [assetRep fullScreenImage];
                            fullScrennImage=[UIImage imageWithCGImage:fullScrennImageRef scale:assetRep.scale orientation:UIImageOrientationUp];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (block) block(fullScrennImage,nil,NO);
                        });
                    });
                }
            });
        });
    }
    return 0;
}


/**
 *  判断asset在本地是否存在
 *
 *  @param asset 资源
 *  @param block 回调
 */
-(void)isAssetExistinLocal:(id)asset block:(void(^)(BOOL isExist))block{
    if([asset isKindOfClass:[PHAsset class]]){
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.networkAccessAllowed = NO;
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            BOOL isInLocalAblum = imageData ? YES : NO;
            if(block) block(isInLocalAblum);
        }];
    }else if([asset isKindOfClass:[ALAsset class]]){
        if(block) block(YES);
    }
}
/**
 *  获取一定宽度的图片，接口会返回两次
 *
 *  @param asset asset
 *  @param block block
 *
 *  @return
 */
- (PHImageRequestID)getPhotoWithAsset:(id)asset block:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))block{
    return [self getPhotoWithAsset:asset photoWidth:SCREEN_WIDTH*AFFPhotoScreenScale block:block];
}


/**
 *  获取缩略图
 *
 *  @param asset asset
 *  @param block 回调
 */
-(void)getThumbWithAsset:(id)asset photoWidth:(CGFloat)photoWidth block:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))block{
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        CGSize imageSize;
        PHAsset *phAsset = (PHAsset *)asset;
        
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = photoWidth * AFFPhotoScreenScale;
        CGFloat pixelHeight = photoWidth / aspectRatio;
        imageSize = CGSizeMake(pixelWidth, pixelHeight);
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.networkAccessAllowed = NO;
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
//                result = [UIImage fixOrientation:result];
                if (block) block(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
            CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;
            UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:assetRep.scale orientation:UIImageOrientationUp];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) block(thumbnailImage,nil,YES);
            });
        });
    }
}

/**
 *  获取原图
 *
 *  @param asset asset
 *  @param block block
 */
- (void)getOriginalPhotoWithAsset:(id)asset block:(void (^)(UIImage *photo,NSDictionary *info))block{
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
        option.networkAccessAllowed = NO;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
//                result = [UIImage fixOrientation:result];
                if (block) block(result,info);
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            CGImageRef originalImageRef = [assetRep fullResolutionImage];
            UIImage *originalImage = [UIImage imageWithCGImage:originalImageRef scale:assetRep.scale orientation:UIImageOrientationUp];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) block(originalImage,nil);
            });
        });
    }
}

/**
 *  获取视频
 *
 *  @param asset 资源
 *  @param block block
 */
- (void)getVideoWithAsset:(id)asset block:(void (^)(AVPlayerItem *item,NSDictionary *info))block{
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (block) block(playerItem,info);
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *defaultRepresentation = [alAsset defaultRepresentation];
        NSString *uti = [defaultRepresentation UTI];
        NSURL *videoURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        if (block && playerItem) block(playerItem,nil);
    }
}

/**
 *  获取相册封面图片
 *
 *  @param model 相册模型
 *  @param block block
 */
- (void)getPostImageWithAlbumModel:(AFFAlbumModel *)model block:(void (^)(UIImage *postImage))block{
    if([model.result isKindOfClass:[ALAssetsGroup class]]){
        ALAssetsGroup *group = model.result;
        UIImage *postImage = [UIImage imageWithCGImage:group.posterImage];
        if (block) block(postImage);
    }else if([model.result isKindOfClass:[PHFetchResult class]]){
        id asset = [model.result lastObject];
        if (!self.sortAscendingByModificationDate) {
            asset = [model.result firstObject];
        }
        [[self.class shareManager] getPhotoWithAsset:asset photoWidth:80 block:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if(block) block(photo);
        }];
    }
}

- (AFFAlbumModel *)modelWithResult:(id)result name:(NSString *)name isPickVideo:(BOOL)isPickVideo{
    AFFAlbumModel *model = [[AFFAlbumModel alloc] init];
    model.result = result;
    model.name = [self getNewAlbumName:name];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        if(isPickVideo){
           model.count = [fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
        }else{
            model.count = [fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
        }
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        if(isPickVideo){
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        }else{
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        model.count = [group numberOfAssets];
    }
    return model;
}

- (NSString *)getNewAlbumName:(NSString *)name {
    if (IOS_VERSION >= 8.0) {
        NSString *newName;
        if ([name rangeOfString:@"Roll"].location != NSNotFound)         newName = @"相机胶卷";
        else if ([name rangeOfString:@"Stream"].location != NSNotFound)  newName = @"我的照片流";
        else if ([name rangeOfString:@"Added"].location != NSNotFound)   newName = @"最近添加";
        else if ([name rangeOfString:@"Selfies"].location != NSNotFound) newName = @"自拍";
        else if ([name rangeOfString:@"shots"].location != NSNotFound)   newName = @"截屏";
        else if ([name rangeOfString:@"Videos"].location != NSNotFound)  newName = @"视频";
        else if ([name rangeOfString:@"Panoramas"].location != NSNotFound)  newName = @"全景照片";
        else if ([name rangeOfString:@"Favorites"].location != NSNotFound)  newName = @"个人收藏";
        else newName = name;
        return newName;
    } else {
        return name;
    }
}

- (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

/**
 *  获取资源的字节大小
 *
 *  @param asset 资源asset
 *
 *  @return 大小
 */
-(void)getAssetLength:(AFFPhotoModel*)photoModel block:(void(^)(AFFPhotoModel *model))block{
    if(photoModel.byteLen > 0 && block){
        block(photoModel);
        return;
    }
    if([photoModel.asset isKindOfClass:[ALAsset class]]){
        photoModel.byteLen = (NSInteger)((ALAsset*)photoModel.asset).defaultRepresentation.size;
        if(block) block(photoModel);
    }else if ([photoModel.asset isKindOfClass:[PHAsset class]]){
        [[PHImageManager defaultManager] requestImageDataForAsset:photoModel.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            photoModel.byteLen = imageData.length;
            if(block) block(photoModel);
        }];
    }
}


/**
 *  获取资源的类型
 *
 *  @param asset asset
 *
 *  @return 类型
 */
-(AFFAssetMediaType)getAssetType:(id)asset{
    AFFAssetMediaType type = AFFAssetMediaType_Photo;
    if([asset isKindOfClass:[ALAsset class]]){
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            type = AFFAssetMediaType_Video;
        }else if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]){
            type = AFFAssetMediaType_Photo;
        }
    }else if ([asset isKindOfClass:[PHAsset class]]){
        if(((PHAsset*)asset).mediaType == PHAssetMediaTypeImage){
            type = AFFAssetMediaType_Photo;
        }else if (((PHAsset*)asset).mediaType == PHAssetMediaTypeVideo){
            type = AFFAssetMediaType_Video;
        }else if (((PHAsset*)asset).mediaType == PHAssetMediaTypeAudio){
            type = AFFAssetMediaType_Audio;
        }
    }
    return type;
}



/**
 *  将AFFPhotoModel类型的图片存入指定的文件夹
 *
 *  @param path     文件夹路径
 *  @param models   要处理的数组
 *  @param complete 完成回调
 */
-(void)putImageInFolder:(NSString*)path array:(NSArray<AFFPhotoModel*>*)array complete:(void(^)(NSArray<AFFDataPhotoInfo*>*outArray))complete{
    
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    
    dispatch_queue_t queue = dispatch_queue_create("output.queue", DISPATCH_QUEUE_CONCURRENT);
    
    __block NSInteger count = array.count;
    for (AFFPhotoModel *model in array) {
        AFFDataPhotoInfo *photoInfo = [[AFFDataPhotoInfo alloc]init];
        photoInfo.asset = model.asset;
        photoInfo.isRaw = model.isRaw;
        [arr addObject:photoInfo];
        
        [[AFFPhotoPickerManager shareManager] getPhotoWithAsset:model.asset photoWidth:160 block:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            photoInfo.thumb = photo;
        }];
        
        if([model.asset isKindOfClass:[ALAsset class]]){
            ALAssetRepresentation *rep = [model.asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc((size_t)rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0 length:(size_t)rep.size error:nil];
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            photoInfo.length = rep.size;
            photoInfo.md5 = [self.class getMediaMD5:data];
            NSString *url = [NSString stringWithFormat:@"%@/%@",path,photoInfo.md5];
            photoInfo.fullPath = url;
            
            
            [self.class writeFileAsync:url queue:queue data:data complete:^(BOOL result) {
                if(!result) NSLog(@"写入失败");
                count--;
                if(count <= 0){
                    if(complete) complete(arr);
                }
            }];
        }else if ([model.asset isKindOfClass:[PHAsset class]]){
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
            option.networkAccessAllowed = NO;
            [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                photoInfo.length = [imageData length];
                photoInfo.md5 = [self.class getMediaMD5:imageData];
                NSString *url = [NSString stringWithFormat:@"%@/%@",path,photoInfo.md5];
                photoInfo.fullPath = url;
                [self.class writeFileAsync:url queue:queue data:imageData complete:^(BOOL result) {
                    if(!result) NSLog(@"写入失败");
                    count--;
                    if(count <= 0){
                        if(complete) complete(arr);
                    }
                }];
            }];
        }
    }
}

+(NSString*)getImageFolder{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    NSString *pathImage = [NSString stringWithFormat:@"%@/tempImage",cachesDir];
    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:pathImage]){
        [self createFolder:pathImage];
    }
    return pathImage;
}
+(NSString*)getVideoFolder{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    NSString *pathVideo = [NSString stringWithFormat:@"%@/tempVideo",cachesDir];
    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:pathVideo]){
        [self createFolder:pathVideo];
    }
    return pathVideo;
}


+(void)writeFileAsync:(NSString *)path queue:(dispatch_queue_t)queue data:(NSData *)data complete:(void (^)(BOOL result))complete{
    __block BOOL result        = NO;
    dispatch_barrier_async(queue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:path]){
            [fileManager removeItemAtPath:path error:nil];
        }
        result = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete)  complete(result);
        });
    });
}

- (void)getVideoOutputPathWithAsset:(id)asset savePath:(NSString*)savePath block:(void (^)(AFFDataPhotoInfo *photo))block{
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
            AVURLAsset *videoAsset = (AVURLAsset*)avasset;
            [self exportRawVideo:videoAsset asset:asset savePath:savePath block:block];
//            [self startExportVideoWithVideoAsset:videoAsset asset:asset savePath:savePath block:block];
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        NSURL *videoURL =[asset valueForProperty:ALAssetPropertyAssetURL]; // ALAssetPropertyURLs
        AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:videoURL options:nil];
        [self exportRawVideo:videoAsset asset:asset savePath:savePath block:block];
//        [self startExportVideoWithVideoAsset:videoAsset asset:asset savePath:savePath block:block];
    }
}

-(void)exportRawVideo:(AVURLAsset*)avuasset asset:(id)asset savePath:(NSString*)savePath block:(void (^)(AFFDataPhotoInfo *photo))block{
    [self.class deleteFiles:savePath];
    NSString *outputPath = [NSString stringWithFormat:@"%@/temp.mp4",savePath];
    NSError *error;
    NSURL *fileURL = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] copyItemAtURL:avuasset.URL
                                                toURL:fileURL
                                                error:&error]) {
        NSString *md5 = [self.class getFileMD5WithPath:outputPath];
        [self exportCompressVideo:savePath asset:asset rawMd5:md5 block:block];
    }else{
//        [HUD showWithText:@"导出原始视频失败"];
    }
}

-(void)exportCompressVideo:(NSString*)savePath asset:(id)asset rawMd5:(NSString*)rawMd5 block:(void (^)(AFFDataPhotoInfo *photo))block{
    NSString *strOutPath = [NSString stringWithFormat:@"%@/merge.mp4",savePath];
    NSString *strInPath = [NSString stringWithFormat:@"%@/temp.mp4",savePath];
    [self lowQuailtyWithInputURL:[NSURL fileURLWithPath:strInPath] outputURL:[NSURL fileURLWithPath:strOutPath] blockHandler:^(AVAssetExportSession *session) {
        if (session.status == AVAssetExportSessionStatusCompleted){
            [self.class deleteForder:strInPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *realPath = [NSString stringWithFormat:@"%@/%@.mp4",savePath,rawMd5];
                [[NSFileManager defaultManager] moveItemAtPath:strOutPath toPath:realPath error:nil];
                AFFDataPhotoInfo *photoInfo = [AFFDataPhotoInfo new];
                photoInfo.md5 = rawMd5;
                photoInfo.fullPath = realPath;
                photoInfo.asset = asset;
                
                if([asset isKindOfClass:[PHAsset class]]){
                    photoInfo.duration = ((PHAsset*)asset).duration;
                }else if([asset isKindOfClass:[ALAsset class]]){
                    photoInfo.duration = [[asset valueForProperty:ALAssetPropertyDuration] integerValue];
                }
                __block NSInteger count = [asset isKindOfClass:[PHAsset class]] ? 2 : 1;
                [[AFFPhotoPickerManager shareManager] getPhotoWithAsset:asset photoWidth:160 block:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    photoInfo.thumb = photo;
                    count--;
                    if(count == 0){
                        NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:realPath traverseLink:YES];
                        photoInfo.length = [fileDictionary fileSize];
                        block(photoInfo);
                    }
                }];
            });
        }else if (session.status == AVAssetExportSessionStatusFailed) {
//            [HUD showWithType:EHUDFailed text:@"压缩失败"];
        }
    }];
}

/*  视频压缩
*
*  @param inputURL  传入的URL
*  @param outputURL 输出的URL
*  @param handler   返回的block
*/
- (void)lowQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL blockHandler:(void (^)(AVAssetExportSession*))handler
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    
    /*
     视频压缩质量选项
     AVAssetExportPresetLowQuality
     AVAssetExportPresetMediumQuality
     AVAssetExportPresetHighestQuality
     */
    
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    session.outputURL = outputURL;
    
    /*
     输出视频格式选项
     AVFileTypeQuickTimeMovie
     AVFileTypeMPEG4
     AVFileTypeAppleM4V
     AVFileTypeAppleM4A
     AVFileType3GPP
     AVFileType3GPP2
     */
    
    session.outputFileType = AVFileTypeMPEG4;
    //    session.shouldOptimizeForNetworkUse = YES;
    [session exportAsynchronouslyWithCompletionHandler:^(void)
     {
         handler(session);
     }];
}

- (void)startExportVideoWithVideoAsset:(AVURLAsset *)videoAsset asset:(id)asset savePath:(NSString*)savePath block:(void (^)(AFFDataPhotoInfo *photo))block{
    
    NSString *outputPath = [NSString stringWithFormat:@"%@/temp.mp4",savePath];
    NSError *error;
    NSURL *fileURL = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] copyItemAtURL:videoAsset.URL
                                                toURL:fileURL
                                                error:&error]) {
        NSLog(@"Copied correctly");
    }
    return;
    
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
    if ([presets containsObject:AVAssetExportPreset640x480]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:videoAsset presetName:AVAssetExportPreset640x480];
        
        [self.class deleteFiles:savePath];
        NSString *outputPath = [NSString stringWithFormat:@"%@/temp.mp4",savePath];
        NSFileManager *manager=[NSFileManager defaultManager];
        [manager removeItemAtPath:outputPath error:nil];
        session.outputURL = [NSURL fileURLWithPath:outputPath];
        
        // Optimize for network use.
        session.shouldOptimizeForNetworkUse = true;
        
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            NSLog(@"No supported file types 视频类型暂不支持导出");
            return;
        } else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        
        // Begin to export video to the output path asynchronously.
        [session exportAsynchronouslyWithCompletionHandler:^(void) {
            switch (session.status) {
                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"AVAssetExportSessionStatusUnknown"); break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"AVAssetExportSessionStatusWaiting"); break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"AVAssetExportSessionStatusExporting"); break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"AVAssetExportSessionStatusCompleted");
                    if (block) {
                        NSString *md5 = [self.class getFileMD5WithPath:outputPath];
                        NSString *realPath = [NSString stringWithFormat:@"%@/%@.mp4",savePath,md5];
                        [[NSFileManager defaultManager] moveItemAtPath:outputPath toPath:realPath error:nil];
                        AFFDataPhotoInfo *photoInfo = [AFFDataPhotoInfo new];
                        photoInfo.md5 = md5;
                        photoInfo.fullPath = realPath;
                        photoInfo.asset = asset;
                        
                        if([asset isKindOfClass:[PHAsset class]]){
                            photoInfo.duration = ((PHAsset*)asset).duration;
                        }else if([asset isKindOfClass:[ALAsset class]]){
                            photoInfo.duration = [[asset valueForProperty:ALAssetPropertyDuration] integerValue];
                        }
                        __block NSInteger count = [asset isKindOfClass:[PHAsset class]] ? 2 : 1;
                        [[AFFPhotoPickerManager shareManager] getPhotoWithAsset:asset photoWidth:160 block:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                            photoInfo.thumb = photo;
                            count--;
                            if(count == 0){
                                NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:realPath traverseLink:YES];
                                photoInfo.length = [fileDictionary fileSize];
                                block(photoInfo);
                            }
                        }];
                        
                    }
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"AVAssetExportSessionStatusFailed"); break;
                default: break;
            }
        }];
    }
}



+(NSData*)getImageData:(UIImage*)image{
    NSData *data = UIImageJPEGRepresentation(image, 1);
    return data;
}



/**
 *  创建文件夹
 *
 *  @param path 文件夹路径
 */
+(BOOL)createFolder:(NSString*)path{
    NSFileManager *manager=[NSFileManager defaultManager];
    return [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

/**
 *  删除文件夹
 *
 *  @param path 文件夹路径
 */
+(BOOL)deleteForder:(NSString*)path{
    NSFileManager *manager=[NSFileManager defaultManager];
    if(path.length > 0){
        return [manager removeItemAtPath:path error:nil];
    }else{
        return NO;
    }
}

/**
 *  删除文件夹的所有文件
 *
 *  @param path 文件夹路径
 */
+(BOOL)deleteFiles:(NSString*)path{
    if([self.class deleteForder:path]){
        return [self.class createFolder:path];
    }else{
        return NO;
    }
}


-(void)showInView:(UIView*)view info:(NSString*)info{
    if(self.alert) return;
    self.alert = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-150)/2, (SCREEN_HEIGHT-94)/2, 150 , 30)];
    self.alert.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    self.alert.text = info;
//    self.alert.font = kSetting.font_Content;
    self.alert.textAlignment = NSTextAlignmentCenter;
//    self.alert.textColor = kSetting.color_ffffff;
    self.alert.layer.cornerRadius = 3;
    self.alert.layer.masksToBounds = YES;
    [view addSubview:self.alert];
    [self performSelector:@selector(dismissAlert) withObject:nil afterDelay:1];
}

-(void)dismissAlert{
    [self.alert removeFromSuperview];
    self.alert = nil;
}

-(void)showLoadingInView:(UIView*)view{
    if(self.imgV) return;
    
    UIView *bgView = [[UIView alloc]initWithFrame:view.bounds];
    bgView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [view addSubview:bgView];
    self.bgView = bgView;
    
    UIImageView *imgV = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-80)/2, (SCREEN_HEIGHT-80)/2, 80, 80)];
    self.imgV = imgV;
    [bgView addSubview:imgV];
    imgV.layer.cornerRadius = 3;
    imgV.layer.masksToBounds = YES;
    imgV.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    NSMutableArray *images = [NSMutableArray array];
    for (NSInteger i = 1; i < 16; i++) {
        NSString *str = [NSString stringWithFormat:@"refresh_loading%03d",i];
        UIImage *img = [UIImage imageNamed:str];
        [images addObject:img];
    }
    imgV.animationImages = images;
    imgV.animationDuration = 1;
    imgV.animationRepeatCount = INT_MAX;
    [imgV startAnimating];
}

-(void)removeLodingView{
    [self.bgView removeFromSuperview];
    self.bgView = nil;
    [self.imgV removeFromSuperview];
    self.imgV = nil;
}

+ (NSString*)getMediaMD5:(NSData*)raw{
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(raw.bytes, raw.length, md5Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+(NSString*)getFileMD5WithPath:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}



+(BOOL)isAssetEqual:(id)asset1 asset2:(id)asset2{
    if([asset1 isKindOfClass:[PHAsset class]]){
        return [asset1 isEqual:asset2];
    }else if([asset1 isKindOfClass:[ALAsset class]]){
        NSURL *url1 = ((ALAsset*)asset1).defaultRepresentation.url;
        NSURL *url2 = ((ALAsset*)asset2).defaultRepresentation.url;
        return [url1 isEqual:url2];
    }
    return NO;
}

@end
