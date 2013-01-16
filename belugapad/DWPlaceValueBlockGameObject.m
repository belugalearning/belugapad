//
//  DWPlaceValueBlockGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueNetGameObject.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"

@implementation DWPlaceValueBlockGameObject

//@synthesize Mount;
@synthesize Mount=Mount1;
@synthesize LastMount=LastMount1;
@synthesize ObjectValue;
@synthesize PickupSprite;
@synthesize mySprite;
@synthesize SpriteFilename;
@synthesize PosX;
@synthesize PosY;
@synthesize AnimateMe;
@synthesize Selected;
@synthesize lastZIndex;
@synthesize Disabled;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWPlaceValueBlock"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return [self Position]; }

-(void)initComplete
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller registerPollee:(id<LogPolling>)self];
}

-(DWGameObject*)Mount
{
    return Mount1;
}

-(CGPoint)Position
{
    return ccp(PosX,PosY);
}

-(void)setMount:(DWGameObject *)newMount
{
    if(Mount1!=newMount)
    {
        [Mount1 release];
        Mount1=[newMount retain];
    }
}

-(DWGameObject*)LastMount
{
    return LastMount1;
}

-(void)setLastMount:(DWGameObject *)newLastMount
{
    if(LastMount1!=newLastMount)
    {
        [LastMount1 release];
        LastMount1=[newLastMount retain];
    }
}

-(void)dealloc
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller unregisterPollee:(id<LogPolling>)self];
    self.logPollId = nil;
    
    
    logPollId = nil;
    self.Mount=nil;
    self.LastMount=nil;
    self.PickupSprite=nil;
    self.mySprite=nil;
    self.SpriteFilename=nil;

    [super dealloc];
}

@end
