//
//  SJLive.m
//  Subject
//
//  Created by ∞ on 21/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJLive.h"
#import "SJPresentation.h"
#import "SJSlide.h"

#import "SJLiveSchema.h"
#import "SJPresentationSchema.h"
#import "SJSlideSchema.h"
#import "SJPointSchema.h"

#import "ILSensorSink.h"

#define kSJLiveRelativeURLString @"/live"

@interface SJLive ()

@property(retain) NSTimer* timer;

@property(retain) SJEndpoint* endpoint;
@property(copy) NSURL* presentationURL;
@property(copy) NSURL* slideURL;
@property(retain) NSManagedObjectContext* managedObjectContext;

- (void) performLiveHeartbeat;

- (void) beginPresentationWithURL:(NSURL *)p slideURL:(NSURL *)s;
- (void) endPresentation;
- (void) moveToSlideWithURL:(NSURL *)s;

- (SJSlide *) storeSlideDownloadedByRequest:(id <SJRequest>)req;
- (SJPresentation *) storePresentationDownloadedByRequest:(id <SJRequest>)req;

@end


@implementation SJLive

- (id) initWithEndpoint:(SJEndpoint*) endpoint delegate:(id <SJLiveDelegate>) delegate managedObjectContext:(NSManagedObjectContext*) moc;
{
	if ((self = [super init])) {
		self.endpoint = endpoint;
		self.managedObjectContext = moc;
		unassignedSlides = [NSMutableSet new];
		
		self.delegate = delegate;

		// TODO flexible rhythm
		[self performLiveHeartbeat];
		self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(performLiveHeartbeat) userInfo:nil repeats:YES];
	}
	
	return self;
}

- (void) dealloc
{
	self.endpoint = nil;
	self.presentationURL = nil;
	self.slideURL = nil;
	self.managedObjectContext = nil;
	[unassignedSlides release];
	
	[super dealloc];
}

@synthesize endpoint, delegate, presentationURL, slideURL, timer, managedObjectContext;


- (void) stop;
{
	[self.delegate liveDidEnd:self];
	[self.timer invalidate];
	self.timer = nil;
	self.delegate = nil;
	self.endpoint = nil;
	self.presentationURL = nil;
	self.slideURL = nil;
	[unassignedSlides removeAllObjects];
}

- (void) performLiveHeartbeat;
{
	if (isWaitingOnHeartbeatRequest)
		return;
	
	isWaitingOnHeartbeatRequest = YES;
	
	id <SJRequest> request =
	[self.endpoint requestForDownloadingFromURL:kSJLiveRelativeURLString completionHandler:^(id <SJRequest> r) {
		
		if (!self.endpoint)
			return;
		
		NSError* e;
		SJLiveSchema* live = [r JSONValueWithSchema:[SJLiveSchema class] error:&e];
		
		if (live) {
			
			NSURL* newSlideURL = live.slide.URLString? [self.endpoint URL:live.slide.URLString] : nil;
			NSURL* newPresentationURL = live.slide.presentationURLString? [self.endpoint URL:live.slide.presentationURLString] : nil;
			
			if (newPresentationURL && (!self.presentationURL || ![self.presentationURL isEqual:newPresentationURL])) {
				
				// a new presentation started
				[self beginPresentationWithURL:newPresentationURL slideURL:newSlideURL];
				
			} else if (!newPresentationURL && self.presentationURL) {
				
				// the presentation ended
				[self endPresentation];
				
			} else if (newSlideURL && ![newSlideURL isEqual:self.slideURL]) {
				
				// same presentation, slide change
				[self moveToSlideWithURL:newSlideURL];
				
			}
			
		} else
			[self endPresentation];
		
		isWaitingOnHeartbeatRequest = NO;
		
	}];	
	
	[request setShouldNotLog];
	[request start];
}

