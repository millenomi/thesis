//
//  SJPresentationSchema.m
//  Subject
//
//  Created by ∞ on 23/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJPresentationSchema.h"

@implementation SJPresentationSlideInfoSchema

@dynamic URLString;
- validClassForURLStringKey { return [NSString class]; }

@dynamic contents;
- validClassForContentsKey { return [SJSlideSchema class]; }
- (BOOL) isValueOptionalForContentsKey { return YES; }

@end


@implementation SJPresentationSchema

@dynamic title;
- validClassForTitleKey { return [NSString class]; }

@dynamic slides;
- validClassForValuesOfSlidesArrayKey { return [SJPresentationSlideInfoSchema class]; }

@end
