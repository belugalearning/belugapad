//
//  DWPieSplitterSliceGameObject.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPieSplitterSliceGameObject.h"

@implementation DWPieSplitterSliceGameObject

@synthesize Position;
@synthesize mySprite;
@synthesize myPie;
@synthesize Rotation;
@synthesize myCont;
@synthesize SpriteFileName;

-(void)dealloc
{
    self.mySprite=nil;
    self.myPie=nil;
    self.myCont=nil;
    self.SpriteFileName=nil;
    
    [super dealloc];
}

@end