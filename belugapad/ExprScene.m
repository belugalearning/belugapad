//
//  ExprScene.m
//  belugapad
//
//  Created by Gareth Jenkins on 26/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExprScene.h"
#import "ToolHost.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"

@implementation ExprScene

-(id) initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    problemDef=pdef;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
    
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        viz1Layer=[[[CCLayer alloc] init] autorelease];
        [self.ForeLayer addChild:viz1Layer];
        
        [self readProblemDef];
        [self updateExpr];
    }
    
    return self;
}

-(void)readProblemDef
{
    [self loadPpExpr];
}

-(void)loadPpExpr
{
    //populate primary problem expression
    
    BAAdditionOperator *add=[BAAdditionOperator operator];
    BAInteger *i1=[BAInteger integerWithIntValue:2];
    BAInteger *i2=[BAInteger integerWithIntValue:3];
    [add addChild:i1];
    [add addChild:i2];
        
    BAMultiplicationOperator *mult=[BAMultiplicationOperator operator];
    BADivisionOperator *div=[BADivisionOperator operator];
    BAInteger *i3=[BAInteger integerWithIntValue:5];
    BAVariable *x=[BAVariable variableWithName:@"x"];
    [div addChild:i3];
    [div addChild:x];
    
    BAAdditionOperator *add2=[BAAdditionOperator operator];
    BAInteger *i4=[BAInteger integerWithIntValue:12];
    BAInteger *i5=[BAInteger integerWithIntValue:1];
    [add2 addChild:i4];
    [add2 addChild:i5];
    
    [mult addChild:add2];
    [mult addChild:div];
    
    BAEqualsOperator *eq=[BAEqualsOperator operator];
    [eq addChild:add];
    [eq addChild:mult];
    toolHost.PpExpr=[BAExpressionTree treeWithRoot:eq];
}

-(void)writeExprLabel
{
    BATQuery *q=[[BATQuery alloc] initWithExpr:toolHost.PpExpr.root];
    
    NSString *text=[NSString stringWithFormat:@"expressionString: %@ \ndepth: %d", [[toolHost.PpExpr root] expressionString], [q getMaxDepth]];
    
    if(!exprLabel)
    {
        exprLabel=[CCLabelTTF labelWithString:text dimensions:CGSizeMake(lx*0.5f, ly*0.5f) alignment:UITextAlignmentLeft fontName:@"Helvetica" fontSize:24];
//        exprLabel=[CCLabelTTF labelWithString:text fontName:@"Helvetica" fontSize:24];
        [exprLabel setOpacity:100];
        [exprLabel setPosition:ccp(lx*0.25f + lx*0.0075f, ly*0.75f - lx*0.005f)];
        [self.ForeLayer addChild:exprLabel];
    }
    else {
        [exprLabel setString:text];
    }
}

-(void)updateExpr
{
    [self writeExprLabel];
    
    [viz1Layer removeAllChildrenWithCleanup:YES];
    
    [self addVizToLayer:viz1Layer];
}

-(void)addVizToLayer:(CCLayer*)vizLayer
{
    
}

-(void)dealloc
{
    
  
    [super dealloc];
}

@end
