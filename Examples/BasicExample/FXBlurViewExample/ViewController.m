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

- (IBAction)toggleDynamic:(UISwitch *)sender
{
    self.blurView.dynamic = sender.on;
}

- (IBAction)updateBlur:(UISlider *)sender
{
    self.blurView.blurRadius = sender.value;
}

@end
