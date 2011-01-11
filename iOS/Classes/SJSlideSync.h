//
//  SJSlideSync.h
//  Subject
//
//  Created by ∞ on 01/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJClient.h"

@class SJSlide;

@interface SJSlideSync : SJCoreDataSyncController

+ (void) requireUpdateForContentsOfSlide:(SJSlide*) s priority:(SJDownloadPriority) priority;
+ (void) requireUpdateForImageOfSlide:(SJSlide*) s priority:(SJDownloadPriority) priority;

@end
