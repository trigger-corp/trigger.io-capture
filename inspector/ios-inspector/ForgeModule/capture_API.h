//
//  capture_API.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 21/08/2018.
//  Copyright (c) 2018 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface capture_API : NSObject

+ (void)getImage:(ForgeTask*)task source:(NSString*)source;
+ (void)getVideo:(ForgeTask*)task source:(NSString*)source;

@end

extern NSString *io_trigger_capture_dialog_capture_camera_description;
extern NSString *io_trigger_capture_dialog_capture_source_camera;
extern NSString *io_trigger_capture_dialog_capture_source_gallery;
extern NSString *io_trigger_capture_dialog_capture_pick_source;
extern NSString *io_trigger_capture_dialog_cancel;



