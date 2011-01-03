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

@property(nonatomic, retain) NSTimer* updateTimer;

@end


@implementation SJLiveSyncController

+ addControllerForLiveURL:(NSURL*) url delegate:(id <SJLiveSyncControllerDelegate>) d toCoordinator:(SJSyncCoordinator*) coord;
{
	SJLiveSyncController* me = [[[self alloc] initWithLiveURL:url] autorelease];
	me.delegate = d;
	[me addToCoordinator:coord];
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
	[self.updateTimer invalidate];
	self.updateTimer = nil;
	
	self.URL = nil;
	self.lastDownloadedSnapshot = nil;
		
	[super dealloc];
}

@synthesize URL, lastDownloadedSnapshot, delegate, updateTimer;

- (void) addToCoordinator:(SJSyncCoordinator*) coord;
{
	[coord setSyncController:self forEntitiesWithSnapshotsClass:[SJLiveSchema class]];
}

#pragma mark The actual sync stuff

@synthesize syncCoordinator;
- (void) setSyncCoordinator:(SJSyncCoordinator *) sc;
{
	if (sc != syncCoordinator) {
		
		syncCoordinator = sc;
		
		if (syncCoordinator && !self.updateTimer) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
		} else if (!syncCoordinator) {
			[self.updateTimer invalidate];
			self.updateTimer = nil;
		}
		
	}
}

- (void) tick:(NSTimer*) t;
{
	NSLog(@"Did tick: %@", self);
	SJEntityUpdate* update = [SJEntityUpdate updateWithSnapshotsClass:[SJLiveSchema class] URL:self.URL];
	update.downloadPriority = kSJDownloadPriorityLiveUpdate;
	[self.syncCoordinator processUpdate:update];
}

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

			[self.syncCoordinator processUpdate:[update relatedUpdateWithAvailableSnapshot:live.slide URL:[update relativeURLTo:live.slide.URLString] refers:NO]];
			
			for (NSString* s in live.moodURLStrings)
				[self.syncCoordinator processUpdate:[update relatedUpdateWithSnapshotClass:[SJMoodSchema class] URL:[update relativeURLTo:s] refers:NO]];
			
			for (NSString* q in live.URLStringsOfQuestionsPostedDuringLive)
				[self.syncCoordinator processUpdate:[update relatedUpdateWithSnapshotClass:[SJQuestionSchema class] URL:[update relativeURLTo:q] refers:NO]];
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
