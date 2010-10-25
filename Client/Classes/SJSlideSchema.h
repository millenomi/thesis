//
//  SJSlideSchema.h
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJSchema.h"

@interface SJSlideSchema : SJSchema {}

@property(readonly) NSNumber* sortingOrder;
@property(readonly) NSArray* points;
@property(getter=presentation, readonly) NSString* presentationURLString;
@property(getter=URL, readonly) NSString* URLString;

@end
