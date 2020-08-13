//
//  capture_Delegate.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import "capture_Delegate.h"
#import "capture_UIImagePickerControllerViewController.h"
#import "capture_Util.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>

@implementation capture_Delegate

- (capture_Delegate*) initWithTask:(ForgeTask *)initTask andParams:(id)initParams andType:(NSString *)initType {
    if (self = [super init]) {
        _task = initTask;
        params = initParams;
        _didReturn = NO;
        type = initType;
        // "retain"
        me = self;
    }
    return self;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self cancel];
    [self closePicker:nil];
}


/**
 * Five cases:
 *
 * 1. Camera Image => File          => url (/path/to/image)                    => data [x]
 * 2. Camera Image => Photo Library => url (photo-library://image/5B345FEF...) => data [x]
 * 3. Camera Video => Photo Library => url (photo-library://video/5B345FEF...) => data [a]
 * 4. Gallery Image                 => url (photo-library://image/5B345FEF...) => data [x]
 * 5. Gallery Video                 => url (photo-library://video/5B345FEF...) => data [a]
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    _didReturn = YES;
    [self closePicker:^{
        if (self->keepPicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeImage]) {
                UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

                // 1. Save as a local file
                if ([[self->params objectForKey:@"saveLocation"] isEqualToString:@"file"]) {
                    NSString *path = [NSString stringWithFormat:@"%@/%@.jpg", [[NSFileManager defaultManager] applicationSupportDirectory], [NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0]];
                    [UIImageJPEGRepresentation(image, 0.8) writeToFile:path atomically:YES];
                    [self->_task success:path]; // image: /path/to/image
                    return;
                }

                // TODO Write image metadata: http://www.altdevblogaday.com/2011/05/11/adding-metadata-to-ios-images-the-easy-way/
                // 2. Save a camera picture in the library then return the save image's URI
                __block NSString* localIdentifier;
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                    localIdentifier = [[assetChangeRequest placeholderForCreatedAsset] localIdentifier];
                } completionHandler:^(BOOL success, NSError *error) {
                    if (!success) {
                        [self->_task error:[error localizedDescription]];
                        return;
                    }
                    NSString *url = [NSString stringWithFormat:@"photo-library://image/%@?ext=JPG", localIdentifier];
                    [self->_task success:url]; // image: photo-library://image/5B345FEF-30D7-41C3-BC4E-E11A9F6B4F42/L0/001?ext=JPG
                }];

            } else if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMovie]) {
                // 3. Save a video in the library then return the saved video's URI
                NSURL *mediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
                __block NSString* localIdentifier;
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:mediaURL];
                    localIdentifier = [[assetChangeRequest placeholderForCreatedAsset] localIdentifier];
                } completionHandler:^(BOOL success, NSError *error) {
                    if (!success) {
                        [self->_task error:[error localizedDescription]];
                        return;
                    }
                    NSString *ret = [NSString stringWithFormat:@"photo-library://video/%@?ext=MOV", localIdentifier];
                    [self->_task success:ret]; // photo-library://video/5B345FEF-30D7-41C3-BC4E-E11A9F6B4F42/L0/001?ext=MOV
                }];
            }

        } else {  // source is gallery
            PHAsset *asset = [info objectForKey:UIImagePickerControllerPHAsset];
            if (asset == nil) {
                [self->_task error:[NSString stringWithFormat:@"ForgeFile could not locate an asset with reference url: %@", [info objectForKey:@"UIImagePickerControllerReferenceURL"]]];
                return;
            }

            if (asset.mediaType == PHAssetMediaTypeImage) {
                // 4. Select a gallery image and return a reference to the image
                NSString *ret = [NSString stringWithFormat:@"photo-library://image/%@?ext=JPG", [asset localIdentifier]];
                [self->_task success:ret]; // photo-library://image/5B345FEF-30D7-41C3-BC4E-E11A9F6B4F42/L0/001?ext=JPG

            } else if (asset.mediaType == PHAssetMediaTypeVideo) {
                // 5. Select a gallery video, potentially transcode it and return a reference to the video
                NSString *videoQuality = [self->params objectForKey:@"videoQuality"] ? [self->params objectForKey:@"videoQuality"] : @"default";
                if ([videoQuality isEqualToString:@"default"]) {
                    NSString *ret = [NSString stringWithFormat:@"photo-library://video/%@?ext=MOV", [asset localIdentifier]];
                    [self->_task success:ret]; // photo-library://video/5B345FEF-30D7-41C3-BC4E-E11A9F6B4F42/L0/001?ext=MOV
                } else {
                    [capture_Util transcode:asset withTask:self->_task videoQuality:videoQuality]; // /path/to/video
                }

            } else {
                [self->_task error:[NSString stringWithFormat:@"Unknown media type for selection: %@", [info objectForKey:@"UIImagePickerControllerReferenceURL"]]];
            }

        }
    }];
}


- (void) cancel {
    if (!_didReturn) {
        _didReturn = YES;
        [_task error:@"Image selection cancelled" type:@"EXPECTED_FAILURE" subtype:nil];
    }
}


- (void) didDisappear {
    [self cancel];
    // "release"
    me = nil;
}


- (void)closePicker:(void (^ __nullable)(void))success {
    [keepPicker.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (success != nil) success();
    }];
}

- (void)openPicker:(UIImagePickerControllerSourceType)sourceType {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] &&
               sourceType == UIImagePickerControllerSourceTypeCamera) {
        [_task error:@"No camera available on device" type:@"EXPECTED_FAILURE" subtype:nil];
    }

    // create picker
    capture_UIImagePickerControllerViewController *picker = [[capture_UIImagePickerControllerViewController alloc] init];
    keepPicker = picker;

    // configure picker
    picker.sourceType = sourceType;

    // Going to be wanting the most compatible version for a good many years yet!
    if (@available(iOS 11_0, *)) {
        picker.imageExportPreset = UIImagePickerControllerImageURLExportPresetCompatible;
    }

    // Video or Photo
    picker.mediaTypes = [NSArray arrayWithObjects:type, nil];

    if ([type isEqual:(NSString*)kUTTypeMovie] && picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        if ([params objectForKey:@"videoDuration"] && [params objectForKey:@"videoDuration"] != nil) {
            picker.videoMaximumDuration = [[params objectForKey:@"videoDuration"] doubleValue];
        }
        NSString *videoQuality = @"high";
        if ([params objectForKey:@"videoQuality"] && [params objectForKey:@"videoQuality"] != nil) {
            videoQuality = [params objectForKey:@"videoQuality"];
        }
        if ([videoQuality isEqualToString:@"high"]) {
            picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        } else if ([videoQuality isEqualToString:@"medium"]) {
            picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        } else {
            picker.videoQuality = UIImagePickerControllerQualityTypeLow;
        }
    }
    picker.delegate = self;

    // As of iOS 11 UIImagePickerController runs out of process and we can no longer rely on getting permission request dialogs automatically
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            [self->_task error:@"Permission denied. User didn't grant access to storage." type:@"EXPECTED_FAILURE" subtype:nil];
            return;
        }
        [self presentUIImagePickerController:picker];
    }];
}


- (void) presentUIImagePickerController:(UIImagePickerController*)pickerController {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (([ForgeUtil isIpad]) && pickerController.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
            pickerController.modalPresentationStyle = UIModalPresentationPopover;
            pickerController.popoverPresentationController.sourceView = [[ForgeApp sharedApp] viewController].view;
            pickerController.popoverPresentationController.sourceRect = CGRectMake(0.0,0.0,1.0,1.0);
        } else {
            if (@available(iOS 13.0, *)) {
                pickerController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                // As of Xcode 11 GM "UIModalPresentationOverFullScreen" also works on iOS 13 devices (until Apple breaks it again?)
            } else {
                pickerController.modalPresentationStyle = UIModalPresentationOverFullScreen;
            }
        }
        [[[ForgeApp sharedApp] viewController] presentViewController:pickerController animated:NO completion:nil];
    });
}

@end
