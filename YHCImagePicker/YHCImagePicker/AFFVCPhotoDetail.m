//
//  AFFVCPhotoDetail.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#define kCellMargin 2
#define CellNum SCREEN_WIDTH > 504 ? 7 : 4


#import "AFFVCPhotoDetail.h"
#import "AFFPhotoPickerManager.h"
#import "AFFVCSPhotoBrowser.h"

@interface AFFVCPhotoDetail ()<
UICollectionViewDelegate,
UICollectionViewDataSource>
@property (nonatomic,weak  ) UICollectionView *collectionView;
@property (nonatomic,weak  ) UIButton         *btnPreview;
@property (nonatomic,weak  ) UIButton         *btnSend;
@property (nonatomic,assign) BOOL             isDidDisAppare;

@end

@implementation AFFVCPhotoDetail

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setup];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.isDidDisAppare = YES;
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (AFFPhotoModel *photoModel in self.mArrData) {
            photoModel.selected = NO;
            for (AFFPhotoModel *tmp in [AFFPhotoPickerManager shareManager].arrSelect) {
                if([AFFPhotoPickerManager isAssetEqual:tmp.asset asset2:photoModel.asset]){
                    photoModel.selected  = YES;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshBtnSend];
            [self.collectionView reloadData];
        });
    });
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.isDidDisAppare = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)cleanSelf{
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
}


-(void)setupData{
    if(!self.mArrData){
        __weak typeof(self) weakSelf = self;
        if(self.album){
            [AFFPhotoPickerManager shareManager].sortAscendingByModificationDate = YES;
            [[AFFPhotoPickerManager shareManager] getAssetsFromResult:self.album.result
                                                          isPickVideo:self.isPickVideo
                                                                  max:NSUIntegerMax block:^(NSArray<AFFPhotoModel *> *models) {
                                                                      BOOL isPhAsset = YES;
                                                                      AFFPhotoModel *firstModel = [models firstObject];
                                                                      if([firstModel.asset isKindOfClass:[PHAsset class]]){
                                                                          isPhAsset = YES;
                                                                      }else{
                                                                          isPhAsset = NO;
                                                                      }
                                                                      for (AFFPhotoModel *tmp1 in models) {
                                                                          for (AFFPhotoModel *tmp2 in [AFFPhotoPickerManager shareManager].arrSelect) {
                                                                              if([AFFPhotoPickerManager isAssetEqual:tmp1.asset asset2:tmp2.asset]){
                                                                                  tmp1.selected = YES;
                                                                              }
                                                                          }
                                                                      }
                                                                      weakSelf.mArrData = [NSMutableArray arrayWithArray:models];
                                                                      [weakSelf.collectionView reloadData];
                                                                      [weakSelf scrollToBottom];
                                                                  }];
        }else{
            [AFFPhotoPickerManager shareManager].sortAscendingByModificationDate = YES;
            [[AFFPhotoPickerManager shareManager] getDefalutAlbum:self.isPickVideo  block:^(AFFAlbumModel *model) {
                [weakSelf.navigationItem setTitle:model.name];
                [[AFFPhotoPickerManager shareManager] getAssetsFromResult:model.result
                                                              isPickVideo:weakSelf.isPickVideo
                                                                      max:NSUIntegerMax
                                                                    block:^(NSArray<AFFPhotoModel *> *models) {
                                                                        for (AFFPhotoModel *tmp1 in models) {
                                                                            for (AFFPhotoModel *tmp2 in [AFFPhotoPickerManager shareManager].arrSelect) {
                                                                                if([AFFPhotoPickerManager isAssetEqual:tmp1.asset asset2:tmp2.asset]){
                                                                                    tmp1.selected = YES;
                                                                                }
                                                                            }
                                                                        }
                                                                        weakSelf.mArrData = [NSMutableArray arrayWithArray:models];
                                                                        [weakSelf.collectionView reloadData];
                                                                        [weakSelf scrollToBottom];
                                                                    }];
            }];
        }
    }
    self.mArrScope = [NSMutableArray array];
}

-(void)setup{
    if([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    UIButton *btnBack = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, kNavigationBar_Height)];
    [btnBack setImage:[UIImage imageNamed:@"ic_navi_back"] forState:UIControlStateNormal];
    // 让按钮内部的所有内容左对齐
    btnBack.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    // 让按钮的内容往左边偏移10
    btnBack.contentEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 10);
    [btnBack setTitle:@"照片" forState:UIControlStateNormal];
    btnBack.titleLabel.font = [UIFont systemFontOfSize:17];
    [btnBack addTarget:self action:@selector(goToBack) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btnBack];
    
    UIButton *btnCancle = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, kNavigationBar_Height)];
    [btnCancle setTitle:@"取消" forState:UIControlStateNormal];
    btnCancle.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10);
    btnCancle.titleLabel.font = [UIFont systemFontOfSize:17];
    [btnCancle addTarget:self action:@selector(dismissClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btnCancle];

    [self.navigationItem setTitle:self.album.name];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection=UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = kCellMargin;
    layout.minimumInteritemSpacing=kCellMargin;
    layout.itemSize = CGSizeMake(kPhotoListCellWidth, kPhotoListCellWidth);
    
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-kNavigationBar_Height-kStatusBar_Height);
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:frame collectionViewLayout:layout];
    [collectionView registerClass:[AFFVPhotoDetailFooter class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter  withReuseIdentifier:UICollectionElementKindSectionHeader];
    [collectionView registerClass:[AFFVSPhotoCell class] forCellWithReuseIdentifier:reuseCellIdentifier];
    collectionView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    collectionView.contentInset = UIEdgeInsetsMake(kCellMargin, 0, 0, 0);
    collectionView.alwaysBounceVertical = YES;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    [self setBottomView];
    collectionView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-kNavigationBar_Height-kStatusBar_Height-50);
    [self scrollToBottom];
}


