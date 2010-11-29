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
#import "SJQuestion.h"

#import "SJLiveSchema.h"
#import "SJPresentationSchema.h"
#import "SJSlideSchema.h"
#import "SJPointSchema.h"
#import "SJQuestionSchema.h"

#import "ILSensorSink.h"

#import "NSURL+ILURLParsing.h"

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

@property(retain) SJLiveSchema* schema;
- (void) checkForUpdateWithNewSchema:(SJLiveSchema *)s;

- (SJQuestion *) storeQuestionDownloadedByRequest:(id <SJRequest>)r forPointWithURL:(NSURL *)url;
- (SJQuestion *) storeQuestionDownloadedByRequest:(id <SJRequest>)r forPoint:(SJPoint *)pt;

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
			
			if (newPresentationURL && (!self.presentationURL || ![[self.presentationURL absoluteURL] isEqual:[newPresentationURL absoluteURL]])) {
				
				// a new presentation started
				[self beginPresentationWithURL:newPresentationURL slideURL:newSlideURL];
				
			} else if (!newPresentationURL && self.presentationURL) {
				
				// the presentation ended
				[self endPresentation];
				
			} else if (newSlideURL && ![newSlideURL isEqual:self.slideURL]) {
				
				// same presentation, new slide
				[self moveToSlideWithURL:newSlideURL];
				
			}
			
			[self checkForUpdateWithNewSchema:live];
			
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
			[self.delegate live:self didMoveToSlide:slide fromSlide:nil];
		
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
	SJSlideSchema* slideSchema = [req JSONValueWithSchema:[SJSlideSchema class] error:NULL];
	NSURL* url = [self.endpoint URL:slideSchema.presentationURLString];
	
	if (!slideSchema)
		return nil;
	
	SJSlide* s = [SJSlide slideWithURL:req.URL fromContext:self.managedObjectContext];
	SJPresentation* p = [SJPresentation presentationWithURL:url fromContext:self.managedObjectContext];
	
	if (!s)
		s = [SJSlide insertedInto:self.managedObjectContext];
	
	NSURL* newSlideURL = req.URL;
	s.URL = newSlideURL;
	
	if (p)
		s.presentation = p;
	else
		[unassignedSlides addObject:s];
	
	s.sortingOrder = slideSchema.sortingOrder;
		
	NSInteger i = 0;
	for (SJPointSchema* pointSchema in slideSchema.points) {
		SJPoint* pt = [SJPoint oneWithPredicate:[NSPredicate predicateWithFormat:@"URLString == %@", pointSchema.URLString] fromContext:self.managedObjectContext];
		
		if (!pt)
			pt = [SJPoint insertedInto:self.managedObjectContext];
		
		pt.sortingOrderValue = i;
		pt.text = pointSchema.text;
		pt.indentation = pointSchema.indentation;
		pt.URLString = pointSchema.URLString;
		
		for (NSString* questionURLString in pointSchema.questionURLStrings) {
			[self.endpoint beginDownloadingFromURL:questionURLString completionHandler:^(id <SJRequest> r) {
				[self storeQuestionDownloadedByRequest:r forPointWithURL:pt.URL];
			}];
		}
				
		for (SJQuestion* q in [SJQuestion allWithPredicate:[NSPredicate predicateWithFormat:@"point == %@ AND NOT (URLString IN %@)", pt, pointSchema.questionURLStrings] fromContext:self.managedObjectContext]) {
			
			[pt removeQuestionsObject:q];
			[self.managedObjectContext deleteObject:q];
		}
		
		[s addPointsObject:pt];
		
		i++;
	}
	
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
	self.schema = nil;
	
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
	
	NSURL* previousSlideURL = self.slideURL;
	self.slideURL = s;
	
	[self.endpoint beginDownloadingFromURL:s completionHandler:^(id <SJRequest> req) {
		
		if (req.error || !req.JSONValue)
			return; // <#TODO#>
		
		SJSlide* slide = [self storeSlideDownloadedByRequest:req];
		
		SJSlide* previousSlide = [SJSlide slideWithURL:previousSlideURL fromContext:self.managedObjectContext];
		
		if (slide)
			[self.delegate live:self didMoveToSlide:slide fromSlide:previousSlide];
		
	}];	
}

- (void) checkForUpdateWithNewSchema:(SJLiveSchema*) s;
{
	if (!self.schema) {
		self.schema = s;
		return;
	}
	
	if (![self.schema isEqual:s] && self.slideURL) {
		// the slide schema was updated (eg new questions)! redownload!
		
		[self.endpoint beginDownloadingFromURL:self.slideURL completionHandler:^(id <SJRequest> req) {
			
			if (req.error || !req.JSONValue)
				return; // <#TODO#>
			
			SJSlide* slide = [self storeSlideDownloadedByRequest:req];
			
			if (slide)
				[self.delegate live:self didUpdateCurrentSlide:slide];
						
		}];
		
	}
	
	self.schema = s;
}

