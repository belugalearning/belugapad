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
@synthesize firstAnchor;
@synthesize lastAnchor;

-(void)dealloc
{
    self.tiles=nil;
    self.moveHandle=nil;
    self.resizeHandle=nil;
    self.firstAnchor=nil;
    self.lastAnchor=nil;
    
    [super dealloc];
}

@end
