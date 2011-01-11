//
//  SJSyncCoordinator.m
//  Client
//
//  Created by ∞ on 31/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SJSyncCoordinator.h"

#import "JSON.h"
#import "SJSchema.h"

#import "ILSensorSink.h"
#import "ILSensorSession.h"


@interface SJSyncCoordinator () <SJDownloaderDelegate>

@property(nonatomic, retain) NSMutableDictionary* syncControllers;
- (id <SJSyncController>) syncControllerForEntitiesOfClass:(Class) c;

@property(nonatomic, retain) NSMutableDictionary* watches;
- (void) callWatchesForURL:(NSURL*) u;

@property(nonatomic, retain) SJDownloader* downloader;

@property(nonatomic, retain) NSMutableSet* URLsBeingDownloaded;

@end


@implementation SJSyncCoordinator

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.syncControllers = [NSMutableDictionary dictionary];
		self.watches = [NSMutableDictionary dictionary];
		
		self.downloader = [SJDownloader downloader];
		self.downloader.delegate = self;
		self.URLsBeingDownloaded = [NSMutableSet set];
	}
	return self;
}

- (void) dealloc
{
	self.monitorsIncompleteObjectFetchNotifications = NO;
	
	[[self.syncControllers allValues] makeObjectsPerformSelector:@selector(setSyncCoordinator:) withObject:nil];
	self.syncControllers = nil;
	
	self.downloader.delegate = nil;
	self.downloader = nil;
	
	self.watches = nil;
	
	[super dealloc];
}

#pragma mark Incomplete fetch triggering

@synthesize monitorsIncompleteObjectFetchNotifications;
- (void) setMonitorsIncompleteObjectFetchNotifications:(BOOL) m;
{
	if (m != monitorsIncompleteObjectFetchNotifications) {
		monitorsIncompleteObjectFetchNotifications = m;
		
		if (m)
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTriggerIncompleteObjectFetch:) name:kSJIncompleteObjectsRequiresFetchNotification object:nil];
		else
			[[NSNotificationCenter defaultCenter] removeObserver:self name:kSJIncompleteObjectsRequiresFetchNotification object:nil];
	}
}

- (void) didTriggerIncompleteObjectFetch:(NSNotification*) n;
{
	SJEntityUpdate* up = [[n userInfo] objectForKey:kSJEntityUpdateKey];
	[self processUpdate:up];
}

#pragma mark Watches

@synthesize watches;

- (void) afterDownloadingNextSnapshotForEntityAtURL:(NSURL*) url perform:(void (^)()) block;
{
	NSMutableSet* blocksSet = [self.watches objectForKey:url];
	if (!blocksSet) {
		blocksSet = [NSMutableSet set];
		[self.watches setObject:blocksSet forKey:url];
	}
		
	[blocksSet addObject:[[block copy] autorelease]];
	
	ILLogDictInfo(@"Watch set on URL",
				  url, @"URL");
}

- (void) callWatchesForURL:(NSURL*) u;
{
	ILLogDictInfo(@"Will call watchers",
				  u, @"URL");
	
	for (void (^block)() in [self.watches objectForKey:u])
		block();
	
	[self.watches removeObjectForKey:u];
	
	ILLogDictInfo(@"Did call watchers",
				  u, @"URL");
}

#pragma mark Sync Controllers

@synthesize syncControllers;

- (void) setSyncController:(id <SJSyncController>)ctl forEntitiesWithSnapshotsClass:(Class)c;
{
	NSAssert(!ctl.syncCoordinator || ctl.syncCoordinator == self, @"Cannot share a controller between multiple coordinators");
	ctl.syncCoordinator = self;
	[self.syncControllers setObject:ctl forKey:c];
	
	ILLogDictInfo(@"Set a sync controller",
				  c, @"snapshotsClass",
				  ctl, @"syncController");
}

- (void) removeSyncControllerForEntitiesWithSnapshotsClass:(Class)c;
{	
	id <SJSyncController> ctl = [self.syncControllers objectForKey:c];
	if (ctl) {
		ILLogDictInfo(@"Will remove a sync controller",
					  c, @"snapshotsClass",
					  ctl, @"syncController");
		ctl.syncCoordinator = nil;
		[self.syncControllers removeObjectForKey:c];
	}
}

