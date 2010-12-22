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

typedef void (^SJRunnable)(void);
static SJRunnable SJOnMainThread(SJRunnable r) {
	return [[^{
		[[NSOperationQueue mainQueue] addOperationWithBlock:r];
	} copy] autorelease];
};

@interface SJDownloader () <ILHostReachabilityDelegate>

@property(nonatomic, retain) NSOperationQueue* operationQueue, * liveUpdateQueue;
@property(nonatomic, retain) ILHostReachability* reach;

- (void) didDownloadDataWithOperation:(ILInMemoryDownloadOperation *)op fromURL:(NSURL *)url options:(NSDictionary*) options;

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
		
		// we assume all ops go on the outer Internet.
		self.reach = [[[ILHostReachability alloc] initWithHostAddressString:@"infinite-labs.net"] autorelease];
		self.reach.delegate = self;
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


@synthesize operationQueue, liveUpdateQueue, reach;

- (void) beginDownloadingDataFromURL:(NSURL *)u options:(NSDictionary *)options;
{	
	NSNumber* n = [options objectForKey:kSJDownloaderOptionDownloadReason];
	SJDownloaderReason r = n? [n unsignedIntegerValue] : kSJDownloaderReasonOpportunistic;
	
	if (r == kSJDownloaderReasonOpportunistic && self.reach.reachabilityKnown && self.reach.requiresRoutingOnWWAN) {
		[self.delegate downloader:self
	 didFailDownloadingDataForURL:u
						  options:options
							error:[NSError errorWithDomain:kSJDownloaderErrorDomain
													  code:kSJDownloaderErrorWillNotPerformOpportunisticDownloadsOnWWAN
												  userInfo:nil]
		 ];
		return;
	}

	NSURLRequest* req = [NSURLRequest requestWithURL:u];
	
	ILInMemoryDownloadOperation* op = [[[ILInMemoryDownloadOperation alloc] initWithRequest:req] autorelease];
	op.maximumResourceSize = 1 * 1024 * 1024; // TODO configurable?
	
	
	__block id blockOp = op; // avoids retain cycle.
	[op setURLConnectionCompletionBlock:SJOnMainThread(^{
		[self didDownloadDataWithOperation:blockOp fromURL:u options:options];
	})];
	
	NSOperationQueue* opQueue = self.operationQueue;
	
	switch (r) {
		case kSJDownloaderReasonOpportunistic:
			[op setQueuePriority:NSOperationQueuePriorityLow];
			break;
		case kSJDownloaderReasonSubresourceForImmediateDisplay:
			[op setQueuePriority:NSOperationQueuePriorityNormal];
			break;
		case kSJDownloaderReasonResourceForImmediateDisplay:
			[op setQueuePriority:NSOperationQueuePriorityVeryHigh];
			break;
		case kSJDownloaderReasonLiveUpdate:
			opQueue = self.liveUpdateQueue;
			break;
	}
	
	[opQueue addOperation:op];
	
	if (opQueue == self.operationQueue && r == kSJDownloaderReasonOpportunistic) {
		for (NSOperation* currentOp in [self.operationQueue operations]) {
			if ([currentOp queuePriority] <= NSOperationQueuePriorityLow && [currentOp isExecuting])
				[currentOp cancel];
		}
	}
}

@synthesize delegate;

- (void) didDownloadDataWithOperation:(ILInMemoryDownloadOperation*) op fromURL:(NSURL*) url options:(NSDictionary*) options;
{
	if (!op.error)
		[self.delegate downloader:self didDownloadData:op.downloadedData forURL:url options:options];
	else
		[self.delegate downloader:self didFailDownloadingDataForURL:url options:options error:op.error];
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
