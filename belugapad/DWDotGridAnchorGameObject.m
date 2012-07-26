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

-(void)dealloc
{
    if(mySprite)[mySprite release];
    if(tile)[tile release];
    
    [super dealloc];
}

@end
