//
//  DWDotGridTileGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWDotGridTileGameObject.h"

@implementation DWDotGridTileGameObject

@synthesize tileType;
@synthesize mySprite;
@synthesize Position;
@synthesize Selected;
@synthesize tileSize;
@synthesize myAnchor;
@synthesize RenderLayer;
@synthesize myShape;


// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWDotGridTile"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }


-(void)dealloc
{
    self.mySprite=nil;
    self.myAnchor=nil;
    self.selectedSprite=nil;
    self.myShape=nil;
    self.RenderLayer=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;

    [super dealloc];
}

@end
