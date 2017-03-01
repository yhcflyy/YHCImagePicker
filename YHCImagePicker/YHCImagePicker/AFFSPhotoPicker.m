//
//  AFFSPhotoPicker.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import "AFFSPhotoPicker.h"
#import "AFFVSPhotoCell.h"
#import "AFFVCPhotoGroupList.h"
#import "AFFVCPhotoDetail.h"
#import "AFFVCSPhotoBrowser.h"

#define  CollectionViewHeight 150
#define  maxShow 30

@interface AFFSPhotoPicker ()<
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UIScrollViewDelegate,
UIGestureRecognizerDelegate
>
@property (nonatomic,weak    ) UIView                  *bottomView;
@property (nonatomic,strong  ) UIImagePickerController *take;
@property (nonatomic,weak    ) UICollectionView        *collectionView;
@property (nonatomic,assign  ) BOOL                     isAllowPhoto;///<是否有访问相册的权限

@end

@implementation AFFSPhotoPicker

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setUI];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    for (AFFPhotoModel *photoModel in self.mArrData) {
        photoModel.selected = NO;
        for (AFFPhotoModel *tmp in [AFFPhotoPickerManager shareManager].arrSelect) {
            if([AFFPhotoPickerManager isAssetEqual:tmp.asset asset2:photoModel.asset]){
                photoModel.selected  = YES;
            }
        }
    }
    [self.collectionView reloadData];
    [self refreshFirstBtnTitle];
}

-(void)dealloc{
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
    
    [self.arrSelect removeAllObjects];
    self.arrSelect = nil;
    
    self.take = nil;
    
    self.bottomView = nil;
}

-(void)setUI{
    CGRect statusBarRect = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat offY = 0;
    if(CGRectGetHeight(statusBarRect) > kStatusBar_Height){
        offY = 20;
    }
    if(self.bottomView && self.mArrData.count > 0 && !self.collectionView){
        CGRect frame = self.bottomView.frame;
        frame.size.height = 300 + offY;
        frame.origin.y = SCREEN_HEIGHT - 300 - offY;
        self.bottomView.frame = frame;
        [self setupCollectionView];
        [self.collectionView reloadData];
        for(NSInteger i = 0 ; i < 3 ; i++){
            NSInteger tag = 10 + i;
            UIButton *btn = [self.bottomView viewWithTag:tag];
            btn.frame = CGRectMake(0, i*50+CollectionViewHeight, SCREEN_WIDTH, 50);
        }
        return;
    }
    if(self.bottomView) return;
    CGFloat height = 150,collectionHeight = 0;
    if(self.mArrData.count > 0){
        height = 300 + offY;
        collectionHeight = CollectionViewHeight;
    }
    UIView *bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT-40, SCREEN_WIDTH, height)];
    bottomView.hidden = YES;
    bottomView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottomView];
    self.bottomView = bottomView;
    
    NSArray *titles;
    if(self.isPickVideo){
        titles = @[@"拍摄",@"从相册选取",@"取消"];
    }else{
        titles = @[@"拍照",@"从相册选取",@"取消"];
    }
    for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, i*50+collectionHeight, SCREEN_WIDTH, 50)];
        btn.tag = 10 + i;
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        NSString *strTitle = [titles objectAtIndex:i];
        [btn setTitle:strTitle forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [bottomView addSubview:btn];
        
        CALayer *line = [[CALayer alloc]init];
        line.frame = CGRectMake(0, 0, SCREEN_WIDTH, 0.5);
        line.backgroundColor=[UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1].CGColor;
        [btn.layer addSublayer:line];
    }
    [self showViewWithAnimate:YES];
    
    self.take = [[UIImagePickerController alloc]init];
    self.take.delegate = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissView)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}


-(void)setupCollectionView{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CollectionViewHeight) collectionViewLayout:layout];
    collectionView.userInteractionEnabled = YES;
    collectionView.contentInset=UIEdgeInsetsMake(0, 5, 0, 5);
    [collectionView registerClass:[AFFVSPhotoCell class] forCellWithReuseIdentifier:reuseCellIdentifier];
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.alwaysBounceHorizontal=YES;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.bottomView addSubview:collectionView];
    self.collectionView = collectionView;
}

