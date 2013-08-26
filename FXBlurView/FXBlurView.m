//
//  FXBlurView.m
//
//  Version 1.0
//
//  Created by Nick Lockwood on 25/08/2013.
//  Copyright (c) 2013 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/FXBlurView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//


#import "FXBlurView.h"
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>


@implementation UIImage (FXBlurView)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius
{
    //image must be nonzero size
    if (CGSizeEqualToSize(self.size, CGSizeZero)) return self;
    
    //boxsize must be an odd integer
    int boxSize = radius * self.scale;
    if (boxSize % 2 == 0) boxSize ++;
    
    //get image data
    CGImageRef imageRef = self.CGImage;
    CFDataRef inputData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    
    //create image buffers
    vImage_Buffer inputBuffer, outputBuffer;
    inputBuffer.width = outputBuffer.width = CGImageGetWidth(imageRef);
    inputBuffer.height = outputBuffer.height = CGImageGetHeight(imageRef);
    inputBuffer.rowBytes = outputBuffer.rowBytes = CGImageGetBytesPerRow(imageRef);

    //perform blur
    for (int i = 0; i < 3; i++)
    {
        CFMutableDataRef outputData = CFDataCreateMutable(NULL, inputBuffer.rowBytes * inputBuffer.height);
        outputBuffer.data = (void *)CFDataGetBytePtr(outputData);
        inputBuffer.data = (void *)CFDataGetBytePtr(inputData);
        vImageBoxConvolve_ARGB8888(&inputBuffer, &outputBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
        
        CFRelease(inputData);
        inputData = outputData;
    }

    //create image context
    CGContextRef ctx = CGBitmapContextCreate(outputBuffer.data,
                                             outputBuffer.width,
                                             outputBuffer.height,
                                             8,
                                             outputBuffer.rowBytes,
                                             CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));
    
    imageRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    CFRelease(inputData);

    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);

    return image;
}

@end


@interface FXBlurView ()

@property (nonatomic, assign) BOOL updating;
@property (nonatomic, assign) BOOL blurRadiusSet;
@property (nonatomic, assign) BOOL dynamicSet;

@end


@implementation FXBlurView

- (void)setUp
{
    if (!_blurRadiusSet) _blurRadius = 40.0f;
    if (!_dynamicSet) _dynamic = YES;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
        self.clipsToBounds = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

- (void)setBlurRadius:(CGFloat)blurRadius
{
    _blurRadiusSet = YES;
    _blurRadius = blurRadius;
}

- (void)setDynamic:(BOOL)dynamic
{
    _dynamicSet = YES;
    _dynamic = dynamic;
    if (_dynamic && self.superview)
    {
        [self updateAsynchronously];
    }
}

- (void)willMoveToSuperview:(UIView *)superview
{
    [super willMoveToSuperview:superview];
    if (superview)
    {
        UIImage *snapshot = [self snapshotOfSuperview:superview];
        UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius];
        self.layer.contents = (id)blurredImage.CGImage;
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    if (self.superview && self.dynamic)
    {
        [self updateAsynchronously];
    }
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

- (void)displayLayer:(CALayer *)layer
{
    if (self.superview)
    {
        BOOL wasHidden = self.hidden;
        self.hidden = YES;
        UIImage *snapshot = [self snapshotOfSuperview:self.superview];
        self.hidden = wasHidden;
        UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius];
        self.layer.contents = (id)blurredImage.CGImage;
    }
}

- (UIImage *)snapshotOfSuperview:(UIView *)superview
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -self.frame.origin.x, -self.frame.origin.y);
    [superview.layer renderInContext:context];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}

- (void)updateAsynchronously
{
    if (self.superview && !self.updating)
    {
        BOOL wasHidden = self.hidden;
        self.hidden = YES;
        UIImage *snapshot = [self snapshotOfSuperview:self.superview];
        self.hidden = wasHidden;
        
        self.updating = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius];
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                self.layer.contents = (id)blurredImage.CGImage;
                self.updating = NO;
                if (self.dynamic)
                {
                    [self performSelectorOnMainThread:@selector(updateAsynchronously)
                                           withObject:nil
                                        waitUntilDone:NO];
                }
            });
        });
    }
}

@end
