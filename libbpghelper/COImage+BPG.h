//
//  Created by hpking　 on 2016/11/29.
//  Copyright © 2016年 hpking　. All rights reserved.
//

// 代码来自于 https://github.com/chuganzy/HCImage-BPG.git

#import <Foundation/Foundation.h>

#if !__has_feature(nullability)
    #define __nullable
    #define __nonnull
    #define NS_ASSUME_NONNULL_BEGIN
    #define NS_ASSUME_NONNULL_END
#endif

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
    #define COImage UIImage
#else
    #import <Cocoa/Cocoa.h>
    #define COImage NSImage
#endif

//! Project version number for libbpghelper.
FOUNDATION_EXPORT double libbpghelperVersionNumber;

//! Project version string for libbpghelper.
FOUNDATION_EXPORT const unsigned char libbpghelperVersionString[];

NS_ASSUME_NONNULL_BEGIN

@interface COImage (BPG)

+ (COImage * __nullable)imageWithBPGData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
