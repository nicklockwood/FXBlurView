//
//  ViewController.m
//  BasicGradientExample
//
//  Created by Luís Portela Afonso on 19/10/14.
//  Copyright (c) 2014 Baaam. All rights reserved.
//

#import "ViewController.h"

#import "FXBlurView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet FXBlurView *blurView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.blurView.gradientLocations = @[@(0.0f), @(1.0f)];
    self.blurView.gradientColors = @[
        (id)[[UIColor blueColor] colorWithAlphaComponent:0.4f].CGColor,
        (id)[[UIColor blueColor] colorWithAlphaComponent:0.2f].CGColor
    ];
}

#pragma mark - Action Methods

- (IBAction)toggleDynamic:(UISwitch *)sender {
    self.blurView.dynamic = sender.on;
}

- (IBAction)updateBlur:(UISlider *)sender {
    self.blurView.blurRadius = sender.value;
}

@end
