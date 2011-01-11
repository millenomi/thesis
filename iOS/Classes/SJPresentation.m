//
//  SJPresentation.m
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPresentation.h"
#import "SJPresentationSync.h"

@implementation SJPresentation

@dynamic title;
@dynamic slides;
@dynamic URLString;
@dynamic knownCountOfSlides;

- (void) checkIfCompleteWithDownloadPriority:(SJDownloadPriority) priority;
{	
	if (self.URL && (!self.knownCountOfSlides || self.knownCountOfSlidesValue != self.slides.count)) {
		// [SJPresentationSync requireUpdateForContentsOfPresentation:self priority:priority];
	}
}

- (NSURL*) URL;
{
	return self.URLString? [NSURL URLWithString:self.URLString] : nil;
}

- (void) setURL:(NSURL*) u;
{
	self.URLString = [u absoluteString];
}

- (NSUInteger) knownCountOfSlidesValue;
{
	return self.knownCountOfSlides? [self.knownCountOfSlides unsignedIntegerValue] : 0;
}

- (void) setKnownCountOfSlidesValue:(NSUInteger) v;
{
	self.knownCountOfSlides = [NSNumber numberWithUnsignedInteger:v];
}

+ presentationWithURL:(NSURL*) url fromContext:(NSManagedObjectContext*) moc;
{
	NSPredicate* pred = [NSPredicate predicateWithFormat:@"URLString == %@", [url absoluteString]];
	return [self oneWithPredicate:pred fromContext:moc];
}

#if 0
/*
 *
 * You do not need any of these.  
 * These are templates for writing custom functions that override the default CoreData functionality.
 * You should delete all the methods that you do not customize.
 * Optimized versions will be provided dynamically by the framework.
 *
 *
 */


// coalesce these into one @interface SJPresentation (CoreDataGeneratedPrimitiveAccessors) section
@interface SJPresentation (CoreDataGeneratedPrimitiveAccessors)

- (NSString *)primitiveTitle;
- (void)setPrimitiveTitle:(NSString *)value;

- (NSMutableSet*)primitiveSlides;
- (void)setPrimitiveSlides:(NSMutableSet*)value;

@end

- (NSString *)title 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey:@"title"];
    tmpValue = [self primitiveTitle];
    [self didAccessValueForKey:@"title"];
    
    return tmpValue;
}

- (void)setTitle:(NSString *)value 
{
    [self willChangeValueForKey:@"title"];
    [self setPrimitiveTitle:value];
    [self didChangeValueForKey:@"title"];
}

- (BOOL)validateTitle:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}


- (void)addSlidesObject:(NSManagedObject *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"slides" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveSlides] addObject:value];
    [self didChangeValueForKey:@"slides" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)removeSlidesObject:(NSManagedObject *)value 
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"slides" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveSlides] removeObject:value];
    [self didChangeValueForKey:@"slides" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)addSlides:(NSSet *)value 
{    
    [self willChangeValueForKey:@"slides" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveSlides] unionSet:value];
    [self didChangeValueForKey:@"slides" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeSlides:(NSSet *)value 
{
    [self willChangeValueForKey:@"slides" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveSlides] minusSet:value];
    [self didChangeValueForKey:@"slides" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

#endif

@end
