//
//  ViewController.m
//  FXBlurViewExample
//
//  Created by Nick Lockwood on 25/08/2013.
//  Copyright (c) 2013 Charcoal Design. All rights reserved.
//

#import "ViewController.h"
@import QuartzCore;
@import FXBlurView;


@interface ViewController ()

@property (nonatomic, weak) IBOutlet FXBlurView *blurView;

@end


@implementation ViewController

- (IBAction)toggleBlur
{
    if (self.blurView.blurRadius < 5)
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.blurView.blurRadius = 40;
        }];
    }
    else
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.blurView.blurRadius = 0;
        }];
    }
}

@end
