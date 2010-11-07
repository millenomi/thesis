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
#import "SJQuestion.h"

@interface SJPointTableViewCell : ILNIBTableViewCell {
	SJPoint* point;
	IBOutlet UILabel* pointTextLabel;
	IBOutlet UIView* actionView;
	
	BOOL showingActionView;
}

@property(nonatomic, retain) SJPoint* point;

+ (CGFloat) cellHeightForPoint:(SJPoint*) p width:(CGFloat) width;

@property(retain) IBOutlet UIView* questionsView;

@property(assign) IBOutlet UILabel* didNotUnderstandIconographyLabel;
@property(assign) IBOutlet UILabel* goInDepthIconographyLabel;
@property(assign) IBOutlet UILabel* freeformIconographyLabel;

@property(assign) IBOutlet UILabel* didNotUnderstandCountLabel;
@property(assign) IBOutlet UILabel* goInDepthCountLabel;
@property(assign) IBOutlet UILabel* freeformCountLabel;

- (void) updateWithAddedQuestion:(SJQuestion*) q;
- (void) update;

@end
