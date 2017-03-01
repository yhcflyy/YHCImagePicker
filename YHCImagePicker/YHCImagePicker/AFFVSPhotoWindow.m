//
//  AFFVSPhotoWindow.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/14.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import "AFFVSPhotoWindow.h"

@interface AFFVSPhotoWindow()
@property(nonatomic,strong) AFFSPhotoPicker *picker;
@property(nonatomic,assign) BOOL isCleanFolder;

@end

@implementation AFFVSPhotoWindow

-(instancetype)init{
    self = [super init];
    if(self){
        [self setUI];
        self.picker = [[AFFSPhotoPicker alloc] init];
        self.imagePath = [AFFPhotoPickerManager getImageFolder];
        self.maxSelCount = 9;
        self.isAllowMulSel = YES;
        self.maxImageShowInPicker = 30;
        
        [AFFPhotoPickerManager deleteFiles:self.imagePath];
        self.isCleanFolder = YES;
        __weak typeof(self) weakSelf = self;
        self.picker.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
            if([weakSelf.delegate respondsToSelector:@selector(photoWindowSendImages:images:)]){
                [weakSelf dismiss];
                [weakSelf.delegate photoWindowSendImages:weakSelf images:arr];
            }
        };
        self.picker.dismissBlock = ^(){
            if([weakSelf.delegate respondsToSelector:@selector(photoWindowSendImages:images :)]){
                [weakSelf.delegate photoWindowSendImages:weakSelf images:nil];
            }
        };
        self.userInteractionEnabled = YES;
        self.rootViewController = self.picker;
    }
    return self;
}

-(instancetype)initWithType:(BOOL)isPickVideo
                  maxSelect:(NSInteger)maxSelect {
    return [self initWithCutType:isPickVideo maxSelect:maxSelect imagePath:nil isAllowMulSel:YES isCleanFolder:YES];
}

-(instancetype)initWithCutType:(BOOL)isPickVideo
                     maxSelect:(NSInteger)maxSelect
                     imagePath:(NSString*)imagePath
                 isAllowMulSel:(BOOL)isAllowMulSel
                 isCleanFolder:(BOOL)isCleanFolder{
    
    self = [super init];
    if(self){
        self.picker = [[AFFSPhotoPicker alloc] init];
        self.isPickVideo = isPickVideo;
        self.maxSelCount = maxSelect;
        self.imagePath = imagePath;
        self.isCleanFolder = isCleanFolder;
        self.isAllowMulSel = isAllowMulSel;
        [self setUI];
        self.isCleanFolder = isCleanFolder;
        if(imagePath == nil || imagePath.length <= 0){
            if(self.isPickVideo){
                self.picker.imagePath = [AFFPhotoPickerManager getVideoFolder];
            }else{
                self.picker.imagePath = [AFFPhotoPickerManager getImageFolder];
            }
        }else{
            self.picker.imagePath = imagePath;
        }
        if(isCleanFolder){
            [AFFPhotoPickerManager deleteFiles:self.imagePath];
        }
        __weak typeof(self) weakSelf = self;
        self.picker.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
            if([weakSelf.delegate respondsToSelector:@selector(photoWindowSendImages:images:)]){
                [weakSelf dismiss];
                [weakSelf.delegate photoWindowSendImages:weakSelf images:arr];
            }
        };
        self.picker.dismissBlock = ^(){
            if([weakSelf.delegate respondsToSelector:@selector(photoWindowSendImages:images:)]){
                [weakSelf.delegate photoWindowSendImages:weakSelf images:nil];
            }
        };
       
        self.picker.isPickVideo = isPickVideo;
        self.picker.maxSelCount = maxSelect;
        self.userInteractionEnabled = YES;
        self.rootViewController = self.picker;
    }
    return self;
}


