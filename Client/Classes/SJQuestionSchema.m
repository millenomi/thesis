//
//  SJQuestionSchema.m
//  Client
//
//  Created by ∞ on 02/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SJQuestionSchema.h"


@implementation SJQuestionSchema

@dynamic text;
- validClassForTextKey { return [NSString class]; }

@dynamic pointURLString;
- validClassForPointURLStringKey { return [NSString class]; }

@end
