//
//  SJLive.h
//  Subject
//
//  Created by ∞ on 21/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJEndpoint.h"

#import "SJPresentation.h"
#import "SJSlide.h"
#import "SJPoint.h"

#import "SJClient.h"

@protocol SJLiveDelegate;


@interface SJLive : NSObject {
	NSTimer* timer;
	BOOL isWaitingOnHeartbeatRequest;
	NSMutableSet* unassignedSlides;
}

- (id) initWithEndpoint:(SJEndpoint*) endpoint delegate:(id <SJLiveDelegate>) delegate managedObjectContext:(NSManagedObjectContext*) moc;

@property(assign) id <SJLiveDelegate> delegate;

- (void) stop;

- (void) askQuestionOfKind:(NSString*) kind forPoint:(SJPoint*) point; // completionHandler:(void(^)(BOOL ok)) handler;
- (void) askFreeformQuestion:(NSString*) question forPoint:(SJPoint*) point;

@end


@protocol SJLiveDelegate <NSObject>

- (void) live:(SJLive*) live willBeginRunningPresentationAtURL:(NSURL*) presURL slideURL:(NSURL*) slideURL;
- (void) live:(SJLive*) live didFetchRunningPresentation:(SJPresentation*) pres;

- (void) liveDidEnd:(SJLive*) live;

- (void) live:(SJLive*) live willBeginMovingToSlideAtURL:(NSURL*) slideURL;
- (void) live:(SJLive*) live didMoveToSlide:(SJSlide*) slide;

- (void) live:(SJLive*) live didUpdateCurrentSlide:(SJSlide*) slide;

- (void) live:(SJLive*) live didDownloadQuestion:(SJQuestion*) q;

@end