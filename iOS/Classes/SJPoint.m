//
//  SJPoint.m
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPoint.h"


@implementation SJPoint

@dynamic indentation;
@dynamic sortingOrder;
@dynamic text;
@dynamic slide;
@dynamic questions;

- (NSUInteger) indentationValue;
{
	return self.indentation? [self.indentation unsignedIntegerValue] : 0;
}

- (NSUInteger) sortingOrderValue;
{
	return self.sortingOrder? [self.sortingOrder unsignedIntegerValue] : 0;
}

- (void) setIndentationValue:(NSUInteger) i;
{
	self.indentation = [NSNumber numberWithUnsignedInteger:i];
}

- (void) setSortingOrderValue:(NSUInteger) i;
{
	self.sortingOrder = [NSNumber numberWithUnsignedInteger:i];
}

@end
