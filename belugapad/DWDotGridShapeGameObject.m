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
@synthesize SelectAllTiles;
@synthesize firstAnchor;
@synthesize lastAnchor;

@synthesize firstBoundaryAnchor;
@synthesize lastBoundaryAnchor;

@synthesize RenderDimensions;
@synthesize myWidth;
@synthesize myHeight;
@synthesize shapeGroup;
@synthesize RenderLayer;
@synthesize MyNumberWheel;
@synthesize autoUpdateWheel;
@synthesize countLabelType;
@synthesize countLabel;
@synthesize countBubble;
@synthesize hintArrowX;
@synthesize hintArrowY;
@synthesize centreX;
@synthesize centreY;
@synthesize top;
@synthesize bottom;
@synthesize right;
@synthesize left;
@synthesize value;
@synthesize ShapeX;
@synthesize ShapeY;


-(void)dealloc
{
    self.tiles=nil;
    self.moveHandle=nil;
    self.resizeHandle=nil;
    self.firstAnchor=nil;
    self.lastAnchor=nil;
    self.myHeight=nil;
    self.myWidth=nil;
    self.shapeGroup=nil;
    self.RenderLayer=nil;
    self.MyNumberWheel=nil;
    self.countLabel=nil;
    self.countLabelType=nil;
    self.countBubble=nil;
    self.hintArrowX=nil;
    self.hintArrowY=nil;

    self.firstBoundaryAnchor=nil;
    self.lastBoundaryAnchor=nil;
    
    [super dealloc];
}

@end
