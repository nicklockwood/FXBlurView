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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.blurView.dynamic = NO;
}

- (IBAction)updateBlur:(UISlider *)slider
{
    self.blurView.blurRadius = slider.value;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.blurView setNeedsDisplay];
}

@end
