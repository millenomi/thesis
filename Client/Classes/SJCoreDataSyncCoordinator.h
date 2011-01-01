//
//  SJCoreDataSyncCoordinator.h
//  Client
//
//  Created by ∞ on 01/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "SJSyncCoordinator.h"

#define kSJCoreDataSyncControllerWillBeginEditing @"SJCoreDataSyncControllerWillBeginEditing"
#define kSJCoreDataSyncControllerDidEndEditing @"SJCoreDataSyncControllerDidEndEditing"

@interface SJCoreDataSyncController : NSObject <SJSyncController> {
@private
	int saveHoldCount;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*) moc;

- (NSFetchRequest*) fetchRequestForUpdate:(SJEntityUpdate*) update; // abstract
- (NSFetchRequest*) fetchRequestForClass:(Class) c URLStringKeyPath:(NSString*) kp URL:(NSURL*) url;

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update correspondingToFetchedObject:(id) obj;
- (id) managedObjectCorrespondingToUpdate:(SJEntityUpdate *)update;

- (void) beginEditing;
- (void) endEditing;
- (BOOL) saveIfFinished:(NSError **)e;

@property(nonatomic, retain, readonly) NSManagedObjectContext* managedObjectContext;

@end
