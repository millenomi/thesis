//
//  SJSlide.m
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJSlide.h"


@implementation SJSlide

@dynamic sortingOrder;
@dynamic points;
@dynamic presentation;
@dynamic URLString;
@dynamic imageURLString;
@dynamic imageData;

- (NSUInteger) sortingOrderValue;
{
	return self.sortingOrder? [self.sortingOrder unsignedIntegerValue] : 0;
}

- (void) setSortingOrderValue:(NSUInteger) i;
{
	self.sortingOrder = [NSNumber numberWithUnsignedInteger:i];
}

- (NSURL*) URL;
{
	return [NSURL URLWithString:self.URLString];
}

- (void) setURL:(NSURL*) u;
{
	self.URLString = [u absoluteString];
}

+ slideWithURL:(NSURL*) url fromContext:(NSManagedObjectContext*) moc;
{
	NSPredicate* pred = [NSPredicate predicateWithFormat:@"URLString == %@", [url absoluteString]];
	return [self oneWithPredicate:pred fromContext:moc];
}

- (SJPoint*) pointAtIndex:(NSUInteger) i;
{
	NSPredicate* pred = [NSPredicate predicateWithFormat:@"slide == %@ && sortingOrder == %@", self, [NSNumber numberWithUnsignedInteger:i]];
	return [SJPoint oneWithPredicate:pred fromContext:[self managedObjectContext]];
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


// coalesce these into one @interface SJSlide (CoreDataGeneratedPrimitiveAccessors) section
@interface SJSlide (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber *)primitiveSortingOrder;
- (void)setPrimitiveSortingOrder:(NSNumber *)value;

- (SJPresentation *)primitivePresentation;
- (void)setPrimitivePresentation:(SJPresentation *)value;

- (NSMutableSet*)primitivePoints;
- (void)setPrimitivePoints:(NSMutableSet*)value;

@end

- (NSNumber *)sortingOrder 
{
    NSNumber * tmpValue;
    
    [self willAccessValueForKey:@"sortingOrder"];
    tmpValue = [self primitiveSortingOrder];
    [self didAccessValueForKey:@"sortingOrder"];
    
    return tmpValue;
}

- (void)setSortingOrder:(NSNumber *)value 
{
    [self willChangeValueForKey:@"sortingOrder"];
    [self setPrimitiveSortingOrder:value];
    [self didChangeValueForKey:@"sortingOrder"];
}

- (BOOL)validateSortingOrder:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}


- (void)addPointsObject:(NSManagedObject *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"points" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitivePoints] addObject:value];
    [self didChangeValueForKey:@"points" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)removePointsObject:(NSManagedObject *)value 
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"points" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitivePoints] removeObject:value];
    [self didChangeValueForKey:@"points" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)addPoints:(NSSet *)value 
{    
    [self willChangeValueForKey:@"points" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitivePoints] unionSet:value];
    [self didChangeValueForKey:@"points" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removePoints:(NSSet *)value 
{
    [self willChangeValueForKey:@"points" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitivePoints] minusSet:value];
    [self didChangeValueForKey:@"points" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (SJPresentation *)presentation 
{
    id tmpObject;
    
    [self willAccessValueForKey:@"presentation"];
    tmpObject = [self primitivePresentation];
    [self didAccessValueForKey:@"presentation"];
    
    return tmpObject;
}

- (void)setPresentation:(SJPresentation *)value 
{
    [self willChangeValueForKey:@"presentation"];
    [self setPrimitivePresentation:value];
    [self didChangeValueForKey:@"presentation"];
}


- (BOOL)validatePresentation:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

#endif

@end
