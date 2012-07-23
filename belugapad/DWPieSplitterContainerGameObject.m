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
@synthesize mySpriteTop;
@synthesize mySpriteMid;
@synthesize mySpriteBot;

-(void)dealloc
{
    if(mySlices)[mySlices release];
    if(myText)[myText release];
    if(textString)[textString release];
    if(BaseNode)[BaseNode release];
    if(Nodes)[Nodes release];
    if(mySpriteTop)[mySpriteTop release];
    if(mySpriteMid)[mySpriteMid release];
    if(mySpriteBot)[mySpriteBot release];
    
    [super dealloc];
}

@end