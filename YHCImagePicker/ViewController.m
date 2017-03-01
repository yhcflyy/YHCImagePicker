//
//  ViewController.m
//  YHCImagePicker
//
//  Created by yaohongchao on 17/3/1.
//  Copyright © 2017年 yaohongchao. All rights reserved.
//

#import "ViewController.h"
#import "AFFVSPhotoWindow.h"

@interface ViewController ()<AFFVSPhotoWindowDelegate>
@property (nonatomic, strong) AFFVSPhotoWindow *photoWindow;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake((320-100)/2, 400, 100, 40)];
    [btn setTitle:@"选择图片" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}


-(void)btnClick:(UIButton*)btn{
    self.photoWindow = [[AFFVSPhotoWindow alloc]initWithCutType:NO maxSelect:5 imagePath:nil isAllowMulSel:YES isCleanFolder:NO];
    self.photoWindow.isPickVideo = NO;
    self.photoWindow.delegate = self;
    [self.photoWindow makeKeyAndVisible];
}

- (void)photoWindowSendImages:(AFFVSPhotoWindow*)pickerWindow images:(NSArray<AFFDataPhotoInfo*>*)images{
    if(images && images.count > 0){

    }
    [self.photoWindow dismiss];
    self.photoWindow = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
