//
//  SJPresentation.h
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILManagedObject.h"

@interface SJPresentation : ILManagedObject {

}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet* slides;
@property (nonatomic, retain) NSString * URLString;

@property(nonatomic, copy) NSURL* URL;

+ presentationWithURL:(NSURL*) url fromContext:(NSManagedObjectContext*) moc;

@end

@interface SJPresentation (CoreDataGeneratedAccessors)

- (void)addSlidesObject:(NSManagedObject *)value;
- (void)removeSlidesObject:(NSManagedObject *)value;
- (void)addSlides:(NSSet *)value;
- (void)removeSlides:(NSSet *)value;

@end