//
//  SJSlide.h
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILManagedObject.h"
#import "SJPoint.h"

@class SJPresentation;

@interface SJSlide : ILManagedObject {

}

@property (nonatomic, retain) NSNumber * sortingOrder;
@property (nonatomic, retain) NSSet* points;
@property (nonatomic, retain) SJPresentation * presentation;
@property (nonatomic, retain) NSString * URLString;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) NSData * imageData;

@property(nonatomic, assign) NSUInteger sortingOrderValue;
@property(nonatomic, copy) NSURL* URL;

+ slideWithURL:(NSURL*) url fromContext:(NSManagedObjectContext*) moc;

- (SJPoint*) pointAtIndex:(NSUInteger) i;

@end

@interface SJSlide (CoreDataGeneratedAccessors)
- (void)addPointsObject:(NSManagedObject *)value;
- (void)removePointsObject:(NSManagedObject *)value;
- (void)addPoints:(NSSet *)value;
- (void)removePoints:(NSSet *)value;

@end
