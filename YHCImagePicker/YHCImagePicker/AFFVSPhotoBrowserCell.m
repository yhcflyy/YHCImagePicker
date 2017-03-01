//
//  AFFVSPhotoBrowserCell.m
//  AnyfishApp
//
//  Created by yaohongchao on 16/7/12.
//  Copyright © 2016年 Anyfish. All rights reserved.
//

#import "AFFVSPhotoBrowserCell.h"
#import "AFFPhotoPickerManager.h"


@interface AFFVSPhotoBrowserCell()<UIScrollViewDelegate>

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *imageContainerView;
@property (nonatomic, weak) UIImageView *imageView;

@end


#define cellWidth CGRectGetWidth(self.bounds)
#define cellHeight CGRectGetHeight(self.bounds)



@implementation AFFVSPhotoBrowserCell

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self setup];
    }
    return self;
}

-(void)setup{
    self.backgroundColor = [UIColor blackColor];
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.frame = CGRectMake(0, 0,cellWidth, cellHeight);
    scrollView.bouncesZoom = YES;
    scrollView.maximumZoomScale = 2.5;
    scrollView.minimumZoomScale = 1.0;
    scrollView.multipleTouchEnabled = YES;
    scrollView.delegate = self;
    scrollView.scrollsToTop = NO;
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.delaysContentTouches = NO;
    scrollView.canCancelContentTouches = YES;
    scrollView.alwaysBounceVertical = NO;
    [self addSubview:scrollView];
    self.scrollView = scrollView;
    
    UIView *imageContainerView = [[UIView alloc] init];
    imageContainerView.backgroundColor = [UIColor lightGrayColor];
    imageContainerView.clipsToBounds = YES;
    [scrollView addSubview:imageContainerView];
    self.imageContainerView = imageContainerView;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
    imageView.clipsToBounds = YES;
    [imageContainerView addSubview:imageView];
    self.imageView = imageView;
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    [self addGestureRecognizer:tap1];
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tap2.numberOfTapsRequired = 2;
    [tap1 requireGestureRecognizerToFail:tap2];
    [self addGestureRecognizer:tap2];
}

-(void)setPhotoModel:(AFFPhotoModel *)photoModel{
    __weak typeof(self) weakSelf = self;
    [[AFFPhotoPickerManager shareManager] getPhotoWithAsset:photoModel.asset block:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        weakSelf.imageView.image = photo;
        [weakSelf resizeSubviews];
    }];
}

-(void)setCellImageNil{
    self.imageView.image = nil;
}

- (void)recoverSubviews {
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self resizeSubviews];
}

- (void)resizeSubviews {
    CGRect frame = self.imageContainerView.frame;
    frame.origin = CGPointZero;
    frame.size.width = cellWidth;
    self.imageContainerView.frame = frame;
    
    UIImage *image = self.imageView.image;
    
    if (image.size.height / image.size.width > cellHeight / cellWidth) {
        CGRect frame = self.imageContainerView.frame;
        frame.size.height = floor(image.size.height / (image.size.width / cellWidth));
        self.imageContainerView.frame = frame;
    } else {
        CGFloat height = image.size.height / image.size.width * cellWidth;
        if (height < 1 || isnan(height)) height = cellHeight;
        height = floor(height);
        
        CGRect frame = self.imageContainerView.frame;
        frame.size.height = height;
        self.imageContainerView.frame = frame;
        self.imageContainerView.center = CGPointMake(self.imageContainerView.center.x, cellHeight/2);
    }
    
    if (CGRectGetHeight(self.imageContainerView.frame) > cellHeight && CGRectGetHeight(self.imageContainerView.frame) - cellHeight <= 1) {
        CGRect frame = self.imageContainerView.frame;
        frame.size.height = cellHeight;
        self.imageContainerView.frame = frame;
    }
    self.scrollView.contentSize = CGSizeMake(cellWidth, MAX(CGRectGetHeight(self.imageContainerView.frame), cellHeight));
    [self.scrollView scrollRectToVisible:self.bounds animated:NO];
    self.scrollView.alwaysBounceVertical = CGRectGetHeight(self.imageContainerView.frame) <= cellHeight ? NO : YES;
    self.imageView.frame = self.imageContainerView.bounds;
}


