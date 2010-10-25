//
//  ILSensorSink.m
//  TheLongMix
//
//  Created by ∞ on 29/09/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "ILSensorSink.h"

@interface ILSensorSink ()

@property(retain) NSMutableSet* taps;

@end


@implementation ILSensorSink

@synthesize taps, enabled;

- (void) dealloc
{
	self.taps = nil;
	[super dealloc];
}


- (void) logMessageWithContent:(id) plist onChannels:(NSSet*) channels;
{
	if (!self.enabled)
		return;
	
	plist = [[self class] transferableObjectForObject:plist];
	
	BOOL goOn = YES;
	for (id <ILSensorSinkTap> tap in self.taps) {
		
		goOn = goOn && [tap sensorSink:self shouldProcessReceivedMessage:plist postedOnChannels:channels];
		
	}
	
	if (goOn)
		NSLog(@" -> from %@\n\t%@", [[channels allObjects] sortedArrayUsingSelector:@selector(compare:)], plist);
}

- (void) addTap:(id <ILSensorSinkTap>)tap;
{
	if (!self.taps)
		self.taps = [NSMutableSet set];
	
	[self.taps addObject:tap];
}

- (void) removeTap:(id <ILSensorSinkTap>)tap;
{
	[self.taps removeObject:tap];
	
	if ([self.taps count] == 0)
		self.taps = nil;
}

+ (id) transferableObjectForObject:(id)object;
{
	if ([object isKindOfClass:[NSArray class]]) {
		NSMutableArray* a = [[object mutableCopy] autorelease];
		
		NSInteger len = [a count];
		for (NSInteger i = 0; i < len; i++) {
			id subObject = [a objectAtIndex:i];
			id newObject = [self transferableObjectForObject:subObject];
			if (newObject != subObject)
				[a replaceObjectAtIndex:i withObject:newObject];
		}
		
		return a;
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		NSMutableDictionary* a = [[object mutableCopy] autorelease];
		NSArray* keys = [a allKeys];
		
		for (id subKey in keys) {
			id subObject = [a objectForKey:subKey];
			id newObject = [self transferableObjectForObject:subObject];
			
			id newKey = ([subKey isKindOfClass:[NSString class]]? subKey : [subKey description]);
		
			if (newObject != subObject || newKey != subKey) {
				if (newKey != subKey)
					[a removeObjectForKey:subKey];
				[a setObject:newObject forKey:subKey];
			}

		}
		
		return a;
	} else if (![object isKindOfClass:[NSString class]] && ![object isKindOfClass:[NSNumber class]] && object != [NSNull null]) {
		
		return [object respondsToSelector:@selector(descriptionForDebugging)]? [object descriptionForDebugging] : [object description];
		
	} else
		return object;
}

+ sharedSink;
{
	static id me = nil; if (!me)
		me = [self new];
	
	return me;
}

+ (void) log:(id) content atLine:(unsigned long long) line function:(const char*) functionName object:(id) object channel:(NSString*) channel;
{
	if (![[self sharedSink] isEnabled])
		return;
	
	NSMutableSet* s = [NSMutableSet setWithCapacity:3];

	NSString* selfChannel = object? [NSString stringWithFormat:@"%@:%p", NSStringFromClass([object class]), object] : nil;
	NSString* classChannel = object? NSStringFromClass([object class]) : nil;
	
	if (object) {
		[s addObject:selfChannel];
		[s addObject:classChannel];
	}
	
	if (channel)
		[s addObject:channel];
	
	NSDictionary* actualContent =
		[NSDictionary dictionaryWithObjectsAndKeys:
		
		 [NSString stringWithFormat:@"%s", functionName], @"function",
		 [NSNumber numberWithUnsignedLongLong:line], @"line",
		 content ?: [NSNull null], @"content",
		 
		 nil];
	
	[[self sharedSink] logMessageWithContent:actualContent onChannels:s];
}

@end