- (void) beginPresentationWithURL:(NSURL*) p slideURL:(NSURL*) s;
{
	if (self.presentationURL)
		[self endPresentation];
	
	self.presentationURL = p;
	self.slideURL = s;
	
	[self.delegate live:self willBeginRunningPresentationAtURL:p slideURL:s];
	
	id <SJRequest> presentationReq =
	[self.endpoint requestForDownloadingFromURL:p completionHandler:^(id <SJRequest> req) {
		
		if (req.error || !req.JSONValue)
			return; // <#TODO#>
		
		SJPresentation* presentation = [self storePresentationDownloadedByRequest:req];
		
		if (presentation) {
			for (SJSlide* s in unassignedSlides)
				s.presentation = presentation;
			
			[unassignedSlides removeAllObjects];
			
			[self.delegate live:self didFetchRunningPresentation:presentation];
		}
	}];
	
	id <SJRequest> slideReq =
	[self.endpoint requestForDownloadingFromURL:s completionHandler:^(id <SJRequest> req) {
	
		if (req.error || !req.JSONValue)
			return; // <#TODO#>
		
		SJSlide* slide = [self storeSlideDownloadedByRequest:req];
		
		if (slide)
			[self.delegate live:self didMoveToSlide:slide];
		
		[[ILSensorSink sharedSink] setEnabled:NO];

	}];
	
	[presentationReq start];
	[slideReq start];
}

- (SJPresentation*) storePresentationDownloadedByRequest:(id <SJRequest>) req;
{
	SJPresentationSchema* pres = [req JSONValueWithSchema:[SJPresentationSchema class] error:NULL];
	
	if (!pres)
		return nil;
	
	SJPresentation* p = [SJPresentation presentationWithURL:req.URL fromContext:self.managedObjectContext];
	
	if (!p)
		p = [SJPresentation insertedInto:self.managedObjectContext];
	
	p.URL = req.URL;
	p.title = pres.title;
	
	if (![self.managedObjectContext save:NULL]) {
		[self.managedObjectContext rollback];
		return nil;
	} else
		return p;
}

- (SJSlide*) storeSlideDownloadedByRequest:(id <SJRequest>) req;
{
	SJSlideSchema* slide = [req JSONValueWithSchema:[SJSlideSchema class] error:NULL];
	NSURL* url = [self.endpoint URL:slide.presentationURLString];
	
	if (!slide)
		return nil;
	
	SJSlide* s = [SJSlide slideWithURL:req.URL fromContext:self.managedObjectContext];
	SJPresentation* p = [SJPresentation presentationWithURL:url fromContext:self.managedObjectContext];
	
	if (!s)
		s = [SJSlide insertedInto:self.managedObjectContext];
	
	s.URL = req.URL;
	
	if (p)
		s.presentation = p;
	else
		[unassignedSlides addObject:s];
	
	s.sortingOrder = slide.sortingOrder;
	
	NSSet* oldPoints = [[s.points copy] autorelease];
	for (SJPoint* pt in oldPoints)
		[[pt managedObjectContext] deleteObject:pt];

	NSMutableSet* newPoints = [NSMutableSet set];
	
	NSInteger i = 0;
	for (SJPointSchema* point in slide.points) {
		SJPoint* pt = [SJPoint insertedInto:self.managedObjectContext];
		pt.sortingOrderValue = i;
		pt.text = point.text;
		pt.indentation = point.indentation;

		
		[newPoints addObject:pt];
		i++;
	}
	
	s.points = newPoints;
	
	if (![self.managedObjectContext save:NULL]) {
		[self.managedObjectContext rollback];
		return nil;
	} else
		return s;
}

- (void) endPresentation;
{
	if (self.presentationURL)
		[self.delegate liveDidEnd:self];
	
	self.presentationURL = nil;
	self.slideURL = nil;
	
	if ([unassignedSlides count] > 0) {
		for (SJSlide* s in unassignedSlides)
			[self.managedObjectContext deleteObject:s];
		
		[unassignedSlides removeAllObjects];
		
		[self.managedObjectContext save:NULL];
	}
}

- (void) moveToSlideWithURL:(NSURL*) s;
{
	if (!self.presentationURL)
		return;
	
	self.slideURL = s;
	
	[self.endpoint beginDownloadingFromURL:s completionHandler:^(id <SJRequest> req) {
		
		if (req.error || !req.JSONValue)
			return; // <#TODO#>
		
		SJSlide* slide = [self storeSlideDownloadedByRequest:req];
		
		if (slide)
			[self.delegate live:self didMoveToSlide:slide];
		
	}];
}

@end
