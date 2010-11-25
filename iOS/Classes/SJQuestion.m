//
//  SJQuestion.m
//  Subject
//
//  Created by ∞ on 07/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJQuestion.h"


@implementation SJQuestion

@dynamic kind;
@dynamic text;
@dynamic point;
@dynamic URLString;

- (NSURL *) URL;
{
	return self.URLString? [NSURL URLWithString:self.URLString] : nil;
}

- (void) setURL:(NSURL *) u;
{
	self.URLString = [u absoluteString];
}

@end
