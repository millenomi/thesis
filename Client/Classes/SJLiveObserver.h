//
//  SJLiveObserver.h
//  Client
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJSchemaProvider.h"

@class SJLiveSchema, SJSlideSchema, SJEndpoint;

@protocol SJLiveObserverDelegate;

@interface SJLiveObserver : NSObject <SJSchemaProviderObserver> {}

- (id) initWithEndpoint:(SJEndpoint*) ep;

@property(nonatomic, assign) id <SJLiveObserverDelegate> delegate;
@property(nonatomic, retain, readonly) SJLiveSchema* latestDownloadedSchema;

@end


@protocol SJLiveObserverDelegate <NSObject>

- (void) liveDidStart:(SJLiveObserver*) observer;
- (void) liveDidEnd:(SJLiveObserver*) observer;

- (void) live:(SJLiveObserver*) observer didMoveToSlideAtURL:(NSURL*) url schema:(SJSlideSchema*) schema;

- (void) live:(SJLiveObserver*) observer didPostQuestionsAtURLs:(NSSet*) urls;
- (void) live:(SJLiveObserver*) observer didPostMoodsAtURLs:(NSSet*) urls;

- (void) live:(SJLiveObserver*) observer didFailToLoadWithError:(NSError*) e;

@end