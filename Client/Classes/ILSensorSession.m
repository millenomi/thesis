//
//  ILSensorSession.m
//  TheLongMix
//
//  Created by ∞ on 29/09/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "ILSensorSession.h"
#import "ILSensorSink.h"

@interface ILSensorSession ()

- (void) update;

@end


@implementation ILSensorSession

- (id) initWithSourceChannels:(NSSet*) c properties:(NSDictionary*) props;
{
	if ((self = [super init])) {
		chans = [[[c setByAddingObject:NSStringFromClass([self class])] setByAddingObject:[NSString stringWithFormat:@"%@:%p", NSStringFromClass([self class]), self]] copy];
		properties = [[ILSensorSink transferableObjectForObject:props] mutableCopy];
	}
	
	return self;
}

- (void) dealloc
{
	if (!didSendFinishing)
		[self end];
	
	[chans release];
	[properties release];
	[super dealloc];
}

- (void) setObject:(id) o forPropertyKey:(NSString*) k;
{
	[properties setObject:[ILSensorSink transferableObjectForObject:o] forKey:k];
}

- (void) updateBySettingObject:(id) o forPropertyKey:(NSString*) k;
{
	[self setObject:o forPropertyKey:k];
	[self update];
}

- (void) removeObjectForPropertyKey:(NSString*) k;
{
	[properties removeObjectForKey:k];
}

- (void) updateByRemovingObjectForPropertyKey:(NSString*) k;
{
	[self removeObjectForPropertyKey:k];
	[self update];
}

- (void) update;
{
	if (finished && didSendFinishing)
		return;
		
	NSString* event = nil;
	
	if (!finished && !didSendStarting) {
		event = @"start";
		didSendStarting = YES;
	} else if (finished && !didSendFinishing) {
		event = @"end";
		didSendFinishing = YES;
	} else
		event = @"update";
	
	[[ILSensorSink sharedSink] logMessageWithContent:[NSDictionary dictionaryWithObjectsAndKeys:event, @"sessionEventKind", properties, @"content", nil] onChannels:chans];
}

- (void) end;
{
	finished = YES;
	[self update];
}

- (void) updateState:(NSString*) state;
{
	[self updateBySettingObject:state forPropertyKey:@"info"];
}

@end
