//
//  SJPresentationPane_v2.h
//  Subject
//
//  Created by ∞ on 22/12/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ILViewController.h"

@class SJSlide, SJLiveSyncController;

@interface SJPresentationPane_v2 : ILViewController {
	IBOutlet UITableView* tableView;
	
	IBOutlet UIView* moodSendProgressView;
	IBOutlet UIActivityIndicatorView* moodSendSpinner;
	IBOutlet UILabel* moodSendLabel;
	
	IBOutlet UIView* slideImageOverlay;
	IBOutlet UIImageView* slideImageView;
	IBOutlet UIActivityIndicatorView* slideImageLoadSpinner;
	
	UIInterfaceOrientation rotatedToOrientation;
}

@property(nonatomic, retain) SJSlide* displayedSlide;

@property(nonatomic, retain) SJLiveSyncController* liveSyncController;
@property(nonatomic, retain) NSManagedObjectContext* managedObjectContext;

- (IBAction) sendMoodForCurrentSlide;
- (IBAction) beginPosingQuestionForCurrentSlide;

@end


@interface UITableView (ILConveniences)

- (id) cellWithReuseIdentifier:(NSString*) ident ifNoCellToDequeue:(id (^)()) makeOne;

@end

@interface NSArray (ILConveniences)

- (NSArray*) sortedArrayByValueForKey:(NSString*) kp ascending:(BOOL) asc;

@end
