//
//  SJEndpoint.m
//  Subject
//
//  Created by ∞ on 21/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJEndpoint.h"
#import "SBJSON/NSString+SBJSON.h"

#import "ILSensorSink.h"
#import "ILSensorSession.h"

#import "SJSchema.h"

@interface SJEndpoint ()
@property(copy) NSURL* URL;
@end

@interface SJRequest : NSObject <SJRequest> {
	id JSONValue;
	
	BOOL didAddDependencyCompletionHandler;
	BOOL finished;
	BOOL shouldSuppressLogs;
}

- (id) initWithURLRequest:(NSURLRequest *)req completionHandler:(SJRequestCompletionHandler)handler beforeCompletionHandler:(SJRequestCompletionHandler) cleanup;

- (void) addCompletionHandler:(SJRequestCompletionHandler) h;
- (void) addDependencyHandler:(SJRequestCompletionHandler) h;

@property(nonatomic, copy) NSURLRequest* HTTPRequest;
@property(nonatomic, copy) NSHTTPURLResponse* HTTPResponse;

@property(nonatomic, copy) SJRequestCompletionHandler beforeCompletionHandler;
@property(nonatomic, retain) NSMutableSet* completionHandlers;
@property(nonatomic, retain) NSMutableSet* dependencyHandlers;

@property(nonatomic, retain) NSURLConnection* connection;

@property(nonatomic, retain) id JSONValue;
@property(nonatomic, copy) NSError* error;
@property(nonatomic, retain) NSMutableData* downloadedData;

@property(nonatomic, retain) NSMutableSet* unfinishedDependencies;

- (void) endInvokingCompletionHandlers;

@property(nonatomic, retain) ILSensorSession* session;

@end


@implementation SJEndpoint

- (id) initWithURL:(NSURL *)url;
{
	if ((self = [super init])) {
		self.URL = url;
		unfinishedRequests = [NSMutableDictionary new];
	}
	
	return self;
}

- (void) dealloc
{
	self.URL = nil;
	[unfinishedRequests release];
	[super dealloc];
}

- (NSURL*) URL:(NSString*) relativeURL;
{
	return [NSURL URLWithString:relativeURL relativeToURL:self.URL];
}

- (id <SJRequest>) beginDownloadingFromURL:(id) stringOrURL completionHandler:(void(^)(id <SJRequest>)) handler;
{
	id <SJRequest> r = [self requestForDownloadingFromURL:stringOrURL completionHandler:handler];
	[r start];
	return r;
}

- (id <SJRequest>) requestForDownloadingFromURL:(id) stringOrURL completionHandler:(void(^)(id <SJRequest>)) handler;
{
	if ([stringOrURL isKindOfClass:[NSString class]])
		stringOrURL = [self URL:stringOrURL];

	NSURLRequest* req = [NSURLRequest requestWithURL:stringOrURL];
	return [self requestFromURLRequest:req completionHandler:handler];
}

- (id <SJRequest>) requestFromURLRequest:(NSURLRequest*) req completionHandler:(void(^)(id <SJRequest>)) handler;
{
	SJRequest* request;
		request = [[[SJRequest alloc] initWithURLRequest:req completionHandler:handler beforeCompletionHandler:NULL] autorelease];
	
	return request;
}

@synthesize URL; 

- (NSDictionary*) unfinishedRequestsByURL;
{
	return unfinishedRequests;
}

@end



@interface SJRequest ()

@property(copy) NSURL* URL;

@end


@implementation SJRequest

- (id) initWithURLRequest:(NSURLRequest *)req completionHandler:(SJRequestCompletionHandler)handler beforeCompletionHandler:(SJRequestCompletionHandler) cleanup;
{
	if ((self = [super init])) {
		self.URL = [req URL];
		self.HTTPRequest = req;
		self.beforeCompletionHandler = cleanup;
		self.completionHandlers = [NSMutableSet setWithObject:[[handler copy] autorelease]];
		self.dependencyHandlers = [NSMutableSet set];
		
		self.downloadedData = [NSMutableData data];
		self.unfinishedDependencies = [NSMutableSet set];
	}
	
	return self;
}

- (void) dealloc
{
	[self cancel];
	self.connection = nil;
	self.error = nil;
	self.JSONValue = nil;
	self.downloadedData = nil;
	self.unfinishedDependencies = nil;
	self.HTTPRequest = nil;
	self.HTTPResponse = nil;
	self.session = nil;
	self.URL = nil;
	[super dealloc];
}

