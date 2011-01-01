//
//  ILManagedObjectContext.h
//  Subject
//
//  Created by ∞ on 21/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ILManagedObject : NSManagedObject {

}

- (id) initInsertedIntoManagedObjectContext:(NSManagedObjectContext*) moc;

+ insertedInto:(NSManagedObjectContext*) moc;

+ oneWhereKey:(NSString*) key equals:(id) value fromContext:(NSManagedObjectContext*) moc;

+ oneWithPredicate:(NSPredicate*) pred orderBy:(NSArray*) sortDescriptors fromContext:(NSManagedObjectContext*) moc;
+ oneWithPredicate:(NSPredicate*) pred fromContext:(NSManagedObjectContext*) moc;

+ resultOfFetchRequestWithProperties:(void(^)(NSFetchRequest*)) props fromContext:(NSManagedObjectContext*) moc;
+ (NSUInteger) countForFetchRequestWithProperties:(void(^)(NSFetchRequest*)) props fromContext:(NSManagedObjectContext*) moc;
+ (NSUInteger) countForPredicate:(NSPredicate*) pred fromContext:(NSManagedObjectContext*) moc;

+ (NSArray*) allWithPredicate:(NSPredicate*) pred fromContext:(NSManagedObjectContext*) moc;

@end


@interface NSArray (ILAdditions)

- singleContainedObject;

@end