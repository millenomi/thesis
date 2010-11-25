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
@dynamic URLString;

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

+ pointWithURL:(NSURL*) url fromContext:(NSManagedObjectContext*) moc;
{
	NSPredicate* pred = [NSPredicate predicateWithFormat:@"URLString == %@", [url absoluteString]];
	return [self oneWithPredicate:pred fromContext:moc];
}

- (NSURL *) URL;
{
	return self.URLString? [NSURL URLWithString:self.URLString] : nil;
}

- (void) setURL:(NSURL *) u;
{
	self.URLString = [u absoluteString];
}

@end
