//
//  BATTreeViz.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BATTreeViz.h"
#import "BATQuery.h"
#import "BAExpressionHeaders.h"
#import "cocos2d.h"
#import "global.h"

static float kNodeXSpace=60.0f;          //node space at lowest level
static float kNodeYSpace=100.0f;          //space between depths
static NSString *kNodeFont=GENERIC_FONT;
static float kNodeFontSize=24.0f;

@implementation BATTreeViz

-(void)initDraw
{
    //initial drawing of tree
    
    //depth is used to assed basic width
    BATQuery *q=[[BATQuery alloc] initWithExpr:self.Root];
    maxDepth=[q getMaxDepth];
    [q release];
    
    [self drawNode:self.Root atDepth:0 withParentX:0 andSiblingIndex:0];
    
    //call parent scalar
    [super scaleVizToBounds];
    
}

-(void)drawNode:(BAExpression*)node atDepth:(int)depth withParentX:(float)parentX andSiblingIndex:(int)siblingIndex
{
    //nodes are (maxDepth-depth)*kNodeSpaceX / 2 apart, from left
    CCLabelTTF *label=[CCLabelTTF labelWithString:[node stringValue] fontName:kNodeFont fontSize:kNodeFontSize];
    
    float xbase=parentX-((maxDepth-depth)*kNodeXSpace * 0.5f);
    float x=xbase + siblingIndex * ((maxDepth-depth)*kNodeXSpace);
    float y=(maxDepth-depth)*kNodeYSpace;
    
    [label setPosition:CGPointMake(x, y)];
    [self.DrawLayer addChild:label];
    
    //CGPoint parentpos=CGPointMake(parentX, y+kNodeYSpace);
    
    for (int i=0; i<[[node children] count]; i++) {
        [self drawNode:[[node children] objectAtIndex:i] atDepth:depth+1 withParentX:[label position].x andSiblingIndex:i];
    }
}

-(void)updateDrawIndicators
{
    //update statuses on tree elements
    //statuses set by BATQuery / elsewhere
    
}

@end

