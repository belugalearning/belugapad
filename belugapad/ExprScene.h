//
//  ExprScene.h
//  belugapad
//
//  Created by Gareth Jenkins on 26/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolScene.h"

@interface ExprScene : ToolScene
{
    ToolHost *toolHost;
    NSDictionary *problemDef;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    CCLayer *viz1Layer;
    CCLabelTTF *exprLabel;
    
    CCLabelTTF *labelExprString;
    CCLabelTTF *labelExprMathML;
}

-(void)readProblemDef;
-(void)loadPpExpr;
-(void)writeExprLabel;
-(void)updateExpr;
-(void)addVizToLayer:(CCLayer*)vizLayer;


@end
