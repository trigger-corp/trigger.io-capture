//
//  capture_API.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 21/08/2018.
//  Copyright (c) 2018 Trigger Corp. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import <ForgeCore/UIActionSheet+UIAlertInView.h>

#import "JLCameraPermission.h"
#import "JLMicrophonePermission.h"

#import "capture_API.h"
#import "capture_Delegate.h"


@implementation capture_API

NSString *io_trigger_capture_dialog_capture_camera_description = @"Not Used";
NSString *io_trigger_capture_dialog_capture_source_camera = @"Camera";
NSString *io_trigger_capture_dialog_capture_source_gallery = @"Gallery";
NSString *io_trigger_capture_dialog_capture_pick_source = @"Pick a source";
NSString *io_trigger_capture_dialog_cancel = @"Cancel";


+ (void)getImage:(ForgeTask*)task source:(NSString*)source {
    capture_Delegate *delegate = [[capture_Delegate alloc] initWithTask:task
                                                              andParams:task.params
                                                                andType:(NSString *)kUTTypeImage];
    [capture_API _dispatch_delegate:delegate source:source];
}


+ (void)getVideo:(ForgeTask*)task source:(NSString*)source {
    capture_Delegate *delegate = [[capture_Delegate alloc] initWithTask:task
                                                              andParams:task.params
                                                                andType:(NSString *)kUTTypeMovie];
    [capture_API _dispatch_delegate:delegate source:source];
}


+ (void)_dispatch_delegate:(capture_Delegate*)delegate source:(NSString*)source {
    if ([source isEqualToString:@"camera"]) {
        [delegate openPicker:UIImagePickerControllerSourceTypeCamera];
        
    } else if ([source isEqualToString:@"gallery"]) {
        [delegate openPicker:UIImagePickerControllerSourceTypePhotoLibrary];
        
    } else {
        UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:io_trigger_capture_dialog_capture_pick_source
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:[UIAlertAction actionWithTitle:io_trigger_capture_dialog_cancel
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction *action) {
            [alertController dismissViewControllerAnimated:YES completion:^{
                delegate.didReturn = YES;
                [delegate->_task error:@"Image selection cancelled" type:@"EXPECTED_FAILURE" subtype:nil];
            }];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:io_trigger_capture_dialog_capture_source_camera
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            [alertController dismissViewControllerAnimated:YES completion:^{
                [delegate openPicker:UIImagePickerControllerSourceTypeCamera];
            }];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:io_trigger_capture_dialog_capture_source_gallery
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            [alertController dismissViewControllerAnimated:YES completion:^{
                [delegate openPicker:UIImagePickerControllerSourceTypePhotoLibrary];
            }];
        }]];
        [ForgeApp.sharedApp.viewController presentViewController:alertController animated:YES completion:nil];
    }
}


+ (void)permissions_check:(ForgeTask*)task permission:(NSString *)permission {
    JLPermissionsCore* jlpermission = [self resolvePermission:permission];
    if (jlpermission == NULL) {
        [task success:[NSNumber numberWithBool:NO]];
        return;
    }

    JLAuthorizationStatus status = [jlpermission authorizationStatus];
    [task success:[NSNumber numberWithBool:status == JLPermissionAuthorized]];
}


+ (void)permissions_request:(ForgeTask*)task permission:(NSString *)permission {
    JLPermissionsCore* jlpermission = [self resolvePermission:permission];
    if (jlpermission == NULL) {
        [task success:[NSNumber numberWithBool:NO]];
        return;
    }

    if ([jlpermission authorizationStatus] == JLPermissionAuthorized) {
        [task success:[NSNumber numberWithBool:YES]];
        return;
    }

    NSDictionary* params = task.params;
    NSString* rationale = [params objectForKey:@"rationale"];
    if (rationale != nil) {
        [jlpermission setRationale:rationale];
    }

    [jlpermission authorize:^(BOOL granted, NSError * _Nullable error) {
        [jlpermission setRationale:nil]; // reset rationale
        if (error) {
            [ForgeLog d:[NSString stringWithFormat:@"permissions.check '%@' failed with error: %@", permission, error]];
        }
        [task success:[NSNumber numberWithBool:granted]];
    }];
}


+ (JLPermissionsCore*)resolvePermission:(NSString*)permission {
    JLPermissionsCore* ret = NULL;
    if ([permission isEqualToString:@""]) {
        [ForgeLog d:[NSString stringWithFormat:@"Permission not supported on iOS:%@", permission]];

    } else if ([permission isEqualToString:@"ios.permission.camera"]) {
        ret = [JLCameraPermission sharedInstance];
    } else if ([permission isEqualToString:@"ios.permission.microphone"]) {
        ret = [JLMicrophonePermission sharedInstance];

    } else {
        [ForgeLog w:[NSString stringWithFormat:@"Requested unknown permission:%@", permission]];
    }

    return ret;
}

@end
