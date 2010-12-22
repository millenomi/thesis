//
//  SJLiveObserver.m
//  Client
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SJLiveObserver.h"

#import "SJLiveSchema.h"
#import "SJQuestionSchema.h"

#import "SJEndpoint.h"

static const NSTimeInterval kSJLiveObserverRequestDelay = 3.0;

@interface SJLiveObserver ()

@property(nonatomic, retain) SJEndpoint* endpoint;
@property(nonatomic, assign) SJSchemaProvider* schemaProvider;

@property(nonatomic) BOOL needsImmediateUpdate;

@property(nonatomic, retain) SJLiveSchema* latestDownloadedSchema;

@end


@implementation SJLiveObserver

- (id) initWithEndpoint:(SJEndpoint*) ep;
{
	if ((self = [super init])) {
		self.needsImmediateUpdate = YES;
		self.endpoint = ep;
	}
	
	return self;
}

- (void) dealloc
{
	self.endpoint = nil;
	self.latestDownloadedSchema = nil;
	[super dealloc];
}

@synthesize endpoint, latestDownloadedSchema, delegate;

- (void) schemaProvider:(SJSchemaProvider *)sp didDownloadSchema:(id)schema fromURL:(NSURL *)url reason:(SJDownloaderReason) reason partial:(BOOL)partial;
{
	if (partial)
		return;
	
	SJLiveSchema* live = schema;
	if (live.slide)
		[sp provideSchema:live.slide fromURL:url reason:kSJDownloaderReasonResourceForImmediateDisplay partial:YES];
	
	for (NSString* s in live.moodURLStrings)
		[sp noteSchemaOfClass:[SJMoodSchema class] atURL:[self.endpoint URL:s] subresourceOfSchema:schema reason:kSJDownloaderReasonResourceForImmediateDisplay];
	
	for (NSString* q in live.URLStringsOfQuestionsPostedDuringLive)
		[sp noteSchemaOfClass:[SJQuestionSchema class] atURL:[self.endpoint URL:q] subresourceOfSchema:schema reason:kSJDownloaderReasonResourceForImmediateDisplay];

	SJLiveSchema* old = [[self.latestDownloadedSchema retain] autorelease];
	self.latestDownloadedSchema = schema;
		
	BOOL didStart = NO, didEnd = NO;
	if (!old || ([old isFinished] && ![live isFinished])) {
		[self.delegate liveDidStart:self];
		didStart = YES;
	} else if (![old isFinished] && [live isFinished]) {
		[self.delegate liveDidEnd:self];
		didEnd = YES;
	}
	
	if (didStart || (!didEnd && ![old.slide isEqual:live.slide])) {
		[self.delegate live:self didMoveToSlideAtURL:[self.endpoint URL:live.slide.URLString] schema:live.slide];
	}
	
	if (![live isFinished]) {
		NSMutableSet* questions = [NSMutableSet setWithArray:live.URLStringsOfQuestionsPostedDuringLive];
		[questions minusSet:[NSSet setWithArray:old.URLStringsOfQuestionsPostedDuringLive]];
		
		if ([questions count] > 0) {
			NSMutableSet* s = [NSMutableSet set];
			for (id x in questions)
				[s addObject:[self.endpoint URL:x]];
			[self.delegate live:self didPostQuestionsAtURLs:s];
		}
		
		NSMutableSet* moods = [NSMutableSet setWithArray:live.moodURLStrings];
		[moods minusSet:[NSSet setWithArray:old.moodURLStrings]];
		
		if ([moods count] > 0) {
			NSMutableSet* s = [NSMutableSet set];
			for (id x in moods)
				[s addObject:[self.endpoint URL:x]];
			[self.delegate live:self didPostMoodsAtURLs:s];
		}
	}
	
	self.needsImmediateUpdate = NO;
	[self performSelector:@selector(tick) withObject:nil afterDelay:kSJLiveObserverRequestDelay];
}

- (void) schemaProvider:(SJSchemaProvider *)sp didFailToDownloadFromURL:(NSURL *)url error:(NSError *)error;
{
	[self.delegate live:self didFailToLoadWithError:error];
	self.needsImmediateUpdate = YES;
	[self performSelector:@selector(tick) withObject:nil afterDelay:kSJLiveObserverRequestDelay];
}

@synthesize schemaProvider;
- (void) setSchemaProvider:(SJSchemaProvider *) p;
{
	if (schemaProvider != p) {
		BOOL hadSchemaProvider = (schemaProvider != nil);
		
		schemaProvider = p;
		
		if (!hadSchemaProvider && schemaProvider)
			[self performSelector:@selector(tick) withObject:nil afterDelay:kSJLiveObserverRequestDelay];
		else if (hadSchemaProvider && !schemaProvider)
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tick) object:nil];
	}
}

@synthesize needsImmediateUpdate;

- (void) tick;
{
	// NSURL* url = (self.needsImmediateUpdate? [self.endpoint URL:@"/live"] : [self.endpoint URL:@"/live?request.kind=update"]);
	NSURL* url = [self.endpoint URL:@"/live"];
	[self.schemaProvider beginFetchingSchemaOfClass:[SJLiveSchema class] fromURL:url reason:kSJDownloaderReasonLiveUpdate];
}

@end
