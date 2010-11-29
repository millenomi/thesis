//
//  SJLiveViewController.m
//  Subject
//
//  Created by ∞ on 23/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPresentationPane.h"
#import "SJSlide.h"
#import "SJPoint.h"
#import "SJPresentation.h"

#import "SJPoseAQuestionPane.h"
#import "SJPointTableViewCell.h"

#import "ILViewAnimationTools.h"
#import "ILGrowFromPointChoreography.h"

#import <QuartzCore/QuartzCore.h>

@interface SJPresentationPane ()

@property(retain) SJLive* live;
@property(retain) SJSlide* currentSlide;

- (void) setUpObserving;
- (void) endObserving;

@property(retain) SJPoint* askQuestionSheetPoint;
@property(retain) SJSlide* lastLiveSlide;

- (void) moveToSlideInDirection:(int)direction;

- (void) updateCurrentSlideUIFromPreviousSlide:(SJSlide*) old;

@end


@implementation SJPresentationPane

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		// self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@":) :(", @"Emoticon label for mood button in presentation view") style:UIBarButtonItemStyleBordered target:nil action:NULL] autorelease];
		
		[self setUpObserving];
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder;
{
	if ((self = [super initWithCoder:aDecoder])) {
		// self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@":) :(", @"Emoticon label for mood button in presentation view") style:UIBarButtonItemStyleBordered target:nil action:NULL] autorelease];

		[self setUpObserving];
	}
	
	return self;
}

- (void) dealloc
{
	[self endObserving];
	self.managedObjectContext = nil;
	self.endpoint = nil;
	
	[super dealloc];
}


@synthesize live, endpoint, managedObjectContext, currentSlide, lastLiveSlide;

- (void) setUpObserving;
{
	[self addObserver:self forKeyPath:@"managedObjectContext" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"endpoint" options:0 context:NULL];
	
	[self addObserver:self forKeyPath:@"live" options:0 context:NULL];
	
	[self addObserver:self forKeyPath:@"currentSlide" options:NSKeyValueObservingOptionOld context:NULL];
	[self addObserver:self forKeyPath:@"lastLiveSlide" options:NSKeyValueObservingOptionOld context:NULL];
}

