//
//  SJQuestionSending.h
//  Subject
//
//  Created by ∞ on 07/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJQuestion.h"
#import "ILURLConnectionOperation.h"

@interface SJQuestion (SJQuestionSending)

- (void) sendUsingQueue:(NSOperationQueue*) queue whenSent:(void (^)(BOOL done)) whenSent;

@end

@interface ILURLConnectionOperation (SJConveniences)

@property(readonly, nonatomic, getter=isSuccessful) BOOL successful;

@end
