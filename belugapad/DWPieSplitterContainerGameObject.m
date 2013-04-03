//
//  DWPieSplitterContainerGameObject.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPieSplitterContainerGameObject.h"

@implementation DWPieSplitterContainerGameObject

@synthesize Position;
@synthesize MountPosition;
@synthesize RealYPosOffset;
//@synthesize mySprite;
@synthesize mySlices;
@synthesize ScaledUp;
@synthesize myText;
@synthesize textString;
@synthesize BaseNode;
@synthesize Nodes;
@synthesize mySprite;


-(void)dealloc
{
    self.mySlices=nil;
    self.myText=nil;
    self.textString=nil;
    self.BaseNode=nil;
    self.Nodes=nil;
    self.mySprite=nil;
    
    [super dealloc];
}

@end