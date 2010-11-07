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
#import "ILFauxActionSheetWindow.h"

@interface SJLivePresentationPane : ILViewController <SJLiveDelegate, UITableViewDelegate, UITableViewDataSource, ILFauxActionSheetDelegate> {
	IBOutlet UIActivityIndicatorView* spinner;
	IBOutlet UITableView* tableView;
	IBOutlet UIView* tableHostView;
	
	IBOutlet UIView* questionActionView;
	IBOutlet ILStretchableImageButton* actionViewCancelButton;
	
	IBOutlet ILFauxActionSheetWindow* fauxActionSheet;
}

@property(retain) NSManagedObjectContext* managedObjectContext;
@property(retain) SJEndpoint* endpoint;

- (IBAction) cancelQuestionSheet;
- (IBAction) askDidNotUnderstandQuestion;
- (IBAction) askGoInDepthQuestion;
- (IBAction) askFreeformQuestion;

@end
