//
//  SJPointSchema.h
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJSchema.h"

@interface SJPointSchema : SJSchema {}

@property(readonly) NSString* text;
@property(readonly) NSNumber* indentation;

@property(readonly) NSInteger indentationValue;

@property(readonly, getter=URL) NSString* URLString;
@property(readonly, getter=slideURL) NSString* slideURLString;

@end
