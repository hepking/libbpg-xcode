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
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"animation.bpg" ofType:@""];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    UIImage *image = [UIImage imageWithBPGData:data];
    
    // 问题：不能控制循环次数
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 100, image.size.width, image.size.height)];
    CGRect frame = CGRectMake(0, 10, SCREEN_WIDTH, SCREEN_HEIGHT);
    imgView.center = CGPointMake(frame.size.width/2, 200); // 设置中心点
    imgView.contentMode = UIViewContentModeScaleAspectFit;//自适应
    imgView.image = image;
    
    [self.view addSubview:imgView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
