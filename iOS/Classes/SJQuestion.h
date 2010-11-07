//
//  SJQuestion.h
//  Subject
//
//  Created by ∞ on 07/11/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJPoint.h"
#import "ILManagedObject.h"

#import "SJQuestionSchema.h" // for the kSJQuestion*Kind constants

@interface SJQuestion : ILManagedObject

@property (nonatomic, retain) NSString* kind;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, retain) SJPoint* point;
@property (nonatomic, retain) NSString * URLString;

@end