- (id <SJSyncController>) syncControllerForEntitiesOfClass:(Class) c;
{
	for (Class x in self.syncControllers) {
		if ([c isSubclassOfClass:x])
			return [self.syncControllers objectForKey:x];
	}
	
	return nil;
}

#pragma mark Updates

@synthesize downloader, URLsBeingDownloaded;

- (void) processUpdate:(SJEntityUpdate*) update;
{
	id <SJSyncController> ctl = [self syncControllerForEntitiesOfClass:update.snapshotsClass];
	
	if (!ctl) {
		ILLogDictInfo(@"No sync controller to process update, ignoring",
					  update, @"update");
		return;
	}
	
	ILLogDictInfo(@"About to process update",
				  update, @"update",
				  ctl, @"syncController");
	
	if (update.availableSnapshot) {
		ILLogDictInfo(@"Will process available snapshot first",
					  update, @"update",
					  ctl, @"syncController");
		[ctl processSnapshot:update.availableSnapshot forUpdate:update];
	}
	
	NSURL* absURL = [update.URL absoluteURL];
	
	if (update.downloadPriority == kSJDownloadPriorityOpportunistic &&
		[self.URLsBeingDownloaded containsObject:absURL]) {
		ILLogDictInfo(@"Processing an update for an URL already being downloaded",
					  update, @"update",
					  ctl, @"syncController");
	} else {
		if (update.requireRefetch || [ctl shouldDownloadSnapshotForUpdate:update]) {
			ILLogDictInfo(@"Controller said OK to download update or update requires refetch",
						  update, @"update",
						  ctl, @"syncController");
			
			[self.URLsBeingDownloaded addObject:absURL];
			
			SJDownloadRequest* req = [SJDownloadRequest downloadRequest];
			req.URL = update.URL;
			req.reason = update.downloadPriority;
			req.userInfo = update;
			
			[self.downloader beginDownloadingWithRequest:req];
			
		} else {
			ILLogDictInfo(@"Controller said no to download update, calling watches",
						  update, @"update",
						  ctl, @"syncController");
			[self callWatchesForURL:update.URL];
		}
	}
		
}

- (void) downloader:(SJDownloader*) d didFinishDowloadingRequest:(SJDownloadRequest*) req;
{
	SJEntityUpdate* update = req.userInfo;
	[self.URLsBeingDownloaded removeObject:[update.URL absoluteURL]];
	
	id <SJSyncController> ctl = [self syncControllerForEntitiesOfClass:update.snapshotsClass];
	
	ILLogDictInfo(@"Got download for update",
				  update, @"update",
				  ctl, @"syncController",
				  req.error?: [NSNull null], @"error");
	
	if (req.error) {
		BOOL reschedule = [ctl shouldRescheduleFailedDownloadForUpdate:update error:req.error];
		ILLogDictInfo(@"Asked controller to reschedule failed download",
					  update, @"update",
					  ctl, @"syncController",
					  req.error?: [NSNull null], @"error",
					  [NSNumber numberWithBool:reschedule], @"shouldRescheduleDownload");
		
		if (reschedule)
			[self processUpdate:update];
		
		return;
	}
	
	id snapshot = nil;
	if (update.snapshotKind == kSJEntityUpdateSnapshotKindSchema) {
		// TODO below, call didFailDownloading… with appropriate NSErrors instead of just returning.
			
		NSString* downloadedString = [[[NSString alloc] initWithData:req.downloadedData encoding:NSUTF8StringEncoding] autorelease];
		if (!downloadedString)
			return;
		
		id dict = [downloadedString JSONValue];
		if (![dict isKindOfClass:[NSDictionary class]])
			return;
		
		snapshot = [[[update.snapshotsClass alloc] initWithJSONDictionaryValue:dict error:NULL] autorelease];
		if (!snapshot)
			return;
	} else {
		snapshot = req.downloadedData;
	}
	
	ILLogDictInfo(@"Will process snapshot for update",
				  update, @"update",
				  ctl, @"syncController",
				  [snapshot isKindOfClass:[NSData class]]? @"((data))" : snapshot, @"snapshot");
	
	[ctl processSnapshot:snapshot forUpdate:update];
	
	ILLogDictInfo(@"Did process snapshot for update",
				  update, @"update",
				  ctl, @"syncController",
				  [snapshot isKindOfClass:[NSData class]]? @"((data))" : snapshot, @"snapshot");

	[self callWatchesForURL:update.URL];
}

