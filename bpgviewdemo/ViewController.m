//
//  ViewController.m
//  bpgviewdemo
//
//  Created by hpking　 on 2016/11/29.
//  Copyright © 2016年 jgorski. All rights reserved.
//

#import "ViewController.h"
//#import "HBPGImageView.h"

#include <CoreGraphics/CGImage.h>
#import <ImageIO/ImageIO.h>
#import "libbpg.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

// 动画结束指针
typedef  void (^AnimationComplete) (BOOL isFinished);

@interface ViewController ()
{
    BPGDecoderContext *_bpgcontext;
    BPGImageInfo _bpgInfo;
    size_t _bpgLineSize;
    
    CALayer *_layer;
    
    int _index;
    NSMutableArray *_images;
    
    CADisplayLink *displayLink;
    NSTimeInterval timestamp;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 解码动画
    // cinemagraph
    // animation
    NSString *bpgPath = [[NSBundle mainBundle] pathForResource:@"animation" ofType:@"bpg"];
    
    [self playAni:bpgPath];
    
    /*UIImage* image = [UIImage imageNamed:@"logo2.png"];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(10, 100, image.size.width, image.size.height)];
    CGRect frame = CGRectMake(0, 10, SCREEN_WIDTH, SCREEN_HEIGHT);
    iv.center = CGPointMake(frame.size.width/2, 200); // 设置中心点
    iv.contentMode = UIViewContentModeScaleAspectFit;//自适应
    iv.image = image;
    
    [self.view addSubview:iv];*/
    
    // CALayer的寄宿图
    /*UIImage* image = [UIImage imageNamed:@"logo2.png"];
    self.view.layer.contents = (__bridge id)image.CGImage;
    self.view.layer.contentsGravity = kCAGravityCenter;
//    self.view.layer.contentsGravity = kCAGravityResizeAspect;
    self.view.layer.contentsScale = image.scale;*/
}

// 播放动画
-(void) playAni:(NSString*)bpgPath //complete:(AnimationComplete)animationComplete
{
    
    NSData *bpgData = [NSData dataWithContentsOfFile:bpgPath];
    _images = [self bpgdecode:bpgData];
    
    UIImage* frame0 = [[_images objectAtIndex:0] objectForKey:@"frame"];
    
    // 创建图像显示图层
    _layer = [[CALayer alloc] init];
    _layer.bounds = CGRectMake(0, 0, frame0.size.width, frame0.size.height);
    _layer.position = CGPointMake(self.view.center.x, self.view.center.y);
    [self.view.layer addSublayer:_layer];
    
    // 定义时钟对象
    displayLink  = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
    
    // 添加时钟对象到主运行循环
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    //  添加路径动画
//    [self addAnimation];

}

#pragma mark ---- 添加关键帧动画 --- > 给钟表一个游动的路线
-(void)addAnimation
{
    // 1. 创建动画对象
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 430, 600);
    CGPathAddCurveToPoint(path, NULL, 100, 600, 400, 200, -10, 50);
    animation.path = path;
    animation.repeatCount = HUGE_VALF;
    animation.duration = 8.0;
    animation.removedOnCompletion = NO;
    
    [_layer addAnimation:animation forKey:@"fishAnimation"];
    
    CGPathRelease(path);
}

#pragma mark --- 每次屏幕刷新都会执行一次此方法(每秒接近60次)
- (void)step
{
    /*timestamp += fmin(displayLink.duration, 1);
    
    // 延时时间
    NSDictionary* d =  [_images objectAtIndex:_index];
    float ti = [[d objectForKey:@"duration"] floatValue];
    ti = floorf(ti*100/100);
    
    if(timestamp >= ti)
    {
        _index ++;
        if(_index >= _images.count)
        {
//            NSLog(@"执行完一次了，停止");
//            [displayLink invalidate];
//            displayLink = nil;
            
            _index = 0; // 执行完一次了
        }
        
        NSDictionary* d =  [_images objectAtIndex:_index];
        UIImage* image = [d objectForKey:@"frame"];
        _layer.contents = (id)image.CGImage; // 更新图片
        //_index = (_index + 1) % _images.count;
    }*/
    
    // 定义一个变量记录执行次数
    static int a = 0;
    if (++a % _images.count == 0) // 延迟时间
    {
        a = 0;
        
        if(_index ==_images.count -1)
        {
            NSLog(@"播放玩一轮了");
        }
        
        NSDictionary* d =  [_images objectAtIndex:_index];
        UIImage* image = [d objectForKey:@"frame"];
        _layer.contents = (id)image.CGImage; // 更新图片
        _index = (_index + 1) % _images.count;
    }
}

