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

@synthesize moodPickerDelegate;

- (void) cancel;
{
	[self.moodPickerDelegate moodPickerDidCancel:self];
}

- (void) pickMoodFromSenderTag:(id)sender;
{
	NSInteger i = [sender tag];
	[self.moodPickerDelegate moodPicker:self didPickMood:[SJMoodPickerOrderedMoods() objectAtIndex:i]];
}

@end
