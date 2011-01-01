//
//  SJSchemaProvider.h
//  Client
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDownloader.h"
#import "SJSchema.h"

@protocol SJSchemaProviderObserver;

@interface SJSchemaProvider : NSObject <SJDownloaderDelegate> {}

- (void) noteSchemaOfClass:(Class) c atURL:(NSURL*) url;
- (void) noteSchemaOfClass:(Class) c atURL:(NSURL*) url subresourceOfSchema:(id) x reason:(SJDownloadPriority) reason;

- (void) provideSchema:(SJSchema*) s fromURL:(NSURL*) url reason:(SJDownloadPriority) reason partial:(BOOL) partial;

- (void) beginFetchingSchemaOfClass:(Class) c fromURL:(NSURL*) url reason:(SJDownloadPriority) reason;
- (void) beginFetchingDataFromURL:(NSURL*) url subresourceOfSchema:(SJSchema*) s reason:(SJDownloadPriority) reason;

- (void) setObserver:(id <SJSchemaProviderObserver>) o forFetchedSchemasOfClass:(Class) c;
- (void) removeObserverForFetchedSchemasOfClass:(Class) c;

@end


@protocol SJSchemaProviderObserver <NSObject>

- (void) setSchemaProvider:(SJSchemaProvider*) sp; // assign only

- (void) schemaProvider:(SJSchemaProvider*) sp didDownloadSchema:(id) schema fromURL:(NSURL*) url reason:(SJDownloadPriority) reason partial:(BOOL) partial;

@optional
- (void) schemaProvider:(SJSchemaProvider*) sp didFailToDownloadFromURL:(NSURL*) url error:(NSError*) error;
- (void) schemaProvider:(SJSchemaProvider*) sp didNoteSchemaOfClass:(Class) c atURL:(NSURL*) url subresourceOfSchema:(id) x reason:(SJDownloadPriority) reason;
- (void) schemaProvider:(SJSchemaProvider*) sp didDownloadResourceData:(NSData*) data fromURL:(NSURL*) url subresourceOfSchema:(id) schema;

@end