-(void)setupData{
    if(self.maxSelCount <= 0){
        if(self.isPickVideo) self.maxSelCount = 1;
        else self.maxSelCount = 9;
    }
    if(self.isPickVideo && self.imagePath.length > 0){
        //        self.imagePath = kSetting.path_TempVideo;
    }
    __weak typeof(self) weakSelf = self;
    [self getData];
    //    if(IOS_VERSION < 8.0){
    //        kPermissionAccess accType = [[UIApplication sharedApplication] hasAccessToPhotos];
    //        if(accType == kPermissionAccessGranted){
    //            if(!self.isAllowPhoto) [weakSelf getData];
    //            self.isAllowPhoto = YES;
    //        }else if(accType == kPermissionAccessNotRequest){
    //            [[UIApplication sharedApplication] requestAccessToPhotosWithSuccess:^{
    //                if(!self.isAllowPhoto) [weakSelf getData];
    //                self.isAllowPhoto = YES;
    //            } andFailure:^{
    //
    //            }];
    //        }else if(accType == kPermissionAccessDenied) {
    //            [UIAlertView alertWithCallBackBlock:^(NSInteger buttonIndex) {
    //            } title:@"无法使用相册请在iPhone的\"设置-隐私-相册\"中允许百鱼访问您的相册" message:nil cancelButtonName:@"确定" otherButtonTitles:nil, nil];
    //        }
    //
    //    }else{
    //        kPermissionAccess accType = [[UIApplication sharedApplication] hasAccessToPhotos];
    //        if(accType == kPermissionAccessGranted){
    //            if(!self.isAllowPhoto) [weakSelf getData];
    //            self.isAllowPhoto = YES;
    //        }else if(accType == kPermissionAccessNotRequest){
    //            [[UIApplication sharedApplication] requestAccessToPhotosWithSuccess:^{
    //                if(!self.isAllowPhoto) [weakSelf getData];
    //                self.isAllowPhoto = YES;
    //            } andFailure:^{
    //
    //            }];
    //        }else if(accType == kPermissionAccessDenied) {
    //            [UIAlertView alertWithCallBackBlock:^(NSInteger buttonIndex) {
    //                if(buttonIndex == 1){
    //                    [weakSelf showPermiss];
    //                }
    //            } title:@"无法访问相册，是否前往打开相册访问权限？" message:nil cancelButtonName:@"否" otherButtonTitles:@"是", nil];
    //        }
    //    }
    self.mArrScope = [NSMutableArray array];
    [AFFPhotoPickerManager shareManager].maxSelect = self.maxSelCount;
    if(self.arrSelect.count > 0){
        [AFFPhotoPickerManager shareManager].arrSelect = self.arrSelect;
    }else{
        [AFFPhotoPickerManager shareManager].arrSelect = [NSMutableArray array];
    }
}

-(void)getData{
    __weak typeof(self) weakSelf = self;
    [AFFPhotoPickerManager shareManager].sortAscendingByModificationDate = NO;
    [[AFFPhotoPickerManager shareManager] getDefalutAlbum:self.isPickVideo block:^(AFFAlbumModel *model) {
        [[AFFPhotoPickerManager shareManager] getAssetsFromResult:model.result isPickVideo:self.isPickVideo max:maxShow block:^(NSArray<AFFPhotoModel *> *models) {
            weakSelf.mArrData = [NSMutableArray arrayWithArray:models];
            [weakSelf setUI];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.collectionView setContentOffset:CGPointMake(weakSelf.collectionView.contentOffset.x + 1, 0) animated:NO];
            });
        }];
    }];
}

-(void)showPermiss{
    NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if([[UIApplication sharedApplication] canOpenURL:url]) {
        NSURL*url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if(touch.view != self.view){
        return NO;
    }else{
        return YES;
    }
}

-(void)showViewWithAnimate:(BOOL)animate{
    self.bottomView.hidden = NO;
    self.view.backgroundColor = [UIColor clearColor];
    if(animate){
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect frame = weakSelf.bottomView.frame;
            frame.origin.y = SCREEN_HEIGHT - frame.size.height;
            weakSelf.bottomView.frame = frame;
            weakSelf.view.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        } completion:^(BOOL finished) {
            
        }];
    }else{
        self.view.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        CGRect frame = self.bottomView.frame;
        frame.origin.y = SCREEN_HEIGHT - frame.size.height;
        self.bottomView.frame = frame;
    }
}

