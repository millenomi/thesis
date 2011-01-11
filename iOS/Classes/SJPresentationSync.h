//
//  SJPresentationSync.h
//  Subject
//
//  Created by ∞ on 03/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJClient.h"

@class SJPresentation;

@interface SJPresentationSync : SJCoreDataSyncController

+ (void) requireUpdateForContentsOfPresentation:(SJPresentation*) p priority:(SJDownloadPriority) priority;

@end
