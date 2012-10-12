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
@synthesize CancellingObject;
@synthesize mySprite;
@synthesize Hidden;
@synthesize renderType;
@synthesize AllowMultipleMount;

-(void)dealloc
{
    self.MountedObject=nil;
    self.mySprite=nil;
    
    [super dealloc];
}

@end
