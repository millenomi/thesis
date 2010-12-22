#import <Foundation/Foundation.h>
#import <SJClient/SJClient.h>

@interface SJTestCollectingSchemaObserver : NSObject <SJSchemaProviderObserver> {
	NSMutableSet* collected;
}

@end

@implementation SJTestCollectingSchemaObserver

- (id) init;
{
	if ((self = [super init]))
		collected = [NSMutableSet new];
	
	return self;
}

- (void) dealloc
{
	[collected release];
	[super dealloc];
}


- (void) schemaProvider:(SJSchemaProvider *)sp didDownloadSchema:(id)schema fromURL:(NSURL *)url partial:(BOOL) partial;
{
	// NSLog(@" --> [%@ %s]: %@, %@, %@", self, __func__, sp, schema, url);
	
	if (partial && ![collected containsObject:url]) {
		[sp beginFetchingSchemaOfClass:[sp class] fromURL:url reason:kSJDownloaderReasonOpportunistic];
		return;
	}
	
	[collected addObject:url];
}

- (void) schemaProvider:(SJSchemaProvider *)sp didDownloadResourceData:(NSData *)data fromURL:(NSURL *)url subresourceOfSchema:(id)schema;
{
	// NSLog(@" --> [%@ %s]: %@, %@, %@, %@", self, __func__, sp, data, url, schema);	
	NSLog(@"(Collected: %@)", url);
	[collected addObject:url];
}

- (void) schemaProvider:(SJSchemaProvider*) sp didNoteSchemaOfClass:(Class) c atURL:(NSURL*) url;
{
	// NSLog(@" --> [%@ %s]: %@, %@, %@", self, __func__, sp, c, url);
	if (![collected containsObject:url])
		[sp beginFetchingSchemaOfClass:c fromURL:url reason:kSJDownloaderReasonOpportunistic];
}

- (void) schemaProvider:(SJSchemaProvider*) sp didFailToDownloadFromURL:(NSURL*) url error:(NSError*) error;
{
	// NSLog(@" -- [%@ %s]: %@, %@, %@ [%@]", self, __func__, sp, url, error, [error userInfo]);
}

- (void) setSchemaProvider:(SJSchemaProvider*) sp {}

@end

@interface SJTestLiveDelegate : NSObject <SJLiveObserverDelegate> {}
@end

@implementation SJTestLiveDelegate

- (void) liveDidStart:(SJLiveObserver *)observer
{
	NSLog(@"! Start");
}

- (void) liveDidEnd:(SJLiveObserver *)observer;
{
	NSLog(@"! End");	
}

- (void) live:(SJLiveObserver *)observer didMoveToSlideAtURL:(NSURL *)url schema:(SJSlideSchema *)schema;
{
	NSLog(@"! Moved to %@", url);
}

- (void) live:(SJLiveObserver *)observer didPostQuestionsAtURLs:(NSSet *)urls;
{
	NSLog(@"! Questions %@", urls);	
}

- (void) live:(SJLiveObserver *)observer didPostMoodsAtURLs:(NSSet *)urls;
{
	NSLog(@"! Moods %@", urls);		
}

- (void) live:(SJLiveObserver*) observer didFailToLoadWithError:(NSError*) e;
{
	NSLog(@"XX ERROR: %@", e);
}

@end



int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	SJSchemaProvider* p = [[SJSchemaProvider new] autorelease];
	SJEndpoint* ep = [[[SJEndpoint alloc] initWithURL:[NSURL URLWithString:@"http://infinitelabs-subject.appspot.com"]] autorelease];
	
	SJLiveObserver* o = [[[SJLiveObserver alloc] initWithEndpoint:ep] autorelease];
	SJTestLiveDelegate* d = [SJTestLiveDelegate new];
	o.delegate = d;
	[p setObserver:o forFetchedSchemasOfClass:[SJLiveSchema class]];
	
	for (Class c in [NSArray arrayWithObjects:
					 [SJQuestionSchema class],
					 [SJPointSchema class],
					 [SJSlideSchema class],
					 [SJPresentationSchema class],
					 nil])
		[p setObserver:[[SJTestCollectingSchemaObserver new] autorelease] forFetchedSchemasOfClass:c];
	
	while (YES)
		[[NSRunLoop currentRunLoop] run];
	
	[pool drain];
    return 0;
}