-(void)hideViewWithAnimate:(BOOL)animate completion:(void (^)(BOOL finished))completion{
    if(animate){
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            //底部view坐标变化
            CGRect frame = weakSelf.bottomView.frame;
            frame.origin.y = SCREEN_HEIGHT;
            weakSelf.bottomView.frame = frame;
            //整个view背景色变化
            weakSelf.view.backgroundColor=[UIColor clearColor];
        } completion:^(BOOL finished) {
            weakSelf.bottomView.hidden = YES;
            if(completion){
                completion(YES);
            }
        }];
    }else{
        CGRect frame = self.bottomView.frame;
        frame.origin.y = SCREEN_HEIGHT;
        self.bottomView.frame = frame;
        self.view.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
}



/**
 *  点击事件
 */
-(void)btnClick:(UIButton*)btn{
    __weak typeof(self) weakSelf = self;
    if(btn.tag == 10){
        if([btn.titleLabel.text isEqualToString:@"拍照"]){
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                self.take.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:self.take animated:YES completion:nil];
            }else{
                NSLog(@"不可用");
            }
        }else if([btn.titleLabel.text isEqualToString:@"拍摄"]){
            
        }else{
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2-60, (CGRectGetHeight(btn.frame)-20)/2, 20, 20)];
            [btn setTitle:@"处理中..." forState:UIControlStateNormal];
            [btn addSubview:indicator];
            [indicator startAnimating];
            
            __weak typeof(self) weakSelf = self;
            if(!self.isPickVideo){
                [[AFFPhotoPickerManager shareManager] putImageInFolder:self.imagePath array:[AFFPhotoPickerManager shareManager].arrSelect complete:^(NSArray<AFFDataPhotoInfo *> *outArray) {
                    [indicator stopAnimating];
                    [indicator removeFromSuperview];
                    [[AFFPhotoPickerManager shareManager].arrSelect removeAllObjects];
                    [weakSelf refreshFirstBtnTitle];
                    [weakSelf hideViewWithAnimate:YES completion:^(BOOL finished) {
                        if(weakSelf.sendBlock) weakSelf.sendBlock(outArray);
                    }];
                }];
            }else{
                AFFDataPhotoInfo *photoInfo = [[AFFPhotoPickerManager shareManager].arrSelect firstObject];
                [[AFFPhotoPickerManager shareManager] getVideoOutputPathWithAsset:photoInfo.asset savePath:[AFFPhotoPickerManager getVideoFolder] block:^(AFFDataPhotoInfo *photo) {
                    [indicator stopAnimating];
                    [indicator removeFromSuperview];
                    [[AFFPhotoPickerManager shareManager].arrSelect removeAllObjects];
                    [weakSelf refreshFirstBtnTitle];
                    [weakSelf hideViewWithAnimate:YES completion:^(BOOL finished) {
                        if(weakSelf.sendBlock) weakSelf.sendBlock(@[photo]);
                    }];
                }];
            }
            
        }
    }else if (btn.tag == 11){
        
        [[AFFPhotoPickerManager shareManager]getDefalutAlbum:self.isPickVideo block:^(AFFAlbumModel *model) {
            AFFVCPhotoGroupList *list    = [[AFFVCPhotoGroupList alloc] init];
            list.isPickVideo = self.isPickVideo;
            list.maxSelCount = self.maxSelCount;
            list.imagePath = self.imagePath;
            list.isAllowMulSel = self.isAllowMulSel;
            list.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
                if(weakSelf.sendBlock) weakSelf.sendBlock(arr);
                [weakSelf hideViewWithAnimate:YES completion:^(BOOL finished) {
                }];
            };
            AFFVCPhotoDetail *detail = [[AFFVCPhotoDetail alloc] init];
            detail.isPickVideo = self.isPickVideo;
            detail.maxSelCount = self.maxSelCount;
            detail.imagePath = self.imagePath;
            detail.isAllowMulSel = self.isAllowMulSel;
            detail.album = model;
            detail.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
                [self dismissViewControllerAnimated:YES completion:nil];
                //            if(weakSelf.cutType == EImgCut_None){
                //                [weakSelf hideViewWithAnimate:YES completion:nil];
                //            }else{
                [weakSelf dismissView];
                //            }
                if(weakSelf.sendBlock) weakSelf.sendBlock(arr);
            };
            UINavigationController *nav = [[UINavigationController alloc]initWithNavigationBarClass:[UINavigationBar class] toolbarClass:nil];
            nav.navigationBar.barStyle = UIBarStyleBlack;
            nav.navigationBar.barTintColor = [UIColor colorWithRed:0.13 green:0.16 blue:0.17 alpha:1];
            nav.viewControllers = @[list,detail];
            nav.navigationBar.translucent = NO;
            [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
            [self presentViewController:nav animated:YES completion:nil];
            
        }];
        
    }else if (btn.tag == 12){
        [self dismissView];
    }
}

