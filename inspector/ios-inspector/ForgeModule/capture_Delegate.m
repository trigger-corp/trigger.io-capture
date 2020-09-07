//
//  capture_Delegate.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import "capture_Delegate.h"
#import "capture_UIImagePickerController.h"
#import "capture_Storage.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>

@implementation capture_Delegate


#pragma mark life-cycle

+ (capture_Delegate*) withTask:(ForgeTask*)task type:(NSString *)type {
    capture_Delegate *delegate = [[self alloc] init];
    if (delegate) {
        delegate->me = delegate; // retain
        delegate->task = task;
        delegate->type = type;
        
        delegate.width = 0;
        delegate.height = 0;
        delegate.saveLocation = @"file";
        delegate.videoDuration = 0;
        delegate.videoQuality = @"default";
    }
    return delegate;
}



#pragma mark interface

- (void)openPicker {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self->task error:@"No camera available on device" type:@"EXPECTED_FAILURE" subtype:nil];
        return;
    }

    self->picker = [[capture_UIImagePickerController alloc] init];
    self->picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self->picker.imageExportPreset = UIImagePickerControllerImageURLExportPresetCompatible;
    self->picker.mediaTypes = @[ self->type ];
    self->picker.delegate = self;

    if ([type isEqual:(NSString*)kUTTypeMovie]) {
        if ([self.videoQuality isEqualToString:@"high"]) {
            picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        } else if ([self.videoQuality isEqualToString:@"medium"]) {
            picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        } else if ([self.videoQuality isEqualToString:@"low"]) {
            picker.videoQuality = UIImagePickerControllerQualityTypeLow;
        }
        if (self.videoDuration > 0) {
            picker.videoMaximumDuration = self.videoDuration;
        }
    }

    // still needed ?
    /*if (@available(iOS 13.0, *)) {
        picker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        // As of Xcode 11 GM "UIModalPresentationOverFullScreen" also works on iOS 13 devices (until Apple breaks it again?)
    } else {
        picker.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }*/

    [[[ForgeApp sharedApp] viewController] presentViewController:picker animated:NO completion:nil];
}



#pragma mark callbacks

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
    [[[ForgeApp sharedApp] viewController] dismissViewControllerAnimated:YES completion:^{
        [self->task error:@"Image selection cancelled" type:@"EXPECTED_FAILURE" subtype:nil];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [[[ForgeApp sharedApp] viewController] dismissViewControllerAnimated:YES completion:^{
        
        if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeImage]) {
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            if (image == nil) {
                [self->task error:@"Failed to obtain image for the selected item" type:@"UNEXPECTED_FAILURE" subtype:nil];
                return;
            }
            
            // Save image in the library if required
            if ([self.saveLocation isEqualToString:@"gallery"]) {
                __block NSString* localIdentifier;
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                    localIdentifier = [[assetChangeRequest placeholderForCreatedAsset] localIdentifier];
                    // TODO Write image metadata: http://www.altdevblogaday.com/2011/05/11/adding-metadata-to-ios-images-the-easy-way
                } completionHandler:^(BOOL success, NSError *error) {
                    if (!success) {
                        [ForgeLog e:[NSString stringWithFormat:@"Failed to save image to library: %@", error.localizedDescription]];
                        return;
                    }
                    [ForgeLog d:[NSString stringWithFormat:@"Saved image to library: %@", localIdentifier]];
                }];
            }

            // Save and return a local copy of the image
            NSError *error = nil;
            ForgeFile *forgeFile = [capture_Storage writeUIImageToTemporaryFile:image maxWidth:self.width maxHeight:self.height error:&error];
            if (error != nil) {
                [self->task error:error.localizedDescription type:@"UNEXPECTED_FAILURE" subtype:nil];
                return;
            }
            
            [self->task success:[forgeFile toScriptObject]];

        } else if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMovie]) {
            NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
            if (url == nil) {
                [self->task error:@"Failed to obtain video for the selected item" type:@"UNEXPECTED_FAILURE" subtype:nil];
                return;
            }
            
            // Save video in the library if required
            if ([self.saveLocation isEqualToString:@"gallery"]) {
                __block NSString* localIdentifier;
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                    localIdentifier = [[assetChangeRequest placeholderForCreatedAsset] localIdentifier];
                } completionHandler:^(BOOL success, NSError *error) {
                    if (!success) {
                        [ForgeLog e:[NSString stringWithFormat:@"Failed to save image to library: %@", error.localizedDescription]];
                        return;
                    }
                    [ForgeLog d:[NSString stringWithFormat:@"Saved image to library: %@", localIdentifier]];
                }];
            }
            
            // Save and return a local copy of the video
            NSError *error = nil;
            ForgeFile *forgeFile = [capture_Storage writeNSURLToTemporaryFile:url error:&error];
            if (error != nil) {
                [self->task error:error.localizedDescription type:@"UNEXPECTED_FAILURE" subtype:nil];
                return;
            }
            
            [self->task success:[forgeFile toScriptObject]];
        }        
    }];
}



@end
