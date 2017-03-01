//
//  AFFVCSPhotoBrowser.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/12.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import "AFFVCSPhotoBrowser.h"
#import "AFFVSPhotoBrowserCell.h"
#import "AFFPhotoPickerManager.h"

static NSString *reuseID = @"reuseID";

@interface AFFVCSPhotoBrowser ()<UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>
@property (nonatomic,weak    ) UICollectionView *collectionView;
@property (nonatomic,strong  ) UIButton         *btnRight;
@property (nonatomic,weak    ) UIButton         *btnRaw;
@property (nonatomic,weak    ) UIButton         *btnSend;
@property (nonatomic,weak    ) UIView           *bottomView;
@property (nonatomic,weak    ) UILabel          *lblSize;
@property (nonatomic,strong  ) NSMutableArray   *selectArr;
@end

@implementation AFFVCSPhotoBrowser

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)cleanSelf{
    
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
    
}

-(void)dealloc{
    [self cleanSelf];
}

-(void)popOrDismiss{
    if(self.navigationController.viewControllers.count <= 1){
        __weak typeof(self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            [weakSelf cleanSelf];
        }];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
        
    }
}

-(void)setup{
    self.navigationController.navigationBar.translucent = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    UIButton *btnBack = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, kNavigationBar_Height)];
    [btnBack setImage:[UIImage imageNamed:@"ic_navi_back"] forState:UIControlStateNormal];
    btnBack.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btnBack.contentEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 10);
    [btnBack setTitle:@"返回" forState:UIControlStateNormal];
    btnBack.titleLabel.font = [UIFont systemFontOfSize:17];
    [btnBack addTarget:self action:@selector(popOrDismiss) forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btnBack];
    //设置导航栏右边按钮
    self.btnRight=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.btnRight addTarget:self action:@selector(selectClick:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:self.btnRight];
    [self.btnRight setImage:[UIImage imageNamed:@"ic_navi_check_sel"] forState:UIControlStateSelected];
    [self.btnRight setImage:[UIImage imageNamed:@"ic_navi_check_nor"] forState:UIControlStateNormal];
    
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
    layout.minimumLineSpacing = 40.0;
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(-20, 0, SCREEN_WIDTH+40 , SCREEN_HEIGHT) collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor blackColor];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.pagingEnabled = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.alwaysBounceHorizontal = YES;
    [collectionView registerClass:[AFFVSPhotoBrowserCell class] forCellWithReuseIdentifier:reuseCellIdentifier];
    [collectionView registerClass:[AFFVSPhotoBrowserVideoCell class] forCellWithReuseIdentifier:reuseID];
    
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    
    [self setBottomView];
    
    CGPoint offset = collectionView.contentOffset;
    offset.x = self.index*(SCREEN_WIDTH+40);
    collectionView.contentOffset = offset;
    AFFPhotoModel *model = [self.mArrData objectAtIndex:self.index];
    self.btnRight.selected = model.selected;
    
    [self refreshTitle:self.index];
    [self refreshBtnSend];
}


