//
//  DWPlaceValueNetGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPlaceValueNetGameObject.h"
#import "AppDelegate.h"
#import "LogPoller.h"
#import "LoggingService.h"

@implementation DWPlaceValueNetGameObject

@synthesize PosX;
@synthesize PosY;
@synthesize myRow;
@synthesize myCol;
@synthesize myRope;
@synthesize ColumnValue;
@synthesize MountedObject;
@synthesize CancellingObject;
@synthesize mySprite;
@synthesize Hidden;
@synthesize renderType;
@synthesize AllowMultipleMount;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWPlaceValueNet"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return [self Position]; }

-(CGPoint)Position
{
    return ccp(PosX, PosY);
}

-(void)dealloc
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller unregisterPollee:(id<LogPolling>)self];
    
    self.MountedObject=nil;
    self.mySprite=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;

    [super dealloc];
}

@end