-(void)setBottomView{
    UIView *bottomView = [[UIView alloc]initWithFrame:
                          CGRectMake(0, SCREEN_HEIGHT -kNavigationBar_Height-kStatusBar_Height - 50, SCREEN_WIDTH, 50)];
    bottomView.backgroundColor=[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
    [self.view addSubview:bottomView];
    
    CALayer *line=[[CALayer alloc]init];
    line.frame = CGRectMake(0, 0, SCREEN_WIDTH, 1);
    line.backgroundColor=[UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1].CGColor;
    [bottomView.layer addSublayer:line];
    
    UIButton *btnPreview=[[UIButton alloc]initWithFrame:CGRectMake(6, 15, 50, 20)];
    [btnPreview setTitle:@"预览" forState:UIControlStateNormal];
    btnPreview.titleLabel.font=[UIFont systemFontOfSize:14];
    btnPreview.enabled=NO;
    [btnPreview setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnPreview setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [btnPreview addTarget:self action:@selector(previewClick) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:btnPreview];
    self.btnPreview = btnPreview;
    
    UIButton *btnSend=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 80, 12.5, 60, 25)];
    btnSend.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:0.95 alpha:1];
    btnSend.layer.masksToBounds = YES;
    btnSend.layer.cornerRadius = 3;
    btnSend.titleLabel.font=[UIFont systemFontOfSize:14];
    [btnSend addTarget:self action:@selector(sendClick:) forControlEvents:UIControlEventTouchUpInside];
    btnSend.enabled=NO;
    [btnSend setTitle:@"发送" forState:UIControlStateNormal];
    [bottomView addSubview:btnSend];
    self.btnSend = btnSend;
}

-(void)refreshBtnSend{
    NSInteger count = 0;
    for (AFFPhotoModel *model in [AFFPhotoPickerManager shareManager].arrSelect) {
        if(model.selected) count++;
    }
    if (count > 0) {
        self.btnSend.enabled = YES;
        [self.btnSend setTitle:[NSString stringWithFormat:@"发送(%lu)",(unsigned long)count] forState:UIControlStateNormal];
        self.btnPreview.enabled = YES;
    }else{
        [self.btnSend setTitle:@"发送" forState:UIControlStateNormal];
        self.btnSend.enabled = NO;
        self.btnPreview.enabled = NO;
    }
}

-(void)scrollToBottom{
    CGFloat offset=self.mArrData.count*kPhotoListCellWidth/4;
    CGPoint point = self.collectionView.contentOffset;
    point.y = offset;
    self.collectionView.contentOffset = point;
}


