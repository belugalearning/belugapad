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

-(id)initWithExpr:(BAExpression*)expr andLayer:(CCLayer*)layer
{
    if(self=[super init])
    {
        self.Root=expr;        
        self.DrawLayer=layer;
        
        [self initDraw];
    }
    
    return self;
}

-(void)initDraw
{
    
}

-(void)updateDrawIndicators
{
    
}

@end
