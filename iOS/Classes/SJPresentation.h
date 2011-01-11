//
//  SJPresentation.h
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILManagedObject.h"
#import "SJClient.h"

@interface SJPresentation : ILManagedObject {
	BOOL checkedCompleteness;
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet* slides;
@property (nonatomic, retain) NSString * URLString;
@property (nonatomic, retain) NSArray * knownSlideURLs;

@property(nonatomic, copy) NSURL* URL;
@property(nonatomic, readonly) NSNumber * knownCountOfSlides;
@property(nonatomic, readonly) NSUInteger knownCountOfSlidesValue;

+ presentationWithURL:(NSURL*) url fromContext:(NSManagedObjectContext*) moc;

- (void) checkIfCompleteWithDownloadPriority:(SJDownloadPriority) priority;

@end

@interface SJPresentation (CoreDataGeneratedAccessors)

- (void)addSlidesObject:(NSManagedObject *)value;
- (void)removeSlidesObject:(NSManagedObject *)value;
- (void)addSlides:(NSSet *)value;
- (void)removeSlides:(NSSet *)value;

@end
