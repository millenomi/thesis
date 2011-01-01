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
	[self.syncControllers setObject:ctl forKey:c];
}

- (void) removeSyncControllerForEntitiesWithSnapshotsClass:(Class)c;
{
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
		[ctl didFailDownloadingUpdate:update error:req.error];
		return;
	}
	
	// TODO below, call didFailDownloading… with appropriate NSErrors instead of just returning.
		
	NSString* downloadedString = [[[NSString alloc] initWithData:req.downloadedData encoding:NSUTF8StringEncoding] autorelease];
	if (!downloadedString)
		return;
	
	id dict = [downloadedString JSONValue];
	if (![dict isKindOfClass:[NSDictionary dictionary]])
		return;
	
	id snapshot = [[[update.snapshotsClass alloc] initWithJSONDictionaryValue:dict error:NULL] autorelease];
	if (!snapshot)
		return;
	
	[ctl processSnapshot:snapshot forUpdate:update];
	
	[self callWatchesForURL:update.URL];
}

@end

#pragma mark -

@interface SJEntityUpdate ()

@end


@implementation SJEntityUpdate

- (void) dealloc
{
	self.URL = nil;
	self.availableSnapshot = nil;
	[super dealloc];
}

@synthesize snapshotsClass, URL, availableSnapshot, downloadPriority;

+ updateWithSnapshotsClass:(Class) c URL:(NSURL*) url;
{
	SJEntityUpdate* me = [[self new] autorelease];
	me.URL = url;
	me.snapshotsClass = c;
}

+ updateWithAvailableSnapshot:(id) snap URL:(NSURL*) url;
{
	SJEntityUpdate* me = [self updateWithSnapshotsClass:[snap class] URL:url];
	me.availableSnapshot = snap;
	return me;
}

- (SJEntityUpdate*) relatedUpdateWithSnapshotClass:(Class) c URL:(NSURL*) url;
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
	
	return related;
}

- (SJEntityUpdate*) relatedUpdateWithAvailableSnapshot:(id) snap URL:(NSURL*) url;
{
	SJEntityUpdate* related = [self relatedUpdateWithSnapshotClass:[snap class] URL:url];
	related.availableSnapshot = snap;
	return related;
}

- (NSURL*) relativeURLTo:(NSString*) path;
{
	return [NSURL URLWithString:path relativeToURL:self.URL];
}

@end

