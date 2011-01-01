//
//  SJLiveSyncController.h
//  Client
//
//  Created by ∞ on 01/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJSyncCoordinator.h"
#import "SJLiveSchema.h"
@protocol SJLiveSyncControllerDelegate;

@interface SJLiveSyncController : NSObject <SJSyncController> {}

+ addControllerForLiveURL:(NSURL*) url toCoordinator:(SJSyncCoordinator*) coord;

- (id) initWithLiveURL:(NSURL*) url;

@property(nonatomic, assign) id <SJLiveSyncControllerDelegate> delegate;

@end


@protocol SJLiveSyncControllerDelegate <NSObject>

- (void) liveDidStart:(SJLiveSyncController*) observer;
- (void) liveDidEnd:(SJLiveSyncController*) observer;

- (void) live:(SJLiveSyncController*) observer didMoveToSlideAtURL:(NSURL*) url schema:(SJSlideSchema*) schema;

- (void) live:(SJLiveSyncController*) observer didPostQuestionsAtURLs:(NSSet*) urls;
- (void) live:(SJLiveSyncController*) observer didPostMoodsAtURLs:(NSSet*) urls;

- (void) live:(SJLiveSyncController*) observer didFailToLoadWithError:(NSError*) e;

@end