#pragma mark - UITapGestureRecognizer Event

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (self.scrollView.zoomScale > 1.0) {
        [self.scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [tap locationInView:self.imageView];
        CGFloat newZoomScale = _scrollView.maximumZoomScale;
        CGFloat xsize = self.frame.size.width / newZoomScale;
        CGFloat ysize = self.frame.size.height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

- (void)singleTap:(UITapGestureRecognizer *)tap {
    if(self.tapBlock) self.tapBlock();
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageContainerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat scrollWidth = SCREEN_WIDTH;
    CGFloat scrollHeight = CGRectGetHeight(scrollView.frame);

    CGFloat offsetX = (scrollWidth > scrollView.contentSize.width) ? (scrollWidth - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollHeight > scrollView.contentSize.height) ? (scrollHeight - scrollView.contentSize.height) * 0.5 : 0.0;
    self.imageContainerView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}


@end

@interface AFFVSPhotoBrowserVideoCell()

@property (nonatomic,strong ) AVPlayer      *player;
@property (nonatomic,strong ) UIButton      *btnPlay;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation AFFVSPhotoBrowserVideoCell

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self setup];
    }
    return self;
}

-(void)setup{
    UIButton *btnPlay=[[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 80)/2, (SCREEN_HEIGHT - 80)/2, 80, 80)];
    btnPlay.hidden = NO;
    [btnPlay setImage:[UIImage imageNamed:@"ic_chat_video_play"] forState:UIControlStateNormal];
    [btnPlay addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnPlay];
    self.btnPlay = btnPlay;
    
//    __weak typeof(self) weakSelf = self;
//    [self addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
//        [weakSelf tap];
//    }];
    

}

-(void)setPhotoModel:(AFFPhotoModel *)photoModel{
    _photoModel = photoModel;
    __weak typeof(self) weakSelf = self;
    [[AFFPhotoPickerManager shareManager]getVideoWithAsset:photoModel.asset block:^(AVPlayerItem *item, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.playerLayer removeFromSuperlayer];
            weakSelf.playerLayer = nil;
            [self.btnPlay removeFromSuperview];
            [weakSelf.player pause];
            weakSelf.player = nil;
            
            [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];

            weakSelf.player = [AVPlayer playerWithPlayerItem:item];
            [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(reset) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];
            
            weakSelf.playerLayer = [AVPlayerLayer playerLayerWithPlayer:weakSelf.player];
            weakSelf.playerLayer.frame = weakSelf.bounds;
            [weakSelf.layer addSublayer:weakSelf.playerLayer];
            [weakSelf addSubview:weakSelf.btnPlay];
            weakSelf.btnPlay.hidden = NO;
        });
    }];
}

-(void)playClick:(UIButton*)btn{
    CMTime currentTime = _player.currentItem.currentTime;
    CMTime durationTime = _player.currentItem.duration;
    if (self.player.rate == 0.0f) {
        if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        [self.player play];
        self.btnPlay.hidden = YES;
        if(self.hideBlock) self.hideBlock();
    } else {
        [self.player pause];
        self.btnPlay.hidden = NO;
    }
}

-(void)reset{
    self.btnPlay.hidden = NO;
    if(self.tapBlock) self.tapBlock();
}

-(void)tap{
    [self.player pause];
    self.btnPlay.hidden = NO;
    if(self.tapBlock) self.tapBlock();
}


- (void)dealloc {
    [self.player pause];
    self.player = nil;
    
    self.btnPlay = nil;
    
    self.playerLayer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end














