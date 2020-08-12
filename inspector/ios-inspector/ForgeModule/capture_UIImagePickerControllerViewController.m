//
//  capture_UIImagePickerControllerViewController.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import "capture_UIImagePickerControllerViewController.h"
#import "capture_Delegate.h"

@interface capture_UIImagePickerControllerViewController ()

@end

@implementation capture_UIImagePickerControllerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [(capture_Delegate*)self.delegate didDisappear];
}

- (BOOL)shouldAutorotate {
    return YES;
}

-(UIViewController *)childViewControllerForStatusBarHidden {
    return nil;
}

-(BOOL)prefersStatusBarHidden {
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        return YES;
    } else {
        return NO;
    }
}

@end
