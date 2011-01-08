//
//  SJMoodSending.m
//  Subject
//
//  Created by ∞ on 08/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJMoodSending.h"
#import "SJQuestionSending.h"

#import "NSURL+ILURLParsing.h"


@implementation SJSlide (SJMoodSending)

- (void) sendMoodOfKind:(NSString*) kind usingQueue:(NSOperationQueue*) queue whenSent:(void (^)(BOOL done)) whenSent;
{
	NSParameterAssert(kind != nil);
	NSParameterAssert(queue != nil);
	NSAssert(self.URL != nil, @"This slide must have a URL before this method can be used");
	
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"/live%@/new_mood", [self.URL path]] relativeToURL:self.URL];
	NSAssert(url != nil, @"Could not create a valid mood post URL");
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	
	[request setHTTPMethod:@"POST"];
	
	NSMutableDictionary* query = [NSMutableDictionary dictionaryWithObject:kind forKey:@"kind"];
	
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[[query queryString] dataUsingEncoding:NSUTF8StringEncoding]];
	
	ILURLConnectionOperation* operation = [[[ILURLConnectionOperation alloc] initWithRequest:request] autorelease];
	
	if (whenSent) {
		[operation setURLConnectionCompletionBlock:^{
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				whenSent(operation.successful);
			}];
		}];
	}
	
	[queue addOperation:operation];
}

@end
