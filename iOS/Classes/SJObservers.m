//
//  SJObservers.m
//  Subject
//
//  Created by ∞ on 22/12/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJObservers.h"

#import "SJPresentation.h"
#import "SJSlide.h"
#import "SJPoint.h"
#import "SJQuestion.h"

#if 0

CF_INLINE SJDownloaderReason SJReasonFor(SJDownloaderReason reason) {
	return (reason == kSJDownloaderReasonResourceForImmediateDisplay? kSJDownloaderReasonSubresourceForImmediateDisplay : kSJDownloaderReasonOpportunistic);
}

NSDictionary* SJDefaultObservers(NSManagedObjectContext* moc, id <SJLiveObserverDelegate> liveDelegate) {
	SJLiveObserver* live = [[SJLiveObserver new] autorelease];
	live.delegate = liveDelegate;
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[SJPresentationSchema class], [[SJPresentationObserver observerWithManagedObjectContext:moc] autorelease],
			[SJSlideSchema class], [[SJSlideObserver observerWithManagedObjectContext:moc] autorelease],
			[SJPointSchema class], [[SJPointObserver observerWithManagedObjectContext:moc] autorelease],
			[SJQuestionSchema class], [[SJQuestionObserver observerWithManagedObjectContext:moc] autorelease],
			[SJLiveSchema class], live,
			nil];
}

#define kSJBaseSchemaProviderObserverWillBeginEditing @"SJBaseSchemaProviderObserverWillBeginEditing"
#define kSJBaseSchemaProviderObserverDidEndEditing @"SJBaseSchemaProviderObserverDidEndEditing"

@implementation SJBaseSchemaProviderObserver

- (void) beginEditing;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSJBaseSchemaProviderObserverWillBeginEditing object:self];
}

- (void) endEditing;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSJBaseSchemaProviderObserverDidEndEditing object:self];
}

- (void) observerWillBeginEditing:(NSNotification*) n;
{
	if (self.managedObjectContext == [[n object] managedObjectContext])
		saveHoldCount++;
}

- (void) observerDidEndEditing:(NSNotification *)n;
{
	if (self.managedObjectContext == [[n object] managedObjectContext])
		saveHoldCount--;
}

- (BOOL) saveIfFinished:(NSError**) e;
{
	if (saveHoldCount == 0) {
		BOOL ok = [self.managedObjectContext save:e];
		if (!ok)
			[self.managedObjectContext rollback];
		return ok;
	} else {
		return YES;
	}
}

+ observerWithManagedObjectContext:(NSManagedObjectContext*) moc;
{
	return [[[self alloc] initWithManagedObjectContext:moc] autorelease];
}

- initWithManagedObjectContext:(NSManagedObjectContext*) moc;
{
	if ((self = [super init])) {
		self.managedObjectContext = moc;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observerWillBeginEditing:) name:kSJBaseSchemaProviderObserverWillBeginEditing object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observerDidEndEditing:) name:kSJBaseSchemaProviderObserverDidEndEditing object:nil];
	}
	
	return self;
}

- (void) dealloc
{
	self.managedObjectContext = nil;
	[super dealloc];
}


@synthesize managedObjectContext;
@synthesize schemaProvider;

@end

@implementation SJPresentationObserver

- (void) schemaProvider:(SJSchemaProvider*) sp didNoteSchemaOfClass:(Class) c atURL:(NSURL*) url subresourceOfSchema:(id) x reason:(SJDownloaderReason) reason;
{
	[sp beginFetchingSchemaOfClass:c fromURL:url reason:[x isKindOfClass:[SJLiveSchema class]]? kSJDownloaderReasonResourceForImmediateDisplay : reason];
}

