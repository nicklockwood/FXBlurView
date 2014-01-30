//
//  FXBlurView.m
//
//  Version 1.5.3
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
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>


#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wgnu"


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
    uint32_t boxSize = (uint32_t)(radius * self.scale);
    if (boxSize % 2 == 0) boxSize ++;
    
    //create image buffers
    CGImageRef imageRef = self.CGImage;
    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    size_t bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);
    
    //create temp buffer
    void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                                 NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
    
    //copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);
    
    for (NSUInteger i = 0; i < iterations; i++)
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
    if (tintColor && CGColorGetAlpha(tintColor.CGColor) > 0.0f)
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


@interface FXBlurScheduler : NSObject

@property (nonatomic, strong) NSMutableArray *views;
@property (nonatomic, assign) NSUInteger viewIndex;
@property (nonatomic, assign) NSUInteger updatesEnabled;
@property (nonatomic, assign) BOOL blurEnabled;
@property (nonatomic, assign) BOOL updating;

@end


@interface FXBlurView ()

@property (nonatomic, assign) BOOL iterationsSet;
@property (nonatomic, assign) BOOL blurRadiusSet;
@property (nonatomic, assign) BOOL dynamicSet;
@property (nonatomic, assign) BOOL blurEnabledSet;
@property (nonatomic, strong) NSDate *lastUpdate;

- (UIImage *)snapshotOfUnderlyingView;
- (BOOL)shouldUpdate;

@end


@implementation FXBlurScheduler