- (void) endObserving;
{
	[self removeObserver:self forKeyPath:@"managedObjectContext"];
	[self removeObserver:self forKeyPath:@"endpoint"];

	[self removeObserver:self forKeyPath:@"live"];

	[self removeObserver:self forKeyPath:@"currentSlide"];
	[self removeObserver:self forKeyPath:@"lastLiveSlide"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if ([keyPath isEqual:@"managedObjectContext"] || [keyPath isEqual:@"endpoint"]) {
	
		if (!self.live && self.managedObjectContext && self.endpoint && [self isViewLoaded]) {
			self.live = [[[SJLive alloc] initWithEndpoint:self.endpoint delegate:self managedObjectContext:self.managedObjectContext] autorelease];
		} else if (self.live && (!self.managedObjectContext || !self.endpoint)) {
			[self.live stop];
			self.live.delegate = nil;
			self.live = nil;
			self.lastLiveSlide = nil;
			self.navigationItem.rightBarButtonItem = nil;
		}
		
	}
	
	if ([keyPath isEqual:@"currentSlide"] || [keyPath isEqual:@"lastLiveSlide"]) {
		id slide = [change objectForKey:NSKeyValueChangeOldKey];
		if (slide == [NSNull null])
			slide = nil;
		
		[self updateCurrentSlideUIFromPreviousSlide:slide];
	}
	
	if ([keyPath isEqual:@"lastLiveSlide"])
		moodToolbarItem.enabled = (self.lastLiveSlide && self.currentSlide && self.live);
}

- (void) updateCurrentSlideUIFromPreviousSlide:(SJSlide*) oldSlide;
{
	if (self.currentSlide) {
		
		backToolbarItem.enabled = [SJSlide countForFetchRequestWithProperties:^(NSFetchRequest *r) {
			
			r.predicate = [NSPredicate predicateWithFormat:@"presentation == %@ && sortingOrder < %@", self.currentSlide.presentation, self.currentSlide.sortingOrder];
			r.fetchLimit = 1;
			
		} fromContext:self.managedObjectContext] > 0;
		
		forwardToolbarItem.enabled = [SJSlide countForFetchRequestWithProperties:^(NSFetchRequest *r) {
			
			r.predicate = [NSPredicate predicateWithFormat:@"presentation == %@ && sortingOrder > %@", self.currentSlide.presentation, self.currentSlide.sortingOrder];
			r.fetchLimit = 1;
			
		} fromContext:self.managedObjectContext] > 0;
		
		if ([self isViewLoaded]) {
			BOOL goLeft = !(!self.currentSlide || !oldSlide || self.currentSlide.sortingOrderValue < oldSlide.sortingOrderValue);
			
			CATransition* animation = [CATransition animation];
			animation.type = kCATransitionPush;
			animation.subtype = goLeft? kCATransitionFromRight : kCATransitionFromLeft;
			animation.duration = 0.4;
			animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			[tableHostView.layer addAnimation:animation forKey:@"SJSlideChangeTransition"];
			
			[tableView reloadData];
			[spinner stopAnimating];
		}
	} else {
		backToolbarItem.enabled = NO;
		forwardToolbarItem.enabled = NO;
		self.navigationItem.rightBarButtonItem = nil;
	}
	
	if (self.currentSlide && self.lastLiveSlide && ![self.currentSlide isEqual:self.lastLiveSlide]) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FastForwardArrowToolbarIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(moveToLastSlide)] autorelease];	
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	moodToolbarItem.enabled = NO;
	
	if (!self.live && self.managedObjectContext && self.endpoint) {
		self.live = [[[SJLive alloc] initWithEndpoint:self.endpoint delegate:self managedObjectContext:self.managedObjectContext] autorelease];
	}
	
	if (toolbarWithOurItems) {
		NSArray* items = [[[toolbarWithOurItems items] copy] autorelease];
		toolbarWithOurItems.items = [NSArray array];
		self.toolbarItems = items;
	}
	
	tableView.dataSource = self;
	tableView.delegate = self;
	
	actionViewCancelButton.backgroundImageCaps = CGSizeMake(16, 0);
	
	[self updateCurrentSlideUIFromPreviousSlide:nil];
}

- (void) viewWillAppear:(BOOL)animated;
{
	[self.navigationController setToolbarHidden:NO animated:animated];
}

- (void) clearOutlets;
{
	[super clearOutlets];
	
	tableView.delegate = nil;
	tableView.dataSource = nil;
	[tableView release]; tableView = nil;
	
	[spinner release]; spinner = nil;
	
	[actionViewCancelButton release]; actionViewCancelButton = nil;
	[questionActionView release]; questionActionView = nil;
	
	[fauxActionSheet dismissAnimated:NO];
	fauxActionSheet.coverDelegate = nil;
	[fauxActionSheet release]; fauxActionSheet = nil;
	
	[backToolbarItem release]; backToolbarItem = nil;
	[forwardToolbarItem release]; forwardToolbarItem = nil;
	[moodToolbarItem release]; moodToolbarItem = nil;
	
	[self.live stop];
	self.live.delegate = nil;
	self.live = nil;
	self.lastLiveSlide = nil;
	self.navigationItem.rightBarButtonItem = nil;
	
	moodPicker.moodPickerDelegate = nil;
	moodPicker.coverDelegate = nil;
	[moodPicker release]; moodPicker = nil;
}

- (void) live:(SJLive *)live willBeginRunningPresentationAtURL:(NSURL *)presURL slideURL:(NSURL *)slideURL;
{
	self.currentSlide = nil;
	[tableView reloadData];
	[spinner startAnimating];
}

- (void) live:(SJLive *)live didFetchRunningPresentation:(SJPresentation *)pres;
{
	self.title = pres.title;
	self.navigationItem.title = self.title;
}

- (void) live:(SJLive*) live didMoveToSlide:(SJSlide*) slide fromSlide:(SJSlide*) previousSlide;
{
	BOOL shouldMove = !self.currentSlide || [previousSlide isEqual:self.currentSlide];
	
	if (!shouldMove)
		return;
	
	self.currentSlide = slide;
	self.lastLiveSlide = slide;
}

