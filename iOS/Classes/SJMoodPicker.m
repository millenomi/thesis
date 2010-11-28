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
	if ((self = [super initWithNibName:NSStringFromClass(self->isa) bundle:nil])) {
		self.delegate = self;
		self.contentView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	}
	
	return self;
}



@end
