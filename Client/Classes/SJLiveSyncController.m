//
//  SJLiveSyncController.m
//  Client
//
//  Created by ∞ on 01/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SJLiveSyncController.h"

#import "SJLiveSchema.h"
#import "SJQuestionSchema.h"

@interface SJLiveSyncController ()

@property(nonatomic, copy) SJLiveSchema* lastDownloadedSnapshot;
@property(nonatomic, copy) NSURL* URL;

@end


@implementation SJLiveSyncController

+ addControllerForLiveURL:(NSURL*) url toCoordinator:(SJSyncCoordinator*) coord;
{
	id me = [[[self alloc] initWithLiveURL:url] autorelease];
	[coord setSyncController:me forEntitiesWithSnapshotsClass:[SJLiveSchema class]];
	return me;
}

- (id) initWithLiveURL:(NSURL *)url;
{
	if ((self = [super init])) {
		self.URL = url;
	}
	
	return self;
}

- (void) dealloc
{
	self.URL = nil;
	self.lastDownloadedSnapshot = nil;
	[super dealloc];
}

@synthesize URL, lastDownloadedSnapshot, delegate;

#pragma mark The actual sync stuff

@synthesize syncCoordinator;

- (BOOL) shouldDownloadSnapshotForUpdate:(SJEntityUpdate *)update;
{
	return (!update.availableSnapshot || ![update.availableSnapshot isEqual:self.lastDownloadedSnapshot]);
}

- (void) didFailDownloadingUpdate:(SJEntityUpdate *)update error:(NSError *)error;
{
	[self.delegate live:self didFailToLoadWithError:error];
}

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update;
{
	SJLiveSchema* live = snapshot;
	if (live.slide) {
		[self.syncCoordinator processUpdate:[update relatedUpdateWithAvailableSnapshot:live.slide URL:[update relativeURLTo:live.slide.URLString] refers:NO]];
		
		for (NSString* s in live.moodURLStrings)
			[self.syncCoordinator processUpdate:[update relatedUpdateWithSnapshotClass:[SJMoodSchema class] URL:[update relativeURLTo:s] refers:NO]];
		
		for (NSString* q in live.URLStringsOfQuestionsPostedDuringLive)
			[self.syncCoordinator processUpdate:[update relatedUpdateWithSnapshotClass:[SJQuestionSchema class] URL:[update relativeURLTo:q] refers:NO]];
		
		SJLiveSchema* old = [[self.lastDownloadedSnapshot retain] autorelease];
		self.lastDownloadedSnapshot = live;
		
		BOOL didStart = NO, didEnd = NO;
		BOOL oldWasFinished = !old || [old isFinished];
		if (oldWasFinished && ![live isFinished]) {
			[self.delegate liveDidStart:self];
			didStart = YES;
		} else if (!oldWasFinished && [live isFinished]) {
			[self.delegate liveDidEnd:self];
			didEnd = YES;
		}
		
		if (didStart || (![live isFinished] && ![old.slide isEqual:live.slide])) {
			[self.delegate live:self didMoveToSlideAtURL:[update relativeURLTo:live.slide.URLString] schema:live.slide];
		}
		
		if (![live isFinished]) {
			NSMutableSet* questions = [NSMutableSet setWithArray:live.URLStringsOfQuestionsPostedDuringLive];
			[questions minusSet:[NSSet setWithArray:old.URLStringsOfQuestionsPostedDuringLive]];
			
			if ([questions count] > 0) {
				NSMutableSet* s = [NSMutableSet set];
				for (id x in questions)
					[s addObject:[update relativeURLTo:x]];
				[self.delegate live:self didPostQuestionsAtURLs:s];
			}
			
			NSMutableSet* moods = [NSMutableSet setWithArray:live.moodURLStrings];
			[moods minusSet:[NSSet setWithArray:old.moodURLStrings]];
			
			if ([moods count] > 0) {
				NSMutableSet* s = [NSMutableSet set];
				for (id x in moods)
					[s addObject:[update relativeURLTo:x]];
				[self.delegate live:self didPostMoodsAtURLs:s];
			}
		}
		
	}
}

@end
