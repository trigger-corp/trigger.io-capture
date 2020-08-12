//
//  capture_Delegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface capture_Delegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
@public
    ForgeTask *_task;
@protected
    capture_Delegate *me;
    UIImagePickerController *keepPicker;
    id params;
    NSString* type;
}

//@property(atomic, assign) ForgeTask * _Nonnull task;
@property(atomic, assign) BOOL didReturn;

- (capture_Delegate*_Nullable) initWithTask:(ForgeTask*_Nonnull)initTask andParams:(id _Nullable )initParams andType:(NSString*_Nonnull)initType;
- (void)openPicker:(UIImagePickerControllerSourceType)sourceType;
- (void)closePicker:(void (^ __nullable)(void))success;
- (void)cancel;
- (void)didDisappear;

@end
