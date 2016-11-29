//
//  ViewController.m
//  BGPDemo
//
//  Created by hpking　 on 2016/11/29.
//  Copyright © 2016年 hpking　. All rights reserved.
//

#import "ViewController.h"
#import "COImage+BPG.h"

//#import "libbpg.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@interface ViewController ()

@end

@implementation ViewController

//http://bellard.org/bpg/animation.html

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //animation.bpg        cinemagraph.bpg
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cinemagraph.bpg" ofType:@""];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    UIImage *image = [UIImage imageWithBPGData:data];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 100, image.size.width, image.size.height)];
    CGRect frame = CGRectMake(0, 10, SCREEN_WIDTH, SCREEN_HEIGHT);
    imgView.center = CGPointMake(frame.size.width/2, 200); // 设置中心点
    imgView.contentMode = UIViewContentModeScaleAspectFit;//自适应
    imgView.image = image;
    imgView.animationRepeatCount = 1;
    
    [self.view addSubview:imgView];
}

// 另外一种显示方式
- (void)bpgViewInit
{
    /*NSString *bpgPath = [[NSBundle mainBundle] pathForResource:@"test.bpg" ofType:@""];
    NSData *bpgData = [NSData dataWithContentsOfFile:bpgPath];
    
    // 开始编码
    BPGDecoderContext *img = bpg_decoder_open();
    
    if (bpg_decoder_decode(img, [bpgData bytes], [bpgData length]) < 0)
    {
        NSLog(@"Could not decode image");
        return;
    }
    
    BPGImageInfo img_info_s, *img_info = &img_info_s;
    bpg_decoder_get_info(img, img_info);
    
    bpg_decoder_start(img, BPG_OUTPUT_FORMAT_RGBA32);
    
    unsigned int rowWidth = img_info->width * 4;
    NSMutableData *pixData = [[NSMutableData alloc] initWithCapacity:rowWidth * img_info->height];
    
    unsigned char *pixbuf = [pixData mutableBytes];
    unsigned char *row = pixbuf;
    for (int y = 0; y < img_info->height; y++)
    {
        bpg_decoder_get_line(img, row);
        row += rowWidth;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixbuf, img_info->width, img_info->height, 8, rowWidth, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipLast);
    
    if (!ctx)
    {
        NSLog(@"error creating UIImage");
        return;
    }
    
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage* rawImage = [UIImage imageWithCGImage:imageRef];
    
    CGContextRelease(ctx);
    
    bpg_decoder_close(img);
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:rawImage];
    
    [self.view addSubview:imageView];*/
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
