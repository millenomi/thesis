//
//  SJPointSync.m
//  Subject
//
//  Created by ∞ on 03/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPointSync.h"

#import "SJPoint.h"
#import "SJSlide.h"
#import "SJQuestion.h"

@implementation SJPointSync

- (void) addToCoordinator:(SJSyncCoordinator *)coord;
{
	[coord setSyncController:self forEntitiesWithSnapshotsClass:[SJPointSchema class]];
}

- (NSFetchRequest *) fetchRequestForUpdate:(SJEntityUpdate *)update;
{
	return [self fetchRequestForClass:[SJPoint class] URLStringKeyPath:@"URLString" URL:update.URL];
}

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update correspondingToFetchedObject:(id)obj;
{
	SJPoint* point = obj?: [SJPoint insertedInto:self.managedObjectContext];
	SJPointSchema* pointSchema = snapshot;
	
	point.URL = update.URL;
	point.text = pointSchema.text;
	point.indentationValue = pointSchema.indentationValue;
	
	if (pointSchema.slideURLString) {
		NSURL* slideURL = [NSURL URLWithString:pointSchema.slideURLString relativeToURL:update.URL];
		SJSlide* slide = [SJSlide slideWithURL:slideURL fromContext:self.managedObjectContext];
		
		if (slide)
			point.slide = slide;
		else {
			[self.syncCoordinator afterDownloadingNextSnapshotForEntityAtURL:slideURL perform:^{
				SJPoint* p = [self managedObjectCorrespondingToUpdate:update];
				SJSlide* s = [SJSlide slideWithURL:slideURL fromContext:self.managedObjectContext];
				
				p.slide = s;
			}];
			
			[self.syncCoordinator processUpdate:[SJEntityUpdate updateWithSnapshotsClass:[SJSlideSchema class] URL:slideURL]];
		}
	}
	
	for (NSString* questionURLString in pointSchema.questionURLStrings) {
		NSURL* questionURL = [NSURL URLWithString:questionURLString relativeToURL:update.URL];
		
		SJQuestion* question = [SJQuestion oneWhereKey:@"URLString" equals:[questionURL absoluteString] fromContext:self.managedObjectContext];
		if (question) {
			question.point = point;
		} else {
			[self.syncCoordinator afterDownloadingNextSnapshotForEntityAtURL:questionURL perform:^{
				SJPoint* p = [self managedObjectCorrespondingToUpdate:update];
				SJQuestion* question = [SJQuestion oneWhereKey:@"URLString" equals:[questionURL absoluteString] fromContext:self.managedObjectContext];
				question.point = p;
			}];
			
			[self.syncCoordinator processUpdate:[update relatedUpdateWithSnapshotsClass:[SJQuestionSchema class] URL:questionURL refers:NO]];
		}
	}
}

@end
