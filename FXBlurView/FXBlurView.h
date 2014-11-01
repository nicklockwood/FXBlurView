//
//  FXBlurView.h
//
//  Version 1.6.3
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


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#import <Availability.h>
#undef weak_ref
#if __has_feature(objc_arc) && __has_feature(objc_arc_weak)
#define weak_ref weak
#else
#define weak_ref unsafe_unretained
#endif


@interface UIImage (FXBlurView)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor;

@end


@interface FXBlurView : UIView

+ (void)setBlurEnabled:(BOOL)blurEnabled;
+ (void)setUpdatesEnabled;
+ (void)setUpdatesDisabled;

@property (nonatomic, getter = isBlurEnabled) BOOL blurEnabled;
@property (nonatomic, getter = isDynamic) BOOL dynamic;
@property (nonatomic, assign) NSUInteger iterations;
@property (nonatomic, assign) NSTimeInterval updateInterval;
@property (nonatomic, assign) CGFloat blurRadius;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, weak_ref) IBOutlet UIView *underlyingView;

- (void)updateAsynchronously:(BOOL)async completion:(void (^)())completion;

@end


#pragma GCC diagnostic pop

