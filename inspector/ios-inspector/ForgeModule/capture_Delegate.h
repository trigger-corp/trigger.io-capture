//
//  capture_Delegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface capture_Delegate : NSObject <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    ForgeTask *task;
    capture_Delegate *me;
    UIPopoverController *keepPopover;
    UIImagePickerController *keepPicker;
    id params;
    BOOL didReturn;
    NSString* type;
}

- (capture_Delegate*_Nullable) initWithTask:(ForgeTask*_Nullable)initTask andParams:(id _Nullable )initParams andType:(NSString*_Nullable)initType;
- (void)closePicker:(void (^ __nullable)(void))success;
- (void)cancel;
- (void)didDisappear;

@end
