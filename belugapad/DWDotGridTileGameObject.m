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

-(void)dealloc
{
    self.mySprite=nil;
    self.myAnchor=nil;
    
    [super dealloc];
}

@end