- (void)repeatFinished:(NSNotification *)notification
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Tip" message:@"Repeat one finished , do you want to continue play GIF ?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
    
    [alertView show];
}

// 解码bpg
// 返回 nil || NSMutableArray（{frame:UIImage*对象,duration:float延时时间},...）
- (NSMutableArray*)bpgdecode:(NSData*)bpgData
{
    // 解码上下文
    _bpgcontext = bpg_decoder_open();
    
    // 检查能否解码
    if (bpg_decoder_decode(_bpgcontext, [bpgData bytes], (int)[bpgData length]) < 0)
    {
        NSLog(@"Could not decode image");
        return nil;
    }
    
    //获取图片信息
    //BPGImageInfo img_info_s, *img_info = &img_info_s;
    bpg_decoder_get_info(_bpgcontext, &_bpgInfo);
    
    const BPGDecoderOutputFormat fmt = BPG_OUTPUT_FORMAT_RGBA32;// _imageInfo.has_alpha ? BPG_OUTPUT_FORMAT_RGBA32 : BPG_OUTPUT_FORMAT_RGB24;

    _bpgLineSize = 4 * _bpgInfo.width; //(_imageInfo.has_alpha ? 4 : 3) // 一行的大小,以及总行数的大小
    
    // 开始解码
    if (bpg_decoder_start(_bpgcontext, fmt) != 0) {
        NSLog(@"error bpg_decoder_start");
        return nil;
    }
    
    // 获取帧数组
    NSMutableArray* frmelist = [[NSMutableArray alloc]init];
    
    // 如果没有动画信息,则不继续处理
    if (!_bpgInfo.has_animation) {
        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setObject:[self getBpgFrame] forKey:@"frame"];
        [d setObject:@(0) forKey:@"duration"];
        
        [frmelist addObject:d];
        
        return frmelist;
    }
    
    do {
        int num, den;
        bpg_decoder_get_frame_duration(_bpgcontext, &num, &den); //获取一帧的延时
        
        UIImage* img = [self getBpgFrame];
        NSTimeInterval du = (NSTimeInterval)num / den; // 延时
        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setObject:img forKey:@"frame"];
        [d setObject:@(du) forKey:@"duration"];
        
        [frmelist addObject:d];
        
    } while (bpg_decoder_start(_bpgcontext, fmt) == 0);
    
    bpg_decoder_close(_bpgcontext);
    
    return frmelist;
}

// 获取当前帧的图片
-(UIImage*)getBpgFrame
{
    NSMutableData *pixData = [[NSMutableData alloc] initWithCapacity:_bpgLineSize * _bpgInfo.height];
    unsigned char *pixbuf = [pixData mutableBytes];
    unsigned char *row = pixbuf;
    for (int y = 0; y < _bpgInfo.height; y++)
    {
        bpg_decoder_get_line(_bpgcontext, row);
        row += _bpgLineSize;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    #define kCGImageAlphaPremultipliedLast  (kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast)
#else
    #define kCGImageAlphaPremultipliedLast  kCGImageAlphaPremultipliedLast
#endif
    
    NSLog(@"kCGImageAlphaNone= %i", kCGImageAlphaNone);
    
    CGContextRef ctxRef = CGBitmapContextCreate(pixbuf,
                          _bpgInfo.width,
                          _bpgInfo.height,
                          8,
                          _bpgLineSize,
                          colorSpace,
                          (_bpgInfo.has_alpha ? kCGImageAlphaPremultipliedLast:kCGImageAlphaNoneSkipLast)
                          );
    
    if (!ctxRef)
    {
        NSLog(@"error creating UIImage");
        return nil;
    }
    
    CGFloat _imageScale = [UIScreen mainScreen].scale;
    CGImageRef imgRef = CGBitmapContextCreateImage(ctxRef);
    UIImage* rawImage = [UIImage imageWithCGImage:imgRef
                                            scale:_imageScale
                                      orientation:UIImageOrientationUp];
    
    CGContextRelease(ctxRef);
    
    return rawImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
