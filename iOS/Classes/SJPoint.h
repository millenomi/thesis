//
//  SJPoint.h
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILManagedObject.h"

@class SJSlide, SJQuestion;

@interface SJPoint : ILManagedObject {

}

@property (nonatomic, retain) NSNumber * indentation;
@property (nonatomic, retain) NSNumber * sortingOrder;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) SJSlide * slide;
@property (nonatomic, retain) NSString* URLString;

@property(nonatomic, assign) NSUInteger indentationValue, sortingOrderValue;

@property (nonatomic, retain) NSSet* questions;

+ pointWithURL:(NSURL*) url fromContext:(NSManagedObjectContext*) moc;

@property (nonatomic, copy) NSURL* URL;

@end

@interface SJPoint (CoreDataGeneratedAccessors)

- (void)addQuestionsObject:(SJQuestion *)value;
- (void)removeQuestionsObject:(SJQuestion *)value;
- (void)addQuestions:(NSSet *)value;
- (void)removeQuestions:(NSSet *)value;

@end
