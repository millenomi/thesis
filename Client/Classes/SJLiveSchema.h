//
//  SJLiveSchema.h
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJSchema.h"
#import "SJSlideSchema.h"

@interface SJLiveSchema : SJSchema

@property(readonly) SJSlideSchema* slide;
@property(readonly, getter=finished) NSNumber* finishedValue;

@property(readonly, getter=isFinished) BOOL finished;

@end
