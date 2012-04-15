//
//  ToolScene.m
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolScene.h"
#import "ToolHost.h"

@implementation ToolScene

@synthesize ProblemComplete;
@synthesize BkgLayer;
@synthesize ForeLayer;
@synthesize ScaleMin;
@synthesize ScaleMax;
@synthesize PassThruScaling;

-(id)initWithToolHost:(ToolHost*)host andProblemDef:(NSDictionary*)pdef
{
    return self;
}

-(void)problemStateChanged
{
    
}

-(void)doUpdateOnTick:(ccTime)delta
{
    
}

-(void)doUpdateOnSecond:(ccTime)delta
{
    
}

-(void)doUpdateOnQuarterSecond:(ccTime)delta
{
    
}

-(float)metaQuestionTitleXLocation
{
    return 0;
}

-(float)metaQuestionAnswersXLocation
{
    return 0;
}

-(float)metaQuestionTitleYLocation
{
    return 0;
}

-(float)metaQuestionAnswersYLocation
{
    return 0;
}

-(void)evalProblem
{
    
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}

@end
