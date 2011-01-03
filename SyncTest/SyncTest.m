#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Foundation/Basics/ILErrorHandling.h"
#import "SJClient.h"
#import "SJSlideSync.h"

// ------------ the sync controller delegate

@interface SJTestLiveSyncDelegate : NSObject <SJLiveSyncControllerDelegate>
@end


// -----------------------------------------

int main (int argc, const char * argv[]) {

	// Let's build a CD stack.
	NSBundle* me = [NSBundle mainBundle];
	NSDictionary* environment = [[NSProcessInfo processInfo] environment];
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSManagedObjectModel* mom = [NSManagedObjectModel mergedModelFromBundles:nil];
	NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
	
	NSURL* store = [[me bundleURL] URLByAppendingPathComponent:@"Store.sqlite"];
	
	if ([[environment objectForKey:@"SJSyncTestClearBackingStoreBeforeUse"] boolValue])
		[fm removeItemAtURL:store error:NULL];
	
	ILCAssertNoNSError([psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:store options:nil error:&ERROR]);
	
	NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] init];
	[moc setPersistentStoreCoordinator:psc];
	
	// ---------------------------------
	
	// Now, set up a sync stack.
	
	NSURL* baseURL = [NSURL URLWithString:@"http://localhost:8083/"];
	
	SJSyncCoordinator* coord = [[SJSyncCoordinator alloc] init];
	[SJLiveSyncController addControllerForLiveURL:[NSURL URLWithString:@"/live" relativeToURL:baseURL] delegate:[SJTestLiveSyncDelegate new] toCoordinator:coord];
	[SJSlideSync addControllerWithManagedObjectContext:moc toCoordinator:coord];
	
	// ---------------------------------
	
	// RUN BABY RUN
	
	while (YES) // 'til interrupt does us part
		[[NSRunLoop currentRunLoop] run];
	
    return 0;
}

// live sync logging

@implementation SJTestLiveSyncDelegate

- (void) liveDidStart:(SJLiveSyncController *)observer;
{
	NSLog(@"Did start");
}

- (void) liveDidEnd:(SJLiveSyncController *)observer;
{
	NSLog(@"Did end");
}

- (void) live:(SJLiveSyncController *)observer didPostMoodsAtURLs:(NSSet *)urls;
{
	NSLog(@"Did post moods at URLs: %@", urls);
}

- (void) live:(SJLiveSyncController *)observer didPostQuestionsAtURLs:(NSSet *)urls;
{
	NSLog(@"Did post questions at URLs: %@", urls);
}

- (void) live:(SJLiveSyncController *)observer didMoveToSlideAtURL:(NSURL *)url schema:(SJSlideSchema *)schema;
{
	NSLog(@"Did move to slide with URL %@, schema %@", url, schema);
}

- (void) live:(SJLiveSyncController *)observer didFailToLoadWithError:(NSError *)e;
{
	NSLog(@"Did fail to load with error %@", e);
}

@end


// -----------------------------------------
