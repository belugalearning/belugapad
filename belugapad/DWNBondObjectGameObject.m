//
//  DWNBondObjectGameObject.m
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWNBondObjectGameObject.h"
#import "DWNBondRowGameObject.h"

@implementation DWNBondObjectGameObject

@synthesize ObjectValue;
@synthesize Position;
@synthesize MovePosition;
@synthesize MountPosition;
@synthesize Mount;
@synthesize BaseNode;
@synthesize Length;
@synthesize Label;
@synthesize InitedObject;
@synthesize IsScaled;
@synthesize IndexPos;
@synthesize NoScaleBlock;
@synthesize lastZIndex;
@synthesize HintObject;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWNBondBlock"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }

-(DWGameObject *) initWithGameWorld:(DWGameWorld*)aGameWorld
{
    if( (self=[super initWithGameWorld:aGameWorld] )) 
    {
        Label = [[CCLabelTTF alloc]init];
    }
	return self;
}

-(void)dealloc
{
    self.Mount=nil;
    self.BaseNode=nil;
    self.Label=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;

    [super dealloc];
}

@end
