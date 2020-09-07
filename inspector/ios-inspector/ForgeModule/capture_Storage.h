//
//  capture_Util.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2018/08/21.
//  Copyright © 2018 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface capture_Storage : NSObject

+ (ForgeFile*)writeUIImageToTemporaryFile:(UIImage*)image maxWidth:(int)maxWidth maxHeight:(int)maxHeight error:(NSError**)error;
+ (ForgeFile*)writeNSURLToTemporaryFile:(NSURL*)url error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
