//
//  SJSchemaProvider.m
//  Client
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SJSchemaProvider.h"
#import "SBJSON/JSON.h"

@interface SJSchemaProvider ()

@property(nonatomic, retain) SJDownloader* downloader;
@property(nonatomic, retain) NSMutableDictionary* observers;
- (id <SJSchemaProviderObserver>) observerForSchemaClass:(Class)c;

@end


@implementation SJSchemaProvider

- (id) init;
{
	if ((self = [super init])) {
		self.downloader = [[SJDownloader new] autorelease];
		self.downloader.delegate = self;
		
		self.observers = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (void) dealloc
{
	self.downloader.delegate = nil;
	self.downloader = nil;
	[super dealloc];
}


@synthesize downloader, observers;

- (void) noteSchemaOfClass:(Class)c atURL:(NSURL *)url;
{
	[self noteSchemaOfClass:c atURL:url subresourceOfSchema:nil reason:kSJDownloadPriorityOpportunistic];
}

- (void) noteSchemaOfClass:(Class) c atURL:(NSURL*) url subresourceOfSchema:(id) x reason:(SJDownloadPriority) reason;
{
	id <SJSchemaProviderObserver> obs = [self observerForSchemaClass:c];
	if (obs && [obs respondsToSelector:@selector(schemaProvider:didNoteSchemaOfClass:atURL:subresourceOfSchema:reason:)])
		[obs schemaProvider:self didNoteSchemaOfClass:c atURL:url subresourceOfSchema:x reason:reason];
}

- (void) provideSchema:(SJSchema *)s fromURL:(NSURL *)url reason:(SJDownloadPriority) reason partial:(BOOL) partial;
{
	[[self observerForSchemaClass:[s class]] schemaProvider:self didDownloadSchema:s fromURL:url reason:reason partial:partial];
}

#define kSJSchemaProviderClass @"SJSchemaProviderClass"
#define kSJSchemaSuperResource @"SJSchemaSuperResource"

- (void) beginFetchingSchemaOfClass:(Class)c fromURL:(NSURL *)url reason:(SJDownloadPriority)reason;
{
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  c, kSJSchemaProviderClass,
							  nil];
	
	SJDownloadRequest* req = [[SJDownloadRequest new] autorelease];
	req.URL = url;
	req.reason = reason;
	req.userInfo = userInfo;
	
	[self.downloader beginDownloadingWithRequest:req];
}

- (void) beginFetchingDataFromURL:(NSURL *)url subresourceOfSchema:(SJSchema*)s reason:(SJDownloadPriority)reason;
{
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  s, kSJSchemaSuperResource,
							  nil];
	
	SJDownloadRequest* req = [[SJDownloadRequest new] autorelease];
	req.URL = url;
	req.reason = reason;
	req.userInfo = userInfo;
	
	[self.downloader beginDownloadingWithRequest:req];
	
}

- (void) downloader:(SJDownloader *)d didFinishDowloadingRequest:(SJDownloadRequest *)req;
{
	if (req.downloadedData && !req.error) {
		NSDictionary* userInfo = req.userInfo;
		Class c = [userInfo objectForKey:kSJSchemaProviderClass];
		SJSchema* superresource = [userInfo objectForKey:kSJSchemaSuperResource];
		
		if (!c && superresource)
			c = [superresource class];
		
		id <SJSchemaProviderObserver> obs = [self observerForSchemaClass:c];
		if (!obs)
			return;
		
		if (superresource)
			[obs schemaProvider:self didDownloadResourceData:req.downloadedData fromURL:req.URL subresourceOfSchema:superresource];
		else {
			
			NSString* s = [[[NSString alloc] initWithData:req.downloadedData encoding:NSUTF8StringEncoding] autorelease];
			id x = [s JSONValue];
			
			if (x && [x isKindOfClass:[NSDictionary class]]) {
				
				NSError* e;
				id schema = [[[c alloc] initWithJSONDictionaryValue:x error:&e] autorelease];
				if (schema)
					[obs schemaProvider:self didDownloadSchema:schema fromURL:req.URL reason:req.reason partial:NO];
				else
					NSLog(@"Error while decoding schema: %@", e); // TODO
				
				
			}
			
		}
	} else if (req.error) {
		NSDictionary* userInfo = req.userInfo;
		Class c = [userInfo objectForKey:kSJSchemaProviderClass];
		SJSchema* superresource = [userInfo objectForKey:kSJSchemaSuperResource];
		
		if (!c && superresource)
			c = [superresource class];
		
		id <SJSchemaProviderObserver> obs = [self observerForSchemaClass:c];
		if ([obs respondsToSelector:@selector(schemaProvider:didFailToDownloadFromURL:error:)])
			[obs schemaProvider:self didFailToDownloadFromURL:req.URL error:req.error];		
	}
}

- (void) setObserver:(id <SJSchemaProviderObserver>)o forFetchedSchemasOfClass:(Class)c;
{
	[self.observers setObject:o forKey:c];
	[o setSchemaProvider:self];
}

- (void) removeObserverForFetchedSchemasOfClass:(Class) c;
{
	id <SJSchemaProviderObserver> o = [self.observers objectForKey:c];
	[o setSchemaProvider:nil];
	[self.observers removeObjectForKey:c];
}

- (id <SJSchemaProviderObserver>) observerForSchemaClass:(Class) c;
{
	for (Class otherClass in self.observers) {
		if ([c isSubclassOfClass:otherClass])
			return [self.observers objectForKey:otherClass];
	}
	
	return nil;
}

@end
