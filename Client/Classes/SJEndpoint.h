//
//  SJEndpoint.h
//  Subject
//
//  Created by ∞ on 21/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SJRequest <NSObject>

- (void) start;
- (void) cancel;

- (BOOL) isFinished;

- (id) JSONValue;
- (id) JSONValueWithSchema:(Class) schema error:(NSError**) e;
- (NSError*) error;

- (NSHTTPURLResponse*) HTTPResponse;
- (NSURLRequest*) HTTPRequest;
- (NSURL*) URL;

- (void) setShouldNotLog;

@end

typedef void (^SJRequestCompletionHandler)(id <SJRequest>);


@interface SJEndpoint : NSObject {
	NSMutableDictionary* unfinishedRequests;
}

- (id) initWithURL:(NSURL*) url;

@property(readonly, copy) NSURL* URL;
- (NSURL*) URL:(NSString*) relativeURL;

// will coalesce multiple calls for the same URL to a single request.
- (id <SJRequest>) beginDownloadingFromURL:(id) stringOrURL completionHandler:(SJRequestCompletionHandler) handler;
- (id <SJRequest>) requestForDownloadingFromURL:(id) stringOrURL completionHandler:(void(^)(id <SJRequest>)) handler;

- (id <SJRequest>) requestFromURLRequest:(NSURLRequest*) req completionHandler:(void(^)(id <SJRequest>)) handler;

@property(readonly, retain) NSDictionary* unfinishedRequestsByURL;

@end
