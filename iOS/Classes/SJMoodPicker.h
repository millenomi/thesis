//
//  SJMoodPaneView.h
//  Subject
//
//  Created by ∞ on 28/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILCoverWindow.h"
#import "SJLiveSchema.h"

@protocol SJMoodPickerDelegate;

CF_INLINE NSArray* SJMoodPickerOrderedMoods() {
	return [NSArray arrayWithObjects: 
			kSJMoodWhyAmIHere, 
			kSJMoodConfused, 
			kSJMoodBored, 
			kSJMoodEngaged, 
			kSJMoodThoughtful, 
			kSJMoodInterested, 
			nil];
}

@interface SJMoodPicker : ILCoverWindow <ILCoverWindowDelegate> {}

- (id) init;

@property(assign) id <SJMoodPickerDelegate> moodPickerDelegate;

- (IBAction) cancel;
- (IBAction) pickMoodFromSenderTag:(id) sender;

@end



@protocol SJMoodPickerDelegate <NSObject>

// 'mood' is one of the kSJMood… constants in SJSlideSchema.h
- (void) moodPicker:(SJMoodPicker*) picker didPickMood:(NSString*) mood;
- (void) moodPickerDidCancel:(SJMoodPicker*) picker;

@end
