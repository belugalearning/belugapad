//
//  DWNBondStoreGameObject.m
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWNBondStoreGameObject.h"


@implementation DWNBondStoreGameObject

@synthesize AcceptedObjectValue;
@synthesize MountedObjects;
@synthesize Position;
@synthesize Label;
@synthesize Length;
// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWNBondStoreObject"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }
-(void)dealloc
{
    self.MountedObjects=nil;
    self.Label=nil;
    
    [super dealloc];
}

@end
