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

#import "Foundation/Basics/ILShorthand.h"

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

#define SJKeyFor(c) \
	[NSValue valueWithNonretainedObject:c]

@interface SJDownloader ()

- (void) tryDequeuingAndRunningLowPriorityRequest;
- (void) cleanUpAfter:(NSURLConnection *)c;

@property(nonatomic) BOOL inABatch;
- (void) beginBatchIfNeeded;
- (void) endPossiblyBatchedRequest;
- (void) endBatchImmediatelyIfNeeded;

@end


@implementation SJDownloader

+ downloader;
{
	return [[self new] autorelease];
}

- (id) init;
{
	ILInit();
	
	runningLowPriorityRequests = [NSMutableSet new];
	runningHighPriorityRequests = [NSMutableSet new];
	
	downloadedDataByConnection = [NSMutableDictionary new];
	requestsByConnection = [NSMutableDictionary new];
	
	pendingLowPriorityRequests = [NSMutableArray new];
	
	self.downloadBatchSize = 1;
	self.downloadBatchWaitTimeout = 5.0;
	
	return self;
}

- (void) dealloc
{
	[runningLowPriorityRequests makeObjectsPerformSelector:@selector(cancel)];
	[runningHighPriorityRequests makeObjectsPerformSelector:@selector(cancel)];
	
	[runningLowPriorityRequests release];
	[runningHighPriorityRequests release];
	
	[downloadedDataByConnection release];
	[requestsByConnection release];
	
	[pendingLowPriorityRequests release];
	
	[super dealloc];
}



- (void) beginDownloadingWithRequest:(SJDownloadRequest*) request;
{
	BOOL isHighPriority = (request.reason != kSJDownloadPriorityOpportunistic);
	
	NSURLRequest* r = [NSURLRequest requestWithURL:request.URL];
	
	NSURLConnection* c = [[[NSURLConnection alloc] initWithRequest:r delegate:self startImmediately:NO] autorelease];

	id k = SJKeyFor(c);
	[downloadedDataByConnection setObject:[NSMutableData data] forKey:k];
	[requestsByConnection setObject:request forKey:k];
	
	if (isHighPriority) {
		[self endBatchImmediatelyIfNeeded];
		
		[runningHighPriorityRequests addObject:c];
		[c start];
		
		for (NSURLConnection* running in [[runningLowPriorityRequests copy] autorelease]) {
			SJDownloadRequest* toReenqueue = [[[requestsByConnection objectForKey:SJKeyFor(running)] retain] autorelease];
			[self cleanUpAfter:running];
			[self beginDownloadingWithRequest:toReenqueue]; // reenqueues it for later.
		}
	} else {		
		[pendingLowPriorityRequests addObject:c];
		[self tryDequeuingAndRunningLowPriorityRequest];
	}
}

- (void) cleanUpAfter:(NSURLConnection*) c;
{
	[c cancel];
	
	id k = SJKeyFor(c);
	[downloadedDataByConnection removeObjectForKey:k];
	[requestsByConnection removeObjectForKey:k];

	[runningLowPriorityRequests removeObject:c];
	[runningHighPriorityRequests removeObject:c];
}

#define kSJMaximumConcurrentOpportunistRequests (3)
- (void) tryDequeuingAndRunningLowPriorityRequest;
{
	if ([pendingLowPriorityRequests count] == 0)
		return;
	
	if ([runningHighPriorityRequests count] != 0)
		return;
	
	if ([runningLowPriorityRequests count] >= kSJMaximumConcurrentOpportunistRequests)
		return;
	
	[self beginBatchIfNeeded];
	
	NSURLConnection* c = [pendingLowPriorityRequests objectAtIndex:0];
	[runningLowPriorityRequests addObject:c];
	[c start];
	[pendingLowPriorityRequests removeObjectAtIndex:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	NSMutableData* d = [downloadedDataByConnection objectForKey:SJKeyFor(connection)];
	[d appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
{
	id k = SJKeyFor(connection);
	
	SJDownloadRequest* request = [requestsByConnection objectForKey:k];

	NSMutableData* d = [downloadedDataByConnection objectForKey:k];
	request.downloadedData = d;
	
	[self.delegate downloader:self didFinishDowloadingRequest:request];
	[self cleanUpAfter:connection];
	[self endPossiblyBatchedRequest];
	
	[self tryDequeuingAndRunningLowPriorityRequest];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	SJDownloadRequest* request = [requestsByConnection objectForKey:SJKeyFor(connection)];
	
	request.error = error;
	
	[self.delegate downloader:self didFinishDowloadingRequest:request];
	[self cleanUpAfter:connection];	
	[self tryDequeuingAndRunningLowPriorityRequest];
}

@synthesize delegate;

#pragma mark Batching

@synthesize downloadBatchSize;
- (void) setDownloadBatchSize:(NSUInteger) i;
{
	if (i == 0)
		i = 1;
	
	if (i != downloadBatchSize) {
		
		NSAssert([pendingLowPriorityRequests count] == 0 && [runningLowPriorityRequests count] == 0 && [runningHighPriorityRequests count] == 0, @"You cannot change the download batch size if downloads are running or pending.");
		
		downloadBatchSize = i;
		
	}
}

@synthesize downloadBatchWaitTimeout;
- (void) setDownloadBatchWaitTimeout:(NSTimeInterval) i;
{
	NSParameterAssert(i > 0);
	
	if (i != downloadBatchWaitTimeout) {
		
		NSAssert([pendingLowPriorityRequests count] == 0 && [runningLowPriorityRequests count] == 0 && [runningHighPriorityRequests count] == 0, @"You cannot change the download batch size if downloads are running or pending.");
		
		downloadBatchWaitTimeout = i;
		
	}
}

@synthesize inABatch;

- (void) beginBatchIfNeeded;
{
	if (self.inABatch)
		return;
	
	if (self.downloadBatchSize == 1)
		return;
	
	self.inABatch = YES;
	NSLog(@"(beginning a new batch)");
	[self.delegate downloaderWillBeginBatch:self];
}

- (void) endPossiblyBatchedRequest;
{
	if (!self.inABatch)
		return;
	
	if (self.downloadBatchSize == 1)
		return;

	batchSize++;
	if (batchSize >= self.downloadBatchSize) {
		[self endBatchImmediatelyIfNeeded];
	} else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(batchDidTimeOut) object:nil];
		[self performSelector:@selector(batchDidTimeOut) withObject:nil afterDelay:self.downloadBatchWaitTimeout];
	}
}

- (void) endBatchImmediatelyIfNeeded;
{
	if (self.downloadBatchSize == 1)
		return;

	if (self.inABatch) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(batchDidTimeOut) object:nil];
		self.inABatch = NO;
		
		NSLog(@"(ending a batch at size %d)", (int) batchSize);
		batchSize = 0;

		[self.delegate downloaderDidEndBatch:self];
	}
}

- (void) batchDidTimeOut;
{
	[self endBatchImmediatelyIfNeeded];
}

@end
