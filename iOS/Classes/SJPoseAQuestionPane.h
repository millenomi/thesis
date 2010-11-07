//
//  SJPoseAQuestionPane.h
//  Subject
//
//  Created by ∞ on 03/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILViewController.h"

typedef void (^SJPoseAQuestionDidAskHandler)(NSString* questionText);

@interface SJPoseAQuestionPane : ILViewController <UITextViewDelegate> {
	IBOutlet UIImageView* balloonBackdrop;
	IBOutlet UIView* keyboardRaiserView;
	IBOutlet UITextView* questionTextView;
	
	NSString* context;
}

@property(copy) NSString* context;
@property(copy) void (^didAskQuestionHandler)(NSString* questionText);
@property(copy) void (^didCancelHandler)();

@end
