//
//  capture_API.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 21/08/2018.
//  Copyright (c) 2018 Trigger Corp. All rights reserved.
//

#import "capture_API.h"
#import "capture_Delegate.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <ForgeCore/UIActionSheet+UIAlertInView.h>

@implementation capture_API

NSString *io_trigger_capture_dialog_capture_camera_description = @"Not Used";
NSString *io_trigger_capture_dialog_capture_source_camera = @"Camera";
NSString *io_trigger_capture_dialog_capture_source_gallery = @"Gallery";
NSString *io_trigger_capture_dialog_capture_pick_source = @"Pick a source";
NSString *io_trigger_capture_dialog_cancel = @"Cancel";

+ (void)getImage:(ForgeTask*)task source:(NSString*)source {
    capture_Delegate *delegate = [[capture_Delegate alloc] initWithTask:task andParams:task.params andType:(NSString *)kUTTypeImage];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && ![source isEqualToString:@"camera"] && ![source isEqualToString:@"gallery"]) {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:io_trigger_capture_dialog_capture_pick_source
                                                          delegate:delegate
                                                 cancelButtonTitle:io_trigger_capture_dialog_cancel
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:io_trigger_capture_dialog_capture_source_camera, io_trigger_capture_dialog_capture_source_gallery, nil];
        menu.delegate = delegate;
        if ([menu respondsToSelector:@selector(alertInView:)]) {
            [menu alertInView:[[ForgeApp sharedApp] viewController].view];
        } else {
            [menu showInView:[[ForgeApp sharedApp] viewController].view];
        }
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
               && [source isEqualToString:@"camera"]) {
        [delegate actionSheet:nil didDismissWithButtonIndex:0];
    } else {
        [delegate actionSheet:nil didDismissWithButtonIndex:1];
    }
}

+ (void)getVideo:(ForgeTask*)task source:(NSString*)source {
    capture_Delegate *delegate = [[capture_Delegate alloc] initWithTask:task andParams:task.params andType:(NSString *)kUTTypeMovie];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && ![source isEqualToString:@"camera"] && ![source isEqualToString:@"gallery"]) {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:io_trigger_capture_dialog_capture_pick_source
                                                          delegate:delegate
                                                 cancelButtonTitle:io_trigger_capture_dialog_cancel
                                            destructiveButtonTitle:nil otherButtonTitles:io_trigger_capture_dialog_capture_source_camera, io_trigger_capture_dialog_capture_source_gallery, nil];
        menu.delegate = delegate;
        if ([menu respondsToSelector:@selector(alertInView:)]) {
            [menu alertInView:[[ForgeApp sharedApp] viewController].view];
        } else {
            [menu showInView:[[ForgeApp sharedApp] viewController].view];
        }
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
               && [source isEqualToString:@"camera"]) {
        [delegate actionSheet:nil didDismissWithButtonIndex:0];
    } else {
        [delegate actionSheet:nil didDismissWithButtonIndex:1];
    }
}


@end
