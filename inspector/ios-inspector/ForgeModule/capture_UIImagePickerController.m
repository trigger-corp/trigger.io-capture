//
//  capture_UIImagePickerController.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import "capture_UIImagePickerController.h"
#import "capture_Delegate.h"

@interface capture_UIImagePickerController ()

@end

@implementation capture_UIImagePickerController

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

- (BOOL)shouldAutorotate {
    return YES;
}

-(BOOL)prefersStatusBarHidden {
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        return YES;
    } else {
        return NO;
    }
}

@end
