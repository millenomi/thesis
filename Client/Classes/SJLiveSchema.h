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

#define kSJMoodWhyAmIHere	@"whyAmIHere"
#define kSJMoodConfused		@"confused"
#define kSJMoodBored		@"bored"
#define kSJMoodInterested	@"interested"
#define kSJMoodEngaged		@"engaged"
#define kSJMoodThoughtful	@"thoughtful"

@interface SJLiveSchema : SJSchema

@property(readonly) SJSlideSchema* slide;
@property(readonly, getter=finished) NSNumber* finishedValue;

@property(readonly, getter=isFinished) BOOL finished;

@property(readonly, getter=questionsPostedDuringLive) NSArray* URLStringsOfQuestionsPostedDuringLive;

@property(readonly, getter=moods) NSArray* moodURLStrings;
@property(readonly) NSDictionary* moodsForCurrentSlide;

@end

@interface SJMoodSchema : SJSchema

@property(readonly, getter=slideURL) NSString* slideURLString;
@property(readonly) NSString* kind;

@end
