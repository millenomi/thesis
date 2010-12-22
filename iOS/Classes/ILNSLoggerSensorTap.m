//
//  ILNSLoggerSensorTap.m
//  Subject
//
//  Created by ∞ on 21/12/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "ILNSLoggerSensorTap.h"
#import "SBJSON/JSON.h"
#import "LoggerClient.h"

@implementation ILNSLoggerSensorTap

- (BOOL) sensorSink:(ILSensorSink *)s shouldProcessReceivedMessage:(id)messageContent postedOnChannels:(NSSet *)channels;
{
	NSString* longestChannel = nil;
	for (NSString* chan in channels) {
		if (!longestChannel || [chan length] > [longestChannel length])
			longestChannel = chan;
	}
	
	LogMessage(longestChannel, 0, @"%@", [messageContent JSONRepresentation]);
	
	return YES;
}

@end
