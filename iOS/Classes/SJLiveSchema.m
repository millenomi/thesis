//
//  SJLiveSchema.m
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJLiveSchema.h"


@implementation SJLiveSchema

@dynamic slide;
- validClassForSlideKey { return [SJSlideSchema class]; }

@end
