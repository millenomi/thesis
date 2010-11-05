//
//  SJPointTableViewCell.h
//  Subject
//
//  Created by ∞ on 05/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILNIBTableViewCell.h"
#import "SJPoint.h"

@interface SJPointTableViewCell : ILNIBTableViewCell {
	SJPoint* point;
	IBOutlet UILabel* pointTextLabel;
}

@property(nonatomic, retain) SJPoint* point;

+ (CGFloat) cellHeightForPoint:(SJPoint*) p width:(CGFloat) width;

@end
