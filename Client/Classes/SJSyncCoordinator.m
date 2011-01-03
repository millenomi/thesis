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

@interface SJSyncCoordinator () <SJDownloaderDelegate>

@property(nonatomic, retain) NSMutableDictionary* syncControllers;
- (id <SJSyncController>) syncControllerForEntitiesOfClass:(Class) c;

@property(nonatomic, retain) NSMutableDictionary* watches;
- (void) callWatchesForURL:(NSURL*) u;

@property(nonatomic, retain) SJDownloader* downloader;

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
	}
	return self;
}

- (void) dealloc
{
	[[self.syncControllers allValues] makeObjectsPerformSelector:@selector(setSyncCoordinator:) withObject:nil];
	self.syncControllers = nil;
	
	self.downloader.delegate = nil;
	self.downloader = nil;
	
	self.watches = nil;
	
	[super dealloc];
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
	
	[blocksSet addObject:[block copy]];
}

- (void) callWatchesForURL:(NSURL*) u;
{
	for (void (^block)() in [self.watches objectForKey:u])
		block();
	
	[self.watches removeObjectForKey:u];
}

#pragma mark Sync Controllers

@synthesize syncControllers;

- (void) setSyncController:(id <SJSyncController>)ctl forEntitiesWithSnapshotsClass:(Class)c;
{
	NSAssert(!ctl.syncCoordinator || ctl.syncCoordinator == self, @"Cannot share a controller between multiple coordinators");
	ctl.syncCoordinator = self;
	[self.syncControllers setObject:ctl forKey:c];
}

- (void) removeSyncControllerForEntitiesWithSnapshotsClass:(Class)c;
{
	id <SJSyncController> ctl = [self.syncControllers objectForKey:c];
	ctl.syncCoordinator = nil;
	[self.syncControllers removeObjectForKey:c];
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

@synthesize downloader;

- (void) processUpdate:(SJEntityUpdate*) update;
{
	id <SJSyncController> ctl = [self syncControllerForEntitiesOfClass:update.snapshotsClass];
	
	if (update.availableSnapshot)
		[ctl processSnapshot:update.availableSnapshot forUpdate:update];
	
	if ([ctl shouldDownloadSnapshotForUpdate:update]) {
		
		SJDownloadRequest* req = [SJDownloadRequest downloadRequest];
		req.URL = update.URL;
		req.reason = update.downloadPriority;
		req.userInfo = update;
		
		[self.downloader beginDownloadingWithRequest:req];
		
	} else {
		[self callWatchesForURL:update.URL];
	}
		
}

- (void) downloader:(SJDownloader*) d didFinishDowloadingRequest:(SJDownloadRequest*) req;
{
	SJEntityUpdate* update = req.userInfo;
	id <SJSyncController> ctl = [self syncControllerForEntitiesOfClass:update.snapshotsClass];
	
	if (req.error) {
		BOOL reschedule = [ctl shouldRescheduleFailedDownloadForUpdate:update error:req.error];
		
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
	
	[ctl processSnapshot:snapshot forUpdate:update];
	
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
		ILCaseReturningNameOfConstant(kSJDownloadPriorityLiveUpdate)
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

@synthesize snapshotsClass, URL, availableSnapshot, downloadPriority;

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
		case kSJDownloadPriorityLiveUpdate:
			related.downloadPriority = kSJDownloadPriorityResourceForImmediateDisplay;
			break;
			
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

