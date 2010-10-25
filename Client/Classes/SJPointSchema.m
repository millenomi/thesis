//
//  SJPointSchema.m
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPointSchema.h"


@implementation SJPointSchema

@dynamic text;
- validClassForTextKey { return [NSString class]; }

@dynamic indentation;
- validClassForIndentationKey { return [NSNumber class]; }

- (NSInteger) indentationValue;
{
	return self.indentation? [self.indentation integerValue] : 0;
}

@dynamic URLString;
- validClassForURLStringKey { return [NSString class]; }
- (BOOL) isValueOptionalForURLStringKey { return YES; }

@dynamic slideURLString;
- validClassForSlideURLStringKey { return [NSString class]; }
- (BOOL) isValueOptionalForSlideURLStringKey { return YES; }

@end
