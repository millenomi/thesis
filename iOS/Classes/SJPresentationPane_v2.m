//
//  SJPresentationPane_v2.m
//  Subject
//
//  Created by ∞ on 22/12/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPresentationPane_v2.h"

#import <QuartzCore/QuartzCore.h>

#import "SJSlide.h"
#import "SJPresentation.h"

#import "SJPointTableViewCell.h"
#import "SJPoseAQuestionPane.h"

#import "SJQuestionKindPicker.h"
#import "SJQuestionSending.h"
#import "SJMoodPicker.h"
#import "SJMoodSending.h"

#define ILRetain(to, newObj) \
	do { [to release]; to = [newObj retain]; } while (0)

typedef enum {
	kSJPresentationMoveAnimationKindNone = 0,
	
	kSJPresentationMoveAnimationKindNext,
	kSJPresentationMoveAnimationKindPrevious,
	kSJPresentationMoveAnimationKindSkip,
} SJPresentationMoveAnimationKind;

#pragma mark Conveniences

@implementation UITableView (ILConveniences)

- (id) cellWithReuseIdentifier:(NSString*) ident ifNoCellToDequeue:(UITableViewCell* (^)()) makeOne;
{
	id cell = [self dequeueReusableCellWithIdentifier:ident];
	if (!cell)
		cell = makeOne();
	
	return cell;
}

@end

@implementation NSArray (ILConveniences)

- (NSArray*) sortedArrayByValueForKey:(NSString*) key ascending:(BOOL) asc;
{
	return [self sortedArrayUsingDescriptors:
			[NSArray arrayWithObject:
			 [[[NSSortDescriptor alloc] initWithKey:key ascending:asc] autorelease]
			 ]
			];
}

@end


#pragma mark -


@interface SJPresentationPane_v2 () <UITableViewDelegate, UITableViewDataSource, SJLiveSyncControllerDelegate>

@property(nonatomic, copy) NSArray* orderedPoints;
@property(nonatomic, retain) SJSlide* currentLiveSlide;

- (void) setDisplayedSlide:(SJSlide *)s animated:(BOOL)ani;

@property(nonatomic, retain) UIBarButtonItem* backButtonItem, * forwardButtonItem;
- (void) updateBackForwardButtonItems;

@property(nonatomic, retain) SJQuestionKindPicker* questionKindPicker;
@property(nonatomic, retain) SJMoodPicker* moodPicker;

@property(nonatomic, retain) NSOperationQueue* operationQueue;
- (void) beginPosingQuestionForPoint:(SJPoint*) point;
- (void) poseQuestionOfKind:(NSString*) kind forPoint:(SJPoint*) point;

- (CATransition *) transitionForAnimationKind:(SJPresentationMoveAnimationKind) kind;
- (void) updateSlideImageWithAnimation:(SJPresentationMoveAnimationKind) ani;

@end


@implementation SJPresentationPane_v2

#pragma mark Observing the Slide

- (void) viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mayHaveUpdated:) name:NSManagedObjectContextDidSaveNotification object:nil];
	
	[self updateBackForwardButtonItems];
	[self.navigationController setToolbarHidden:NO animated:YES];
}

- (void) mayHaveUpdated:(NSNotification*) n;
{
	if ([n object] == self.displayedSlide.managedObjectContext) {
		self.orderedPoints = nil;
		self.title = self.displayedSlide.presentation.title;
		[tableView reloadData];
		
		[self updateBackForwardButtonItems];
		[self updateSlideImageWithAnimation:kSJPresentationMoveAnimationKindSkip];
	}
}

- (void) viewWillDisappear:(BOOL)animated;
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	
	[self.questionKindPicker dismissAnimated:YES];
	self.questionKindPicker = nil;
	
	[self.moodPicker dismissAnimated:YES];
	self.moodPicker = nil;
}

#pragma mark Memory management

- (NSSet *) startingManagedOutlets;
{
	return [NSSet setWithObjects:
			@"tableView",
			@"backButtonItem",
			@"forwardButtonItem",
			
			@"moodSendProgressView",
			@"moodSendSpinner",
			@"moodSendLabel",
			
			@"slideImageOverlay",
			@"slideImageView",
			@"slideImageLoadSpinner",
			nil];
}

@synthesize backButtonItem, forwardButtonItem;

