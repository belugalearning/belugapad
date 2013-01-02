//
//  DWDotGridAnchorGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWDotGridAnchorGameObject.h"

@implementation DWDotGridAnchorGameObject

@synthesize Position;
@synthesize StartAnchor;
@synthesize Disabled;
@synthesize Hidden;
@synthesize mySprite;
@synthesize myXpos;
@synthesize myYpos;
@synthesize resizeHandle;
@synthesize moveHandle;
@synthesize tile;
@synthesize RenderLayer;
@synthesize anchorSize;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"DWDotGridAnchor"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }



-(void)dealloc
{
    self.mySprite=nil;
    self.tile=nil;
    self.RenderLayer=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;
    [super dealloc];
}

@end