@synthesize schema;

#pragma mark Asking questions

- (void) askQuestionOfKind:(NSString*) kind forPoint:(SJPoint*) point;
{
	// TODO URL generation does not belong here methinks.
	NSString* URLString = [NSString stringWithFormat:@"%@/points/%@/new_question", point.slide.URLString, point.sortingOrder];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[self.endpoint URL:URLString]];
	[req setValue:@"application/x-www-form-urlencoded;encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSDictionary* formData = [NSDictionary dictionaryWithObject:kind forKey:@"kind"];
	[req setHTTPBody:[[formData queryString] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPMethod:@"POST"];
	
	[[self.endpoint requestFromURLRequest:req completionHandler:^(id <SJRequest> finalReq) {
		
		ILLog(@"Did finish URL request for asking question of kind %@", kind);
		
		[self storeQuestionDownloadedByRequest:finalReq forPoint:nil];
		
	}] start];
}

- (void) askFreeformQuestion:(NSString*) question forPoint:(SJPoint*) point;
{
	// TODO URL generation does not belong here methinks.
	NSString* URLString = [NSString stringWithFormat:@"%@/points/%@/new_question", point.slide.URLString, point.sortingOrder];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[self.endpoint URL:URLString]];
	
	[req setValue:@"application/x-www-form-urlencoded;encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSDictionary* formData = [NSDictionary dictionaryWithObjectsAndKeys:
							  kSJQuestionFreeformKind, @"kind",
							  question, @"text",
							  nil];
	
	[req setHTTPBody:[[formData queryString] dataUsingEncoding:NSUTF8StringEncoding]];

	[req setHTTPMethod:@"POST"];
	
	[[self.endpoint requestFromURLRequest:req completionHandler:^(id <SJRequest> finalReq) {
		
		ILLog(@"Did finish URL request for asking freeform question: %@", question);

		[self storeQuestionDownloadedByRequest:finalReq forPoint:nil];
		
	}] start];	
}

- (SJQuestion*) storeQuestionDownloadedByRequest:(id <SJRequest>) r forPointWithURL:(NSURL*) url;
{
	SJPoint* pt = [SJPoint pointWithURL:url fromContext:self.managedObjectContext];
	return [self storeQuestionDownloadedByRequest:r forPoint:pt];
}

- (SJQuestion*) storeQuestionDownloadedByRequest:(id <SJRequest>) r forPoint:(SJPoint*) pt;
{
	SJQuestion* newQ = [SJQuestion oneWithPredicate:[NSPredicate predicateWithFormat:@"URLString == %@", r.URL] fromContext:self.managedObjectContext];
	
	if ([r.HTTPResponse statusCode] == 404) {
		if (newQ)
			[[newQ managedObjectContext] deleteObject:newQ];
	} else {
		
		SJQuestionSchema* questionSchema = [r JSONValueWithSchema:[SJQuestionSchema class] error:NULL];
		
		if (questionSchema) {
			if (!pt)
				pt = [SJPoint pointWithURL:[NSURL URLWithString:questionSchema.pointURLString] fromContext:self.managedObjectContext];
			
			if (!pt) {
				pt = [SJPoint insertedInto:self.managedObjectContext];
				pt.URLString = questionSchema.pointURLString;
			}
			
			if (!newQ)
				newQ = [SJQuestion insertedInto:self.managedObjectContext];
			
			newQ.URL = r.URL;
			newQ.kind = questionSchema.kind;
			newQ.text = questionSchema.text;
			
			[pt addQuestionsObject:newQ];
		}
		
	}
	
	if (![self.managedObjectContext save:NULL])
		[self.managedObjectContext rollback];
	else if (newQ && ![newQ isDeleted])
		[self.delegate live:self didDownloadQuestion:newQ];	
	
	return newQ;
}	

- (void) reportMoodOfKind:(NSString*) kind forSlide:(SJSlide*) slide;
{
	NSURL* u = slide.URL;
	NSString* path = [NSString stringWithFormat:@"/live%@/new_mood", [u path]];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[self.endpoint URL:path]];
	[req setHTTPMethod:@"POST"];
	
	[req setValue:@"application/x-www-form-urlencoded;encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSDictionary* formData = [NSDictionary dictionaryWithObjectsAndKeys:
							  kind, @"kind",
							  nil];
	
	[req setHTTPBody:[[formData queryString] dataUsingEncoding:NSUTF8StringEncoding]];
	
	id <SJRequest> actualRequest = [self.endpoint requestFromURLRequest:req completionHandler:^(id <SJRequest> r) {
		
		ILLog(@"Finished reporting mood of kind %@ for slide %@ (HTTP status code: %d)", kind, slide, [[r HTTPResponse] statusCode]);
		
	}];
	
	[actualRequest start];
}

@end