- (void) viewDidLoad;
{
	[super viewDidLoad];
	self.rotationStyle = kILRotateAny;
	
	if (self.operationQueue)
		self.operationQueue = [[NSOperationQueue new] autorelease];
	
	if (!self.backButtonItem || !self.forwardButtonItem) {
		NSMutableArray* items = [NSMutableArray array];
		
		self.backButtonItem =
			[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackArrowToolbarIcon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)] autorelease];
		[items addObject:self.backButtonItem];
		
		[items addObject:
		 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease]
		 ];
		[items addObject:
		 [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"EmoticonToolbarIcon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(sendMoodForCurrentSlide)] autorelease]
		 ];
		[items addObject:
		 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease]
		 ];
		
		self.forwardButtonItem = 
			[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ForwardArrowToolbarIcon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goForward)] autorelease];
		[items addObject:self.forwardButtonItem];
		
		self.toolbarItems = items;
	}
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	UISwipeGestureRecognizer* backSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)] autorelease];
	backSwipe.direction = UISwipeGestureRecognizerDirectionRight;
	
	UISwipeGestureRecognizer* forwardSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goForward)] autorelease];
	forwardSwipe.direction = UISwipeGestureRecognizerDirectionLeft;

	UISwipeGestureRecognizer* twoFingerBackSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)] autorelease];
	twoFingerBackSwipe.direction = UISwipeGestureRecognizerDirectionRight;
	twoFingerBackSwipe.numberOfTouchesRequired = 2;
	
	UISwipeGestureRecognizer* twoFingerForwardSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goForward)] autorelease];
	twoFingerForwardSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
	twoFingerForwardSwipe.numberOfTouchesRequired = 2;
	
	self.view.gestureRecognizers = [NSArray arrayWithObjects:backSwipe, forwardSwipe, twoFingerBackSwipe, twoFingerForwardSwipe, nil];
}

- (void) clearOutlets;
{
	tableView.delegate = nil;
	tableView.dataSource = nil;
	
	[super clearOutlets];
}

#pragma mark Slide display

- (CATransition*) transitionForAnimationKind:(SJPresentationMoveAnimationKind) kind;
{
	switch (kind) {
		case kSJPresentationMoveAnimationKindNext: {
			CATransition* tx = [CATransition animation];
			tx.type = kCATransitionPush;
			tx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			tx.duration = 0.3;

			tx.subtype = kCATransitionFromRight;
			return tx;
		}
			
		case kSJPresentationMoveAnimationKindPrevious: {
			CATransition* tx = [CATransition animation];
			tx.type = kCATransitionPush;
			tx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			tx.duration = 0.3;
			
			tx.subtype = kCATransitionFromLeft;
			return tx;
		}
			
		case kSJPresentationMoveAnimationKindSkip: {
			CATransition* tx = [CATransition animation];
			tx.type = kCATransitionFade;
			return tx;
		}
			
		case kSJPresentationMoveAnimationKindNone:
		default:
			return nil;
	}
}

@synthesize displayedSlide;
- (void) setDisplayedSlide:(SJSlide *) s;
{
	[self setDisplayedSlide:s animated:NO];
}

- (void) setDisplayedSlide:(SJSlide*) s animated:(BOOL) ani;
{
	if (s != displayedSlide) {
		self.orderedPoints = nil;
		
		SJSlide* oldSlide = [[displayedSlide retain] autorelease];
		ILRetain(displayedSlide, s);
		
		[displayedSlide checkIfCompleteWithDownloadPriority:kSJDownloadPriorityResourceForImmediateDisplay];
		
		self.title = displayedSlide.presentation.title;
		SJPresentationMoveAnimationKind kind = kSJPresentationMoveAnimationKindNone;
		
		if (ani) {
			if ([displayedSlide.presentation isEqual:[oldSlide presentation]]) {
									 
				if (displayedSlide.sortingOrderValue > oldSlide.sortingOrderValue) {
					kind = kSJPresentationMoveAnimationKindNext;
				} else {
					kind = kSJPresentationMoveAnimationKindPrevious;
				}
				
			} else {
				kind = kSJPresentationMoveAnimationKindSkip;
			}
			
			CATransition* tx = [self transitionForAnimationKind:kind];
			
			if (tx)
				[self.view.layer addAnimation:tx forKey:@"SJPresentationPaneDisplayedSlideTransition"];
		}
		
		[self updateSlideImageWithAnimation:kind];
		
		[self updateBackForwardButtonItems];
		[tableView reloadData];
	}
}