@end

#pragma mark -

@interface SJEntityUpdate ()

@end

#define ILCaseReturningNameOfConstant(x) \
	case x: \
		return @#x;

CF_INLINE NSString* SJEntityUpdateSnapshotKindDescription(SJEntityUpdateSnapshotKind k) {
	switch (k) {
		ILCaseReturningNameOfConstant(kSJEntityUpdateSnapshotKindSchema)
		ILCaseReturningNameOfConstant(kSJEntityUpdateSnapshotKindData)
		default:
			return @"???";
	}
}

CF_INLINE NSString* SJDownloadPriorityDescription(SJDownloadPriority p) {
	switch (p) {
		ILCaseReturningNameOfConstant(kSJDownloadPriorityResourceForImmediateDisplay)
		ILCaseReturningNameOfConstant(kSJDownloadPrioritySubresourceForImmediateDisplay)
		ILCaseReturningNameOfConstant(kSJDownloadPriorityOpportunistic)
		default:
			return @"???";
	}
}

@implementation SJEntityUpdate

- (void) dealloc
{
	self.URL = nil;
	self.availableSnapshot = nil;
	self.referrerEntityUpdate = nil;
	self.userInfo = nil;
	[super dealloc];
}

@synthesize snapshotsClass, URL, availableSnapshot, downloadPriority, requireRefetch;

+ updateWithSnapshotsClass:(Class) c URL:(NSURL*) url;
{
	SJEntityUpdate* me = [[self new] autorelease];
	me.URL = url;
	me.snapshotsClass = c;
	return me;
}

+ updateWithAvailableSnapshot:(id) snap URL:(NSURL*) url;
{
	SJEntityUpdate* me = [self updateWithSnapshotsClass:[snap class] URL:url];
	me.availableSnapshot = snap;
	return me;
}

- (SJEntityUpdate*) relatedUpdateWithSnapshotsClass:(Class) c URL:(NSURL*) url refers:(BOOL) ref;
{
	SJEntityUpdate* related = [[self class] updateWithSnapshotsClass:c URL:url];
	switch (self.downloadPriority) {
		case kSJDownloadPriorityResourceForImmediateDisplay:
		case kSJDownloadPrioritySubresourceForImmediateDisplay:
			related.downloadPriority = kSJDownloadPrioritySubresourceForImmediateDisplay;
			break;
			
		default:
			related.downloadPriority = kSJDownloadPriorityOpportunistic;
			break;
	}
	
	if (ref)
		related.referrerEntityUpdate = self;
	
	return related;
}

- (SJEntityUpdate*) relatedUpdateWithAvailableSnapshot:(id) snap URL:(NSURL*) url refers:(BOOL) ref;
{
	SJEntityUpdate* related = [self relatedUpdateWithSnapshotsClass:[snap class] URL:url refers:ref];
	related.availableSnapshot = snap;
	return related;
}

- (NSURL*) relativeURLTo:(NSString*) path;
{
	return [NSURL URLWithString:path relativeToURL:self.URL];
}

@synthesize referrerEntityUpdate, snapshotKind, userInfo;

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ { update for entity at URL: %@, with snapshots class: %@, snapshot kind: %@, download priority: %@, referrer update: %@, user info: %@ }",
			[super description],
			self.URL,
			self.snapshotsClass,
			SJEntityUpdateSnapshotKindDescription(self.snapshotKind),
			SJDownloadPriorityDescription(self.downloadPriority),
			self.referrerEntityUpdate,
			self.userInfo];
}

@end

@implementation NSObject (SJEntityFetchTriggering)

- (void) incompleteObjectNeedsFetchingSnapshotWithUpdate:(SJEntityUpdate*) up;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSJIncompleteObjectsRequiresFetchNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																up, kSJEntityUpdateKey,
																nil]];
}

@end