-(void)setBottomView{
    UIView *bottomView = [[UIView alloc]initWithFrame:
                          CGRectMake(0, SCREEN_HEIGHT - 50, SCREEN_WIDTH, 50)];
    
    bottomView.backgroundColor=[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
    [self.view addSubview:bottomView];
    
    CALayer *line=[[CALayer alloc]init];
    line.frame = CGRectMake(0, 0, SCREEN_WIDTH, 1);
    line.backgroundColor=[UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1].CGColor;
    [bottomView.layer addSublayer:line];
    self.bottomView = bottomView;
    
    UIButton *btnRaw=[[UIButton alloc]initWithFrame:CGRectMake(6, 15, 60, 20)];
    [btnRaw setImage:[UIImage imageNamed:@"ic_radio_blue_nor"] forState:UIControlStateNormal];
    [btnRaw setImage:[UIImage imageNamed:@"ic_radio_blue_sel"] forState:UIControlStateSelected];
    [btnRaw setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [btnRaw setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [btnRaw setTitle:@" 原图" forState:UIControlStateNormal];
    btnRaw.titleLabel.font=[UIFont systemFontOfSize:14];
    [btnRaw addTarget:self action:@selector(btnRawClick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:btnRaw];
    self.btnRaw = btnRaw;
    
    UILabel *lblSize = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(btnRaw.frame)+2, 15, 60, 20)];
    lblSize.font = [UIFont systemFontOfSize:14];
    lblSize.textColor = [UIColor blackColor];
    [bottomView addSubview:lblSize];
    self.lblSize = lblSize;
    
    UIButton *btnSend=[[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 80, 12.5, 60, 25)];
    btnSend.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:0.95 alpha:1];
    btnSend.layer.masksToBounds = YES;
    btnSend.layer.cornerRadius = 3;
    btnSend.titleLabel.font=[UIFont systemFontOfSize:14];
    [btnSend addTarget:self action:@selector(sendClick) forControlEvents:UIControlEventTouchUpInside];
    btnSend.enabled=NO;
    [btnSend setTitle:[NSString stringWithFormat:@"发送(%lu)",(unsigned long)[AFFPhotoPickerManager shareManager].arrSelect.count] forState:UIControlStateNormal];
    [bottomView addSubview:btnSend];
    self.btnSend = btnSend;
}


#pragma mark UICollectionViewDelegate,UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.mArrData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    AFFPhotoModel *model = [self.mArrData objectAtIndex:indexPath.row];
    __weak typeof(self) weakSelf = self;
    if(model.type == AFFAssetMediaType_Photo || model.type == AFFAssetMediaType_LivePhoto){
        AFFVSPhotoBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseCellIdentifier forIndexPath:indexPath];
        [cell setCellImageNil];
        cell.tapBlock = ^(){
            [weakSelf hideShowNavBar];
        };
        self.lblSize.text = nil;
        cell.photoModel = model;
        [self hideBtnRaw:NO];
        return cell;
    }else{
        AFFVSPhotoBrowserVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
        cell.tapBlock = ^(){
            [weakSelf hideShowNavBar];
        };
        cell.hideBlock = ^(){
            [weakSelf hideNavBar:YES];
        };
        cell.photoModel = model;
        [self hideBtnRaw:YES];
        return cell;
    }
}

-(void)hideBtnRaw:(BOOL)isHide{
    self.btnRaw.hidden = isHide;
    self.lblSize.hidden = isHide;
}

-(void)hideNavBar:(BOOL)isHidden{
    CGFloat y = 0;
    if(!isHidden){
        y = SCREEN_HEIGHT - 50;
    }else{
        y = SCREEN_HEIGHT;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:isHidden withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:isHidden animated:YES];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect frame=self.bottomView.frame;
        frame.origin.y=y;
        self.bottomView.frame=frame;
    } completion:nil];
}

-(void)hideShowNavBar{
    CGFloat y = 0;
    BOOL isHide = NO;
    if(self.navigationController.navigationBar.isHidden){
        isHide = NO;
        y = SCREEN_HEIGHT - 50;
    }else{
        isHide = YES;
        y = SCREEN_HEIGHT;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:isHide withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:isHide animated:YES];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect frame=self.bottomView.frame;
        frame.origin.y=y;
        self.bottomView.frame=frame;
    } completion:nil];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    self.index = (NSInteger)scrollView.contentOffset.x / CGRectGetWidth(self.collectionView.frame);
    [self refreshTitle:self.index];
}

-(void)refreshTitle:(NSInteger)index{
    NSString *title = [NSString stringWithFormat:@"%ld/%lu",(long)index+1,(unsigned long)self.mArrData.count];
    [self.navigationItem setTitle:title];
    
    AFFPhotoModel *model = [self.mArrData objectAtIndex:index];
    self.btnRaw.selected = model.isRaw;
    self.btnRight.selected = model.selected;
    
    if(model.isRaw){
        __weak typeof(self) weakSelf = self;
        [[AFFPhotoPickerManager shareManager] getAssetLength:model block:^(AFFPhotoModel *result) {
            weakSelf.lblSize.text = [NSString stringWithFormat:@"(%@)",[[AFFPhotoPickerManager shareManager] getBytesFromDataLength:result.byteLen]];
            weakSelf.lblSize.hidden = NO;
        }];
    }else{
        self.lblSize.hidden = YES;
    }
}

