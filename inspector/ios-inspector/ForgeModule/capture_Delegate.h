//
//  capture_Delegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface capture_Delegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    capture_Delegate *me;
    ForgeTask *task;
    NSString *type;
        
    UIImagePickerController *picker;
}

@property int width;
@property int height;
@property NSString* _Nonnull saveLocation;
@property double videoDuration;
@property NSString* _Nonnull videoQuality;

+ (capture_Delegate* _Nullable) withTask:(ForgeTask* _Nonnull)task type:(NSString* _Nonnull)type;

- (void)openPicker;

@end
