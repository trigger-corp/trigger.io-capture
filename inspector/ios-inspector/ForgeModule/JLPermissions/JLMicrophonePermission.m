//
//  JLMicrophonePermission.m
//
//  Created by Joseph Laws on 11/3/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLMicrophonePermission.h"

#import <AVFoundation/AVFoundation.h>

#import <ForgeCore/JLPermissionsCore+Internal.h>

#define kJLAskedForMicrophonePermission @"JLAskedForMicrophonePermission"

@implementation JLMicrophonePermission {
    AuthorizationHandler _completion;
}

+ (instancetype)sharedInstance {
    static JLMicrophonePermission *_instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[JLMicrophonePermission alloc] init];
    });
    
    return _instance;
}

#pragma mark - Microphone

- (JLAuthorizationStatus)authorizationStatus {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(recordPermission)]) {
        AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
        switch (permission) {
            case AVAudioSessionRecordPermissionGranted:
                return JLPermissionAuthorized;
            case AVAudioSessionRecordPermissionDenied:
                return JLPermissionDenied;
            case AVAudioSessionRecordPermissionUndetermined:
                return JLPermissionNotDetermined;
        }
    } else {
        bool previouslyAsked =
        [[NSUserDefaults standardUserDefaults] boolForKey:kJLAskedForMicrophonePermission];
        if (previouslyAsked) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            __block BOOL hasAccess;
            [audioSession requestRecordPermission:^(BOOL granted) {
                hasAccess = granted;
                dispatch_semaphore_signal(sema);
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            return (hasAccess) ? JLPermissionAuthorized : JLPermissionDenied;
        } else {
            return JLPermissionNotDetermined;
        }
    }
}

- (void)authorize:(AuthorizationHandler)completion {
    [self authorizeWithTitle:[self defaultTitle:@"Microphone"]
                     message:[self defaultMessage]
                 cancelTitle:[self defaultCancelTitle]
                  grantTitle:[self defaultGrantTitle]
                  completion:completion];
}

- (void)authorizeWithTitle:(NSString *)messageTitle
                   message:(NSString *)message
               cancelTitle:(NSString *)cancelTitle
                grantTitle:(NSString *)grantTitle
                completion:(AuthorizationHandler)completion {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(recordPermission)]) {
        AVAudioSessionRecordPermission permission = [audioSession recordPermission];
        switch (permission) {
            case AVAudioSessionRecordPermissionGranted: {
                if (completion) {
                    completion(true, nil);
                }
            } break;
            case AVAudioSessionRecordPermissionDenied: {
                if (completion) {
                    completion(false, [self previouslyDeniedError]);
                }
            } break;
            case AVAudioSessionRecordPermissionUndetermined: {
                _completion = completion;
                if (self.isExtraAlertEnabled) {
                    UIAlertController *alert =
                        [UIAlertController alertControllerWithTitle:messageTitle
                                                            message:message
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                                  style:UIAlertActionStyleCancel
                                                                handler:^(UIAlertAction * _Nonnull action) {
                            if (self->_completion) {
                                self->_completion(false, nil);
                            }
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:grantTitle
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
                            [self actuallyAuthorize];
                        }]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[ForgeApp sharedApp] viewController] presentViewController:alert animated:YES completion:nil];
                    });
                } else {
                    [self actuallyAuthorize];
                }
            } break;
        }
    } else {
        [audioSession requestRecordPermission:^(BOOL granted) {
            [[NSUserDefaults standardUserDefaults] setBool:true forKey:kJLAskedForMicrophonePermission];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        completion(granted, nil);
                    } else {
                        completion(false, nil);
                    }
                });
            }
        }];
    }
}

- (JLPermissionType)permissionType {
    return JLPermissionMicrophone;
}

- (void)actuallyAuthorize {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:@"AVAudioSessionCategoryPlayAndRecord" error:&error];
    [session requestRecordPermission:^(BOOL granted) {
        if (self->_completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    self->_completion(true, nil);
                } else {
                    self->_completion(false, nil);
                }
            });
        }
    }];
}

- (void)canceledAuthorization:(NSError *)error {
    if (_completion) {
        _completion(false, error);
    }
}

@end
