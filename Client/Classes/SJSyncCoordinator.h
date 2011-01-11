//
//  SJSyncCoordinator.h
//  Client
//
//  Created by ∞ on 31/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJDownloader.h"
@class SJEntityUpdate;
@protocol SJSyncController;

enum {
	kSJEntityUpdateSnapshotKindSchema,
	kSJEntityUpdateSnapshotKindData,
};
typedef NSInteger SJEntityUpdateSnapshotKind;


@interface SJSyncCoordinator : NSObject {}

@property(nonatomic, assign) BOOL monitorsIncompleteObjectFetchNotifications;

- (void) setSyncController:(id <SJSyncController>) ctl forEntitiesWithSnapshotsClass:(Class) c;
- (void) removeSyncControllerForEntitiesWithSnapshotsClass:(Class) c;

- (void) processUpdate:(SJEntityUpdate*) update;

- (void) afterDownloadingNextSnapshotForEntityAtURL:(NSURL*) url perform:(void (^)()) block;

@property(nonatomic, readonly, retain) SJDownloader* downloader;

@end


@interface SJEntityUpdate : NSObject

+ updateWithSnapshotsClass:(Class) c URL:(NSURL*) url;
+ updateWithAvailableSnapshot:(id) snap URL:(NSURL*) url;

// To be used whenever this update needs:
// - a subresource for immediate display; or
// - a superresource.
- (SJEntityUpdate*) relatedUpdateWithSnapshotsClass:(Class) c URL:(NSURL*) url refers:(BOOL) ref;
- (SJEntityUpdate*) relatedUpdateWithAvailableSnapshot:(id) snap URL:(NSURL*) url refers:(BOOL) ref;

- (NSURL*) relativeURLTo:(NSString*) path;

@property(nonatomic, assign) Class snapshotsClass;
@property(nonatomic, copy) NSURL* URL;

@property(nonatomic, copy) id availableSnapshot;

@property(nonatomic) SJDownloadPriority downloadPriority;
@property(nonatomic) BOOL requireRefetch;

@property(nonatomic, copy) id userInfo;
@property(nonatomic) SJEntityUpdateSnapshotKind snapshotKind;
@property(nonatomic, retain) SJEntityUpdate* referrerEntityUpdate;

@end


@protocol SJSyncController <NSObject>

- (BOOL) shouldDownloadSnapshotForUpdate:(SJEntityUpdate*) update;
- (void) processSnapshot:(id) snapshot forUpdate:(SJEntityUpdate*) update;

- (BOOL) shouldRescheduleFailedDownloadForUpdate:(SJEntityUpdate*) update error:(NSError*) error;

@property(nonatomic, assign) SJSyncCoordinator* syncCoordinator;

@end


// Model snapshot fetch triggering

#define kSJIncompleteObjectsRequiresFetchNotification @"SJIncompleteObjectsRequiresFetchNotification"
#define kSJEntityUpdateKey @"SJEntityUpdate"

@interface NSObject (SJEntityFetchTriggering)

- (void) incompleteObjectNeedsFetchingSnapshotWithUpdate:(SJEntityUpdate*) up;

@end

