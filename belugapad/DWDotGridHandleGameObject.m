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

-(void)dealloc
{
    if(mySprite)[mySprite release];
    if(myShape)[myShape release];
    
    [super dealloc];
}

@end
