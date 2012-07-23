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

-(void)dealloc
{
    if(mySprite)[mySprite release];
    if(myAnchor)[myAnchor release];
    
    [super dealloc];
}

@end
