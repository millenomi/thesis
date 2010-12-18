//
//  SJLiveViewController.h
//  Subject
//
//  Created by ∞ on 23/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SJEndpoint.h"
#import "SJLive.h"

#import "ILViewController.h"
#import "ILStretchableImageButton.h"
#import "ILCoverWindow.h"

#import "ILManagedObject.h"

#import "SJMoodPicker.h"

@class SJSlide;

@interface SJPresentationPane : ILViewController <SJLiveDelegate, UITableViewDelegate, UITableViewDataSource, ILCoverWindowDelegate, SJMoodPickerDelegate> {
	IBOutlet UIActivityIndicatorView* spinner;
	IBOutlet UITableView* tableView;
	IBOutlet UIView* tableHostView;
	
	IBOutlet UIView* questionActionView;
	IBOutlet ILStretchableImageButton* actionViewCancelButton;
	
	IBOutlet ILCoverWindow* fauxActionSheet;
	
	IBOutlet UIToolbar* toolbarWithOurItems;
	IBOutlet UIBarButtonItem* backToolbarItem;
	IBOutlet UIBarButtonItem* forwardToolbarItem;
	IBOutlet UIBarButtonItem* moodToolbarItem;
	
	IBOutlet UIImageView* largeImageView;

	CGRect originalTableViewFrame;
	
	SJMoodPicker* moodPicker;
	
	NSMutableDictionary* loadedImages;
}

@property(retain) NSManagedObjectContext* managedObjectContext;
@property(retain) SJEndpoint* endpoint;

- (IBAction) cancelQuestionSheet;
- (IBAction) askDidNotUnderstandQuestion;
- (IBAction) askGoInDepthQuestion;
- (IBAction) askFreeformQuestion;

- (IBAction) moveToNextSlide;
- (IBAction) moveToPreviousSlide;

- (IBAction) moveToLastSlide;

- (IBAction) reportMood;

@end