-(void)dismissView{
    __weak typeof(self) weakSelf = self;
    [self hideViewWithAnimate:YES completion:^(BOOL finished) {
        if(finished == YES){
            if(weakSelf.dismissBlock) weakSelf.dismissBlock();
        }
    }];
}

#pragma mark 拍照代理
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image=(UIImage*)[info objectForKey:UIImagePickerControllerOriginalImage];
    
    AFFDataPhotoInfo *photoInfo = [[AFFDataPhotoInfo alloc]init];
    NSData *data = [AFFPhotoPickerManager getImageData:image];
    NSString *url = [NSString stringWithFormat:@"%@/%@",self.imagePath,photoInfo.md5];
    photoInfo.fullPath = url;
    BOOL success = [data writeToFile:url atomically:YES];
    if(!success) NSLog(@"写入失败");
    [picker dismissViewControllerAnimated:YES completion:nil];
    if(self.sendBlock) self.sendBlock(@[photoInfo]);
    [self hideViewWithAnimate:YES completion:^(BOOL finished) {
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UICollectionViewDelegate,UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.mArrData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    AFFPhotoModel *model = [self.mArrData objectAtIndex:indexPath.row];
    AFFVSPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseCellIdentifier forIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.btnSelectBlock = ^(AFFPhotoModel *photoModel,AFFVSPhotoCell *outcell){
        if(!photoModel.selected){
            [[AFFPhotoPickerManager shareManager] isAssetExistinLocal:photoModel.asset block:^(BOOL isExist) {
                if(isExist){
                    if([AFFPhotoPickerManager shareManager].arrSelect.count < weakSelf.maxSelCount){
                        photoModel.selected = !photoModel.selected;
                        [[AFFPhotoPickerManager shareManager].arrSelect addObject:photoModel];
                        [outcell setBtnClick:photoModel.selected model:photoModel];
                        [weakSelf selectScroll:outcell];
                    }else{
                        if(weakSelf.maxSelCount == 1){
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
                            [weakSelf selectScroll:outcell];
                            
                        }else{
                            if(model.type == AFFAssetMediaType_Photo || model.type == AFFAssetMediaType_LivePhoto){
                                [[AFFPhotoPickerManager shareManager] showInView:weakSelf.view info:[NSString stringWithFormat:@"图片不能超过%ld张",(long)self.maxSelCount]];
                            }else{
                                [[AFFPhotoPickerManager shareManager] showInView:weakSelf.view info:[NSString stringWithFormat:@"视频不能超过%ld个",(long)self.maxSelCount]];
                            }
                        }
                    }
                }else{
                    [[AFFPhotoPickerManager shareManager] showInView:weakSelf.view info:@"图片未从iCloud同步"];
                }
                [weakSelf refreshFirstBtnTitle];
            }];
        }else{
            photoModel.selected = !photoModel.selected;
            photoModel.isRaw = NO;
            [weakCell setBtnClick:photoModel.selected model:photoModel];
            [[AFFPhotoPickerManager shareManager].arrSelect removeObject:photoModel];
        }
        [weakSelf refreshFirstBtnTitle];
    };
    [cell refreshCell:model isFormPicker:YES];
    return cell;
}

-(void)selectScroll:(AFFVSPhotoCell*)cell{
    CGRect frame = [self.collectionView convertRect:cell.frame toView:nil];
    CGFloat x = frame.origin.x + frame.size.width/2 - SCREEN_WIDTH/2;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    x = self.collectionView.contentOffset.x + x;
    if(indexPath.row != 0 && x > 0){
        [self.collectionView setContentOffset:CGPointMake(x, 0) animated:YES];
    }else{
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x + 20, 0) animated:YES];
    }
}

