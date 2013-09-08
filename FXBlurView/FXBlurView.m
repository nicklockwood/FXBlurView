//
//  FXBlurView.m
//
//  Version 1.3.3
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
#import <objc/message.h>


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


@implementation UIImage (FXBlurView)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor
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
    
    //apply tint
    if (tintColor && ![tintColor isEqual:[UIColor clearColor]])
    {
        CGContextSetFillColorWithColor(ctx, [tintColor colorWithAlphaComponent:0.25].CGColor);
        CGContextSetBlendMode(ctx, kCGBlendModePlusLighter);
        CGContextFillRect(ctx, CGRectMake(0, 0, buffer1.width, buffer1.height));
    }
    
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
    
    int unsigned numberOfMethods;
    Method *methods = class_copyMethodList([UIView class], &numberOfMethods);
    for (int i = 0; i < numberOfMethods; i++)
    {
        if (method_getName(methods[i]) == @selector(tintColor))
        {
            _tintColor = super.tintColor;
        }
    }
    
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
    if (_dynamic != dynamic)
    {
        _dynamic = dynamic;
        if (dynamic)
        {
            [self updateAsynchronously];
        }
        else
        {
            [self setNeedsDisplay];
        }
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    [self setNeedsDisplay];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self.layer displayIfNeeded];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    [self updateAsynchronously];
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

- (void)displayLayer:(CALayer *)layer
{
    if (self.superview && !CGRectIsEmpty(self.bounds) && !CGRectIsEmpty(self.superview.bounds))
    {
        UIImage *snapshot = [self snapshotOfSuperview:self.superview];
        UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius
                                                      iterations:self.iterations
                                                       tintColor:self.tintColor];
        self.layer.contents = (id)blurredImage.CGImage;
        self.layer.contentsScale = blurredImage.scale;
    }
}

- (UIImage *)snapshotOfSuperview:(UIView *)superview
{
    CGFloat scale = 0.5;
    if (self.iterations > 0 && ([UIScreen mainScreen].scale > 1 || self.contentMode == UIViewContentModeScaleAspectFill))
    {
        CGFloat blockSize = 12.0f/self.iterations;
        scale = blockSize/MAX(blockSize * 2, floor(self.blurRadius));
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -self.frame.origin.x, -self.frame.origin.y);
    NSArray *hiddenViews = [self prepareSuperviewForSnapshot:superview];
    [superview.layer renderInContext:context];
    [self restoreSuperviewAfterSnapshot:hiddenViews];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}

- (NSArray *)prepareSuperviewForSnapshot:(UIView *)superview
{
    NSMutableArray *views = [NSMutableArray array];
    NSInteger index = [superview.subviews indexOfObject:self];
    if (index != NSNotFound)
    {
        for (int i = index; i < [superview.subviews count]; i++)
        {
            UIView *view = superview.subviews[i];
            if (!view.hidden)
            {
                view.hidden = YES;
                [views addObject:view];
            }
        }
    }
    return views;
}

- (void)restoreSuperviewAfterSnapshot:(NSArray *)hiddenViews
{
    for (UIView *view in hiddenViews)
    {
        view.hidden = NO;
    }
}

- (void)updateAsynchronously
{
    if (self.dynamic && !self.updating  && self.window && updatesEnabled > 0 &&
        !CGRectIsEmpty(self.bounds) && !CGRectIsEmpty(self.superview.bounds))
    {
        self.updating = YES;
        UIImage *snapshot = [self snapshotOfSuperview:self.superview];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            UIImage *blurredImage = [snapshot blurredImageWithRadius:self.blurRadius
                                                          iterations:self.iterations
                                                           tintColor:self.tintColor];
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                self.updating = NO;
                if (self.dynamic)
                {
                    self.layer.contents = (id)blurredImage.CGImage;
                    self.layer.contentsScale = blurredImage.scale;
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
                }
            });
        });
    }
}

@end
