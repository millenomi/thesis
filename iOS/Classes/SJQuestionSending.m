//
//  SJQuestionSending.m
//  Subject
//
//  Created by ∞ on 07/01/11.
//  Copyright 2011 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJQuestionSending.h"

#import "SJClient.h"

#import "NSURL+ILURLParsing.h"


@implementation ILURLConnectionOperation (SJConveniences)

- (BOOL) isSuccessful;
{
	return !self.error && (!self.HTTPResponse || [self.HTTPResponse statusCode] < 400);
}

@end

@implementation SJQuestion (SJQuestionSending)

- (void) sendUsingQueue:(NSOperationQueue*) queue whenSent:(void (^)(BOOL done)) whenSent;
{
	NSParameterAssert(queue != nil);
	NSAssert(self.point, @"This question must be associated to a point");
	
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/new_question", self.point.URLString]];
	NSAssert(url != nil, @"Could not create a valid question URL");
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	
	[request setHTTPMethod:@"POST"];
	
	NSAssert(self.kind, @"The kind must be specified");
	NSAssert(![self.kind isEqual:kSJQuestionFreeformKind] || self.text, @"For freeform questions, the ");
	
	NSMutableDictionary* query = [NSMutableDictionary dictionaryWithObject:self.kind forKey:@"kind"];
	
	if (self.text)
		[query setObject:self.text forKey:@"text"];
	
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[[query queryString] dataUsingEncoding:NSUTF8StringEncoding]];
	
	ILURLConnectionOperation* operation = [[[ILURLConnectionOperation alloc] initWithRequest:request] autorelease];
	
	[operation setURLConnectionCompletionBlock:^{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			if (operation.successful)
				self.URL = operation.response.URL;
			else
				[self.managedObjectContext deleteObject:self];
			

			if (![self.managedObjectContext save:NULL])
				[self.managedObjectContext rollback];
			
			if (whenSent)
				whenSent(operation.successful);
		}];
	}];
	
	[queue addOperation:operation];
}

@end

