//
//  SJLiveSchema.m
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJLiveSchema.h"


@implementation SJLiveSchema

@dynamic slide;
- validClassForSlideKey { return [SJSlideSchema class]; }

@dynamic finishedValue;
- validClassForFinishedValueKey { return [NSNumber class]; }
- (BOOL) isValueOptionalForFinishedValueKey { return YES; }

@dynamic URLStringsOfQuestionsPostedDuringLive;
- validClassForValuesOfURLStringsOfQuestionsPostedDuringLiveArrayKey { return [NSString class]; }

@dynamic moodURLStrings;
- validClassForValuesOfMoodURLStringsArrayKey { return [NSString class]; }

@dynamic moodsForCurrentSlide;
- validClassForMoodsForCurrentSlideKey { return [NSDictionary class]; }

- (BOOL) isFinished;
{
	return self.finishedValue? [self.finishedValue boolValue] : NO;
}

@end



@implementation SJMoodSchema : SJSchema

@dynamic slideURLString;
- validClassForSlideURLStringKey { return [NSString class]; }

@dynamic kind;
- validClassForKindKey { return [NSString class]; }

@end
