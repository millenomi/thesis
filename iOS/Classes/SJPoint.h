//
//  SJPoint.h
//  Subject
//
//  Created by ∞ on 19/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILManagedObject.h"

@class SJSlide;

@interface SJPoint : ILManagedObject {

}

@property (nonatomic, retain) NSNumber * indentation;
@property (nonatomic, retain) NSNumber * sortingOrder;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) SJSlide * slide;

@property(nonatomic, assign) NSUInteger indentationValue, sortingOrderValue;

@end