- (void) live:(SJLive *)live willBeginMovingToSlideAtURL:(NSURL *)slideURL;
{
	[spinner startAnimating];
}

- (void) liveDidEnd:(SJLive *)live;
{
	self.lastLiveSlide = nil;
}


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView;
{
	return 1;
}

- (NSInteger) tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section;
{
	if (self.currentSlide)
		return [[self.currentSlide points] count];
	else
		return 0;
}

- (NSInteger) tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	SJPoint* p = [self.currentSlide pointAtIndex:[indexPath row]];
	return p.indentationValue;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	SJPoint* p = [self.currentSlide pointAtIndex:[indexPath row]];
	SJPointTableViewCell* cell = (SJPointTableViewCell*)
		[tableView dequeueReusableCellWithIdentifier:[SJPointTableViewCell reuseIdentifier]];
	
	if (!cell)
		cell = [[[SJPointTableViewCell alloc] init] autorelease];
	
	cell.point = p;
	
	return cell;
}

- (CGFloat) tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	SJPoint* p = [self.currentSlide pointAtIndex:[indexPath row]];
	return [SJPointTableViewCell cellHeightForPoint:p width:tableView.bounds.size.width];
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	self.askQuestionSheetPoint = [self.currentSlide pointAtIndex:[indexPath row]];
	if (!self.askQuestionSheetPoint)
		return;
	
	if (!fauxActionSheet) {
		fauxActionSheet = [[ILCoverWindow alloc] initWithContentView:questionActionView];
		fauxActionSheet.coverDelegate = self;
		fauxActionSheet.contentViewInsets = UIEdgeInsetsMake(25, 0, 0, 0);
	}
	
	[fauxActionSheet showAnimated:YES];
}

- (void) viewWillDisappear:(BOOL)animated;
{
	[fauxActionSheet dismissAnimated:animated];
	[moodPicker dismissAnimated:animated];
}

- (void) live:(SJLive *)live didUpdateCurrentSlide:(SJSlide *)slide;
{
	[[tableView visibleCells] makeObjectsPerformSelector:@selector(update)];
}

#pragma mark Question sheet

@synthesize askQuestionSheetPoint;

- (IBAction) cancelQuestionSheet;
{
	[fauxActionSheet dismissAnimated:YES];
}

- (IBAction) askDidNotUnderstandQuestion;
{
	[self.live askQuestionOfKind:kSJQuestionDidNotUnderstandKind forPoint:self.askQuestionSheetPoint];
	[fauxActionSheet dismissAnimated:YES];
}

- (IBAction) askGoInDepthQuestion;
{
	[self.live askQuestionOfKind:kSJQuestionGoInDepthKind forPoint:self.askQuestionSheetPoint];
	[fauxActionSheet dismissAnimated:YES];
}

- (IBAction) askFreeformQuestion;
{
	SJPoint* p = self.askQuestionSheetPoint;
	
	SJPoseAQuestionPane* pane;
	UIViewController* modal = [SJPoseAQuestionPane modalPaneForViewController:&pane];
	pane.context = p.text;
	
	pane.didAskQuestionHandler = ^(NSString* questionText) {
		[self.live askFreeformQuestion:questionText forPoint:p];
		[pane dismissModalViewControllerAnimated:YES];
	};
	
	pane.didCancelHandler = ^() {
		[pane dismissModalViewControllerAnimated:YES];		
	};
	
	[self presentModalViewController:modal animated:YES];
	[fauxActionSheet dismissAnimated:YES];
}

- (void) viewDidAppear:(BOOL)animated;
{
	[super viewDidAppear:animated];
	originalTableViewFrame = tableView.frame;
}

