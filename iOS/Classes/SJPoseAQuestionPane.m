//
//  SJPoseAQuestionPane.m
//  Subject
//
//  Created by ∞ on 03/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPoseAQuestionPane.h"

@interface SJPoseAQuestionPane ()

- (void) animateKeyboardRaiserToFrame:(CGRect)frame duration:(CGFloat)duration curve:(UIViewAnimationCurve)curve;

@end


@implementation SJPoseAQuestionPane

- (id) init;
{
	if ((self = [super init])) {
		
		self.title = NSLocalizedString(@"Question", @"Pose a question pane title");
		
		// Cancel button
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)] autorelease];
		
		// Ask button
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Ask", @"'Ask' modal dismiss button on the pose-a-question pane") style:UIBarButtonItemStyleDone target:self action:@selector(ask)] autorelease];

		self.navigationItem.rightBarButtonItem.enabled = NO;
		
		// Keyboard stuff
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
		
		// Outlets
		
		[self addManagedOutletKeys:
		 @"balloonBackdrop",
		 @"keyboardRaiserView",
		 @"questionTextView",
		 nil];
		
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.didAskQuestionHandler = nil;
	self.didCancelHandler = nil;
	
	[context release];
	[super dealloc];
}


@synthesize context;
- (void) setContext:(NSString *) s;
{
	if (s != context) {
		[context release];
		context = [s copy];
		
		NSString* promptString = nil;
		if (s)
			promptString = [NSString stringWithFormat:@"Re: \u201c%@\u201d", s];
		self.navigationItem.prompt = promptString;
	}
}
		
- (void) viewDidLoad;
{	
	balloonBackdrop.image = [[UIImage imageNamed:@"Balloon.png"] stretchableImageWithLeftCapWidth:25 topCapHeight:16];
	keyboardRaiserView.frame = self.view.bounds;
	
	questionTextView.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated;
{
	keyboardRaiserView.frame = self.view.bounds;
	[questionTextView becomeFirstResponder];
}

- (void) clearOutlets;
{
	questionTextView.delegate = nil;
	[super clearOutlets];
}

#pragma mark Keyboard stuff

- (void) willShowKeyboard:(NSNotification*) n;
{
	if (![self isViewLoaded] || !self.view.window)
		return;
	
	double duration = [[[n userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	UIViewAnimationCurve curve = [[[n userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];

	CGRect keyboardFrame = [[[n userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];

	// we're evil and we assume the keyboard is on the bottom side of the screen.
	
	CGRect frame = keyboardRaiserView.frame;
	frame.size.height = keyboardFrame.origin.y;
	
	[self animateKeyboardRaiserToFrame:frame duration:duration curve:curve];
}

- (void) willHideKeyboard:(NSNotification*) n;
{
	if (![self isViewLoaded] || !self.view.window)
		return;
	
	double duration = [[[n userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	UIViewAnimationCurve curve = [[[n userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[self animateKeyboardRaiserToFrame:self.view.bounds duration:duration curve:curve];	
}

- (void) animateKeyboardRaiserToFrame:(CGRect) frame duration:(CGFloat) duration curve:(UIViewAnimationCurve) curve;
{
	if (![self isViewLoaded] || !self.view.window)
		return;
	
	UIViewAnimationOptions opts = 0;
	
	switch (curve) {
		case UIViewAnimationCurveEaseIn:
			opts |= UIViewAnimationOptionCurveEaseIn;
			break;
		case UIViewAnimationCurveEaseOut:
			opts |= UIViewAnimationOptionCurveEaseOut;
			break;
		case UIViewAnimationCurveEaseInOut:
			opts |= UIViewAnimationOptionCurveEaseInOut;
			break;
		case UIViewAnimationCurveLinear:
			opts |= UIViewAnimationOptionCurveLinear;
			break;
	}
	
	[UIView animateWithDuration:duration
						  delay:0
						options:opts
					 animations:^{
						 keyboardRaiserView.frame = frame;
					 }
					 completion:NULL];
}

#pragma mark Actually asking

@synthesize didAskQuestionHandler, didCancelHandler;

- (void) ask;
{
	if (self.didAskQuestionHandler)
		(self.didAskQuestionHandler)(questionTextView.text);
}

- (void) dismiss;
{
	// we rely on our client to dismiss ourselves.
	if (self.didCancelHandler)
		(self.didCancelHandler)();
}

- (void) textViewDidChange:(UITextView*) tv;
{
	self.navigationItem.rightBarButtonItem.enabled = [questionTextView hasText];
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
	if (range.length == 0 && [text isEqual:@"\n"]) {
		[self ask];
		return NO;
	}
	
	return YES;
}

#pragma mark Rotation

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
	return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end
