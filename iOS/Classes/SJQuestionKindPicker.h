//
//  SJQuestionKindPicker.h
//  Subject
//
//  Created by ∞ on 07/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ILCoverWindow.h"
#import "SJQuestionSchema.h"

static inline NSArray* SJQuestionKindsByTag() {
	return [NSArray arrayWithObjects:
			kSJQuestionDidNotUnderstandKind,	// 0
			kSJQuestionGoInDepthKind,			// 1
			kSJQuestionFreeformKind,			// 2
			nil];
}

@interface SJQuestionKindPicker : ILCoverWindow {}

@property(copy, nonatomic) void (^didPickQuestionKind)(NSString* kind);
@property(copy, nonatomic) void (^didCancel)();

- (IBAction) pickQuestionKindFromButton:(id) sender;
- (IBAction) cancel;

@end
