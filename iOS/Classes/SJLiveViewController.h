//
//  SJLiveViewController.h
//  Subject
//
//  Created by ∞ on 23/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SJEndpoint.h"
#import "SJLive.h"

@interface SJLiveViewController : UIViewController <SJLiveDelegate, UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UIActivityIndicatorView* spinner;
	IBOutlet UITableView* tableView;
	IBOutlet UIView* tableHostView;
}

@property(retain) NSManagedObjectContext* managedObjectContext;
@property(retain) SJEndpoint* endpoint;

@end
