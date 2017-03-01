# YHCImagePicker
类似于QQ的相册选择器
使用方法在类中持有一个AFFVSPhotoWindow对象，该弹框是一个UIWindow
-(void)btnClick:(UIButton*)btn{
    self.photoWindow = [[AFFVSPhotoWindow alloc]initWithCutType:NO maxSelect:5 imagePath:nil isAllowMulSel:YES isCleanFolder:NO];
    self.photoWindow.delegate = self;
    [self.photoWindow makeKeyAndVisible];
}

- (void)photoWindowSendImages:(AFFVSPhotoWindow*)pickerWindow images:(NSArray<AFFDataPhotoInfo*>*)images{
    if(images && images.count > 0){

    }
    [self.photoWindow dismiss];
    self.photoWindow = nil;
}
