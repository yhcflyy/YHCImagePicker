# YHCImagePicker
类似于QQ的相册选择器
使用方法在类中持有一个AFFVSPhotoWindow对象，该弹框是一个UIWindow
在需要调用的地方编写如下代码
self.photoWindow = [[AFFVSPhotoWindow alloc]initWithCutType:NO maxSelect:5 imagePath:nil isAllowMulSel:YES isCleanFolder:NO];
self.photoWindow.isPickVideo = NO;
self.photoWindow.delegate = self;
[self.photoWindow makeKeyAndVisible];接下来挂上AFFVSPhotoWindowDelegate代理实现photoWindowSendImages:images:代理方法
