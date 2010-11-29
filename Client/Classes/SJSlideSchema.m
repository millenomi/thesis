//
//  SJSlideSchema.m
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJSlideSchema.h"
#import "SJPointSchema.h"

@implementation SJSlideSchema

@dynamic sortingOrder;
@dynamic points;
@dynamic presentationURLString;
@dynamic URLString;

- validClassForSortingOrderKey { return [NSNumber class]; }
- validClassForValuesOfPointsArrayKey { return [SJPointSchema class]; }
- validClassForPresentationURLStringKey { return [NSString class]; }
- validClassForURLStringKey { return [NSString class]; }

- (BOOL) isValueOptionalForURLStringKey { return YES; }

@end
