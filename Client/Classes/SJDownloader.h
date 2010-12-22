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

enum {
	// only attempted on non-WWAN networks.
	// all executing ones will be cancelled if a user request arrives.
	kSJDownloaderReasonOpportunistic,
	
	// cancelled if running and a user request arrives.
	kSJDownloaderReasonSubresourceForImmediateDisplay,
	
	// never cancelled. highest priority of all.
	kSJDownloaderReasonResourceForImmediateDisplay,
	
	// has its own private queue
	kSJDownloaderReasonLiveUpdate,
};
typedef NSUInteger SJDownloaderReason;

#define kSJDownloaderOptionDownloadReason @"SJDownloaderOptionDownloadReason"
#define kSJDownloaderOptionUserInfo @"SJDownloaderOptionUserInfo"

@protocol SJDownloaderDelegate;


@interface SJDownloader : NSObject {}

+ downloader;

- (void) beginDownloadingDataFromURL:(NSURL*) u options:(NSDictionary*) options;
@property(nonatomic, assign) id <SJDownloaderDelegate> delegate;

@end

@protocol SJDownloaderDelegate <NSObject>

- (void) downloader:(SJDownloader*) d didDownloadData:(NSData*) data forURL:(NSURL*) url options:(NSDictionary*) options;
- (void) downloader:(SJDownloader*) d didFailDownloadingDataForURL:(NSURL*) url options:(NSDictionary*) options error:(NSError*) e;

@end