- (void) schemaProvider:(SJSchemaProvider*) sp didDownloadSchema:(id) schema fromURL:(NSURL*) url reason:(SJDownloaderReason) reason partial:(BOOL) partial;
{
	[self beginEditing];
	
	SJPresentationSchema* ps = schema;
	SJPresentation* p = [SJPresentation oneWhereKey:@"URLString" equals:[url absoluteString] fromContext:self.managedObjectContext];
	
	if (!p)
		p = [SJPresentation insertedInto:self.managedObjectContext];
	
	if (!p.URL)
		p.URL = url;
	
	p.title = ps.title;
	
	for (SJPresentationSlideInfoSchema* slideInfo in ps.slides) {
		NSURL* slideURL = [NSURL URLWithString:slideInfo.URLString relativeToURL:url];
		
		if (slideInfo.contents)
			[sp provideSchema:slideInfo.contents
					  fromURL:slideURL 
					   reason:SJReasonFor(reason)
					  partial:NO];
		else
			[sp beginFetchingSchemaOfClass:[SJSlideSchema class]
								   fromURL:slideURL
									reason:SJReasonFor(reason)];
	}
	
	[self endEditing];
	[self saveIfFinished:NULL];
}

@end

@implementation SJSlideObserver

- (void) schemaProvider:(SJSchemaProvider *)sp didNoteSchemaOfClass:(Class)c atURL:(NSURL *)url subresourceOfSchema:(id)x reason:(SJDownloaderReason)reason;
{
	[sp beginFetchingSchemaOfClass:c fromURL:url reason:reason];
}

- (void) schemaProvider:(SJSchemaProvider *)sp didDownloadSchema:(id)schema fromURL:(NSURL *)url reason:(SJDownloaderReason)reason partial:(BOOL)partial;
{
	[self beginEditing];
	
	SJSlideSchema* slideSchema = schema;
	SJSlide* s = [SJSlide oneWhereKey:@"URLString" equals:[url absoluteURL] fromContext:self.managedObjectContext];
	
	if (!s)
		s = [SJSlide insertedInto:self.managedObjectContext];
	
	if (!s.URL)
		s.URL = url;
	
	if (!s.presentation)
		s.presentation = [SJPresentation oneWhereKey:@"URLString" equals:slideSchema.presentationURLString fromContext:self.managedObjectContext];
	
	s.sortingOrder = slideSchema.sortingOrder;
	
	for (SJPointSchema* ps in slideSchema.points) {
		NSURL* pointURL = [NSURL URLWithString:ps.URLString relativeToURL:url];
		[sp provideSchema:ps fromURL:pointURL reason:SJReasonFor(reason) partial:NO];
		
		SJPoint* p = [SJPoint pointWithURL:pointURL fromContext:self.managedObjectContext];
		[s addPointsObject:p];
	}
	
	if (slideSchema.imageURLString && ![s.imageURLString isEqual:slideSchema.imageURLString]) {
		s.imageURLString = slideSchema.imageURLString;
		
		NSURL* imageURL = [NSURL URLWithString:slideSchema.imageURLString relativeToURL:url];
		
		[sp beginFetchingDataFromURL:imageURL subresourceOfSchema:slideSchema reason:SJReasonFor(reason)];
	}
	
	[self endEditing];
	[self saveIfFinished:NULL];
}

- (void) schemaProvider:(SJSchemaProvider *)sp didDownloadResourceData:(NSData *)data fromURL:(NSURL *)url subresourceOfSchema:(id)schema;
{
	[self beginEditing];
	
	SJSlide* s = [SJSlide oneWhereKey:@"URLString" equals:[url absoluteURL] fromContext:self.managedObjectContext];

	if ([[url absoluteString] isEqual:s.imageURLString]) 
		s.imageData = data;
	
	[self endEditing];
	[self saveIfFinished:NULL];
}

@end

@implementation SJPointObserver

- (void) schemaProvider:(SJSchemaProvider *)sp didNoteSchemaOfClass:(Class)c atURL:(NSURL *)url subresourceOfSchema:(id)x reason:(SJDownloaderReason)reason;
{
	SJPoint* p = [SJPoint pointWithURL:url fromContext:self.managedObjectContext];
	if (!p)
		[sp beginFetchingSchemaOfClass:c fromURL:url reason:SJReasonFor(reason)];
}

- (void) schemaProvider:(SJSchemaProvider *)sp didDownloadSchema:(id)schema fromURL:(NSURL *)url reason:(SJDownloaderReason)reason partial:(BOOL)partial;
{
	[self beginEditing];
	
	SJPointSchema* ps = schema;
	SJPoint* p = [SJPoint pointWithURL:url fromContext:self.managedObjectContext];
	
	if (!p)
		p = [SJPoint insertedInto:self.managedObjectContext];
	
	
}

@end

@implementation SJQuestionObserver
@end

#endif
