//
//  ILManagedObjectContext.m
//  Subject
//
//  Created by ∞ on 21/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "ILManagedObject.h"


@implementation ILManagedObject

- (id) initInsertedIntoManagedObjectContext:(NSManagedObjectContext*) moc;
{
	NSEntityDescription* ed = [NSEntityDescription entityForName:NSStringFromClass(self->isa) inManagedObjectContext:moc];
	return [self initWithEntity:ed insertIntoManagedObjectContext:moc];
}

+ insertedInto:(NSManagedObjectContext*) moc;
{
	return [[[self alloc] initInsertedIntoManagedObjectContext:moc] autorelease];
}

+ oneWithPredicate:(NSPredicate*) pred orderBy:(NSArray*) sortDescriptors fromContext:(NSManagedObjectContext*) moc;
{
	NSEntityDescription* ed = [NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:moc];
	
	NSFetchRequest* fetch = [[NSFetchRequest new] autorelease];
	fetch.predicate = pred;
	fetch.fetchLimit = 1;
	fetch.entity = ed;
	fetch.sortDescriptors = sortDescriptors;
	
	NSArray* a = [moc executeFetchRequest:fetch error:NULL];
	
	return ([a count] > 0)? [a objectAtIndex:0] : nil;
}

+ oneWithPredicate:(NSPredicate*) pred fromContext:(NSManagedObjectContext*) moc;
{
	return [self oneWithPredicate:pred orderBy:nil fromContext:moc];
}

@end