@synthesize orderedPoints;
- (NSArray *) orderedPoints;
{
	if (!orderedPoints && self.displayedSlide) {
		// TODO query the displayedSlide's MOC instead.
		
		orderedPoints = [[[self.displayedSlide.points allObjects] sortedArrayByValueForKey:@"sortingOrder" ascending:YES] copy];
	}
	
	return orderedPoints;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
	if (!self.displayedSlide)
		return 0;
	
	return [self.displayedSlide.points count];
}

- (UITableViewCell *)tableView:(UITableView *) tv cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
#define kSJSlideCell @"SJSlideCell"
	SJPointTableViewCell* cell = 
	[tableView cellWithReuseIdentifier:[SJPointTableViewCell reuseIdentifier] ifNoCellToDequeue:^{
		return [[SJPointTableViewCell new] autorelease];
	}];
	
	cell.point = [self.orderedPoints objectAtIndex:[indexPath row]];
	return cell;
}

- (CGFloat) tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	SJPoint* p = [self.orderedPoints objectAtIndex:[indexPath row]];
	return [SJPointTableViewCell cellHeightForPoint:p width:tableView.bounds.size.width];
}

#pragma mark Back/Forward

- (void) updateBackForwardButtonItems;
{
	if (!self.displayedSlide) {
		self.backButtonItem.enabled = NO;
		self.forwardButtonItem.enabled = NO;
		self.navigationItem.rightBarButtonItem = nil;
		return;
	}
	
	SJSlide* s = self.displayedSlide;
	
	self.backButtonItem.enabled = s.sortingOrderValue != 0 && ([SJSlide countForFetchRequestWithProperties:^(NSFetchRequest* req) {
		
		[req setPredicate:[NSPredicate predicateWithFormat:@"sortingOrder == %d", s.sortingOrderValue - 1]];
		[req setFetchLimit:1];
		
	} fromContext:[s managedObjectContext]] > 0);

	BOOL isKnownLast = s.presentation && s.sortingOrderValue == (s.presentation.knownCountOfSlidesValue - 1);
	
	self.forwardButtonItem.enabled = !isKnownLast && ([SJSlide countForFetchRequestWithProperties:^(NSFetchRequest* req) {
		
		[req setPredicate:[NSPredicate predicateWithFormat:@"sortingOrder == %d", s.sortingOrderValue + 1]];
		[req setFetchLimit:1];
		
	} fromContext:[s managedObjectContext]] > 0);
	
	BOOL isNotOnCurrentSlide = self.currentLiveSlide && (![self.currentLiveSlide isEqual:self.displayedSlide]);
	if (isNotOnCurrentSlide)
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FastForwardArrowToolbarIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(goToCurrentSlide)] autorelease];
	else
		self.navigationItem.rightBarButtonItem = nil;
}

- (void) goToCurrentSlide;
{
	if (self.currentLiveSlide)
		[self setDisplayedSlide:self.currentLiveSlide animated:YES];
}

- (void) goBack;
{
	if (!self.displayedSlide)
		return;
	
	SJSlide* s = self.displayedSlide;
	
	if (s.sortingOrderValue != 0) {
		
		SJSlide* backSlide = [SJSlide oneWithPredicate:
							  [NSPredicate predicateWithFormat:@"presentation == %@ && sortingOrder == %d", s.presentation, s.sortingOrderValue - 1]
										   fromContext:[self.displayedSlide managedObjectContext]];
		
		if (backSlide)
			[self setDisplayedSlide:backSlide animated:YES];
	}
}

- (void) goForward;
{
	if (!self.displayedSlide)
		return;
	
	SJSlide* s = self.displayedSlide;
	
	if (s.sortingOrderValue != s.presentation.knownCountOfSlidesValue - 1) {
		SJSlide* forwardSlide = [SJSlide oneWithPredicate:
							  [NSPredicate predicateWithFormat:@"presentation == %@ &&sortingOrder == %d", s.presentation, s.sortingOrderValue + 1]
										   fromContext:[self.displayedSlide managedObjectContext]];
		
		if (forwardSlide)
			[self setDisplayedSlide:forwardSlide animated:YES];
	}
}

#pragma mark Following a live

@synthesize liveSyncController;
- (void) setLiveSyncController:(SJLiveSyncController *) live;
{
	if (liveSyncController != live) {
		liveSyncController.delegate = nil;
		
		ILRetain(liveSyncController, live);
		
		liveSyncController.delegate = self;
	}
}

@synthesize managedObjectContext;