-(void)refreshFirstBtnTitle{
    UIButton *btnFirst = [self.bottomView viewWithTag:10];
    if([AFFPhotoPickerManager shareManager].arrSelect.count > 0){
        AFFPhotoModel *model = [[AFFPhotoPickerManager shareManager].arrSelect firstObject];
        NSString *strTitle;
        if(model.type == AFFAssetMediaType_Photo || model.type == AFFAssetMediaType_LivePhoto){
            strTitle = [NSString stringWithFormat:@"发送(%lu)张",(unsigned long)[AFFPhotoPickerManager shareManager].arrSelect.count];
        }else  if(model.type == AFFAssetMediaType_Video){
            strTitle = [NSString stringWithFormat:@"发送(%lu)个",(unsigned long)[AFFPhotoPickerManager shareManager].arrSelect.count];
        }
        [btnFirst setTitle:strTitle forState:UIControlStateNormal];
        [btnFirst setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }else{
        if(self.isPickVideo){
            [btnFirst setTitle:@"拍摄" forState:UIControlStateNormal];
            [btnFirst setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }else{
            [btnFirst setTitle:@"拍照" forState:UIControlStateNormal];
            [btnFirst setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    AFFPhotoModel *model = [self.mArrData objectAtIndex:indexPath.row];
    //处理超高超宽图片
    CGFloat scale = model.size.width/model.size.height;
    if(scale > 2){
        return CGSizeMake(240, 140);
    }else if (scale < 0.5){
        return CGSizeMake(100, 140);
    }
    CGSize size=CGSizeMake(140*model.size.width/model.size.height,140);
    return size;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    AFFPhotoModel *model = [self.mArrData objectAtIndex:indexPath.row];
    __weak typeof(self) weakSelf = self;
    if(!self.isAllowMulSel){
        
        if(self.isPickVideo){
            AFFVCSPhotoBrowser *browser = [[AFFVCSPhotoBrowser alloc]init];
            browser.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
                if(weakSelf.sendBlock) weakSelf.sendBlock(arr);
                [weakSelf hideViewWithAnimate:YES completion:^(BOOL finished) {
                    
                }];
            };
            browser.index = model.selected ? 0 : indexPath.row;
            browser.maxSelCount = 1;
            browser.mArrData = self.mArrData;
            browser.imagePath = self.imagePath;
            
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:browser];
            nav.navigationBar.barStyle = UIBarStyleBlack;
            nav.navigationBar.barTintColor = [UIColor colorWithRed:0.13 green:0.16 blue:0.17 alpha:1];
            nav.navigationBar.translucent = NO;
            [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
            [self presentViewController:nav animated:YES completion:nil];
            
        }else{
            [[AFFPhotoPickerManager shareManager] putImageInFolder:self.imagePath array:@[model] complete:^(NSArray<AFFDataPhotoInfo *> *outArray) {
                [weakSelf hideViewWithAnimate:YES completion:^(BOOL finished) {
                    if(weakSelf.sendBlock) weakSelf.sendBlock(outArray);
                }];
            }];
        }
        return;
    }
    AFFVCSPhotoBrowser *browser = [AFFVCSPhotoBrowser new];
    browser.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
        if(weakSelf.sendBlock) weakSelf.sendBlock(arr);
        [weakSelf hideViewWithAnimate:YES completion:^(BOOL finished) {
            
        }];
    };
    browser.index = model.selected ? 0 : indexPath.row;
    browser.maxSelCount = self.maxSelCount;
    browser.mArrData = model.selected ? [NSMutableArray arrayWithArray:[AFFPhotoPickerManager shareManager].arrSelect] : self.mArrData;
    browser.mArrScope = [NSMutableArray arrayWithArray:[AFFPhotoPickerManager shareManager].arrSelect];
    browser.imagePath = self.imagePath;
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:browser];
    nav.navigationBar.barStyle = UIBarStyleBlack;
    nav.navigationBar.barTintColor = [UIColor colorWithRed:0.13 green:0.16 blue:0.17 alpha:1];
    [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [self presentViewController:nav animated:YES completion:nil];
}



- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoPickercontentOffsetX" object:[NSNumber numberWithFloat:scrollView.contentOffset.x+SCREEN_WIDTH]];
}


@end