-(instancetype)initWithCutType:(BOOL)isPickVideo
                     maxSelect:(NSInteger)maxSelect
                     imagePath:(NSString*)imagePath
                   selectedArr:(NSArray*)selectedArr
                 isAllowMulSel:(BOOL)isAllowMulSel
                 isCleanFolder:(BOOL)isCleanFolder{
    self = [super init];
    if(self){
        self.picker = [[AFFSPhotoPicker alloc] init];
        self.isPickVideo = isPickVideo;
        self.maxSelCount = maxSelect;
        self.imagePath = imagePath;
        self.isCleanFolder = isCleanFolder;
        self.isAllowMulSel = isAllowMulSel;
        NSMutableArray *arrSelect = [NSMutableArray array];
        for (AFFDataPhotoInfo *photo in selectedArr) {
            AFFPhotoModel *model = [[AFFPhotoModel alloc]init];
            model.selected = YES;
            model.isRaw =  photo.isRaw;
            model.asset = photo.asset;
            [arrSelect addObject:model];
        }
        self.picker.arrSelect = arrSelect;
        [self setUI];
        self.isCleanFolder = isCleanFolder;
        if(imagePath == nil || imagePath.length <= 0){
            if(self.isPickVideo){
                self.picker.imagePath = [AFFPhotoPickerManager getVideoFolder];
            }else{
                self.picker.imagePath = [AFFPhotoPickerManager getImageFolder];
            }
        }else{
            self.picker.imagePath = imagePath;
        }
        if(isCleanFolder){
            [AFFPhotoPickerManager deleteFiles:self.imagePath];
        }
        __weak typeof(self) weakSelf = self;
        self.picker.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
            if([weakSelf.delegate respondsToSelector:@selector(photoWindowSendImages:images:)]){
                [weakSelf dismiss];
                [weakSelf.delegate photoWindowSendImages:weakSelf images:arr];
            }
        };
        self.picker.dismissBlock = ^(){
            if([weakSelf.delegate respondsToSelector:@selector(photoWindowSendImages:images:)]){
                [weakSelf.delegate photoWindowSendImages:weakSelf images:nil];
            }
        };
        self.picker.isPickVideo = isPickVideo;
        self.picker.maxSelCount = maxSelect;
        self.userInteractionEnabled = YES;
        self.rootViewController = self.picker;
    }
    return self;
}


-(void)setUI{
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.backgroundColor = [UIColor clearColor];
    self.windowLevel = UIWindowLevelStatusBar - 1;
}

-(void)setImagePath:(NSString *)imagePath{
    _imagePath = imagePath;
    self.picker.imagePath = imagePath;
}


-(void)setIsPickVideo:(BOOL)isPickVideo{
    _isPickVideo = isPickVideo;
    self.picker.isPickVideo = isPickVideo;
}

-(void)setIsAllowMulSel:(BOOL)isAllowMulSel{
    _isAllowMulSel = isAllowMulSel;
    self.picker.isAllowMulSel = isAllowMulSel;
}

-(void)setMaxSelCount:(NSInteger)maxSelCount{
    _maxSelCount = maxSelCount;
    self.picker.maxSelCount = maxSelCount;
}

-(void)setDelegate:(id<AFFVSPhotoWindowDelegate>)delegate{
    if(delegate &&
       ![delegate isKindOfClass:[AFFSPhotoPicker class]] &&
       ![delegate isKindOfClass:[UINavigationController class]]){
        _delegate = delegate;
    }
}

-(void)setMaxImageShowInPicker:(NSInteger)maxImageShowInPicker{
    _maxImageShowInPicker = maxImageShowInPicker;
    self.picker.maxImageShowInPicker = maxImageShowInPicker;
}

-(void)dismiss{
    self.picker = nil;
    self.delegate = nil;
    self.rootViewController = nil;
    [self removeFromSuperview];
}

+(BOOL)cleanFolder:(NSString*)path{
    if(path == nil || path.length <= 0){
        return [AFFPhotoPickerManager deleteFiles:[AFFPhotoPickerManager getImageFolder]];
        return [AFFPhotoPickerManager deleteFiles:[AFFPhotoPickerManager getVideoFolder]];
    }else{
        return [AFFPhotoPickerManager deleteFiles:path];
    }
}
@end
