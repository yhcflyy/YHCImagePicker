//
//  AFFPhotoModel.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import "AFFPhotoModel.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AFFPhotoPickerManager.h"

@implementation AFFPhotoModel

+ (instancetype)modelWithAsset:(id)asset type:(AFFAssetMediaType)type{
    AFFPhotoModel *model = [[AFFPhotoModel alloc] init];
    model.asset = asset;
    model.selected = NO;
    model.type = type;
    if([asset isKindOfClass:[ALAsset class]]){
        model.size = ((ALAsset*)asset).defaultRepresentation.dimensions;
    }else if([asset isKindOfClass:[PHAsset class]]){
        model.size = CGSizeMake(((PHAsset*)asset).pixelWidth, ((PHAsset*)asset).pixelHeight);
    }
    return model;
}

+ (instancetype)modelWithAsset:(id)asset type:(AFFAssetMediaType)type duration:(NSUInteger)duration{
    AFFPhotoModel *model = [self modelWithAsset:asset type:type];
    if(type == AFFAssetMediaType_Video){
        NSUInteger duration;
        if([asset isKindOfClass:[PHAsset class]]){
            duration = ((PHAsset*)asset).duration;
        }else if([asset isKindOfClass:[ALAsset class]]){
            duration = [[asset valueForProperty:ALAssetPropertyDuration] integerValue];
        }
        model.duration = duration;
        NSUInteger seconds = duration % 60;
        NSUInteger minutes = (duration / 60) % 60;
        NSUInteger hours = duration / 3600;
        if(hours > 0){
            model.timeLength = [NSString stringWithFormat:@"%02lu:%02lu:%02lu",(unsigned long)hours,(unsigned long)minutes,(unsigned long)seconds];
        }else{
            model.timeLength = [NSString stringWithFormat:@"%02lu:%02lu",(unsigned long)minutes,(unsigned long)seconds];
        }
    }
    return model;
}
@end



@implementation AFFAlbumModel


@end


@implementation AFFDataPhotoInfo

@end
