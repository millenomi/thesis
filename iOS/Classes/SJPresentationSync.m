//
//  SJPresentationSync.m
//  Subject
//
//  Created by ∞ on 03/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPresentationSync.h"
#import "SJClient.h"

#import "SJPresentation.h"
#import "SJSlide.h"

@implementation SJPresentationSync

- (void) addToCoordinator:(SJSyncCoordinator *)coord;
{
	[coord setSyncController:self forEntitiesWithSnapshotsClass:[SJPresentationSchema class]];
}

- (NSFetchRequest *) fetchRequestForUpdate:(SJEntityUpdate *)update;
{
	return [self fetchRequestForClass:[SJPresentation class] URLStringKeyPath:@"URLString" URL:update.URL];
}

- (BOOL) shouldDownloadSnapshotForUpdate:(SJEntityUpdate *)update;
{
	SJPresentation* p = [self managedObjectCorrespondingToUpdate:update];
	return !p || !p.knownCountOfSlides || p.knownCountOfSlidesValue != [p.slides count];
}

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update correspondingToFetchedObject:(id)obj;
{
	if (!obj)
		obj = [SJPresentation insertedInto:self.managedObjectContext];
	
	SJPresentation* pres = obj;
	SJPresentationSchema* presSchema = snapshot;
	
	pres.title = presSchema.title;
	pres.knownCountOfSlidesValue = [presSchema.slides count];
	
	for (SJPresentationSlideInfoSchema* slideInfo in presSchema.slides) {
		SJEntityUpdate* slideUpdate = [SJEntityUpdate updateWithSnapshotsClass:[SJSlideSchema class] URL:[NSURL URLWithString:slideInfo.URLString relativeToURL:update.URL]];
		
		slideUpdate.availableSnapshot = slideInfo.contents;
		
		[self.syncCoordinator processUpdate:slideUpdate];
	}
}

@end
