//
//  DWDotGridShapeGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWDotGridShapeGameObject.h"

@implementation DWDotGridShapeGameObject

@synthesize tiles;
@synthesize moveHandle;
@synthesize resizeHandle;
@synthesize Disabled;
@synthesize SelectAllTiles;
@synthesize firstAnchor;
@synthesize lastAnchor;
@synthesize RenderDimensions;
@synthesize myWidth;
@synthesize myHeight;

-(void)dealloc
{
    self.tiles=nil;
    self.moveHandle=nil;
    self.resizeHandle=nil;
    self.firstAnchor=nil;
    self.lastAnchor=nil;
    self.myHeight=nil;
    self.myWidth=nil;
    
    [super dealloc];
}

@end
