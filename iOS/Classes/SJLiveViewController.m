//
//  SJLiveViewController.m
//  Subject
//
//  Created by ∞ on 23/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJLiveViewController.h"
#import "SJSlide.h"
#import "SJPoint.h"
#import "SJPresentation.h"

#import <QuartzCore/QuartzCore.h>

@interface SJLiveViewController ()

@property(retain) SJLive* live;
@property(retain) SJSlide* currentSlide;

- (void) setUpObserving;
- (void) endObserving;



@end


@implementation SJLiveViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
		[self setUpObserving];
	
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder;
{
	if ((self = [super initWithCoder:aDecoder]))
		[self setUpObserving];
	
	return self;
}

- (void) dealloc
{
	[self endObserving];
	self.managedObjectContext = nil;
	self.endpoint = nil;
	self.live = nil;
	[super dealloc];
}


@synthesize live, endpoint, managedObjectContext, currentSlide;

- (void) setUpObserving;
{
	[self addObserver:self forKeyPath:@"managedObjectContext" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"endpoint" options:0 context:NULL];
}

- (void) endObserving;
{
	[self removeObserver:self forKeyPath:@"managedObjectContext"];
	[self removeObserver:self forKeyPath:@"endpoint"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if (self.managedObjectContext && self.endpoint && [self isViewLoaded])
		self.live = [[[SJLive alloc] initWithEndpoint:self.endpoint delegate:self managedObjectContext:self.managedObjectContext] autorelease];
	else {
		[self.live stop];
		self.live.delegate = nil;
		self.live = nil;
	}
}

- (void) viewDidLoad;
{
	if (!self.live && self.managedObjectContext && self.endpoint)
		self.live = [[[SJLive alloc] initWithEndpoint:self.endpoint delegate:self managedObjectContext:self.managedObjectContext] autorelease];
	
	tableView.dataSource = self;
	tableView.delegate = self;
}

- (void) viewDidUnload;
{
	tableView.delegate = nil;
	tableView.dataSource = nil;
	[tableView release]; tableView = nil;
	
	[spinner release]; spinner = nil;
	
	[self.live stop];
	self.live.delegate = nil;
	self.live = nil;	
}

/* <#TODO#> Support forward/back */

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

- (void) live:(SJLive *)live didMoveToSlide:(SJSlide *)slide;
{
	BOOL goLeft = !self.currentSlide || self.currentSlide.sortingOrderValue < slide.sortingOrderValue;
	
	CATransition* animation = [CATransition animation];
	animation.type = kCATransitionPush;
	animation.subtype = goLeft? kCATransitionFromRight : kCATransitionFromLeft;
	animation.duration = 0.4;
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	
	[tableHostView.layer addAnimation:animation forKey:@"SJSlideChangeTransition"];
	
	self.currentSlide = slide;
	[tableView reloadData];
	[spinner stopAnimating];
}

- (void) live:(SJLive *)live willBeginMovingToSlideAtURL:(NSURL *)slideURL;
{
	[spinner startAnimating];
}

- (void) liveDidEnd:(SJLive *)live;
{
	self.title = @"";
	self.navigationItem.title = @"";
	
	self.currentSlide = nil;
	[tableView reloadData];
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
	
#define kSJLiveViewCell @"SJLiveViewCell"
	
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kSJLiveViewCell];
	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSJLiveViewCell] autorelease];
	
	cell.textLabel.text = (p.indentationValue == 0)? p.text : [NSString stringWithFormat:@"%C %@", 0x2022, p.text];
	
	return cell;
}

@end

