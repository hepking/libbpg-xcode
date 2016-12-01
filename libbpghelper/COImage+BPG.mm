//
//  Created by hpking　 on 2016/11/29.
//  Copyright © 2016年 hpking　. All rights reserved.
//

#include <CoreGraphics/CGImage.h>

#import "COImage+BPG.h"

#import <vector>
#import <memory>

extern "C" {
#import "libbpg.h"
}

namespace CG{

    class ColorSpace{
        
    public:
        static ColorSpace CreateDeviceRGB(){
        
            CGColorSpaceRef ref = CGColorSpaceCreateDeviceRGB();
            ColorSpace space = ColorSpace(ref);
            CGColorSpaceRelease(ref);
            return space;
        }
        
        ColorSpace(CGColorSpaceRef ref) : _ref(ref){ CGColorSpaceRetain(ref); }
        
        ~ColorSpace(){
            if (this->_ref) {
                CGColorSpaceRelease(this->_ref);
                this->_ref = nullptr;
            }
        }
        
        operator CGColorSpaceRef() const {return this->_ref;}
        
    private:
        CGColorSpaceRef _ref;
    };
    
    class DataProvider{
        
    public:
        DataProvider(void *info, const void *data, size_t size, CGDataProviderReleaseDataCallback releaseData): _ref(CGDataProviderCreateWithData(info, data, size, releaseData)){
            
        }
        
        ~DataProvider(){
            if (this->_ref) {
                CGDataProviderRelease(this->_ref);
                this->_ref = nullptr;
            }

        }
        
        operator CGDataProviderRef() const {return this->_ref;}
        
    private:
        CGDataProviderRef _ref;
    };
    
    class Image{
        
    public:
        Image(size_t width, size_t height,
              size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,
              const ColorSpace &space, CGBitmapInfo bitmapInfo,
              const DataProvider &provider,
              const CGFloat *decode, bool shouldInterpolate,
              CGColorRenderingIntent intent)
        : _ref(CGImageCreate(width, height,
                             bitsPerComponent, bitsPerPixel, bytesPerRow,
                             space, bitmapInfo,
                             provider,
                             decode, shouldInterpolate,
                             intent)) {
        }
        
        ~Image(){
            
            if (this->_ref) {
                CGImageRelease(this->_ref);
                this->_ref = nullptr;
            }
        }
        
        operator CGImageRef() const {return this->_ref;}
        
    private:
        CGImageRef _ref;
    };
}


/**
 * 解码器类
 */
class Decoder{
    
public:
    Decoder(const uint8_t *buffer, int length)
    : _colorSpace(CG::ColorSpace::CreateDeviceRGB()),  _context(bpg_decoder_open())
#if TARGET_OS_IPHONE
    , _imageScale([UIScreen mainScreen].scale)
#endif
    {
        if (!this->_context) {
            throw "bpg_decoder_open";
        }
        
        if (bpg_decoder_decode(this->_context, buffer, length) != 0) {
            bpg_decoder_close(this->_context);
            throw "bpg_decoder_decode";
        }
        
        if (bpg_decoder_get_info(this->_context, &this->_imageInfo) != 0) {
            bpg_decoder_close(this->_context);
            throw "bpg_decoder_get_info";
        }
        
        this->_imageLineSize = (this->_imageInfo.has_alpha ? 4 : 3) * this->_imageInfo.width;
        this->_imageTotalSize = this->_imageLineSize * this->_imageInfo.height;
    }
    
    ~Decoder()
    {
        if (this->_context) {
            bpg_decoder_close(this->_context);
            this->_context = nullptr;
        }
    }
    
