//
//  SJPointTableViewCell.m
//  Subject
//
//  Created by ∞ on 05/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPointTableViewCell.h"

@interface SJPointTableViewCell ()

+ (UIEdgeInsets) defaultCellEdgeInsets;
+ (UIFont*) textFontForPoint:(SJPoint*) p;
+ (NSString*) displayTextForPoint:(SJPoint*) p;

@end


@implementation SJPointTableViewCell

@synthesize point;
- (void) setPoint:(SJPoint *) p;
{
	if (p != point) {
		[point release];
		point = [p retain];
		
		// we don't need to set label height since the label has autoresize masks set that do that for us.
		pointTextLabel.font = [[self class] textFontForPoint:p];
		pointTextLabel.text = [[self class] displayTextForPoint:p];
	}
}

+ (UIEdgeInsets) defaultCellEdgeInsets;
{
	// hardcoded, must correspond to positioning of UILabel in the NIB
	UIEdgeInsets i;
	i.top = 10;
	i.left = 20;
	i.right = 20;
	i.bottom = 10;
	return i;
}

+ (CGFloat) cellHeightForPoint:(SJPoint*) p width:(CGFloat) width;
{
	UIEdgeInsets i = [self defaultCellEdgeInsets];
	UIFont* f = [self textFontForPoint:p];
	
	// "word wrap" must be the same as the label in the NIB.
	return MAX(55, i.top + i.bottom + [[self displayTextForPoint:p] sizeWithFont:f constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
}

+ (UIFont*) textFontForPoint:(SJPoint*) p;
{
	// hardcoded, but can be changed without modifying the NIB
	const CGFloat fontSize = 14;
	
	return p.indentationValue == 0? [UIFont boldSystemFontOfSize:fontSize] : [UIFont systemFontOfSize:fontSize];
}

+ (NSString*) displayTextForPoint:(SJPoint*) p;
{
	return (p.indentationValue == 0)? p.text : [NSString stringWithFormat:@"%C %@", 0x2022, p.text];
}

@end
