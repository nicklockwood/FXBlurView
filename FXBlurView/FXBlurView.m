//
//  FXBlurView.m
//
//  Version 1.2
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

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations
{
    //image must be nonzero size
    if (floorf(self.size.width) * floorf(self.size.height) <= 0.0f) return self;
    
    //boxsize must be an odd integer
    int boxSize = radius * self.scale;
    if (boxSize % 2 == 0) boxSize ++;
    
    //create image buffers
    CGImageRef imageRef = self.CGImage;
    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    CFIndex bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);
    
    //create temp buffer
    void *tempBuffer = malloc(vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                         NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
    
    //copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);
    
    for (int i = 0; i < iterations; i++)
    {
        //perform blur
        vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
        
        //swap buffers
        void *temp = buffer1.data;
        buffer1.data = buffer2.data;
        buffer2.data = temp;
    }
    
    //free buffers
    free(buffer2.data);
    free(tempBuffer);
    
    //create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                             8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));
    
    //create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);
    return image;
}

@end


NSString *const FXBlurViewUpdatesEnabledNotification = @"FXBlurViewUpdatesEnabledNotification";


@interface FXBlurView ()

@property (nonatomic, assign) BOOL updating;
@property (nonatomic, assign) BOOL iterationsSet;
@property (nonatomic, assign) BOOL blurRadiusSet;
@property (nonatomic, assign) BOOL dynamicSet;

@end


@implementation FXBlurView

static NSInteger updatesEnabled = 1;

+ (void)setUpdatesEnabled
{
    updatesEnabled ++;
    if (updatesEnabled > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FXBlurViewUpdatesEnabledNotification object:nil];
    }
}

+ (void)setUpdatesDisabled
{
    updatesEnabled --;
}

- (void)setUp
{
    if (!_iterationsSet) _iterations = 3;
    if (!_blurRadiusSet) _blurRadius = 40.0f;
    if (!_dynamicSet) _dynamic = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAsynchronously)
                                                 name:FXBlurViewUpdatesEnabledNotification
                                               object:nil];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setIterations:(NSUInteger)iterations
{
    _iterationsSet = YES;
    _iterations = iterations;
    [self setNeedsDisplay];
}

- (void)setBlurRadius:(CGFloat)blurRadius
{
    _blurRadiusSet = YES;
    _blurRadius = blurRadius;
    [self setNeedsDisplay];
}

- (void)setDynamic:(BOOL)dynamic
{
    _dynamicSet = YES;
    _dynamic = dynamic;
    [self updateAsynchronously];
}

- (void)willMoveToSuperview:(UIView *)superview
{
    [super willMoveToSuperview:superview];
    if (superview)
    {
        UIImage *snapshot = [self snapshotOfSuperview:superview];
        UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius iterations:self.iterations];
        self.layer.contents = (id)blurredImage.CGImage;
    }
}

- (void)didMoveToWindow
{
    [super didMoveToSuperview];
    [self updateAsynchronously];
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
        UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius iterations:self.iterations];
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
    if (self.dynamic && !self.updating  && self.window && updatesEnabled > 0)
    {
        BOOL wasHidden = self.hidden;
        self.hidden = YES;
        UIImage *snapshot = [self snapshotOfSuperview:self.superview];
        self.hidden = wasHidden;
        
        self.updating = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius iterations:self.iterations];
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                self.layer.contents = (id)blurredImage.CGImage;
                self.updating = NO;
                if (self.updateInterval)
                {
                    [self performSelector:@selector(updateAsynchronously) withObject:nil
                               afterDelay:self.updateInterval inModes:@[NSDefaultRunLoopMode, UITrackingRunLoopMode]];
                }
                else
                {
                    [self performSelectorOnMainThread:@selector(updateAsynchronously) withObject:nil
                                    waitUntilDone:NO modes:@[NSDefaultRunLoopMode, UITrackingRunLoopMode]];
                }
            });
        });
    }
}

@end
