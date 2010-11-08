//
//  SJPointTableViewCell.m
//  Subject
//
//  Created by ∞ on 05/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPointTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@interface SJPointTableViewCell ()

+ (UIEdgeInsets) defaultCellEdgeInsets;
+ (UIFont*) textFontForPoint:(SJPoint*) p;
+ (NSString*) displayTextForPoint:(SJPoint*) p;

@end


@implementation SJPointTableViewCell

- (id) initWithNibName:(NSString *)name bundle:(NSBundle *)bundle reuseIdentifier:(NSString *)reuseIdent;
{
	if ((self = [super initWithNibName:name bundle:bundle reuseIdentifier:reuseIdent])) {
		self.clipsToBounds = YES;
		self.contentView.clipsToBounds = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mayHaveChangedStuff:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[pointTextLabel release];
	[actionView release];
	
	self.questionsView = nil;
	
	[super dealloc];
}


- (void) mayHaveChangedStuff:(NSNotification*) n;
{
	if ([self.point isDeleted])
		self.point = nil;
	else
		[self update];
}

@synthesize point;
- (void) setPoint:(SJPoint *) p;
{
	if (p != point) {
		[point release];
		point = [p retain];	
		
		[self update];
	}
}

- (void) updateWithAddedQuestion:(SJQuestion*) q;
{
	if (q.point == self.point)
		[self update];
}

- (void) update;
{
	// we don't need to set label height since the label has autoresize masks set that do that for us.
	pointTextLabel.font = [[self class] textFontForPoint:self.point];
	pointTextLabel.text = [[self class] displayTextForPoint:self.point];
	
	if ([self.point.questions count] == 0)
		self.accessoryView = nil;
	else {
		// TODO grossly inefficient!
		int dNU = 0, gID = 0, fF = 0;
		
		for (SJQuestion* q in self.point.questions) {
			if ([q.kind isEqual:kSJQuestionDidNotUnderstandKind])
				dNU++;
			else if ([q.kind isEqual:kSJQuestionGoInDepthKind])
				gID++;
			else if ([q.kind isEqual:kSJQuestionFreeformKind] && q.text)
				fF++;
			
			UIView* v = self.questionsView;
			CGRect f = v.bounds;
			CGRect firstColLabelFrame = self.didNotUnderstandCountLabel.frame;
			f.size.width = firstColLabelFrame.origin.x + firstColLabelFrame.size.width + 8;
			v.bounds = f;
			
			if (dNU > 0 || gID > 0 || fF > 0) {
				if (!self.accessoryView) {
					self.didNotUnderstandIconographyLabel.hidden = YES;
					self.goInDepthIconographyLabel.hidden = YES;
					self.freeformIconographyLabel.hidden = YES;
					self.didNotUnderstandCountLabel.hidden = YES;
					self.goInDepthCountLabel.hidden = YES;
					self.freeformCountLabel.hidden = YES;
					
					self.accessoryView = self.questionsView;
				}
				
				CATransition* slide = [CATransition animation];
				slide.type = kCATransitionFade;
				[self.questionsView.layer addAnimation:slide forKey:@"SJPointTableViewCellQuestionsUpdateTransition"];
				
				[UIView animateWithDuration:0.2 animations:^{
					self.didNotUnderstandIconographyLabel.hidden = (dNU == 0);
					self.didNotUnderstandCountLabel.hidden = (dNU == 0);
					self.didNotUnderstandCountLabel.text = [NSString stringWithFormat:@"%d", dNU];

					self.goInDepthIconographyLabel.hidden = (gID == 0);
					self.goInDepthCountLabel.hidden = (gID == 0);
					self.goInDepthCountLabel.text = [NSString stringWithFormat:@"%d", gID];

					self.freeformIconographyLabel.hidden = (fF == 0);
					self.freeformCountLabel.hidden = (fF == 0);
					self.freeformCountLabel.text = [NSString stringWithFormat:@"%d", fF];
				}];
			} else
				self.accessoryView = nil;
		}
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

#if 0

- (void) prepareForReuse;
{
	[self setShowingActionView:NO animated:NO];
}

@synthesize showingActionView;
- (void) setShowingActionView:(BOOL) s;
{
	[self setShowingActionView:s animated:YES];
}

- (void) setShowingActionView:(BOOL) s animated:(BOOL) animated;
{
	if (s != showingActionView) {
		showingActionView = s;
		
		BOOL wereEnabled = [UIView areAnimationsEnabled];

		if (s) {
			[UIView setAnimationsEnabled:NO];
			
			self.selectionStyle = UITableViewCellSelectionStyleNone;
			
			if (!actionView.superview)
				[self.contentView insertSubview:actionView belowSubview:self.cellContentView];
			actionView.frame = self.contentView.bounds;
			
			self.cellContentView.backgroundColor = [UIColor whiteColor];
			self.cellContentView.opaque = YES;
			
			[UIView setAnimationsEnabled:wereEnabled];

			
			self.contentView.clipsToBounds = YES;
			
			[UIView setAnimationsEnabled:animated];
			[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut
							 animations:^{
								 CGRect f = self.cellContentView.frame;
								 f.origin.y -= f.size.height;
								 self.cellContentView.frame = f;
							 }
							 completion:NULL];
			[UIView setAnimationsEnabled:wereEnabled];
			
		} else {
			[UIView setAnimationsEnabled:animated];
			[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction
							 animations:^{
								 self.cellContentView.frame = self.contentView.bounds;
							 }
							 completion:^(BOOL done) {
								 [actionView removeFromSuperview];
								 self.cellContentView.backgroundColor = [UIColor whiteColor];
								 self.selectionStyle = UITableViewCellSelectionStyleBlue;
							 }];
			[UIView setAnimationsEnabled:wereEnabled];
		}
		
	}
}

#endif

@synthesize questionsView;

@synthesize didNotUnderstandIconographyLabel;
@synthesize goInDepthIconographyLabel;
@synthesize freeformIconographyLabel;

@synthesize didNotUnderstandCountLabel;
@synthesize goInDepthCountLabel;
@synthesize freeformCountLabel;

@end
