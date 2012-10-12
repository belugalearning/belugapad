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

-(void)dealloc
{
    self.mySprite=nil;
    self.tile=nil;
    self.RenderLayer=nil;
    
    [super dealloc];
}

@end
