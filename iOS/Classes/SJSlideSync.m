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
		 [SJEntityUpdate updateWithSnapshotsClass:[SJPresentationSchema class] URL:presentationURL]
		 ];
	}
	
	NSInteger i = 0;
	
	for (SJPointSchema* pointSchema in schema.points) {
		NSURL* pointURL = [update relativeURLTo:pointSchema.URLString];
		
		[self.syncCoordinator processUpdate:
		 [SJEntityUpdate updateWithAvailableSnapshot:pointSchema URL:pointURL]
		 ];
		
		SJPoint* point = [SJPoint pointWithURL:pointURL fromContext:self.managedObjectContext];
		[slide addPointsObject:point];
		point.sortingOrderValue = i;
		
		i++;
	}
	
	if (!slide.imageData && schema.imageURLString) {
		SJEntityUpdate* imageUpdate = 
			[update relatedUpdateWithSnapshotClass:[SJSlideSchema class] URL:[update relativeURLTo:schema.imageURLString] refers:YES];
		
		imageUpdate.userInfo = @"image";
		imageUpdate.snapshotKind = kSJEntityUpdateSnapshotKindData;
		
		[self.syncCoordinator processUpdate:imageUpdate];
	}
}

@end
