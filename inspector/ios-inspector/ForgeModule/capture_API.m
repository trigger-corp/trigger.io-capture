//
//  capture_API.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 21/08/2018.
//  Copyright (c) 2018 Trigger Corp. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>

#import "JLCameraPermission.h"
#import "JLMicrophonePermission.h"
#import "JLPhotosPermission.h"

#import "capture_API.h"
#import "capture_Delegate.h"


@implementation capture_API

#pragma mark interface

+ (void)getImage:(ForgeTask*)task {
    capture_Delegate *delegate = [capture_Delegate withTask:task type:(NSString*)kUTTypeImage];
    delegate.saveLocation = task.params[@"saveLocation"] ? (NSString*)task.params[@"saveLocation"] : @"file";
    delegate.width = task.params[@"width"] ? [task.params[@"width"] intValue] : 0;
    delegate.height = task.params[@"height"] ? [task.params[@"height"] intValue] : 0;

    [delegate openPicker];
}


+ (void)getVideo:(ForgeTask*)task {
    capture_Delegate *delegate = [capture_Delegate withTask:task type:(NSString*)kUTTypeMovie];
    delegate.saveLocation = task.params[@"saveLocation"] ? (NSString*)task.params[@"saveLocation"] : @"file";
    delegate.videoDuration = task.params[@"videoDuration"] ? [task.params[@"videoDuration"] doubleValue] : 0;
    delegate.videoQuality = task.params[@"videoQuality"] ? (NSString*)task.params[@"videoQuality"] : @"default";

    [delegate openPicker];
}


#pragma mark permissions

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        [jlpermission setRationale:nil]; // force reset rationale
#pragma clang diagnostic pop
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
    } else if ([permission isEqualToString:@"ios.permission.photos_write"]) {
        ret = [JLPhotosPermission sharedInstance];
        
    } else {
        [ForgeLog w:[NSString stringWithFormat:@"Requested unknown permission:%@", permission]];
    }

    return ret;
}

@end
