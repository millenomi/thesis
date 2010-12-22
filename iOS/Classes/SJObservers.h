//
//  SJObservers.h
//  Subject
//
//  Created by ∞ on 22/12/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJClient.h"

@interface SJBaseSchemaProviderObserver : NSObject {
	SJSchemaProvider* schemaProvider;
	NSManagedObjectContext* managedObjectContext;

	NSInteger saveHoldCount;
}

+ observerWithManagedObjectContext:(NSManagedObjectContext*) moc;
- initWithManagedObjectContext:(NSManagedObjectContext*) moc;

@property(assign) SJSchemaProvider* schemaProvider;
@property(retain) NSManagedObjectContext* managedObjectContext;
- (BOOL) saveIfFinished:(NSError**) e;

@end

@interface SJPresentationObserver : SJBaseSchemaProviderObserver <SJSchemaProviderObserver>
@end

@interface SJSlideObserver : SJBaseSchemaProviderObserver <SJSchemaProviderObserver>
@end

@interface SJPointObserver : SJBaseSchemaProviderObserver <SJSchemaProviderObserver>
@end

@interface SJQuestionObserver : SJBaseSchemaProviderObserver <SJSchemaProviderObserver>
@end

extern NSDictionary* SJDefaultObservers();
