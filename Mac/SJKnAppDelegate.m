//
//  KeynoteAgentAppDelegate.m
//  KeynoteAgent
//
//  Created by ∞ on 24/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SJKnAppDelegate.h"

#import <ScriptingBridge/ScriptingBridge.h>
#import <SJClient/SJClient.h>

#import "Key.h"

@interface SJKnAppDelegate ()

@property NSTimer* timer;
@property SJEndpoint* endpoint;

@end


@implementation SJKnAppDelegate

@synthesize window;
@synthesize timer;
@synthesize presentationID;
@synthesize slideNumber;
@synthesize endpoint;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(pollForCurrentKeynoteSlide:) userInfo:nil repeats:YES];
	
	self.endpoint = [[SJEndpoint alloc] initWithURL:[NSURL URLWithString:@"http://localhost:8083"]];
	
}

- (void) pollForCurrentKeynoteSlide:(NSTimer*) t;
{
//	KeyApplication* app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iWork.Keynote"];
	
	NSRunningApplication* keynoteApp = nil;
	for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if ([app.bundleIdentifier isEqual:@"com.apple.iWork.Keynote"] && app.finishedLaunching) {
			keynoteApp = app;
			break;
		}
	}
	
	if (!keynoteApp) {
		NSLog(@"Not running");
		self.slideNumber = nil;
		return;
	}

	KeyApplication* app = [SBApplication applicationWithProcessIdentifier:keynoteApp.processIdentifier];
		
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"playing == %@", [NSNumber numberWithBool:YES]];
	NSArray* a = [[app slideshows] filteredArrayUsingPredicate:predicate];
	
	if ([a count] == 0) {
		NSLog(@"No items in filtered array");
		self.slideNumber = nil;
		return;
	}
	
	KeySlideshow* runningSlideshow = [a objectAtIndex:0];
	if (!runningSlideshow.playing) {
		NSLog(@"Not playing");
		self.slideNumber = nil;
		return;
	}

	KeySlide* slide = runningSlideshow.currentSlide;
	
	NSInteger i = [[[runningSlideshow slides] get] indexOfObject:[slide get]];
	
	NSLog(@"index of slide == %d", (int) i);
	self.slideNumber = [NSNumber numberWithInteger:i];
}

- (void) setSlideNumber:(NSNumber*) n;
{
	if (slideNumber != n) {
		slideNumber = n;
		
		if (self.presentationID && ![self.presentationID isEqual:@""]) {
			NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[self.endpoint URL:@"/live"]];
			
			NSString* str;
			if (self.slideNumber)
				str = [NSString stringWithFormat:@"presentation=%@&slide=%@", self.presentationID, self.slideNumber];
			else
				str = @"end=true";
			
			[req setHTTPBody:[str dataUsingEncoding:NSASCIIStringEncoding]];
			[req setHTTPMethod:@"POST"];
			[req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			
			[[self.endpoint requestFromURLRequest:req completionHandler:^(id <SJRequest> req) {
				
				NSLog(@"Did change slide to %@, %@ (end if nil)", self.presentationID, self.slideNumber);
				NSLog(@"Result was: %d", req.HTTPResponse? [req.HTTPResponse statusCode] : 0);
				
			}] start];
		}
	}
}

@end
