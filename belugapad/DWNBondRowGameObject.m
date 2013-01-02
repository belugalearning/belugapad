//
//  DWNBondRowGameObject.m
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWNBondRowGameObject.h"

@implementation DWNBondRowGameObject

@synthesize MaximumValue;
@synthesize MountedObjects;
@synthesize HintObjects;
@synthesize Locked;
@synthesize Position;
@synthesize Length;
@synthesize BaseNode;
@synthesize MyHeldValue;
// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWNBondRowGameObject"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }

-(DWGameObject *) initWithGameWorld:(DWGameWorld*)aGameWorld
{
    if( (self=[super initWithGameWorld:aGameWorld] )) 
    {
        MountedObjects = [[NSMutableArray alloc]init];
        HintObjects = [[NSMutableArray alloc] init];
    }
	return self;
}

-(void)dealloc
{
    self.MountedObjects=nil;
    self.BaseNode=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;

    [super dealloc];
}

@end
