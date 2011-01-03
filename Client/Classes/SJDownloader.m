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
		self.liveUpdateQueue = [[NSOperationQueue new] autorelease];
		
		self.monitorsInternetReachability = YES;
	}
	
	return self;
}

- (void) dealloc
{
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
	
	
	__block id blockOp = op; // avoids retain cycle.
	[op setURLConnectionCompletionBlock:SJOnMainThread(^{
		[self didDownloadDataWithOperation:blockOp request:request];
	})];
	
	NSOperationQueue* opQueue = self.operationQueue;
	
	switch (r) {
		case kSJDownloadPriorityOpportunistic:
			[op setQueuePriority:NSOperationQueuePriorityLow];
			break;
		case kSJDownloadPrioritySubresourceForImmediateDisplay:
			[op setQueuePriority:NSOperationQueuePriorityNormal];
			break;
		case kSJDownloadPriorityResourceForImmediateDisplay:
			[op setQueuePriority:NSOperationQueuePriorityVeryHigh];
			break;
		case kSJDownloadPriorityLiveUpdate:
			opQueue = self.liveUpdateQueue;
			break;
	}
	
	[opQueue addOperation:op];
	
//	if (opQueue == self.operationQueue && r == kSJDownloadPriorityOpportunistic) {
//		for (NSOperation* currentOp in [self.operationQueue operations]) {
//			if ([currentOp queuePriority] <= NSOperationQueuePriorityLow && [currentOp isExecuting])
//				[currentOp cancel];
//		}
//	}
}

@synthesize delegate;

- (void) didDownloadDataWithOperation:(ILInMemoryDownloadOperation *)op request:(SJDownloadRequest*) req;
{
	req.error = op.error;
	req.downloadedData = op.downloadedData;
	[self.delegate downloader:self didFinishDowloadingRequest:req];
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
