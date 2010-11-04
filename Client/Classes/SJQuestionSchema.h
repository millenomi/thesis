//
//  SJQuestionSchema.h
//  Client
//
//  Created by ∞ on 02/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJSchema.h"

#define kSJQuestionFreeformKind @"freeform"
#define kSJQuestionDidNotUnderstandKind @"didNotUnderstand"
#define kSJQuestionGoInDepthKind @"goInDepth"

@interface SJQuestionSchema : SJSchema

@property(readonly) NSString* kind;
@property(readonly) NSString* text;
@property(readonly, getter=pointURL) NSString* pointURLString;

@end
