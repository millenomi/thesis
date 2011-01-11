//
//  SJDownloader.m
//  Client
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SJDownloader.h"
#import "ILInMemoryDownloadOperation.h"
#import "ILHostReachability.h"

#import <objc/runtime.h>

// -------------------------------------------
// -------------------------------------------

#pragma mark Download requests

@implementation SJDownloadRequest

+ downloadRequest;
{
	return [[self new] autorelease];
}

@synthesize URL, reason, userInfo, downloadedData, error;

- (void) dealloc
{
	self.URL = nil;
	self.userInfo = nil;
	self.downloadedData = nil;
	self.error = nil;
	
	[super dealloc];
}

- (id) copyWithZone:(NSZone *)zone;
{
	SJDownloadRequest* req = [[[self class] allocWithZone:zone] init];
	req.URL = self.URL;
	req.reason = self.reason;
	req.userInfo = self.userInfo;
	
	return req;
}

- (NSUInteger) hash;
{
	return [[self class] hash] ^ [self.URL hash] ^ self.reason ^ [self.userInfo hash];
}

- (BOOL) isEqual:(id)object;
{
	if (![object isKindOfClass:[self class]])
		return NO;
	
	SJDownloadRequest* req = object;
	return
		[[req URL] isEqual:self.URL] &&
		[[req userInfo] isEqual:self.userInfo] &&
		[req reason] == self.reason;
}

@end

// -------------------------------------------



@interface ILURLConnectionOperation (SJConveniences)
@property(copy, nonatomic) SJDownloadRequest* subject_originalDownloadRequest;
@end

@implementation ILURLConnectionOperation (SJConveniences)

char kSJOriginalDownloadRequestAssociatedObjectKeyValue = 0;
void* const kSJOriginalDownloadRequestAssociatedObjectKey = &kSJOriginalDownloadRequestAssociatedObjectKeyValue;

- (SJDownloadRequest*) subject_originalDownloadRequest;
{
	return objc_getAssociatedObject(self, kSJOriginalDownloadRequestAssociatedObjectKey);
}

- (void) setSubject_originalDownloadRequest:(SJDownloadRequest*) req;
{
	objc_setAssociatedObject(self, kSJOriginalDownloadRequestAssociatedObjectKey, req, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

// -------------------------------------------
// -------------------------------------------

#pragma mark The Downloader proper

typedef void (^SJRunnable)(void);
static SJRunnable SJOnMainThread(SJRunnable r) {
	return [[^{
		[[NSOperationQueue mainQueue] addOperationWithBlock:r];
	} copy] autorelease];
};

@interface SJDownloader () <ILHostReachabilityDelegate>

@property(nonatomic, retain) NSOperationQueue* operationQueue, * liveUpdateQueue;
@property(nonatomic, retain) ILHostReachability* reach;

- (void) didDownloadDataWithOperation:(ILInMemoryDownloadOperation *)op request:(SJDownloadRequest*) req;

- (void) beginHoldingQueue;
- (void) endHoldingQueue;

@end


@implementation SJDownloader

+ (id) downloader;
{
	return [[self new] autorelease];
}

- (id) init;
{
	if ((self = [super init])) {
		self.operationQueue = [[NSOperationQueue new] autorelease];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBeginUsingNetworkForImmediateUse:) name:kSJWillBeginUsingNetworkForImmediateDisplayNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEndUsingNetworkForImmediateUse:) name:kSJDidEndUsingNetworkForImmediateDisplayNotification object:nil];
		
		self.monitorsInternetReachability = YES;
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self.operationQueue cancelAllOperations];
	self.operationQueue = nil;
	[self.liveUpdateQueue cancelAllOperations];
	self.liveUpdateQueue = nil;
	
	self.reach.delegate = nil;
	self.reach = nil;
	
	[super dealloc];
}


#pragma mark Downloading stuff

@synthesize operationQueue, liveUpdateQueue, reach;

