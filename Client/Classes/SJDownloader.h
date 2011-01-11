//
//  SJDownloader.h
//  Client
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSJDownloaderErrorDomain @"SJDownloaderErrorDomain"
enum {
	kSJDownloaderErrorWillNotPerformOpportunisticDownloadsOnWWAN = 1,
};

typedef enum {
	// only attempted on non-WWAN networks.
	// all executing ones will be cancelled if a user request arrives.
	kSJDownloadPriorityOpportunistic = 0,
	
	kSJDownloadPrioritySubresourceForImmediateDisplay,
	kSJDownloadPriorityResourceForImmediateDisplay,
	kSJDownloadPriorityLiveUpdate,
} SJDownloadPriority;

#define kSJDownloaderOptionDownloadReason @"SJDownloaderOptionDownloadReason"
#define kSJDownloaderOptionUserInfo @"SJDownloaderOptionUserInfo"

@class SJDownloadRequest;
@protocol SJDownloaderDelegate;


@interface SJDownloader : NSObject {
	int queueHoldCount;
}

+ downloader;

- (void) beginDownloadingWithRequest:(SJDownloadRequest*) request;
@property(nonatomic, assign) id <SJDownloaderDelegate> delegate;

@property(nonatomic) BOOL monitorsInternetReachability;

@end


@protocol SJDownloaderDelegate <NSObject>

// The request
- (void) downloader:(SJDownloader*) d didFinishDowloadingRequest:(SJDownloadRequest*) req;

@end


@interface SJDownloadRequest : NSObject <NSCopying> {}

+ downloadRequest;

@property(copy) NSURL* URL;
@property SJDownloadPriority reason;
@property(retain) id userInfo;

@property(retain) NSData* downloadedData;
@property(copy) NSError* error;

@end
