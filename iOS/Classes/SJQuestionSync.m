//
//  SJQuestionSync.m
//  Subject
//
//  Created by ∞ on 03/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJQuestionSync.h"

#import "SJQuestion.h"
#import "SJPoint.h"

@implementation SJQuestionSync

- (void) addToCoordinator:(SJSyncCoordinator *)coord;
{
	[coord setSyncController:self forEntitiesWithSnapshotsClass:[SJQuestionSchema class]];
}

- (NSFetchRequest*) fetchRequestForUpdate:(SJEntityUpdate *)update;
{
	return [self fetchRequestForClass:[SJQuestion class] URLStringKeyPath:@"URLString" URL:update.URL];
}

- (void) processSnapshot:(id)snapshot forUpdate:(SJEntityUpdate *)update correspondingToFetchedObject:(id)obj;
{
	SJQuestion* question = obj ?: [SJQuestion insertedInto:self.managedObjectContext];
	SJQuestionSchema* schema = snapshot;
	
	question.URL = update.URL;
	question.kind = schema.kind;
	question.text = schema.text;
	
	NSURL* pointURL = [NSURL URLWithString:schema.pointURLString relativeToURL:update.URL];
	SJPoint* point = [SJPoint pointWithURL:pointURL fromContext:self.managedObjectContext];
	
	if (point)
		question.point = point;
	else {
		[self.syncCoordinator afterDownloadingNextSnapshotForEntityAtURL:pointURL perform:^{
			SJQuestion* q = [self managedObjectCorrespondingToUpdate:update];
			if (!q.point)
				q.point = [SJPoint pointWithURL:pointURL fromContext:self.managedObjectContext];
		}];
		
		[self.syncCoordinator processUpdate:[SJEntityUpdate updateWithSnapshotsClass:[SJPointSchema class] URL:pointURL]];
	}
}

@end