@synthesize JSONValue, error, downloadedData, completionHandlers, dependencyHandlers, beforeCompletionHandler, connection, HTTPRequest, unfinishedDependencies, HTTPResponse, session, URL;


- (void) start;
{
	if (finished) {
		ILLog(@"Not restarted as it has already finished");
		return;
	}
	
	if (!self.connection) {
		if (!shouldSuppressLogs)
			self.session = ILSession(self.URL, @"URL", @"not yet started", @"state");
		
		self.connection = [[[NSURLConnection alloc] initWithRequest:self.HTTPRequest delegate:self] autorelease];
	}
}

- (BOOL) isFinished;
{
	return finished;
}

- (void) cancel;
{
	if (finished)
		return;
	
	[self.session updateBySettingObject:@"cancelled" forPropertyKey:@"state"];
	
	self.unfinishedDependencies = nil;
	self.error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
	[self.connection cancel];
	[self endInvokingCompletionHandlers];
}

- (void) addDependency:(id <SJRequest>)req;
{
	if (req == self)
		return;
		
	if ([req isFinished]) {
		ILLog(@"Won't add a dependency, since it's already finished: %@", req);
		return;
	}
	
	if ([self.unfinishedDependencies containsObject:req]) {
		ILLog(@"Won't add a dependency because we're already waiting for it: %@", req);
		return;
	}
	
	[self.unfinishedDependencies addObject:req];

	[self.session updateBySettingObject:self.unfinishedDependencies forPropertyKey:@"unfinishedDependencies"];

	[(SJRequest*)req addDependencyHandler:^(id <SJRequest> r) {
		if (finished)
			return;
		
		ILLog(@"Detected a finished dependency: %@", r);
		
		[self.unfinishedDependencies removeObject:r];
		if ([self.unfinishedDependencies count] == 0) {
			ILLog(@"All dependencies have finished; finishing ourselves");
			[self endInvokingCompletionHandlers];
		}
	}];
}

- (void) endInvokingCompletionHandlers;
{
	if ([self.unfinishedDependencies count] > 0) {
		ILLog(@"Delaying finishing because there are unfinished dependencies");
		return;
	}
	
	finished = YES;
	ILLog(@"Finishing");
	
	[[self retain] autorelease];
	
	if (self.beforeCompletionHandler)
		(self.beforeCompletionHandler)(self);
	
	for (SJRequestCompletionHandler h in self.completionHandlers)
		h(self);

	for (SJRequestCompletionHandler h in self.dependencyHandlers)
		h(self);
	
	self.beforeCompletionHandler = nil;
	self.completionHandlers = nil;
	self.dependencyHandlers = nil;
	
	[self.session updateBySettingObject:@"finished" forPropertyKey:@"state"];
	self.session = nil;
}

- (void) addCompletionHandler:(SJRequestCompletionHandler) h;
{
	if (self.completionHandlers)
		[self.completionHandlers addObject:[[h copy] autorelease]];
}

- (void) addDependencyHandler:(SJRequestCompletionHandler) h;
{
	if (self.dependencyHandlers)
		[self.dependencyHandlers addObject:[[h copy] autorelease]];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	[self.downloadedData appendData:data];
	[self.session updateBySettingObject:[NSNumber numberWithInteger:[self.downloadedData length]] forPropertyKey:@"receivedBytes"];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)e;
{
	[self.session setObject:@"connection finished with error" forPropertyKey:@"state"];
	[self.session setObject:e forPropertyKey:@"error"];
	[self.session update];
	
	self.error = e;
	self.downloadedData = nil;
	[self endInvokingCompletionHandlers];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
{
	[self.session updateBySettingObject:@"connection finished ok" forPropertyKey:@"state"];
	[self endInvokingCompletionHandlers];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	[self.session updateBySettingObject:response forPropertyKey:@"HTTPResponse"];
	self.HTTPResponse = (NSHTTPURLResponse*) response;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
{
	self.URL = request.URL;
	return request;
}

- (id) JSONValue;
{
	if (!JSONValue && self.downloadedData) {
		NSString* s = [[[NSString alloc] initWithData:self.downloadedData encoding:NSUTF8StringEncoding] autorelease];
		self.JSONValue = [s JSONValue];
	}
	
	return JSONValue;
}

- (id) JSONValueWithSchema:(Class) schema error:(NSError**) e;
{
	id x = self.JSONValue;
	return x? [[[schema alloc] initWithJSONDictionaryValue:x error:e] autorelease] : nil;
}

- (void) setShouldNotLog;
{
	self.session = nil;
	shouldSuppressLogs = YES;
}

- (NSData*) data;
{
	return self.downloadedData;
}

@end
