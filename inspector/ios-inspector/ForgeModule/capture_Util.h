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

@interface capture_Util : NSObject

+ (void)transcode:(PHAsset*)asset withTask:(ForgeTask*)task videoQuality:(NSString*)videoQuality;

@end

NS_ASSUME_NONNULL_END
