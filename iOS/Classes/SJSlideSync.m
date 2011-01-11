//
//  SJSlideSync.m
//  Subject
//
//  Created by ∞ on 01/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJSlideSync.h"

#import "SJSlide.h"
#import "SJPresentation.h"
#import "SJPoint.h"

@implementation SJSlideSync

- (void) addToCoordinator:(SJSyncCoordinator *)coord;
{
	[coord setSyncController:self forEntitiesWithSnapshotsClass:[SJSlideSchema class]];
}

- (BOOL) shouldDownloadSnapshotForUpdate:(SJEntityUpdate *)update;
{
	if ([update.userInfo isEqual:@"image"]) {
		SJSlide* s = [self managedObjectCorrespondingToUpdate:update.referrerEntityUpdate];
		return s.imageData == nil;
	} else {
		return [super shouldDownloadSnapshotForUpdate:update];
	}
}

- (NSFetchRequest *) fetchRequestForUpdate:(SJEntityUpdate *)update;
{
	return [self fetchRequestForClass:[SJSlide class] URLStringKeyPath:@"URLString" URL:update.URL];
}

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update correspondingToFetchedObject:(id)obj;
{
	if ([update.userInfo isEqual:@"image"]) {
		SJSlide* s = [self managedObjectCorrespondingToUpdate:update.referrerEntityUpdate];
		s.imageData = snapshot;
		return;
	}
	
	SJSlide* slide = obj;
	if (!slide)
		slide = [SJSlide insertedInto:self.managedObjectContext];
	
	SJSlideSchema* schema = snapshot;
	slide.URL = update.URL;
	slide.sortingOrderValue = [schema.sortingOrder unsignedIntegerValue];

	NSURL* presentationURL = [update relativeURLTo:schema.presentationURLString];
	SJPresentation* presentation = [SJPresentation presentationWithURL:presentationURL fromContext:self.managedObjectContext];

	if (presentation)
		slide.presentation = presentation;
	else {
		[self.syncCoordinator afterDownloadingNextSnapshotForEntityAtURL:presentationURL perform:^{
			
			SJPresentation* presentation = [SJPresentation presentationWithURL:presentationURL fromContext:self.managedObjectContext];
			SJSlide* s = [self managedObjectCorrespondingToUpdate:update];
			
			s.presentation = presentation;
			
		}];
		
		[self.syncCoordinator processUpdate:
		 [update relatedUpdateWithSnapshotsClass:[SJPresentationSchema class] URL:presentationURL refers:NO]
		 ];
	}
	
	NSInteger i = 0;
	
	for (SJPointSchema* pointSchema in schema.points) {
		NSURL* pointURL = [update relativeURLTo:pointSchema.URLString];
		
		[self.syncCoordinator processUpdate:
		 [SJEntityUpdate updateWithAvailableSnapshot:pointSchema URL:pointURL]
		 ];
		
		SJPoint* point = [SJPoint pointWithURL:pointURL fromContext:self.managedObjectContext];
		if (point) {
			[slide addPointsObject:point];
			point.sortingOrderValue = i;
		}
		
		i++;
	}
		
	if (!slide.imageData && schema.imageURLString) {
		SJEntityUpdate* imageUpdate = 
			[update relatedUpdateWithSnapshotsClass:[SJSlideSchema class] URL:[update relativeURLTo:schema.imageURLString] refers:YES];
		
		imageUpdate.userInfo = @"image";
		imageUpdate.snapshotKind = kSJEntityUpdateSnapshotKindData;
		
		BOOL _debug_isInteresting = [[[imageUpdate URL] absoluteString] isEqual:@"http://infinitelabs-subject.appspot.com/presentations/at/4001/slides/1/image"] && imageUpdate.downloadPriority != kSJDownloadPrioritySubresourceForImmediateDisplay;

		[self.syncCoordinator processUpdate:imageUpdate];
	}
}

+ (void) requireUpdateForContentsOfSlide:(SJSlide*) s priority:(SJDownloadPriority) priority;
{
	SJEntityUpdate* up;
	
	up = [SJEntityUpdate updateWithSnapshotsClass:[SJSlideSchema class] URL:s.URL];
	up.requireRefetch = YES;
	up.downloadPriority = priority;
	[s incompleteObjectNeedsFetchingSnapshotWithUpdate:up];
	
	if (s.imageURLString && !s.imageData) {
		up = [up relatedUpdateWithSnapshotsClass:[SJSlideSchema class] URL:s.URL refers:YES];
		up.requireRefetch = YES;
		up.userInfo = @"image";
		up.snapshotKind = kSJEntityUpdateSnapshotKindData;
		[s incompleteObjectNeedsFetchingSnapshotWithUpdate:up];
	}
}

@end
