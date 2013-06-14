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
@synthesize textString;
@synthesize BaseNode;
@synthesize Nodes;
@synthesize mySprite;
@synthesize Touchable;
@synthesize labelNode;
@synthesize wholeNum;
@synthesize fractNum;
@synthesize fractDenom;
@synthesize decimalNum;
@synthesize fractLine;

-(CGRect)returnLabelBox
{
    CGRect thisRect=CGRectNull;
    
    thisRect=CGRectUnion(wholeNum.boundingBox, thisRect);
    thisRect=CGRectUnion(fractNum.boundingBox, thisRect);
    thisRect=CGRectUnion(fractDenom.boundingBox, thisRect);
    thisRect=CGRectUnion(decimalNum.boundingBox, thisRect);
    
    return thisRect;
}

-(void)dealloc
{
    self.mySlices=nil;
    self.textString=nil;
    self.BaseNode=nil;
    self.Nodes=nil;
    self.mySprite=nil;
    self.labelNode=nil;
    self.wholeNum=nil;
    self.decimalNum=nil;
    self.fractNum=nil;
    self.fractDenom=nil;
    self.fractLine=nil;
    
    [super dealloc];
}

@end