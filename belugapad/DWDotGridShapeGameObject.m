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
    if(tiles)[tiles release];
    if(moveHandle)[moveHandle release];
    if(resizeHandle)[resizeHandle release];
    if(firstAnchor)[firstAnchor release];
    if(lastAnchor)[lastAnchor release];
    
    [super dealloc];
}

@end
