//
//  DWDotGridHandleGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWDotGridHandleGameObject.h"

@implementation DWDotGridHandleGameObject

@synthesize handleType;
@synthesize Position;
@synthesize mySprite;
@synthesize myShape;
@synthesize RenderLayer;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWDotGridHandle"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }


-(void)dealloc
{
    self.mySprite=nil;
    self.myShape=nil;
    self.RenderLayer=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;

    [super dealloc];
}

@end
