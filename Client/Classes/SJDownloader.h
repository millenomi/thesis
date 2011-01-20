//
//  SJDownloader.h
//  Client
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSJWillBeginUsingNetworkForImmediateDisplayNotification @"kSJWillBeginUsingNetworkForImmediateDisplayNotification"
#define kSJDidEndUsingNetworkForImmediateDisplayNotification @"kSJDidEndUsingNetworkForImmediateDisplayNotification"

#define kSJDownloaderErrorDomain @"SJDownloaderErrorDomain"
enum {
	kSJDownloaderErrorWillNotPerformOpportunisticDownloadsOnWWAN = 1,
};

typedef enum {
	// only attempted on non-WWAN networks.
	// all executing ones will be cancelled if a user request arrives.
	kSJDownloadPriorityOpportunistic = 0,
	
	kSJDownloadResourceWillProbablyDisplayInImmediateFuture,
	
	kSJDownloadPrioritySubresourceForImmediateDisplay,
	kSJDownloadPriorityResourceForImmediateDisplay,
	kSJDownloadPriorityLiveUpdate,
} SJDownloadPriority;

#define kSJDownloaderOptionDownloadReason @"SJDownloaderOptionDownloadReason"
#define kSJDownloaderOptionUserInfo @"SJDownloaderOptionUserInfo"

@class SJDownloadRequest;
@protocol SJDownloaderDelegate;


@interface SJDownloader : NSObject {
	NSMutableArray* pendingLowPriorityRequests;
	NSMutableSet* runningLowPriorityRequests, * runningHighPriorityRequests;
	NSMutableDictionary* downloadedDataByConnection, * requestsByConnection;
	
	NSInteger batchSize;
}

+ downloader;

- (void) beginDownloadingWithRequest:(SJDownloadRequest*) request;
@property(nonatomic, assign) id <SJDownloaderDelegate> delegate;

// Batching can only be turned on if there are no pending requests.
// If this property is 1, then no batching occurs. Default is 1, so no batching. Setting to 0 will set this value to 1 instead.
// If > 1, the delegate will receive batching method calls before and after each batch.
@property(nonatomic) NSUInteger downloadBatchSize;

// Defines a time interval. If a batch has to wait for this many seconds for a new result, instead it's closed, even if it hasn't reached the .downloadBatchSize.
// Only meaningful while .downloadBatchSize > 1.
// Default is 5 seconds.
@property(nonatomic) NSTimeInterval downloadBatchWaitTimeout;

@end


@protocol SJDownloaderDelegate <NSObject>

// The request
- (void) downloader:(SJDownloader*) d didFinishDowloadingRequest:(SJDownloadRequest*) req;

@optional
// but required if you set .downloadBatchSize > 1.

// Called before calling didFinishDowloadingRequest:... for all requests in the batch.
// Please note that some requests may not be batched; these requests do not cause this method to be called prior to calling didFinishDowloadingRequest:.
- (void) downloaderWillBeginBatch:(SJDownloader*) d;

// Called after calling didFinishDowloadingRequest:... for all requests in the batch. Only sent after downloaderWillBeginBatch: has been called.
- (void) downloaderDidEndBatch:(SJDownloader*) d;

@end


@interface SJDownloadRequest : NSObject <NSCopying> {}

+ downloadRequest;

@property(copy) NSURL* URL;
@property SJDownloadPriority reason;
@property(retain) id userInfo;

@property(retain) NSData* downloadedData;
@property(copy) NSError* error;

@end
