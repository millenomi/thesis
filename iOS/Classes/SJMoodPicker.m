//
//  SJMoodPaneView.m
//  Subject
//
//  Created by ∞ on 28/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJMoodPicker.h"
#import "ILGrowFromPointChoreography.h"

@implementation SJMoodPicker

- (id) init;
{
	if ((self = [super initWithNibName:@"SJMoodPicker" bundle:nil])) {
		self.coverDelegate = self;
		self.contentView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	}
	
	return self;
}

- (void) dealloc
{
	self.didPickMood = nil;
	self.didCancel = nil;
	[super dealloc];
}


@synthesize didPickMood, didCancel;

- (void) cancel;
{
	if (self.didCancel)
		(self.didCancel)();
}

- (void) pickMoodFromSenderTag:(id)sender;
{
	if (self.didPickMood) {
		NSInteger i = [sender tag];
		(self.didPickMood)([SJMoodPickerOrderedMoods() objectAtIndex:i]);
	}
}

@end
