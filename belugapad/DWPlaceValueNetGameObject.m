//
//  DWPlaceValueNetGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPlaceValueNetGameObject.h"

@implementation DWPlaceValueNetGameObject

@synthesize PosX;
@synthesize PosY;
@synthesize myRow;
@synthesize myCol;
@synthesize myRope;
@synthesize ColumnValue;
@synthesize MountedObject;
@synthesize mySprite;
@synthesize Hidden;

-(void)dealloc
{
    if(MountedObject)[MountedObject release];
    if(mySprite)[mySprite release];
    
    [super dealloc];
}

@end
