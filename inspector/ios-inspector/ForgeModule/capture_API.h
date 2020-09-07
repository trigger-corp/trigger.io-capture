//
//  capture_API.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 21/08/2018.
//  Copyright (c) 2018 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface capture_API : NSObject

+ (void)getImage:(ForgeTask*)task;
+ (void)getVideo:(ForgeTask*)task;

@end

