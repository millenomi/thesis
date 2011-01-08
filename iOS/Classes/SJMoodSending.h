//
//  SJMoodSending.h
//  Subject
//
//  Created by ∞ on 08/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJSlide.h"

@interface SJSlide (SJMoodSending)

- (void) sendMoodOfKind:(NSString*) kind usingQueue:(NSOperationQueue*) queue whenSent:(void (^)(BOOL done)) whenSent;

@end
