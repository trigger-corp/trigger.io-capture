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


+ (void)check:(ForgeTask*)task permission:(NSString *)permission {
    JLPermissionsCore* jlpermission = [self resolvePermission:permission];
    if (jlpermission == NULL) {
        [task success:[NSNumber numberWithBool:NO]];
        return;
    }

    JLAuthorizationStatus status = [jlpermission authorizationStatus];
    [task success:[NSNumber numberWithBool:status == JLPermissionAuthorized]];
}


+ (void)request:(ForgeTask*)task permission:(NSString *)permission {
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
