//
//  ViewController.m
//  FXBlurViewExample
//
//  Created by Nick Lockwood on 25/08/2013.
//  Copyright (c) 2013 Charcoal Design. All rights reserved.
//

#import "ViewController.h"
#import "FXBlurView.h"
#import <QuartzCore/QuartzCore.h>


@interface ViewController ()

@property (nonatomic, weak) IBOutlet FXBlurView *blurView;

@end


@implementation ViewController

- (IBAction)updateBlur:(UISlider *)sender
{
    self.blurView.blurRadius = sender.value;
}

- (IBAction)animate:(__unused UIButton *)sender
{
    [UIView animateWithDuration:1 animations:^{
        
        if (self.blurView.frame.origin.x < 50)
        {
            self.blurView.frame = CGRectMake(100, 200, 200, 200);
        }
        else
        {
            self.blurView.frame = CGRectMake(10, 10, 100, 100);
        }
    }];
}

@end
