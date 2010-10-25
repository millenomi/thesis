//
//  SJPoint.m
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPoint.h"


@implementation SJPoint

@dynamic indentation;
@dynamic sortingOrder;
@dynamic text;
@dynamic slide;

- (NSUInteger) indentationValue;
{
	return self.indentation? [self.indentation unsignedIntegerValue] : 0;
}

- (NSUInteger) sortingOrderValue;
{
	return self.sortingOrder? [self.sortingOrder unsignedIntegerValue] : 0;
}

- (void) setIndentationValue:(NSUInteger) i;
{
	self.indentation = [NSNumber numberWithUnsignedInteger:i];
}

- (void) setSortingOrderValue:(NSUInteger) i;
{
	self.sortingOrder = [NSNumber numberWithUnsignedInteger:i];
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


// coalesce these into one @interface SJPoint (CoreDataGeneratedPrimitiveAccessors) section
@interface SJPoint (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber *)primitiveIndentation;
- (void)setPrimitiveIndentation:(NSNumber *)value;

- (NSNumber *)primitiveSortingOrder;
- (void)setPrimitiveSortingOrder:(NSNumber *)value;

- (NSString *)primitiveText;
- (void)setPrimitiveText:(NSString *)value;

- (NSManagedObject *)primitiveSlide;
- (void)setPrimitiveSlide:(NSManagedObject *)value;

@end

- (NSNumber *)indentation 
{
    NSNumber * tmpValue;
    
    [self willAccessValueForKey:@"indentation"];
    tmpValue = [self primitiveIndentation];
    [self didAccessValueForKey:@"indentation"];
    
    return tmpValue;
}

- (void)setIndentation:(NSNumber *)value 
{
    [self willChangeValueForKey:@"indentation"];
    [self setPrimitiveIndentation:value];
    [self didChangeValueForKey:@"indentation"];
}

- (BOOL)validateIndentation:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

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

- (NSString *)text 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey:@"text"];
    tmpValue = [self primitiveText];
    [self didAccessValueForKey:@"text"];
    
    return tmpValue;
}

- (void)setText:(NSString *)value 
{
    [self willChangeValueForKey:@"text"];
    [self setPrimitiveText:value];
    [self didChangeValueForKey:@"text"];
}

- (BOOL)validateText:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}


- (NSManagedObject *)slide 
{
    id tmpObject;
    
    [self willAccessValueForKey:@"slide"];
    tmpObject = [self primitiveSlide];
    [self didAccessValueForKey:@"slide"];
    
    return tmpObject;
}

- (void)setSlide:(NSManagedObject *)value 
{
    [self willChangeValueForKey:@"slide"];
    [self setPrimitiveSlide:value];
    [self didChangeValueForKey:@"slide"];
}


- (BOOL)validateSlide:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

#endif

@end
