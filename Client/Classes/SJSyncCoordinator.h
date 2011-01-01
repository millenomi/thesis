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


@interface SJSyncCoordinator : NSObject {}

- (void) setSyncController:(id <SJSyncController>) ctl forEntitiesWithSnapshotsClass:(Class) c;
- (void) removeSyncControllerForEntitiesWithSnapshotsClass:(Class) c;

- (void) processUpdate:(SJEntityUpdate*) update;

- (void) afterDownloadingNextSnapshotForEntityAtURL:(NSURL*) url perform:(void (^)()) block;

@end


@interface SJEntityUpdate : NSObject

+ updateWithSnapshotsClass:(Class) c URL:(NSURL*) url;
+ updateWithAvailableSnapshot:(id) snap URL:(NSURL*) url;

- (SJEntityUpdate*) relatedUpdateWithSnapshotClass:(Class) c URL:(NSURL*) url;
- (SJEntityUpdate*) relatedUpdateWithAvailableSnapshot:(id) snap URL:(NSURL*) url;

- (NSURL*) relativeURLTo:(NSString*) path;

@property(nonatomic, assign) Class snapshotsClass;
@property(nonatomic, copy) NSURL* URL;

@property(nonatomic, copy) id availableSnapshot;

@property(nonatomic) SJDownloadPriority downloadPriority;

@end


@protocol SJSyncController <NSObject>

- (BOOL) shouldDownloadSnapshotForUpdate:(SJEntityUpdate*) update;
- (void) processSnapshot:(id) snapshot forUpdate:(SJEntityUpdate*) update;

- (void) didFailDownloadingUpdate:(SJEntityUpdate*) update error:(NSError*) error;

@property(nonatomic, assign) SJSyncCoordinator* syncCoordinator;

@end

