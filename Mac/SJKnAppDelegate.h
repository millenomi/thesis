//
//  KeynoteAgentAppDelegate.h
//  KeynoteAgent
//
//  Created by ∞ on 24/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SJKnAppDelegate : NSObject <NSApplicationDelegate> {
	NSNumber* slideNumber;
}

@property IBOutlet NSWindow *window;

@property(copy) NSString* presentationID;
@property(copy) NSNumber* slideNumber;

- (IBAction) copyJSONFromFrontmostPresentation:(id) sender;

@end
