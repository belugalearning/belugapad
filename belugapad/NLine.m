//
//  NLine.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NLine.h"
#import "MenuScene.h"
#import "global.h"
#import "BLMath.h"
#import "SimpleAudioEngine.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "DWRamblerGameObject.h"
#import "DWSelectorGameObject.h"
#import "Daemon.h"
#import "ToolHost.h"
#import "NLineConsts.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"


@implementation NLine

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
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
        gw = [[DWGameWorld alloc] initWithGameScene:self];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        gw.Blackboard.ComponentRenderLayer=self.ForeLayer;
        
        [self setupLabels];
        
        [self readPlist:pdef];
        
        [self populateGW];
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        gw.Blackboard.inProblemSetup = NO;
    }
    
    return self;
}

-(void)setupLabels
{
    problemCompleteLabel=[CCLabelTTF labelWithString:@"problem complete" fontName:TITLE_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemCompleteLabel setColor:kLabelCompleteColor];
    [problemCompleteLabel setPosition:ccp(cx, cy*0.2f)];
    [problemCompleteLabel setVisible:NO];
    [self.ForeLayer addChild:problemCompleteLabel z:5];

}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    
}

-(void)populateGW
{
    rambler=[DWRamblerGameObject alloc];
    [gw populateAndAddGameObject:rambler withTemplateName:@"TnLineRambler"];
    
    rambler.Value=[[problemDef objectForKey:START_VALUE] floatValue];
    rambler.StartValue=rambler.Value;
    rambler.CurrentSegmentValue=[[problemDef objectForKey:SEGMENT_VALUE] floatValue];
    rambler.MinValue=[problemDef objectForKey:MIN_VALUE];
    rambler.MaxValue=[problemDef objectForKey:MAX_VALUE];

    //positioning
    rambler.DefaultSegmentSize=115;
    rambler.Pos=ccp(cx,cy - 75.0f);
    
    selector=[DWSelectorGameObject alloc];
    [gw populateAndAddGameObject:selector withTemplateName:@"TnLineSelector"];
    
    //point the selector at the rambler
    selector.WatchRambler=rambler;
    selector.pos=ccp(cx,cy + 75.0f);
    
    if(toolHost.PpExpr)
    {
        //point gameWorld at expression
        gw.Blackboard.ProblemExpression=toolHost.PpExpr;
    
        //get list of vars for selector
        BATQuery *q=[[BATQuery alloc] initWithExpr:toolHost.PpExpr.root andTree:toolHost.PpExpr];
        selector.PopulateVariableNames=[q getDistinctVarNames];
    }
}

-(void)readPlist:(NSDictionary*)pdef
{
    //set eval and reject modes
    NSNumber *eMode=[pdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    
    NSNumber *rMode=[pdef objectForKey:REJECT_MODE];
    if (rMode) rejectMode=[rMode intValue];
    
    
    if(evalMode==kProblemEvalOnCommit)
    {
        CCSprite *commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/commit.png")];
        [commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [self.ForeLayer addChild:commitBtn z:2];
    }
    
    //render problem label
    problemDescLabel=[CCLabelTTF labelWithString:[pdef objectForKey:PROBLEM_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    //[problemDescLabel setColor:kLabelTitleColor];
    [problemDescLabel setTag:1];
    [problemDescLabel setOpacity:0];
    [self.ForeLayer addChild:problemDescLabel];
    
    
}

-(void)problemStateChanged
{
    if(evalMode==kProblemEvalAuto)
    {
        self.ProblemComplete=[self evalProblem];
        
        if(!self.ProblemComplete) 
        {
            toolHost.flagResetProblem=YES;
        }
        else {
            [self showComplete];
        }
    }
}

-(void)showComplete
{
    //[problemCompleteLabel setVisible:YES];
    [toolHost showProblemCompleteMessage];
}

-(BOOL)evalProblem
{
    //not possible to eval without expression
    if(!toolHost.PpExpr) return NO;
    
    //copy, sub eval and compare the expression
    BAExpressionTree *evalTree=[toolHost.PpExpr copy];
    
    //set subs & execute
    evalTree.VariableSubstitutions=gw.Blackboard.ProblemVariableSubstitutions;
    [evalTree substitueVariablesForIntegersOnNode:evalTree.root];

    NSLog(@"problem expression: %@", [toolHost.PpExpr expressionString]);
    NSLog(@"substituted expression: %@", [evalTree expressionString]);
    
    //evaluate
    [evalTree evaluateTree];
    
    NSLog(@"evaluated expression: %@", [evalTree expressionString]);
    
    //query comparison for equality (currently has to assume as a top level eq using query layer
    BATQuery *q=[[BATQuery alloc] initWithExpr:evalTree.root andTree:evalTree];
    BOOL result=[q assumeAndEvalEqualityAtRoot];
    
    return result;
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if (CGRectContainsPoint(kRectButtonCommit, location) && evalMode==kProblemEvalOnCommit)
    {
        self.ProblemComplete=[self evalProblem];
        
        if(!self.ProblemComplete) 
        {
            toolHost.flagResetProblem=YES;
        }
        else {
            [self showComplete];
        }
    }
    else if (location.y < kRamblerYMax)
    {
        inRamblerArea=YES;
    }
    else 
    {
        NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
        [gw handleMessage:kDWhandleTap andPayload:pl withLogLevel:-1];
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if(inRamblerArea)
    {
        CGPoint a = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView:touch.view]];
        CGPoint b = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
    
        rambler.TouchXOffset+=b.x-a.x;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    
    if(inRamblerArea)
    {
        [rambler handleMessage:kDWnlineReleaseRamblerAtOffset];
        
        inRamblerArea=NO;
        rambler.TouchXOffset=0;
    }

    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    inRamblerArea=NO;
}
@end