-(void)selectClick:(UIButton*)btn{
    AFFPhotoModel *model = [self.mArrData objectAtIndex:self.index];
    if(!model.selected && [AFFPhotoPickerManager shareManager].arrSelect.count >= self.maxSelCount){
        if(model.type == AFFAssetMediaType_Photo || model.type == AFFAssetMediaType_LivePhoto){
            [[AFFPhotoPickerManager shareManager] showInView:self.view info:[NSString stringWithFormat:@"图片不能超过%ld张",(long)self.maxSelCount]];
        }else{
            [[AFFPhotoPickerManager shareManager] showInView:self.view info:[NSString stringWithFormat:@"视频不能超过%ld个",(long)self.maxSelCount]];
        }
        return;
    }
    [[AFFPhotoPickerManager shareManager] isAssetExistinLocal:model.asset block:^(BOOL isExist) {
        if(isExist){
            model.selected = !model.selected;
            btn.selected = model.selected;
            if(model.selected){
                if(![[AFFPhotoPickerManager shareManager].arrSelect containsObject:model] ){
                    [[AFFPhotoPickerManager shareManager].arrSelect addObject:model];
                }
            }else{
                model.isRaw = NO;
                self.btnRaw.selected = model.isRaw;
                model.selected = NO;
                [[AFFPhotoPickerManager shareManager].arrSelect removeObject:model];
            }
            [self refreshBtnSend];
        }else{
            [[AFFPhotoPickerManager shareManager] showInView:self.view info:@"图片未从iCloud同步"];
        }
    }];
}

-(void)btnRawClick:(UIButton*)btn{
    AFFPhotoModel *model = [self.mArrData objectAtIndex:self.index];
    if(!model.selected && [AFFPhotoPickerManager shareManager].arrSelect.count >= self.maxSelCount){
        if(model.type == AFFAssetMediaType_Photo || model.type == AFFAssetMediaType_LivePhoto){
            [[AFFPhotoPickerManager shareManager] showInView:self.view info:[NSString stringWithFormat:@"图片不能超过%ld张",(long)self.maxSelCount]];
        }else{
            [[AFFPhotoPickerManager shareManager] showInView:self.view info:[NSString stringWithFormat:@"视频不能超过%ld个",(long)self.maxSelCount]];
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[AFFPhotoPickerManager shareManager] isAssetExistinLocal:model.asset block:^(BOOL isExist) {
        if(isExist){
            if(!model.isRaw){
                model.selected = YES;
                self.btnRight.selected = YES;
                if(![[AFFPhotoPickerManager shareManager].arrSelect containsObject:model]){
                    [[AFFPhotoPickerManager shareManager].arrSelect addObject:model];
                }
                [self refreshBtnSend];
                [[AFFPhotoPickerManager shareManager] getAssetLength:model block:^(AFFPhotoModel *result) {
                    weakSelf.lblSize.text = [NSString stringWithFormat:@"(%@)",[[AFFPhotoPickerManager shareManager] getBytesFromDataLength:result.byteLen]];
                    weakSelf.lblSize.hidden = NO;
                }];
            }else{
                self.lblSize.hidden = YES;
            }
            model.isRaw = !model.isRaw;
            btn.selected = model.isRaw;
        }else{
            [[AFFPhotoPickerManager shareManager] showInView:self.view info:@"图片未从iCloud同步"];
        }
    }];
}

-(void)refreshBtnSend{
    self.selectArr = [NSMutableArray array];
    for (AFFPhotoModel *model in [AFFPhotoPickerManager shareManager].arrSelect) {
        if(model.selected){
            [self.selectArr addObject:model];
        }
    }
    if(self.selectArr.count > 0){
        self.btnSend.enabled = YES;
    }else{
        self.btnSend.enabled = NO;
    }
    [self.btnSend setTitle:[NSString stringWithFormat:@"发送(%lu)",(unsigned long)self.selectArr.count] forState:UIControlStateNormal];
}

-(void)sendClick{
    __weak typeof(self) weakSelf = self;
    AFFPhotoModel *model = [[AFFPhotoPickerManager shareManager].arrSelect firstObject];
    if(model.type == AFFAssetMediaType_Video){
        [[AFFPhotoPickerManager shareManager] showLoadingInView:self.view];
        AFFDataPhotoInfo *photoInfo = [[AFFPhotoPickerManager shareManager].arrSelect firstObject];
        [[AFFPhotoPickerManager shareManager] getVideoOutputPathWithAsset:photoInfo.asset
                                                                 savePath:[AFFPhotoPickerManager getVideoFolder]
                                                                    block:^(AFFDataPhotoInfo *photo) {
            [weakSelf dismissViewControllerAnimated:YES completion:^{
                if(weakSelf.sendBlock) self.sendBlock(@[photo]);
                [weakSelf cleanSelf];
            }];
        }];
    }else{
        [[AFFPhotoPickerManager shareManager] putImageInFolder:self.imagePath array:self.selectArr complete:^(NSArray<AFFDataPhotoInfo *> *outArray) {
            if(weakSelf.sendBlock) self.sendBlock(outArray);
            [weakSelf dismissViewControllerAnimated:YES completion:^{
                [weakSelf cleanSelf];
            }];
        }];
    }
}
@end
