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
    
    selector.pos=ccp(cx,cy + 75.0f);
    
    //point gameWorld at expression
    gw.Blackboard.ProblemExpression=toolHost.PpExpr;
    
    //get list of vars for selector
    BATQuery *q=[[BATQuery alloc] initWithExpr:toolHost.PpExpr.root andTree:toolHost.PpExpr];
    selector.PopulateVariableNames=[q getDistinctVarNames];
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
    [problemDescLabel setTag:3];
    [problemDescLabel setOpacity:0];
    [self.ForeLayer addChild:problemDescLabel];
    
    
}

-(void)problemStateChanged
{
    if(evalMode==kProblemEvalAuto)
    {
        self.ProblemComplete=[self evalProblem];
    }
}

-(BOOL)evalProblem
{
    BOOL result=NO;
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
