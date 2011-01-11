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
	
	pres.URL = update.URL;
	pres.title = presSchema.title;
	
	NSMutableArray* URLs = [NSMutableArray arrayWithCapacity:[presSchema.slides count]];
	
	// To avoid problems, first we fill in the presentation, then we issue updates.
	
	for (SJPresentationSlideInfoSchema* slideInfo in presSchema.slides) {
		NSURL* slideURL = [NSURL URLWithString:slideInfo.URLString relativeToURL:update.URL];
		[URLs addObject:slideURL];
	}
	
	pres.knownSlideURLs = [[URLs copy] autorelease];
	
	NSInteger i = 0;
	for (SJPresentationSlideInfoSchema* slideInfo in presSchema.slides) {
		NSURL* url = [URLs objectAtIndex:i];
		
		SJSlide* s = [SJSlide slideWithURL:url fromContext:self.managedObjectContext];
		s.presentation = pres;

		SJEntityUpdate* up = [SJEntityUpdate updateWithSnapshotsClass:[SJSlideSchema class] URL:url];
		up.availableSnapshot = slideInfo.contents;
		[self.syncCoordinator processUpdate:up];
	
		i++;
	}
}

+ (void) requireUpdateForContentsOfPresentation:(SJPresentation*) p priority:(SJDownloadPriority) priority;
{
	SJEntityUpdate* up;
	
	if (!p.knownSlideURLs) {
		up = [SJEntityUpdate updateWithSnapshotsClass:[SJPresentationSchema class] URL:p.URL];
		up.downloadPriority = priority;
		[p incompleteObjectNeedsFetchingSnapshotWithUpdate:up];	
	}
}

@end
