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
	[self noteSchemaOfClass:c atURL:url subresourceOfSchema:nil reason:kSJDownloaderReasonOpportunistic];
}

- (void) noteSchemaOfClass:(Class) c atURL:(NSURL*) url subresourceOfSchema:(id) x reason:(SJDownloaderReason) reason;
{
	id <SJSchemaProviderObserver> obs = [self observerForSchemaClass:c];
	if (obs && [obs respondsToSelector:@selector(schemaProvider:didNoteSchemaOfClass:atURL:subresourceOfSchema:reason:)])
		[obs schemaProvider:self didNoteSchemaOfClass:c atURL:url subresourceOfSchema:x reason:reason];
}

- (void) provideSchema:(SJSchema *)s fromURL:(NSURL *)url reason:(SJDownloaderReason) reason partial:(BOOL) partial;
{
	[[self observerForSchemaClass:[s class]] schemaProvider:self didDownloadSchema:s fromURL:url reason:reason partial:partial];
}

#define kSJSchemaProviderClass @"SJSchemaProviderClass"
#define kSJSchemaSuperResource @"SJSchemaSuperResource"

- (void) beginFetchingSchemaOfClass:(Class)c fromURL:(NSURL *)url reason:(SJDownloaderReason)reason;
{
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  c, kSJSchemaProviderClass,
							  nil];
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
							 userInfo, kSJDownloaderOptionUserInfo,
							 [NSNumber numberWithUnsignedInteger:reason], kSJDownloaderOptionDownloadReason,
							 nil];
	[self.downloader beginDownloadingDataFromURL:url options:options];
}

- (void) beginFetchingDataFromURL:(NSURL *)url subresourceOfSchema:(SJSchema*)s reason:(SJDownloaderReason)reason;
{
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  s, kSJSchemaSuperResource,
							  nil];
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
							 userInfo, kSJDownloaderOptionUserInfo,
							 [NSNumber numberWithUnsignedInteger:reason], kSJDownloaderOptionDownloadReason,
							 nil];
	[self.downloader beginDownloadingDataFromURL:url options:options];
}

- (void) downloader:(SJDownloader*) d didDownloadData:(NSData*) data forURL:(NSURL*) url options:(NSDictionary*) options;
{
	NSDictionary* userInfo = [options objectForKey:kSJDownloaderOptionUserInfo];
	Class c = [userInfo objectForKey:kSJSchemaProviderClass];
	SJSchema* superresource = [userInfo objectForKey:kSJSchemaSuperResource];

	if (!c && superresource)
		c = [superresource class];
	
	id <SJSchemaProviderObserver> obs = [self observerForSchemaClass:c];
	if (!obs)
		return;
	
	if (superresource)
		[obs schemaProvider:self didDownloadResourceData:data fromURL:url subresourceOfSchema:superresource];
	else {
		
		NSString* s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		id x = [s JSONValue];
		
		if (x && [x isKindOfClass:[NSDictionary class]]) {
			
			NSError* e;
			id schema = [[[c alloc] initWithJSONDictionaryValue:x error:&e] autorelease];
			if (schema)
				[obs schemaProvider:self didDownloadSchema:schema fromURL:url reason:[[options objectForKey:kSJDownloaderOptionDownloadReason] unsignedIntegerValue] partial:NO];
			else
				NSLog(@"Error while decoding schema: %@", e); // TODO

			
		}
		
	}
}

- (void) downloader:(SJDownloader*) d didFailDownloadingDataForURL:(NSURL*) url options:(NSDictionary*) options error:(NSError*) e;
{
	NSDictionary* userInfo = [options objectForKey:kSJDownloaderOptionUserInfo];
	Class c = [userInfo objectForKey:kSJSchemaProviderClass];
	SJSchema* superresource = [userInfo objectForKey:kSJSchemaSuperResource];
	
	if (!c && superresource)
		c = [superresource class];
	
	id <SJSchemaProviderObserver> obs = [self observerForSchemaClass:c];
	if ([obs respondsToSelector:@selector(schemaProvider:didFailToDownloadFromURL:error:)])
		 [obs schemaProvider:self didFailToDownloadFromURL:url error:e];
}

- (void) setObserver:(id <SJSchemaProviderObserver>)o forFetchedSchemasOfClass:(Class)c;
{
	[self.observers setObject:o forKey:NSStringFromClass(c)];
	[o setSchemaProvider:self];
}

- (void) removeObserverForFetchedSchemasOfClass:(Class) c;
{
	NSString* key = NSStringFromClass(c);
	id <SJSchemaProviderObserver> o = [self.observers objectForKey:key];
	[o setSchemaProvider:nil];
	[self.observers removeObjectForKey:key];
}

- (id <SJSchemaProviderObserver>) observerForSchemaClass:(Class) c;
{
	for (NSString* className in self.observers) {
		Class otherClass = NSClassFromString(className);
		
		if ([c isSubclassOfClass:otherClass])
			return [self.observers objectForKey:className];
		
	}
	
	return nil;
}

@end
