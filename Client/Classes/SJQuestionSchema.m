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
- (BOOL) isValueOptionalForTextKey { return YES; }

@dynamic pointURLString;
- validClassForPointURLStringKey { return [NSString class]; }

@dynamic kind;
- validClassForKindKey { return [NSString class]; }

- (BOOL) validateAndReturnError:(NSError **)e;
{
	if ([self.kind isEqual:kSJQuestionFreeformKind] && !self.text) {
		
		if (e) {
			NSDictionary* d = [NSDictionary dictionaryWithObject:@"text" forKey:kSJSchemaErrorSourceKey];
			*e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorRequiredValueMissing userInfo:d];
		}
		
		return NO;
		
	}
	
	return YES;
}

@end
