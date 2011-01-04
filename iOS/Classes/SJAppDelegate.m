//
//  SubjectAppDelegate.m
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJAppDelegate.h"
#import "SJEndpoint.h"
#import "SJLiveSchema.h"
#import "SJPresentationSchema.h"
#import "ILSensorSink.h"
#import "ILNSLoggerSensorTap.h"

#import "SJClient.h"

#import "SJSlide.h"

#import "SJSlideSync.h"
#import "SJPresentationSync.h"
#import "SJPointSync.h"
#import "SJQuestionSync.h"

@interface SJAppDelegate ()

@property(nonatomic, retain) SJSyncCoordinator* syncCoordinator;
@property(nonatomic, retain) SJLiveSyncController* liveSyncController;

- (void) saveCurrentSlideIdentifier;

@end


@implementation SJAppDelegate

#pragma mark -
#pragma mark Application lifecycle

@synthesize syncCoordinator, liveSyncController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	application.idleTimerDisabled = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
	
	[[ILSensorSink sharedSink] addTap:[[ILNSLoggerSensorTap new] autorelease]];
	//[[ILSensorSink sharedSink] setEnabled:YES];
	
	
	NSString* baseURLString = [[[NSProcessInfo processInfo] environment] objectForKey:@"SJEndpointURL"];
	if (!baseURLString)
		baseURLString = @"http://infinitelabs-subject.appspot.com";
	
	NSURL* baseURL = [NSURL URLWithString:baseURLString];
	
	self.syncCoordinator = [[SJSyncCoordinator alloc] init];
	
	SJSyncCoordinator* coord = self.syncCoordinator;
	NSManagedObjectContext* moc = self.managedObjectContext;
	
	self.liveSyncController = [SJLiveSyncController addControllerForLiveURL:[NSURL URLWithString:@"live" relativeToURL:baseURL] delegate:nil toCoordinator:coord];
	[SJSlideSync addControllerWithManagedObjectContext:moc toCoordinator:coord];
	[SJPresentationSync addControllerWithManagedObjectContext:moc toCoordinator:coord];
	[SJPointSync addControllerWithManagedObjectContext:moc toCoordinator:coord];
	[SJQuestionSync addControllerWithManagedObjectContext:moc toCoordinator:coord];	
	
	livePane.liveSyncController = self.liveSyncController;
	livePane.managedObjectContext = moc;
	
	NSString* slideIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"SJLastDisplayedSlideURIIdentifier"];
	NSURL* slideIdentifierURL = nil; 
	NSManagedObjectID* slideIdentifierObject = nil;

	if (slideIdentifier)
		slideIdentifierURL = [NSURL URLWithString:slideIdentifier];
		
	if (slideIdentifierURL)
		slideIdentifierObject = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:slideIdentifierURL];
	
	if (slideIdentifierObject) {
		id s = [self.managedObjectContext objectWithID:slideIdentifierObject];
		if (s && [s isKindOfClass:[SJSlide class]])
			livePane.displayedSlide = s;
	}
	
    [window makeKeyAndVisible];
    
    return YES;
}

- (void) saveCurrentSlideIdentifier;
{	
	SJSlide* s = livePane.displayedSlide;
	NSManagedObjectID* ident = [s objectID];
	
	if (![ident isTemporaryID]) {
		NSString* slideIdentifier = [[ident URIRepresentation] absoluteString];
		[[NSUserDefaults standardUserDefaults] setObject:slideIdentifier forKey:@"SJLastDisplayedSlideURIIdentifier"];
	}
}

- (void) userDefaultsDidChange:(NSNotificationCenter*) nc;
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kSJEraseAllLocalContent"] && persistentStoreCoordinator_)
		abort();
}

- (void) applicationDidEnterBackground:(UIApplication*) application;
{
    [self saveContext];
	[self saveCurrentSlideIdentifier];
}

- (void) applicationWillTerminate:(UIApplication *) application;
{
    [self saveContext];
	[self saveCurrentSlideIdentifier];
}


- (void)saveContext {
    
    NSError *error = nil;
    if (managedObjectContext_ != nil) {
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}    


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Subject" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
	
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Subject.sqlite"]];
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	if ([ud boolForKey:@"kSJEraseAllLocalContent"]) {
		[ud setBool:NO forKey:@"kSJEraseAllLocalContent"];
		[ud synchronize];
		
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];
	}
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
    [window release];
    [super dealloc];
}


@end

