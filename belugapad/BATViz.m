//
//  BATViz.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BATViz.h"
#import "BAExpressionTree.h"
#import "BAExpressionHeaders.h"
#import "cocos2d.h"

@implementation BATViz

@synthesize Root;
@synthesize DrawLayer;
@synthesize Bounds;

-(id)initWithExpr:(BAExpression*)expr andLayer:(CCLayer*)layer andBounds:(CGRect)bounds
{
    if(self=[super init])
    {
        self.Root=expr;        
        self.DrawLayer=layer;
        self.Bounds=bounds;
        
        [self initDraw];
    }
    
    return self;
}

-(void)scaleVizToBounds
{
    //scale the drawn viz (by subclass implementors) to fit the supplied bounds
    
    //TODO: implement
    
    [self.DrawLayer setPosition:ccp(self.Bounds.size.width * 0.75f, self.Bounds.size.height * 0.25f)];
}

-(void)initDraw
{
    //this shouldn't really do anything -- implement in subclass implementations
}

-(void)updateDrawIndicators
{
    //this shouldn't really do anything -- implement in subclass implementations
}

-(void)dealloc
{
    self.DrawLayer=nil;
    self.Root=nil;
    [super dealloc];
}

@end