- (void) live:(SJLiveSyncController*) live didMoveToSlideAtURL:(NSURL*) url schema:(SJSlideSchema*) schema;
{
	if (!self.managedObjectContext)
		return;
	
	SJSlide* s = [SJSlide slideWithURL:url fromContext:self.managedObjectContext];
	if (s)
		self.currentLiveSlide = s;
	else {
		[live.syncCoordinator afterDownloadingNextSnapshotForEntityAtURL:url perform:^{
			
			SJSlide* s = [SJSlide slideWithURL:url fromContext:self.managedObjectContext];
			if (s)
				self.currentLiveSlide = s;
			
		}];
	}
}

@synthesize currentLiveSlide;
- (void) setCurrentLiveSlide:(SJSlide *) cls;
{
	if (cls != currentLiveSlide) {
		
		BOOL needsToChangeToNewSlide = !currentLiveSlide || [currentLiveSlide isEqual:self.displayedSlide];
		ILRetain(currentLiveSlide, cls);
		
		if (needsToChangeToNewSlide)
			[self setDisplayedSlide:cls animated:YES];
		
	}
}

#pragma mark Pose a question

@synthesize operationQueue;
- (NSOperationQueue *) operationQueue;
{
	if (!operationQueue)
		operationQueue = [NSOperationQueue new];
	
	return operationQueue;
}

@synthesize questionKindPicker;
- (SJQuestionKindPicker*) questionKindPicker;
{
	if (!questionKindPicker) {
		questionKindPicker = [[SJQuestionKindPicker alloc] init];
		
		questionKindPicker.didCancel = ^{
			NSIndexPath* path = [tableView indexPathForSelectedRow];
			if (path)
				[tableView deselectRowAtIndexPath:path animated:YES];
			
			[questionKindPicker dismissAnimated:YES];
		};
		
		questionKindPicker.rotateWithStatusBarOrientation = YES;
	}
	
	return questionKindPicker;
}

- (void) beginPosingQuestionForPoint:(SJPoint*) point;
{
	self.questionKindPicker.didPickQuestionKind = ^(NSString* kind) {
		[self poseQuestionOfKind:kind forPoint:point];
		[self.questionKindPicker dismissAnimated:YES];
	};
	
	[self.questionKindPicker showAnimated:YES];
}

- (void) poseQuestionOfKind:(NSString*) kind forPoint:(SJPoint*) point;
{
	void (^sendQuestion)(NSString*) = ^(NSString* text) {
		NSIndexPath* path = [tableView indexPathForSelectedRow];
		if (path)
			[tableView deselectRowAtIndexPath:path animated:YES];

		SJQuestion* question = [SJQuestion insertedInto:self.managedObjectContext];
		
		question.kind = kind;
		question.point = point;
		question.text = text;
		if ([self.managedObjectContext save:NULL])
			[question sendUsingQueue:self.operationQueue whenSent:NULL];
		else
			[self.managedObjectContext rollback];
	};
	
	if ([kind isEqual:kSJQuestionFreeformKind]) {
		
		SJPoseAQuestionPane* pane;
		UIViewController* modal = [SJPoseAQuestionPane modalPaneForViewController:&pane];
		
		pane.context = point.text;
		
		pane.didCancelHandler = ^{
			NSIndexPath* path = [tableView indexPathForSelectedRow];
			if (path)
				[tableView deselectRowAtIndexPath:path animated:YES];

			[pane dismissModalViewControllerAnimated:YES];
		};
		
		pane.didAskQuestionHandler = ^(NSString* questionText) {
			sendQuestion(questionText);
			[pane dismissModalViewControllerAnimated:YES];
		};
		
		[self presentModalViewController:modal animated:YES];
		
	} else {
		sendQuestion(nil);
	}
}

