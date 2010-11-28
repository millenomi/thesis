//
//  SJSlideSchema.h
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJSchema.h"

#define kSJMoodWhyAmIHere	@"whyAmIHere"
#define kSJMoodConfused		@"confused"
#define kSJMoodBored		@"bored"
#define kSJMoodInterested	@"interested"
#define kSJMoodEngaged		@"engaged"
#define kSJMoodThoughtful	@"thoughtful"

@interface SJSlideSchema : SJSchema {}

@property(readonly) NSNumber* sortingOrder;
@property(readonly) NSArray* points;
@property(getter=presentation, readonly) NSString* presentationURLString;
@property(getter=URL, readonly) NSString* URLString;
@property(readonly) NSDictionary* moods;
@property(readonly) NSNumber* revision;

@end
