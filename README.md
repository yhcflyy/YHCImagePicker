# YHCImagePicker
类似于QQ的相册选择器

![image](https://github.com/yhcflyy/YHCImagePicker/blob/master/screenshot/1.png)![image](https://github.com/yhcflyy/YHCImagePicker/blob/master/screenshot/2.png)![image](https://github.com/yhcflyy/YHCImagePicker/blob/master/screenshot/3.png)![image](https://github.com/yhcflyy/YHCImagePicker/blob/master/screenshot/4.png)


使用方法：

1.现在类中持有一个AFFVSPhotoWindow对象

2.使用相关初始化代码，如下调用


  self.photoWindow = [[AFFVSPhotoWindow alloc]initWithCutType:NO maxSelect:5 imagePath:nil isAllowMulSel:YES isCleanFolder:NO];
  
    self.photoWindow.delegate = self;
    
    [self.photoWindow makeKeyAndVisible];
    
    主要的入参有是否选择视频isPickVideo、是否允许你多选isAllowMulSel，从相册取出图片、视频的临时存放目录imagePath，最多能选择几张图片maxImageShowInPicker
    
3.挂上AFFVSPhotoWindowDelegate代理，images数组中的AFFDataPhotoInfo对象就包含了图片和视频等相关信息

-(void)photoWindowSendImages:(AFFVSPhotoWindow*)pickerWindow images:(NSArray<AFFDataPhotoInfo*>*)images{
    [self.photoWindow dismiss];
    self.photoWindow = nil;
}

4.为了节省内存占用所以从相册导出图片或视频都存在了沙盒的临时目录中