- (void) tableView:(UITableView*) tv didSelectRowAtIndexPath:(NSIndexPath*) indexPath;
{
	SJPointTableViewCell* pointCell = (SJPointTableViewCell*) [tv cellForRowAtIndexPath:indexPath];
	
	SJPoint* p = pointCell.point;
	[self beginPosingQuestionForPoint:p];
	
	[tv scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark Send a mood

@synthesize moodPicker;
- (SJMoodPicker*) moodPicker;
{
	if (!moodPicker) {
		moodPicker = [[SJMoodPicker alloc] init];
		
		moodPicker.didCancel = ^{
			NSIndexPath* path = [tableView indexPathForSelectedRow];
			if (path)
				[tableView deselectRowAtIndexPath:path animated:YES];
			
			[moodPicker dismissAnimated:YES];
		};
		
		moodPicker.rotateWithStatusBarOrientation = YES;
	}
	
	return moodPicker;
}

- (IBAction) sendMoodForCurrentSlide;
{
	self.moodPicker.didPickMood = ^(NSString* mood) {
		[self.moodPicker dismissAnimated:YES];
		
		moodSendProgressView.hidden = YES;
		moodSendProgressView.alpha = 1.0;
		
		moodSendLabel.hidden = YES;
		moodSendSpinner.hidden = NO;
		[moodSendSpinner startAnimating];
		
		CGPoint from = CGPointMake(0, CGRectGetMaxY(tableView.bounds));
		CGPoint to = from;
		to.y -= moodSendProgressView.frame.size.height;
		
		CGRect frame = moodSendProgressView.frame;
		
		frame.origin = from;
		moodSendProgressView.frame = frame;
		moodSendProgressView.hidden = NO;
		
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 CGRect f = frame;
							 f.origin = to;
							 moodSendProgressView.frame = f;
						 }
						 completion:NULL];
		
		[self.displayedSlide sendMoodOfKind:mood usingQueue:self.operationQueue whenSent:^(BOOL done) {
			
			if (!done) {
				[UIView animateWithDuration:0.2
								 animations:^{
									 moodSendProgressView.alpha = 0.0;
								 }
								 completion:^(BOOL done) {
									 [moodSendSpinner stopAnimating];
									 moodSendProgressView.hidden = YES;
								 }];
			} else {
				moodSendLabel.alpha = 0.0;
				moodSendLabel.hidden = NO;
				
				[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
								 animations:^{
									 moodSendLabel.alpha = 1.0;
									 moodSendSpinner.alpha = 0.0;
								 }
								 completion:^(BOOL finished) {
									 [moodSendSpinner stopAnimating];

									 [UIView animateWithDuration:0.4 delay:1.0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
													  animations:^{
														  moodSendProgressView.frame = frame;
													  }
													  completion:^(BOOL finished) {
														  moodSendProgressView.hidden = YES;
													  }];
									 
								 }];
			}
		}];
	};
	
	[self.moodPicker showAnimated:YES];
}

#pragma mark Slide image display

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) to duration:(NSTimeInterval)duration;
{
	rotatedToOrientation = to;
	
	if (UIInterfaceOrientationIsLandscape(to)) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self.navigationController setNavigationBarHidden:YES];
		[self.navigationController setToolbarHidden:YES];
		
		slideImageOverlay.hidden = NO;
		slideImageOverlay.userInteractionEnabled = YES;

		[UIView animateWithDuration:duration animations:^{
			slideImageOverlay.alpha = 1.0;
		}];
		
		[self updateSlideImageWithAnimation:kSJPresentationMoveAnimationKindNone];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

		slideImageOverlay.userInteractionEnabled = NO;

		[UIView animateWithDuration:duration animations:^{
			slideImageOverlay.alpha = 0.0;
		}];
	}
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) from;
{
	if (UIInterfaceOrientationIsPortrait(rotatedToOrientation)) {
		slideImageOverlay.hidden = YES;
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		[self.navigationController setToolbarHidden:NO animated:YES];
	}
}

- (void) updateSlideImageWithAnimation:(SJPresentationMoveAnimationKind) ani;
{
	if (self.displayedSlide) {
		NSData* d = self.displayedSlide.imageData;
		if (d) {
			[slideImageLoadSpinner stopAnimating];
			slideImageView.image = [UIImage imageWithData:d];
		} else {
			[slideImageLoadSpinner startAnimating];
			slideImageView.image = nil;
		}
	}
}

#pragma mark Live methods we don't use

- (void) liveDidStart:(SJLiveSyncController*) observer;
{
	/* This method intentionally left blank. */
}

- (void) liveDidEnd:(SJLiveSyncController*) observer;
{
	/* This method intentionally left blank. */
}

- (void) live:(SJLiveSyncController*) observer didPostQuestionsAtURLs:(NSSet*) urls;
{
	/* This method intentionally left blank. */
}

- (void) live:(SJLiveSyncController*) observer didPostMoodsAtURLs:(NSSet*) urls;
{
	/* This method intentionally left blank. */
}

- (void) live:(SJLiveSyncController*) observer didFailToLoadWithError:(NSError*) e;
{
	/* This method intentionally left blank. */
}

@end