- (void) beginDownloadingWithRequest:(SJDownloadRequest*) request;
{	
	request = [[request copy] autorelease];
	
	SJDownloadPriority r = request.reason;
	
	if (r == kSJDownloadPriorityOpportunistic && self.reach.reachabilityKnown && self.reach.requiresRoutingOnWWAN) {
		request.error = [NSError errorWithDomain:kSJDownloaderErrorDomain
											code:kSJDownloaderErrorWillNotPerformOpportunisticDownloadsOnWWAN
										userInfo:nil];

		[self.delegate downloader:self didFinishDowloadingRequest:request];
		return;
	}

	NSURLRequest* req = [NSURLRequest requestWithURL:request.URL];
	
	ILInMemoryDownloadOperation* op = [[[ILInMemoryDownloadOperation alloc] initWithRequest:req] autorelease];
	op.maximumResourceSize = 1 * 1024 * 1024; // TODO configurable?
	
	
	__block id blockOp = [op retain]; // avoids retain cycle.
	[op setURLConnectionCompletionBlock:^{
		
		[NSThread sleepForTimeInterval:2.0];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			if (blockOp) {
				[self didDownloadDataWithOperation:blockOp request:request];
				[blockOp release]; blockOp = nil;
			}
		}];
	}];
	
	NSOperationQueue* opQueue = self.operationQueue;
	BOOL executesRightNow = NO, suspendsOpportunistDownloads = NO;
	switch (r) {
		case kSJDownloadPriorityOpportunistic:
			[op setQueuePriority:NSOperationQueuePriorityLow];
			break;

		case kSJDownloadResourceWillProbablyDisplayInImmediateFuture:
		case kSJDownloadPrioritySubresourceForImmediateDisplay:
		case kSJDownloadPriorityResourceForImmediateDisplay:			
			executesRightNow = YES;
			suspendsOpportunistDownloads = YES;
			break;
			
		case kSJDownloadPriorityLiveUpdate:
			executesRightNow = YES;
			suspendsOpportunistDownloads = NO;
			break;
	}
		
	if (executesRightNow) {
		NSLog(@"Running immediate download for %@", request.URL);
		if (suspendsOpportunistDownloads) {
			NSLog(@"Suspending queue for this download");
			[self beginHoldingQueue];
		}
		
		[NSThread detachNewThreadSelector:@selector(start) toTarget:op withObject:nil];
	} else {
		NSLog(@"Enqueuing opportunity download for %@", request.URL);
		[op setSubject_originalDownloadRequest:request];
		[opQueue addOperation:op];
	}
}

- (void) beginHoldingQueue;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resumeOpportunistDownloads) object:nil];
	queueHoldCount++;
	
	[self.operationQueue setSuspended:YES];
	
	for (ILURLConnectionOperation* op in [self.operationQueue operations]) {
		[op cancel];
	}
}

- (void) endHoldingQueue;
{
	if (queueHoldCount > 0) {
		queueHoldCount--;
		if (queueHoldCount == 0)
			[self performSelector:@selector(resumeOpportunistDownloads) withObject:nil afterDelay:2.0];
	}
}

- (void) applicationWillBeginUsingNetworkForImmediateUse:(NSNotification*) n;
{
	[self beginHoldingQueue];
}

- (void) applicationDidEndUsingNetworkForImmediateUse:(NSNotification*) n;
{
	[self endHoldingQueue];
}

@synthesize delegate;

- (void) didDownloadDataWithOperation:(ILInMemoryDownloadOperation *)op request:(SJDownloadRequest*) req;
{
	NSLog(@"Did finish downloading %@ (was opportunity? = %d)", req.URL, req.reason == kSJDownloadPriorityOpportunistic);
	
	if ([[op.error domain] isEqual:NSCocoaErrorDomain] && [op.error code] == NSUserCancelledError && [op subject_originalDownloadRequest]) {
		NSLog(@"Was cancelled, re-enqueuing");
		[self beginDownloadingWithRequest:[op subject_originalDownloadRequest]]; // reenqueues it for later.
	} else {
		req.error = op.error;
		req.downloadedData = op.downloadedData;
		[self.delegate downloader:self didFinishDowloadingRequest:req];
	}
	
	if (req.reason == kSJDownloadPriorityResourceForImmediateDisplay || req.reason == kSJDownloadPrioritySubresourceForImmediateDisplay) {
		NSLog(@"No more suspend-queue downloads pending");
		[self endHoldingQueue];
	}
}

- (void) resumeOpportunistDownloads;
{
	if (queueHoldCount == 0) {
		NSLog(@"Resuming queue");
		[self.operationQueue setSuspended:NO];
	}
}

#pragma mark Reachability

@synthesize monitorsInternetReachability;
- (void) setMonitorsInternetReachability:(BOOL) m;
{
	if (m != monitorsInternetReachability) {
		monitorsInternetReachability = m;
		
		self.reach.delegate = nil;
		[self.reach stop];
		
		if (monitorsInternetReachability) {			
			self.reach = [[[ILHostReachability alloc] initWithHostAddressString:@"infinite-labs.net"] autorelease];
			self.reach.delegate = self;
		} else {
			[self.operationQueue setSuspended:NO];
			[self.liveUpdateQueue setSuspended:NO];			
		}
	}
}

- (void) hostReachabilityDidChange:(ILHostReachability*) r;
{
	if (!r.reachabilityKnown)
		return;
	
	[self.operationQueue setSuspended:!r.reachable];
	[self.liveUpdateQueue setSuspended:!r.reachable];
	
	if (r.reachable && r.requiresRoutingOnWWAN) {
		for (NSOperation* currentOp in [self.operationQueue operations]) {
			if ([currentOp queuePriority] < NSOperationQueuePriorityNormal)
				[currentOp cancel];
		}
	}
}

@end