+ (instancetype)sharedInstance
{
    static FXBlurScheduler *sharedInstance = nil;
    if (!sharedInstance)
    {
        sharedInstance = [[FXBlurScheduler alloc] init];
    }
    return sharedInstance;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        _updatesEnabled = 1;
        _blurEnabled = YES;
        _views = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setBlurEnabled:(BOOL)blurEnabled
{
    _blurEnabled = blurEnabled;
    if (blurEnabled)
    {
        for (FXBlurView *view in self.views)
        {
            [view setNeedsDisplay];
        }
        [self updateAsynchronously];
    }
}

- (void)setUpdatesEnabled
{
    _updatesEnabled ++;
    [self updateAsynchronously];
}

- (void)setUpdatesDisabled
{
    _updatesEnabled --;
}

- (void)addView:(FXBlurView *)view
{
    if (![self.views containsObject:view])
    {
        [self.views addObject:view];
        [self updateAsynchronously];
    }
}

- (void)removeView:(FXBlurView *)view
{
    NSUInteger index = [self.views indexOfObject:view];
    if (index != NSNotFound)
    {
        if (index <= self.viewIndex)
        {
            self.viewIndex --;
        }
        [self.views removeObjectAtIndex:index];
    }
}

- (void)updateAsynchronously
{
    if (self.blurEnabled && !self.updating && self.updatesEnabled > 0 && [self.views count])
    {
        NSTimeInterval timeUntilNextUpdate = 1.0 / 60;
        
        //loop through until we find a view that's ready to be drawn
        self.viewIndex = self.viewIndex % [self.views count];
        for (NSUInteger i = self.viewIndex; i < [self.views count]; i++)
        {
            FXBlurView *view = self.views[i];
            if (view.dynamic && !view.hidden && view.window && [view shouldUpdate])
            {
                NSTimeInterval nextUpdate = [view.lastUpdate timeIntervalSinceNow] + view.updateInterval;
                if (!view.lastUpdate || nextUpdate <= 0)
                {
                    self.updating = YES;
                    [view updateAsynchronously:YES completion:^{
                        
                        //render next view
                        self.updating = NO;
                        self.viewIndex = i + 1;
                        [self updateAsynchronously];
                    }];
                    return;
                }
                else
                {
                    timeUntilNextUpdate = MIN(timeUntilNextUpdate, nextUpdate);
                }
            }
        }

        //try again, delaying until the time when the next view needs an update.
        self.viewIndex = 0;
        [self performSelector:@selector(updateAsynchronously)
                   withObject:nil
                   afterDelay:timeUntilNextUpdate
                      inModes:@[NSDefaultRunLoopMode, UITrackingRunLoopMode]];
    }
}

@end


@implementation FXBlurView

+ (void)setBlurEnabled:(BOOL)blurEnabled
{
    [FXBlurScheduler sharedInstance].blurEnabled = blurEnabled;
}

+ (void)setUpdatesEnabled
{
    [[FXBlurScheduler sharedInstance] setUpdatesEnabled];
}

+ (void)setUpdatesDisabled
{
    [[FXBlurScheduler sharedInstance] setUpdatesDisabled];
}

- (void)setUp
{
    if (!_iterationsSet) _iterations = 3;
    if (!_blurRadiusSet) _blurRadius = 40.0f;
    if (!_dynamicSet) _dynamic = YES;
    if (!_blurEnabledSet) _blurEnabled = YES;
    self.updateInterval = _updateInterval;
    self.layer.magnificationFilter = @"linear"; // kCAFilterLinear
    
    unsigned int numberOfMethods;
    Method *methods = class_copyMethodList([UIView class], &numberOfMethods);
    for (unsigned int i = 0; i < numberOfMethods; i++)
    {
        Method method = methods[i];
        SEL selector = method_getName(method);
        if (selector == @selector(tintColor))
        {
            _tintColor = ((id (*)(id,SEL))method_getImplementation(method))(self, selector);
            break;
        }
    }
    free(methods);
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

- (void)setBlurEnabled:(BOOL)blurEnabled
{
    _blurEnabledSet = YES;
    if (_blurEnabled != blurEnabled)
    {
        _blurEnabled = blurEnabled;
        [self schedule];
        if (_blurEnabled)
        {
            [self setNeedsDisplay];
        }
    }
}

- (void)setDynamic:(BOOL)dynamic
{
    _dynamicSet = YES;
    if (_dynamic != dynamic)
    {
        _dynamic = dynamic;
        [self schedule];
        if (!dynamic)
        {
            [self setNeedsDisplay];
        }
    }
}

- (UIView *)underlyingView
{
    return _underlyingView ?: self.superview;
}

- (void)setUpdateInterval:(NSTimeInterval)updateInterval
{
    _updateInterval = updateInterval;
    if (_updateInterval <= 0) _updateInterval = 1.0/60;
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    [self setNeedsDisplay];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self.layer setNeedsDisplay];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    [self schedule];
}

- (void)schedule
{
    if (self.window && self.dynamic && self.blurEnabled)
    {
        [[FXBlurScheduler sharedInstance] addView:self];
    }
    else
    {
        [[FXBlurScheduler sharedInstance] removeView:self];
    }
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

- (BOOL)shouldUpdate
{
    __strong UIView *underlyingView = [self underlyingView];
    
    return
    underlyingView && !underlyingView.hidden &&
    self.blurEnabled && [FXBlurScheduler sharedInstance].blurEnabled &&
    !CGRectIsEmpty(self.bounds) && !CGRectIsEmpty(underlyingView.bounds);
}

- (void)displayLayer:(__unused CALayer *)layer
{
    [self updateAsynchronously:NO completion:NULL];
}

- (UIImage *)snapshotOfUnderlyingView
{
    self.lastUpdate = [NSDate date];
    CGFloat scale = 0.5;
    if (self.iterations)
    {
        CGFloat blockSize = 12.0f/self.iterations;
        scale = blockSize/MAX(blockSize * 2, self.blurRadius);
        scale = 1.0f/floorf(1.0f/scale);
    }
    CGSize size = self.bounds.size;
    if (self.contentMode == UIViewContentModeScaleToFill ||
        self.contentMode == UIViewContentModeScaleAspectFill ||
        self.contentMode == UIViewContentModeScaleAspectFit ||
        self.contentMode == UIViewContentModeRedraw)
    {
        //prevents edge artefacts
        size.width = floorf(size.width * scale) / scale;
        size.height = floorf(size.height * scale) / scale;
    }
    else if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0f && [UIScreen mainScreen].scale == 1.0f)
    {
        //prevents pixelation on old devices
        scale = 1.0f;
    }
    UIGraphicsBeginImageContextWithOptions(size, YES, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    __strong UIView *underlyingView = self.underlyingView;
    CGRect locationInUnderlyingView = [self convertRect:self.bounds toView:underlyingView];
    CGContextTranslateCTM(context, -locationInUnderlyingView.origin.x, -locationInUnderlyingView.origin.y);

    NSArray *hiddenViews = [self prepareUnderlyingViewForSnapshot];
    [underlyingView.layer renderInContext:context];
    [self restoreSuperviewAfterSnapshot:hiddenViews];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}

- (NSArray *)prepareUnderlyingViewForSnapshot
{
    __strong UIView *underlyingView = self.underlyingView;
    UIView *blurView = self;
    while (blurView.superview && blurView.superview != underlyingView)
    {
        blurView = blurView.superview;
    }
    NSMutableArray *views = [NSMutableArray array];
    NSUInteger index = [underlyingView.subviews indexOfObject:blurView];
    if (index != NSNotFound)
    {
        for (NSUInteger i = index; i < [underlyingView.subviews count]; i++)
        {
            UIView *view = underlyingView.subviews[i];
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

- (UIImage *)blurredSnapshot:(UIImage *)snapshot
{
    return [snapshot blurredImageWithRadius:self.blurRadius
                                 iterations:self.iterations
                                  tintColor:self.tintColor];
}

- (void)setLayerContents:(UIImage *)image
{
    self.layer.contents = (id)image.CGImage;
    self.layer.contentsScale = image.scale;
}

- (void)updateAsynchronously:(BOOL)async completion:(void (^)())completion
{
    if ([self shouldUpdate])
    {
        UIImage *snapshot = [self snapshotOfUnderlyingView];
        if (async)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                
                UIImage *blurredImage = [self blurredSnapshot:snapshot];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    [self setLayerContents:blurredImage];
                    if (completion) completion();
                });
            });
        }
        else
        {
            [self setLayerContents:[self blurredSnapshot:snapshot]];
            if (completion) completion();
        }
    }
    else if (completion)
    {
        completion();
    }
}

@end
