//
//  SJCoreDataSyncCoordinator.m
//  Client
//
//  Created by ∞ on 01/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SJCoreDataSyncCoordinator.h"

@interface SJCoreDataSyncController ()

@property(nonatomic, retain) NSManagedObjectContext* managedObjectContext;

@end


@implementation SJCoreDataSyncController

- (id) initWithManagedObjectContext:(NSManagedObjectContext*) moc;
{
	if ((self = [super init])) {
		self.managedObjectContext = moc;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observerWillBeginEditing:) name:kSJCoreDataSyncControllerWillBeginEditing object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observerDidEndEditing:) name:kSJCoreDataSyncControllerDidEndEditing object:nil];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.managedObjectContext = nil;
	[super dealloc];
}

#pragma mark Processing updates

@synthesize syncCoordinator;
@synthesize managedObjectContext;

- (NSFetchRequest*) fetchRequestForUpdate:(SJEntityUpdate*) update;
{
	return nil;
}

- (NSFetchRequest*) fetchRequestForClass:(Class) c URLStringKeyPath:(NSString*) kp URL:(NSURL*) url;
{
	NSFetchRequest* req = [[NSFetchRequest new] autorelease];
	[req setEntity:[NSEntityDescription entityForName:NSStringFromClass(c) inManagedObjectContext:self.managedObjectContext]];
	[req setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", kp, [url absoluteString]]];
	return req;
}

- (BOOL) shouldDownloadSnapshotForUpdate:(SJEntityUpdate *)update;
{
	NSFetchRequest* req = [self fetchRequestForUpdate:update];
	
	if (req)
		return [self.managedObjectContext countForFetchRequest:req error:NULL] == 0;
	else
		return NO;
}

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update;
{
	[self beginEditing];
	[self processSnapshot:snapshot forUpdate:update correspondingToFetchedObject:[self managedObjectCorrespondingToUpdate:update]];
	[self endEditing];
	[self saveIfFinished:NULL];
}

- (id) managedObjectCorrespondingToUpdate:(SJEntityUpdate*) update;
{
	NSFetchRequest* req = [self fetchRequestForUpdate:update];
	id obj = nil;
	if (req) {
		[req setFetchLimit:1];
		NSArray* objs = [self.managedObjectContext executeFetchRequest:req error:NULL];
		
		obj = [objs count] > 0? [objs objectAtIndex:0] : nil;
	}
	
	return obj;
}

- (void) didFailDownloadingUpdate:(SJEntityUpdate*) update error:(NSError*) error;
{
	// this method intentionally left blank
}

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update correspondingToFetchedObject:(id) obj;
{
	// this method intentionally left blank
}

#pragma mark Editing

- (void) beginEditing;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSJCoreDataSyncControllerWillBeginEditing object:self];
}

- (void) endEditing;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSJCoreDataSyncControllerDidEndEditing object:self];
}

- (void) observerWillBeginEditing:(NSNotification*) n;
{
	if (self.managedObjectContext == [[n object] managedObjectContext])
		saveHoldCount++;
}

- (void) observerDidEndEditing:(NSNotification *)n;
{
	if (self.managedObjectContext == [[n object] managedObjectContext])
		saveHoldCount--;
}

- (BOOL) saveIfFinished:(NSError**) e;
{
	if (saveHoldCount == 0) {
		BOOL ok = [self.managedObjectContext save:e];
		if (!ok)
			[self.managedObjectContext rollback];
		return ok;
	} else {
		return YES;
	}
}

@end
