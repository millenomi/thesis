//
//  SJPointSchema.m
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPointSchema.h"


@implementation SJPointSchema

@dynamic text, indentation;

- validClassForTextKey { return [NSString class]; }
- validClassForIndentationKey { return [NSNumber class]; }

- (NSInteger) indentationValue;
{
	return self.indentation? [self.indentation integerValue] : 0;
}

@end