- (void) coverWindow:(ILCoverWindow *)window willAppearWithAnimationDuration:(CGFloat)duration curve:(UIViewAnimationCurve)curve finalContentViewFrame:(CGRect)frame;
{
	if (window != fauxActionSheet)
		return;
	
	[UIView animateWithDuration:duration delay:0
						options:ILViewAnimationOptionsForCurve(curve) | UIViewAnimationOptionAllowUserInteraction
					 animations:^{
						 
						 CGRect contentViewFrameInSelf = [self.view convertRect:frame fromView:window];
						 
						 CGRect f = originalTableViewFrame;
						 f.size.height = contentViewFrameInSelf.origin.y;
						 tableView.frame = f;
					 }
					 completion:^(BOOL done) {
						 NSIndexPath* indexPath = [tableView indexPathForSelectedRow];
						 if (indexPath)
							 [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
					 }];
}

- (void) coverWindowWillDismiss:(ILCoverWindow *)window;
{
	if (window != fauxActionSheet)
		return;
	
	NSIndexPath* indexPath = [tableView indexPathForSelectedRow];
	if (indexPath)
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	tableView.frame = originalTableViewFrame;
}

- (void) coverWindowDidDismiss:(ILCoverWindow *)window;
{
	if (window != fauxActionSheet)
		return;
	
	self.askQuestionSheetPoint = nil;
}

- (void) live:(SJLive *)live didDownloadQuestion:(SJQuestion *)q;
{
	[[tableView visibleCells] makeObjectsPerformSelector:@selector(updateWithAddedQuestion:) withObject:q];
}

#define kSJPresentationDirectionNext 0
#define kSJPresentationDirectionPrevious 1
// #define kSJPresentationDirectionLast 2

- (IBAction) moveToNextSlide;
{
	[self moveToSlideInDirection:kSJPresentationDirectionNext];
}

- (void) moveToSlideInDirection:(int) direction;
{
	if (!self.currentSlide)
		return;
	
	SJSlide* newSlide = [[SJSlide resultOfFetchRequestWithProperties:^(NSFetchRequest* r) {

		if (direction == kSJPresentationDirectionNext)
			r.predicate = [NSPredicate predicateWithFormat:@"presentation == %@ && sortingOrder > %@", self.currentSlide.presentation, self.currentSlide.sortingOrder];
		else if (direction == kSJPresentationDirectionPrevious)
			r.predicate = [NSPredicate predicateWithFormat:@"presentation == %@ && sortingOrder < %@", self.currentSlide.presentation, self.currentSlide.sortingOrder];
		else
			r.predicate = [NSPredicate predicateWithFormat:@"presentation == %@", self.currentSlide.presentation];
		
		r.sortDescriptors = [NSArray arrayWithObject:
							 [[[NSSortDescriptor alloc] initWithKey:@"sortingOrder" ascending:(direction == kSJPresentationDirectionNext)] autorelease]
							 ];
		r.fetchLimit = 1;
		
	} fromContext:self.managedObjectContext] singleContainedObject];
	
	if (newSlide)
		self.currentSlide = newSlide;
	
}

- (IBAction) moveToPreviousSlide;
{
	[self moveToSlideInDirection:kSJPresentationDirectionPrevious];
}

- (IBAction) moveToLastSlide;
{
	if (self.lastLiveSlide)
		self.currentSlide = self.lastLiveSlide;
}

#pragma mark Mood reporting

- (IBAction) reportMood;
{
	if (!self.live)
		return;
	
	if (!moodPicker) {
		moodPicker = [SJMoodPicker new];
		moodPicker.moodPickerDelegate = self;
		moodPicker.coverDelegate = self;
	}
	
	[moodPicker showAnimated:YES];
}

- (void) moodPicker:(SJMoodPicker *)picker didPickMood:(NSString *)mood;
{
	[self.live reportMoodOfKind:mood forSlide:self.currentSlide];
	[picker dismissAnimated:YES];
}

- (void) moodPickerDidCancel:(SJMoodPicker *)picker;
{
	[picker dismissAnimated:YES];
}

- (void) didReceiveMemoryWarning;
{
	[super didReceiveMemoryWarning];
	
	if (moodPicker.hidden) {
		moodPicker.moodPickerDelegate = nil;
		moodPicker.coverDelegate = nil;
		[moodPicker release]; moodPicker = nil;
	}
	
	if (fauxActionSheet.hidden) {
		fauxActionSheet.coverDelegate = nil;
		[fauxActionSheet release]; fauxActionSheet = nil;
	}
}

@end

