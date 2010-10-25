//
//  SJPresentationSchema.h
//  Subject
//
//  Created by ∞ on 23/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJSchema.h"
#import "SJSlideSchema.h"

@interface SJPresentationSlideInfoSchema : SJSchema 

@property(readonly, getter=URL) NSString* URLString;
@property(readonly) SJSlideSchema* contents;

@end


@interface SJPresentationSchema : SJSchema

@property(readonly) NSString* title;
@property(readonly) NSArray* slides;

@end
