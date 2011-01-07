//
//  SJQuestionKindPicker.m
//  Subject
//
//  Created by ∞ on 07/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJQuestionKindPicker.h"


@implementation SJQuestionKindPicker

- (void) dealloc
{
	self.didPickQuestionKind = nil;
	[super dealloc];
}


@synthesize didPickQuestionKind, didCancel;

- (void) pickQuestionKindFromButton:(id)sender;
{
	if (self.didPickQuestionKind) {
		NSString* kind = [SJQuestionKindsByTag() objectAtIndex:[sender tag]];
		(self.didPickQuestionKind)(kind);
	}
}

- (IBAction) cancel;
{
	if (self.didCancel)
		(self.didCancel)();
}

@end
