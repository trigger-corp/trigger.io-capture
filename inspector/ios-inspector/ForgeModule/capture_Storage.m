//
//  capture_Util.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import "capture_Storage.h"

@implementation capture_Storage

+ (ForgeFile*)writeUIImageToTemporaryFile:(UIImage*)image maxWidth:(int)maxWidth maxHeight:(int)maxHeight error:(NSError**)error {
    if (maxWidth > 0 || maxHeight > 0) {
        image = [image imageWithWidth:maxWidth andHeight:maxHeight];
    }
    
    ForgeFile *forgeFile = [ForgeFile withEndpointId:ForgeStorage.EndpointIds.Temporary
                                            resource:[ForgeStorage temporaryFileNameWithExtension:@"jpg"]];
    NSURL *destination = [ForgeStorage nativeURL:forgeFile];
    
    [UIImageJPEGRepresentation(image, 0.9) writeToURL:destination atomically:YES];
    [NSFileManager.defaultManager addSkipBackupAttributeToItemAtURL:destination];
    
    return forgeFile;
}

+ (ForgeFile*)writeNSURLToTemporaryFile:(NSURL*)url error:(NSError**)error {
    NSString *extension = url.pathExtension;
    if (extension == nil) {
        extension = @"mp4";
    }
    ForgeFile *forgeFile = [ForgeFile withEndpointId:ForgeStorage.EndpointIds.Temporary
                                            resource:[ForgeStorage temporaryFileNameWithExtension:extension]];
    NSURL *destination = [ForgeStorage nativeURL:forgeFile];

    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data == nil) {
        *error = [NSError errorWithDomain:NSItemProviderErrorDomain
                                    code:NSItemProviderUnavailableCoercionError
                                userInfo:@{
            NSLocalizedDescriptionKey:@"Failed to load data for the selected item"
        }];
        return nil;
        
    } else if (![data writeToURL:destination atomically:YES]) {
        *error = [NSError errorWithDomain:NSItemProviderErrorDomain
                                    code:NSItemProviderUnavailableCoercionError
                                userInfo:@{
            NSLocalizedDescriptionKey:@"Failed to write data for the selected item"
        }];
        return nil;
    }
    
    [[NSFileManager defaultManager] addSkipBackupAttributeToItemAtURL:destination];
    
    return forgeFile;
}

@end
