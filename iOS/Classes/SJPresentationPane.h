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

@class SJSlide;

@interface SJPresentationPane : ILViewController <SJLiveDelegate, UITableViewDelegate, UITableViewDataSource, ILCoverWindowDelegate> {
	IBOutlet UIActivityIndicatorView* spinner;
	IBOutlet UITableView* tableView;
	IBOutlet UIView* tableHostView;
	
	IBOutlet UIView* questionActionView;
	IBOutlet ILStretchableImageButton* actionViewCancelButton;
	
	IBOutlet ILCoverWindow* fauxActionSheet;
	
	IBOutlet UIToolbar* toolbarWithOurItems;
	IBOutlet UIBarButtonItem* backToolbarItem;
	IBOutlet UIBarButtonItem* forwardToolbarItem;
	
	CGRect originalTableViewFrame;
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

@end