    COImage *decode() const
    {
        const BPGDecoderOutputFormat fmt = this->_imageInfo.has_alpha ?
        BPG_OUTPUT_FORMAT_RGBA32 : BPG_OUTPUT_FORMAT_RGB24;
        
        if (bpg_decoder_start(this->_context, fmt) != 0) {
            throw "bpg_decoder_start";
        }
        
        if (!this->_imageInfo.has_animation) {
            return this->cgImageToCOImage(*this->getCurrentFrameCGImage());
        }
        
        struct FrameInfo {
            std::shared_ptr<CG::Image> image;
            NSTimeInterval duration;
        };
        
        // 获取每一帧图片
        std::vector<FrameInfo> infos;
        
        do {
            int num, den;
            bpg_decoder_get_frame_duration(this->_context, &num, &den); //获取一帧的延时
            infos.push_back({
                this->getCurrentFrameCGImage(),
                (NSTimeInterval)num / den
            });
        } while (bpg_decoder_start(this->_context, fmt) == 0);
        
#if TARGET_OS_IPHONE
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:infos.size()];
        NSTimeInterval totalDuration = 0;
        for (auto info : infos)
        {
            totalDuration += info.duration;
            [images addObject:this->cgImageToCOImage(*info.image)];
        }
        
//        NSLog(@"动画持续时间 %f", totalDuration);
        
        return [UIImage animatedImageWithImages:images duration:totalDuration];
        
#else
        NSMutableData *data = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data,
                                                                             kUTTypeGIF,
                                                                             infos.size(),
                                                                             nullptr);
        NSDictionary *destProperties = @{
                                         (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
                                                 (__bridge NSString *)kCGImagePropertyGIFLoopCount : @(this->_imageInfo.loop_count),
                                                 }
                                         };
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)destProperties);
        for (auto info : infos) {
            NSDictionary *properties = @{
                                         (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
                                                 (__bridge NSString *)kCGImagePropertyGIFDelayTime : @(info.duration),
                                                 }
                                         };ti
            CGImageDestinationAddImage(destination, *info.image, (__bridge CFDictionaryRef)properties);
        }
        CGImageDestinationFinalize(destination);
        CFRelease(destination);
        return [[NSImage alloc] initWithData:data];
#endif
    }
    
private:
    CG::ColorSpace _colorSpace;
    BPGDecoderContext *_context;
    BPGImageInfo _imageInfo;
    size_t _imageLineSize;
    size_t _imageTotalSize;
    
#if TARGET_OS_IPHONE
    CGFloat _imageScale;
#endif
    
    static void releaseImageData(void *info, const void *data, size_t size)
    {
        delete[] (uint8_t *)data;
    }
    
    // 获取当前帧的内容
    uint8_t *getCurrentFrameBuffer() const
    {
        uint8_t *buffer = new uint8_t[this->_imageTotalSize];
        for (int y = 0; y < this->_imageInfo.height; ++y)
        {
            if (bpg_decoder_get_line(this->_context, buffer + (y * this->_imageLineSize)) == 0) {
                continue;
            }
            delete[] buffer;
            throw "bpg_decoder_get_line";
        }
        return buffer;
    }
    
    // 获取当前帧的图片
    std::shared_ptr<CG::Image> getCurrentFrameCGImage() const
    {
        CG::DataProvider provider = CG::DataProvider(nullptr,
                                                     this->getCurrentFrameBuffer(),
                                                     this->_imageTotalSize,
                                                     this->releaseImageData);
        
        return std::make_shared<CG::Image>(this->_imageInfo.width,
                                           this->_imageInfo.height,
                                           8,
                                           (this->_imageInfo.has_alpha ? 4 : 3) * 8,
                                           this->_imageLineSize,
                                           this->_colorSpace,
                                           (CGBitmapInfo)((this->_imageInfo.has_alpha ? kCGImageAlphaLast : kCGImageAlphaNone) | kCGBitmapByteOrder32Big),
                                           provider,
                                           nullptr,
                                           false,
                                           kCGRenderingIntentDefault);
    }
    
    // cgImage 转 UIImage
    COImage *cgImageToCOImage(const CG::Image &image) const
    {
#if TARGET_OS_IPHONE
        return [UIImage imageWithCGImage:image
                                   scale:this->_imageScale
                             orientation:UIImageOrientationUp];
#else
        return [[NSImage alloc] initWithCGImage:image
                                           size:NSMakeSize(this->_imageInfo.width, this->_imageInfo.height)];
#endif
    }
};


@implementation COImage (BPG)

+ (COImage *)imageWithBPGData:(NSData *)data
{
    NSParameterAssert(data);
    
    try {
        Decoder decoder((uint8_t *)data.bytes, (int)data.length);
        return decoder.decode();
    } catch (...) {
        return nil;
    }
}

@end
