//
//  ViewController.m
//  ModalExample
//
//  Created by Nick Lockwood on 30/08/2013.
//  Copyright (c) 2013 Charcoal Design. All rights reserved.
//

#import "ViewController.h"
#import "FXBlurView.h"


@interface ViewController ()

@property (nonatomic, weak) IBOutlet FXBlurView *blurView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure blur view
    self.blurView.dynamic = NO;
    self.blurView.tintColor = [UIColor colorWithRed:0 green:0.5 blue:0.5 alpha:1];
    self.blurView.contentMode = UIViewContentModeBottom;
    
    //take snapshot, then move off screen once complete
    [self.blurView updateAsynchronously:YES completion:^{
        self.blurView.frame = CGRectMake(0, 568, 320, 0);
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (IBAction)toggleModal
{
    [UIView animateWithDuration:0.5 animations:^{
        BOOL open = self.blurView.frame.size.height > 200;
        self.blurView.frame = CGRectMake(0, open? 568: 143, 320, open? 0: 425);
    }];
}

@end
