//
//  AFFVCPhotoGroupList.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/11.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#define kPhoto_List_Cell_Height  75
#define kPhoto_List_Cell_H_Margin  15
#define kPhoto_List_Cell_V_Margin  7


#import "AFFVCPhotoGroupList.h"
#import "AFFPhotoPickerManager.h"
#import "AFFVCPhotoDetail.h"

@interface AFFVCPhotoGroupList ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,weak) UITableView *tableView;
@end

@implementation AFFVCPhotoGroupList

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
}

-(void)setup{
    if([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.navigationItem.title=@"照片";
    UIButton *btnCancle = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, kNavigationBar_Height)];
    [btnCancle setTitle:@"取消" forState:UIControlStateNormal];
    btnCancle.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10);
    btnCancle.titleLabel.font = [UIFont systemFontOfSize:17];
    [btnCancle addTarget:self action:@selector(dismissClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btnCancle];
    
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-kNavigationBar_Height-kStatusBar_Height);
    UITableView *tableView=[[UITableView alloc]initWithFrame:frame style:UITableViewStylePlain];
    tableView.delegate=self;
    tableView.dataSource=self;
    tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

-(void)setupData{
    __weak typeof(self) weakSelf = self;
    [[AFFPhotoPickerManager shareManager] getAllAlbums:self.isPickVideo completion:^(NSArray<AFFAlbumModel *> *models) {
        weakSelf.mArrData = [NSMutableArray arrayWithArray:models];
        [weakSelf.tableView reloadData];
    }];
}

#pragma UITableView delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.mArrData.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kPhoto_List_Cell_Height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AFFVPhotoGroupListCell *cell=[tableView dequeueReusableCellWithIdentifier:reuseCellIdentifier];
    if(!cell){
        cell=[[AFFVPhotoGroupListCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseCellIdentifier];
    }
    AFFAlbumModel *model=[self.mArrData objectAtIndex:indexPath.row];
    cell.model = model;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    AFFVCPhotoDetail *detail = [[AFFVCPhotoDetail alloc]init];
    detail.isPickVideo = self.isPickVideo;
    detail.maxSelCount = self.maxSelCount;
    detail.imagePath = self.imagePath;
    detail.isAllowMulSel = self.isAllowMulSel;
    detail.album = [self.mArrData objectAtIndex:indexPath.row];
    __weak typeof(self) weakSelf = self;
    detail.sendBlock = ^(NSArray<AFFDataPhotoInfo*> *arr){
        [self dismissViewControllerAnimated:YES completion:nil];
        if(weakSelf.sendBlock) weakSelf.sendBlock(arr);
    };
    [self.navigationController pushViewController:detail animated:YES];
}



-(void)dismissClick{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end


@interface AFFVPhotoGroupListCell()
@property (nonatomic, weak) UILabel *lblTitle;
@property (nonatomic, weak) UILabel *lblCount;
@property (nonatomic, weak) UIImageView *thumbImageView;
@end

@implementation AFFVPhotoGroupListCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        [self setupUI];
    }
    return self;
}

-(void)setupUI{
    
    UIImageView *thumbImageView = [[UIImageView alloc]initWithFrame:CGRectMake(kPhoto_List_Cell_H_Margin, kPhoto_List_Cell_V_Margin, kPhoto_List_Cell_Height- 2*kPhoto_List_Cell_V_Margin, kPhoto_List_Cell_Height- 2*kPhoto_List_Cell_V_Margin)];
    thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
    thumbImageView.clipsToBounds = YES;
    [self addSubview:thumbImageView];
    self.thumbImageView = thumbImageView;
    
    UILabel *lblTitle=[[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.thumbImageView.frame)+kPhoto_List_Cell_H_Margin, 20, SCREEN_WIDTH - (CGRectGetMaxX(self.thumbImageView.frame)+kPhoto_List_Cell_H_Margin) - 30, 18)];
    lblTitle.font = [UIFont systemFontOfSize:16];
    lblTitle.textColor = [UIColor blackColor];
    lblTitle.highlightedTextColor = [UIColor blackColor];
    lblTitle.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:lblTitle];
    self.lblTitle = lblTitle;
    
    UILabel *lblCount=[[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMinX(self.lblTitle.frame), CGRectGetMaxY(self.lblTitle.frame) + 5, CGRectGetWidth(self.lblTitle.frame), 14)];
    lblCount.font = [UIFont systemFontOfSize:16];
    lblCount.textAlignment=NSTextAlignmentLeft;
    lblCount.textColor = [UIColor blackColor];
    lblCount.highlightedTextColor = [UIColor blackColor];
    [self addSubview:lblCount];
    self.lblCount = lblCount;
    
    CALayer *line = [[CALayer alloc]init];
    line.frame = CGRectMake(0,kPhoto_List_Cell_Height - 0.5 , SCREEN_WIDTH, 0.5);
    line.backgroundColor =[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1].CGColor;
    [self.layer addSublayer:line];
    
    self.selectionStyle=UITableViewCellSelectionStyleGray;
}

-(void)setModel:(AFFAlbumModel *)model{
    _model = model;
    
    self.lblTitle.text = model.name;
    self.lblCount.text = [NSString stringWithFormat:@"%ld",(long)model.count];
    __weak typeof(self) weakSelf = self;
    [[AFFPhotoPickerManager shareManager] getPostImageWithAlbumModel:model block:^(UIImage *postImage) {
        weakSelf.thumbImageView.image = postImage;
    }];
}

@end