#pragma mark UICollectionViewDelegate,UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.mArrData.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    AFFPhotoModel *model=[self.mArrData objectAtIndex:indexPath.row];
    AFFVSPhotoCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:reuseCellIdentifier forIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.btnSelectBlock = ^(AFFPhotoModel *photoModel,AFFVSPhotoCell *outcell){
        if(!photoModel.selected){
            [[AFFPhotoPickerManager shareManager] isAssetExistinLocal:photoModel.asset block:^(BOOL isExist) {
                if(isExist){
                    if([AFFPhotoPickerManager shareManager].arrSelect.count < weakSelf.maxSelCount){
                        photoModel.selected = !photoModel.selected;
                        [[AFFPhotoPickerManager shareManager].arrSelect addObject:photoModel];
                        [weakCell setBtnClick:photoModel.selected model:photoModel];
                    }else{
                        if(self.maxSelCount == 1){
                            //已选中的cell要取消选中状态
                            AFFPhotoModel *model = [[AFFPhotoPickerManager shareManager].arrSelect firstObject];
                            model.selected = NO;
                            [[AFFPhotoPickerManager shareManager].arrSelect removeAllObjects];
                            NSInteger index = [weakSelf.mArrData indexOfObject:model];
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                            AFFVSPhotoCell *cell =(AFFVSPhotoCell*)[weakSelf.collectionView cellForItemAtIndexPath:indexPath];
                            [cell setBtnClick:NO model:photoModel];
                            
                            photoModel.selected = !photoModel.selected;
                            [[AFFPhotoPickerManager shareManager].arrSelect addObject:photoModel];
                            [weakCell setBtnClick:photoModel.selected model:photoModel];
                            
                        }else{
                            if(model.type == AFFAssetMediaType_Photo || model.type == AFFAssetMediaType_LivePhoto){
                                [[AFFPhotoPickerManager shareManager] showInView:self.view info:[NSString stringWithFormat:@"图片不能超过%ld张",(long)self.maxSelCount]];
                            }else{
                                [[AFFPhotoPickerManager shareManager] showInView:self.view info:[NSString stringWithFormat:@"视频不能超过%ld个",(long)self.maxSelCount]];
                            }
                        }
                    }
                    
                }else{
                    [[AFFPhotoPickerManager shareManager] showInView:weakSelf.view info:@"图片未从iCloud同步"];
                }
                [weakSelf refreshBtnSend];
            }];
            
            
        }else{
            photoModel.selected = !photoModel.selected;
            photoModel.isRaw = NO;
            [weakCell setBtnClick:photoModel.selected model:photoModel];
            [[AFFPhotoPickerManager shareManager].arrSelect removeObject:photoModel];
        }
        [weakSelf refreshBtnSend];
    };
    [cell refreshCell:model isFormPicker:NO];
    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    AFFVPhotoDetailFooter *reusableview = nil;
    if (kind == UICollectionElementKindSectionFooter) {
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:UICollectionElementKindSectionHeader  forIndexPath:indexPath];
        if(self.isPickVideo)
            reusableview.lblCount.text=[NSString stringWithFormat:@"共有%ld个视频",(unsigned long)self.mArrData.count];
        else
            reusableview.lblCount.text=[NSString stringWithFormat:@"共有%ld张照片",(unsigned long)self.mArrData.count];
        
        reusableview = reusableview;
    }
    return reusableview;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    return CGSizeMake(SCREEN_WIDTH, 20);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    __weak typeof(self) weakSelf = self;
    
    AFFVCSPhotoBrowser *browser = [AFFVCSPhotoBrowser new];
    browser.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
        if(weakSelf.sendBlock)  weakSelf.sendBlock(arr);
    };
    browser.index = indexPath.row;
    browser.maxSelCount = self.maxSelCount;
    browser.mArrData = self.mArrData;
    browser.mArrScope = [AFFPhotoPickerManager shareManager].arrSelect;
    browser.imagePath = self.imagePath;
    [self.navigationController pushViewController:browser animated:YES];
    
}

-(void)previewClick{
    AFFVCSPhotoBrowser *browser = [AFFVCSPhotoBrowser new];
    __weak typeof(self) weakSelf = self;
    browser.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
        if(weakSelf.sendBlock)  weakSelf.sendBlock(arr);
    };
    browser.index = 0;
    browser.maxSelCount = self.maxSelCount;
    browser.mArrData = [NSMutableArray arrayWithArray:[AFFPhotoPickerManager shareManager].arrSelect];
    browser.mArrScope = [NSMutableArray arrayWithArray:[AFFPhotoPickerManager shareManager].arrSelect];
    browser.imagePath = self.imagePath;
    [self.navigationController pushViewController:browser animated:YES];
}

-(void)goToBack{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)sendClick:(UIButton*)btn{
    btn.enabled = NO;
    if(self.sendBlock && [AFFPhotoPickerManager shareManager].arrSelect.count > 0){
        __weak typeof(self) weakSelf = self;
        
        if(!self.isPickVideo){
            [[AFFPhotoPickerManager shareManager] putImageInFolder:self.imagePath array:[AFFPhotoPickerManager shareManager].arrSelect complete:^(NSArray<AFFDataPhotoInfo *> *outArray) {
                if(weakSelf.sendBlock) weakSelf.sendBlock(outArray);
                [weakSelf dismissViewControllerAnimated:YES completion:^{
                    [weakSelf cleanSelf];
                }];
            }];
        }else{
            AFFPhotoModel *model = [[AFFPhotoPickerManager shareManager].arrSelect firstObject];
            [[AFFPhotoPickerManager shareManager] getVideoOutputPathWithAsset:model.asset
                                                                     savePath:[AFFPhotoPickerManager getVideoFolder]
                                                                        block:^(AFFDataPhotoInfo *photo) {
                if(weakSelf.sendBlock) self.sendBlock(@[photo]);
                [weakSelf dismissViewControllerAnimated:YES completion:^{
                    [weakSelf cleanSelf];
                }];
            }];
        }
    }
}



-(void)dismissClick{
    if(self.dismissBlock)
        self.dismissBlock();
    [self dismissViewControllerAnimated:YES completion:^{
        [self cleanSelf];
    }];
}
@end


@implementation AFFVPhotoDetailFooter

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self setupUI];
    }
    return self;
}

-(void)setupUI{
    self.lblCount = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
        self.lblCount.textColor=[UIColor grayColor];
        self.lblCount.font= [UIFont systemFontOfSize:14];
    self.lblCount.textAlignment=NSTextAlignmentCenter;
    [self addSubview:self.lblCount];
}

@end
