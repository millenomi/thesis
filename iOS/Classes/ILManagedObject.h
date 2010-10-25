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

+ oneWithPredicate:(NSPredicate*) pred orderBy:(NSArray*) sortDescriptors fromContext:(NSManagedObjectContext*) moc;
+ oneWithPredicate:(NSPredicate*) pred fromContext:(NSManagedObjectContext*) moc;

@end
