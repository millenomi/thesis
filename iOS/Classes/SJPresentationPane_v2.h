//
//  SJPresentationPane_v2.h
//  Subject
//
//  Created by ∞ on 22/12/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ILViewController.h"

@class SJSlide, SJLiveSyncController;

@interface SJPresentationPane_v2 : ILViewController {
	IBOutlet UITableView* tableView;
}

@property(nonatomic, retain) SJSlide* displayedSlide;

@property(nonatomic, retain) SJLiveSyncController* liveSyncController;
@property(nonatomic, retain) NSManagedObjectContext* managedObjectContext;

@end


@interface UITableView (ILConveniences)

- (id) cellWithReuseIdentifier:(NSString*) ident ifNoCellToDequeue:(id (^)()) makeOne;

@end

@interface NSArray (ILConveniences)

- (NSArray*) sortedArrayByValueForKey:(NSString*) kp ascending:(BOOL) asc;

@end
