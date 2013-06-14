//
//  NLine.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NLine.h"
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
#import "DProblemParser.h"
#import "LoggingService.h"
#import "UsersService.h"
#import "AppDelegate.h"
#import "InteractionFeedback.h"

@interface NLine()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

static float kBubbleProx=35.0f;
static float kBubbleScrollBoundary=450.0f;
static float kBubblePushSpeed=220.0f;

static float kTimeToBubbleShake=7.0f;

static float kFrogYOffset=30.0f;
static float kFrogTargetYOffset=80.0f;
static float kFrogTargetXOffset=0.0f;

float timerIgnoreFrog;

@implementation NLine

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    problemDef=pdef;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
        
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
        
        toolHost.disableDescGwBtxeInteractions=YES;
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        loggingService = ac.loggingService;
        
        gw.Blackboard.ComponentRenderLayer=self.ForeLayer;
        
        [self setupLabels];
        
        [self readPlist:pdef];
        
        [self populateGW];
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        [self setupBubble];
        
        gw.Blackboard.inProblemSetup = NO;
    }
    
    return self;
}

-(void)setupBubble
{
//    bubbleTexRegular=[[CCTexture2D alloc] initWithCGImage:[UIImage imageWithContentsOfFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_Bubble.png")].CGImage resolutionType:kCCResolutioniPad];
//    bubbleTexSelected=[[CCTexture2D alloc] initWithCGImage:[UIImage imageWithContentsOfFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_Bubble.png")].CGImage resolutionType:kCCResolutioniPad];
    
    bubbleSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_Bubble.png")];
    [bubbleSprite setPosition:ccp(cx, cy)];
    [self.ForeLayer addChild:bubbleSprite z:100];
    
}

-(void)setupFrog
{
    frogSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_Bubble.png")];
    frogSprite.color=ccc3(0, 255, 0);
    frogSprite.position=ccp(cx, cy+kFrogYOffset);
    [self.ForeLayer addChild:frogSprite];
    
    frogTargetSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_MoveButton.png")];
    [self.ForeLayer addChild:frogTargetSprite];
    frogTargetSprite.opacity=0;
}

-(void)showFrogTarget
{    
    frogTargetSprite.opacity=0;
    float x=rambler.TouchXOffset + cx + (lastBubbleLoc-initStartLoc) * rambler.DefaultSegmentSize;
    frogTargetSprite.position=ccp(x+kFrogTargetXOffset, cy+kFrogTargetYOffset);
    [frogTargetSprite runAction:[CCFadeIn actionWithDuration:0.25f]];
}

-(void)hideFrogTarget
{
    if(frogTargetSprite.opacity>0)
    {
        [frogTargetSprite runAction:[CCFadeOut actionWithDuration:0.25f]];
    }
}

-(void)hopFrog
{
    if(lastBubbleLoc==lastFrogLoc) return;
    
    ccBezierConfig bc;
    bc.controlPoint_1=ccpAdd(frogSprite.position, ccp(20, 100));
    bc.controlPoint_2=ccpAdd(bubbleSprite.position, ccp(0, 100));
    bc.endPosition=ccpAdd(bubbleSprite.position, ccp(0, kFrogYOffset));
    
    [frogSprite runAction:[CCEaseInOut actionWithAction:[CCBezierTo actionWithDuration:0.5f bezier:bc] rate:2]];
    
    timerIgnoreFrog=0.5f;
    
    [loggingService logEvent:BL_PA_NL_TOUCH_END_JUMP_LINE withAdditionalData:[NSNumber numberWithInt:fabs(lastFrogLoc-lastBubbleLoc)]];
    
    [self hideFrogTarget];
    
    [rambler.UserJumps addObject:[NSValue valueWithCGPoint:ccp((lastFrogLoc-initStartLoc)*rambler.CurrentSegmentValue, lastBubbleValue - (lastFrogLoc * rambler.CurrentSegmentValue))]];
    lastFrogLoc=lastBubbleLoc;
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_line_general_jump_(whoosh).wav")];
}

-(void)slideFrog
{
    CGPoint fp=ccp(rambler.TouchXOffset + cx + rambler.DefaultSegmentSize * (lastFrogLoc-initStartLoc), cy+kFrogYOffset);
    [frogSprite runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.25f position:fp] rate:2.0f]];
    timerIgnoreFrog=0.25;
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
    
    float actualPushDir=bubblePushDir;
    
    //if the bubble is outside of a screen edge/boundary, set the push dir to correct it
//    float absoffset=fabsf(bubbleSprite.position.x)-512.0f;
//    if(bubbleSprite.position.x<512.0f) absoffset=512-bubbleSprite.position.x;
//    
//    if(absoffset>kBubbleScrollBoundary && bubblePushDir==0)
//    {
//        if(bubbleSprite.position.x>512)actualPushDir=-1;
//        else actualPushDir=1;
//    }

//    if(slideLineBy!=0 && bubblePushDir==0)
//    {
//        if(slideLineBy>0)actualPushDir=-1;
//        else actualPushDir=1;
//    }

    float moveRamblerBy=actualPushDir * kBubblePushSpeed * delta;
//    slideLineBy+=moveRamblerBy;
    
    rambler.TouchXOffset+=moveRamblerBy;
    rambler.HeldMoveOffsetX+=moveRamblerBy;
    stitchOffsetX+=actualPushDir * kBubblePushSpeed * delta;
    
//    if(bubblePushDir==0 && actualPushDir!=0)
//    {
//        bubbleSprite.position=ccpAdd(bubbleSprite.position, ccp(actualPushDir * kBubblePushSpeed * delta, 0));
//    }
    
    //update frog position
    if(timerIgnoreFrog>0.0f)timerIgnoreFrog-=delta;
    //else frogSprite.position=ccp(rambler.TouchXOffset + cx + (lastFrogLoc +initStartVal) * rambler.DefaultSegmentSize, cy+kFrogYOffset);
    else frogSprite.position=ccp(rambler.TouchXOffset + cx + rambler.DefaultSegmentSize * (lastFrogLoc-initStartLoc), cy+kFrogYOffset);
    
    
    timeSinceInteractionOrShake+=delta;
    if(timeSinceInteractionOrShake>kTimeToBubbleShake)
    { 
        if(!usedBubble)
        {
            [self animShakeBubble];            
        }
        // are we in the right place, but haven't pressed eval?
        if(evalTarget==lastBubbleLoc && evalMode==kProblemEvalOnCommit)
        {
            [toolHost shakeCommitButton];
        }
        timeSinceInteractionOrShake=0;
    }
    if(holdingBubble)
    {
        timeSinceInteractionOrShake=0;
        
        float offsetFromCX=lasttouch.x-cx-holdingBubbleOffset;
        if(fabsf(offsetFromCX)>kBubbleScrollBoundary)
        {
            if(offsetFromCX>0 && bubbleAtBounds<=0)bubblePushDir=-1;
            if(offsetFromCX<0 && bubbleAtBounds>=0)bubblePushDir=1;
            
            logBubbleDidMoveLine=YES;
            logBubbleDidMove=YES;
        }
        else {
        
            float moveY=0;
            
//            if(jumpMode)
//            {
//                // ===== stitching stuff ===============================================
//                //get ypos --
//                float threshold=100.0f;
//                float diffY=lasttouch.y - cy;
//                if(diffY>0)
//                {
//                    float dampY = diffY<threshold ? diffY / threshold : 1.0f;
//                    dampY*=dampY * dampY;
//                    moveY = diffY * dampY;
//                }
//                
//                if(diffY>=threshold)
//                {
//                    //user is dragging up or past threshold, draw a stitch line
//                    drawStitchLine=YES;
//                    drawStitchCurve=NO;
//                    stitchEndPos=lasttouch;
//                    
//                    if(!hasSetJumpStartValue)
//                    {
//                        hasSetJumpStartValue=YES;
//                        jumpStartValue=logLastBubblePos;
//                    }
//                }
//                else
//                {
//                    // user is below threshold, if they were previously above it, draw a curve
//                    if(drawStitchLine)
//                    {
//                        drawStitchLine=NO;
//                        drawStitchCurve=YES;
//                        stitchApexPos=lasttouch;
//                    }
//                    // otherwise update the end pos -- used to track the end point of the curve, if being drawn
//                    else
//                    {
//                        stitchEndPos=lasttouch;
//                    }
//                }
//                
//                // =====================================================================
//            }
        
            //CGPoint newloc=ccp(location.x - holdingBubbleOffset, bubbleSprite.position.y);
            CGPoint newloc=ccp(lasttouch.x - holdingBubbleOffset, cy + moveY);
            
            float xdiff=newloc.x-bubbleSprite.position.x;
            
            if((bubbleAtBounds>0 && xdiff<0) || (bubbleAtBounds<0 && xdiff>0) || bubbleAtBounds==0)
            {
                [bubbleSprite setPosition:newloc];
                logBubbleDidMove=YES;
                bubbleAtBounds=0;
            }
            
            bubblePushDir=0;
        }
        
        
        float distFromCentre=-rambler.TouchXOffset + (bubbleSprite.position.x - cx);
        float stepsFromCentre=distFromCentre / rambler.DefaultSegmentSize;
        
        int roundedStepsFromCentre=(int)(stepsFromCentre + 0.5f);
        if(stepsFromCentre<0) roundedStepsFromCentre=(int)(stepsFromCentre - 0.5f);
        
        //NSLog(@"bubble pos %d", roundedStepsFromCentre);
        
        int startOffset=initStartVal / initSegmentVal;
        
        
        //lastBubbleLoc = roundedStepsFromCentre+startOffset;
        lastBubbleLoc=(roundedStepsFromCentre+startOffset);
        lastBubbleValue=lastBubbleLoc*initSegmentVal;
        
        int adjustedStepsFromCentre=roundedStepsFromCentre * rambler.CurrentSegmentValue;
        
        BOOL stopLine=NO;
        
        if (lastBubbleValue>[rambler.MaxValue intValue])
        {
            adjustedStepsFromCentre = ([rambler.MaxValue intValue] / initSegmentVal) - startOffset;
            //adjustedStepsFromCentre = [rambler.MaxValue intValue] - (startOffset * initSegmentVal);
            stopLine=YES;
            bubbleAtBounds=1;
            bubblePushDir=0;
        }
        
        if(lastBubbleValue<[rambler.MinValue intValue])
        {
            adjustedStepsFromCentre = ([rambler.MinValue intValue] / initSegmentVal) - startOffset;
            //adjustedStepsFromCentre = [rambler.MinValue intValue] - (startOffset * initSegmentVal);
            stopLine=YES;
            bubbleAtBounds=-1;
            bubblePushDir=0;
        }
        
        if(stopLine)
        {
            //diff (moveby)
            float diffx=((adjustedStepsFromCentre) * rambler.DefaultSegmentSize)-distFromCentre;
            [bubbleSprite runAction:[CCMoveBy actionWithDuration:0.2f position:ccp(diffx, 0)]];
        }
        
        //check if they moved through a current stitch -- if so delete that stich
        NSValue *remJump=nil;
        CGPoint jump;
        for(NSValue *jumpval in rambler.UserJumps)
        {
            jump=[jumpval CGPointValue];
            if(lastBubbleValue>=(jump.x + initStartVal) && lastBubbleValue<(jump.x + initStartVal + jump.y))
            {
                //positive jump match
                remJump=jumpval;
            }
            if(lastBubbleValue<=(jump.x + initStartVal) && lastBubbleValue >(jump.x+initStartVal + jump.y))
            {
                //negative jump match
                remJump=jumpval;
            }
        }
        //put frog back to start of that section if required
        if(frogMode && remJump)
        {
            lastFrogLoc=(int)(jump.x / rambler.CurrentSegmentValue)+initStartLoc;
            [self slideFrog];
        }
        
        if(remJump)[rambler.UserJumps removeObject:remJump];
        remJump=nil;
        
        //do not update rambler -- causes render to carry on scrolling, and eval is at end anyway
        //rambler.BubblePos=lastBubbleLoc;
        
        lastBubbleLoc = adjustedStepsFromCentre;
        lastBubbleValue = lastBubbleLoc * initSegmentVal;
    }

    
    // original touch/push do update
    
    if(touchResetX>0)
    {
        float movex=1+((touchResetX-1) / 15.0f);
        rambler.TouchXOffset += movex * touchResetDir;
        touchResetX -=movex;
    }
    
    //NSLog(@"rambler.TouchXOffset %f", rambler.TouchXOffset);
}

-(void)draw
{
    CGPoint actualStitchStart=ccp(stitchStartPos.x + stitchOffsetX, stitchStartPos.y);
    
    if(drawStitchLine)
    {
        ccDrawLine(actualStitchStart, stitchEndPos);
    }
    
    if(drawStitchCurve)
    {
        ccDrawQuadBezier(actualStitchStart, stitchApexPos, stitchEndPos, 40);
    }
    
    [rambler drawFromMid:ccp(cx, cy) andYOffset:kFrogYOffset];
}

-(void)populateGW
{
    rambler=[DWRamblerGameObject alloc];
    [gw populateAndAddGameObject:rambler withTemplateName:@"TnLineRambler"];
    
    rambler.Value=initStartVal;
    rambler.StartValue=rambler.Value;
    rambler.CurrentSegmentValue=initSegmentVal;
    rambler.MinValue=initMinVal;
    rambler.MaxValue=initMaxVal;
    rambler.BubblePos=initStartVal;
    
    initStartLoc=initStartVal / initSegmentVal;
    lastBubbleLoc=initStartLoc;
    logLastBubblePos=initStartLoc;

    
    enableAudioCounting=YES;
    
    NSNumber *hideAllNumbers=[problemDef objectForKey:@"HIDE_ALL_NUMBERS"];
    if(hideAllNumbers) if([hideAllNumbers boolValue]) rambler.HideAllNumbers=YES;
    
    NSNumber *hideStartNumber=[problemDef objectForKey:@"HIDE_START_NUMBER"];
    if(hideStartNumber) if([hideStartNumber boolValue]) rambler.HideStartNumber=YES;
    
    NSNumber *hideEndNumber=[problemDef objectForKey:@"HIDE_END_NUMBER"];
    if(hideEndNumber) if([hideEndNumber boolValue]) rambler.HideEndNumber=YES;
    
    NSArray *showNumbersAtInterval=[problemDef objectForKey:@"SHOW_NUMBERS_AT_INTERVALS"];
    if(showNumbersAtInterval) if(showNumbersAtInterval.count>0) rambler.ShowNumbersAtIntervals=showNumbersAtInterval;
    
    NSNumber *hideAllNotches=[problemDef objectForKey:@"HIDE_ALL_NOTCHES"];
    if(hideAllNotches) if([hideAllNotches boolValue]) rambler.HideAllNotches=YES;
    
    NSNumber *hideStartNotch=[problemDef objectForKey:@"HIDE_START_NOTCH"];
    if(hideStartNotch) if([hideStartNotch boolValue]) rambler.HideStartNotch=YES;
    
    NSNumber *hideEndNotch=[problemDef objectForKey:@"HIDE_END_NOTCH"];
    if(hideEndNotch) if([hideEndNotch boolValue]) rambler.HideEndNotch=YES;
    
    NSArray *showNotchesAtIntervals=[problemDef objectForKey:@"SHOW_NOTCHES_AT_INTERVALS"];
    if(showNotchesAtIntervals) if(showNotchesAtIntervals.count>0) rambler.ShowNotchesAtIntervals=showNotchesAtIntervals;
    
    if([problemDef objectForKey:@"SHOW_JUMP_LABELS"])
        rambler.showJumpLabels=[[problemDef objectForKey:@"SHOW_JUMP_LABELS"]boolValue];
    else
        rambler.showJumpLabels=NO;
    
    //jump sections
    rambler.UserJumps=[[[NSMutableArray alloc]init] autorelease];
    
    //positioning
    rambler.DefaultSegmentSize=115;
    rambler.Pos=ccp(cx,cy);
    
    NSNumber *dno=[problemDef objectForKey:@"DISPLAY_NUMBER_OFFSET"];
    if(dno) rambler.DisplayNumberOffset=[dno intValue];
    
    NSNumber *dmult=[problemDef objectForKey:@"DISPLAY_NUMBER_MULTIPLIER"];
    if(dmult) rambler.DisplayNumberMultiplier=[dmult floatValue];
    else rambler.DisplayNumberMultiplier=1;
    
    NSNumber *ddp=[problemDef objectForKey:@"DISPLAY_NUMBER_DP"];
    if(ddp)rambler.DisplayNumberDP=[ddp integerValue];
    else rambler.DisplayNumberDP=1;
    
    NSNumber *ddenom=[problemDef objectForKey:@"DISPLAY_DENOMINATOR"];
    if(ddenom) rambler.DisplayDenominator=[ddenom integerValue];
    else rambler.DisplayDenominator=0;
    
    selector=[DWSelectorGameObject alloc];
    [gw populateAndAddGameObject:selector withTemplateName:@"TnLineSelector"];
    
    //point the selector at the rambler
    selector.WatchRambler=rambler;
    selector.pos=ccp(cx,cy + 75.0f);
    
    //frog
    if(frogMode)
    {
        [self setupFrog];
        lastFrogLoc=initStartLoc;
    }
    
    if(markerValuePositions)
    {
        rambler.MarkerValuePositions=markerValuePositions;
    }
    
    //setup rambler drawing -- needs explicit seek and draw prep
    [rambler readyRender];
}

-(void)readPlist:(NSDictionary*)pdef
{
    //set eval and reject modes
    NSNumber *eMode=[pdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    
    NSNumber *rMode=[pdef objectForKey:REJECT_MODE];
    if (rMode) rejectMode=[rMode intValue];
    
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    
    evalTarget=[[pdef objectForKey:@"EVAL_TARGET"] intValue];
    
    evalType=[pdef objectForKey:EVAL_TYPE];
    if(!evalType)evalType=@"TARGET";
    
    [evalType retain];
    
    NSNumber *abseval=[pdef objectForKey:@"EVAL_TARGET_AS_ABSOLUTE_VALUE"];
    if(abseval) evalAbsTarget=[abseval boolValue];
    
    if([pdef objectForKey:@"EVAL_INTERVAL"])
    {
        evalInterval=[[pdef objectForKey:@"EVAL_INTERVAL"] integerValue];
    }
    evalJumpSequence=[pdef objectForKey:@"EVAL_JUMP_SEQUENCE"];
    
    initStartVal=[[pdef objectForKey:START_VALUE] intValue];
    
    initMinVal=(NSNumber*)[pdef objectForKey:MIN_VALUE];
    initMaxVal=(NSNumber*)[pdef objectForKey:MAX_VALUE];
    
    if([pdef objectForKey:SEGMENT_VALUE])
    {
        initSegmentVal=[[pdef objectForKey:SEGMENT_VALUE] intValue];
    }
    else {
        initSegmentVal=1;
    }
    
    
    if([initMaxVal intValue] % initSegmentVal)
    {
        @throw [NSException exceptionWithName:@"nline load pdef error" reason:@"cannot specify a MAX_VALUE that's not an integer multiple of SEGMENT_VALUE " userInfo:nil];
    }
    
    if([initMinVal intValue] % initSegmentVal)
    {
        @throw [NSException exceptionWithName:@"nline load pdef error" reason:@"cannot specify a MIN_VALUE that's not an integer multiple of SEGMENT_VALUE" userInfo:nil];
    }
    
    //force default on segment value if not specified
    if(initSegmentVal==0)initSegmentVal=1;
    
    if([pdef objectForKey:@"JUMP_MODE"])
    {
        //jump mode is now interpretted as frog mode
        //jumpMode=[[pdef objectForKey:@"JUMP_MODE"] boolValue];
        
        //check also for a jumping evaluation
        if([evalType isEqualToString:@"REPEATED_ADDITION"] || [evalType isEqualToString:@"JUMP_SEQUENCE"])
        {
            frogMode=[[pdef objectForKey:@"JUMP_MODE"] boolValue];
        }
    }
    
    if([pdef objectForKey:@"MARKER_POSITIONS"])
    {
        markerValuePositions=[pdef objectForKey:@"MARKER_POSITIONS"];
    }
    
    NSNumber *countFromInitVal=[pdef objectForKey:@"COUNT_OUT_LOUD_FROM_START_VALUE"];
    if(countFromInitVal) countOutLoudFromInitStartVal=[countFromInitVal boolValue];
    
    if([evalType isEqualToString:@"TARGET"] && evalTarget<0)
        [usersService notifyStartingFeatureKey:@"NLINE_TARGET_LESS_0"];
    if([evalType isEqualToString:@"TARGET"] && evalTarget>=0)
        [usersService notifyStartingFeatureKey:@"NLINE_TARGET_GREATER_EQUAL_0"];
    
    if(frogMode)
        [usersService notifyStartingFeatureKey:@"NLINE_JUMP_MODE"];
    if(frogMode && ([evalType isEqualToString:@"REPEATED_ADDITION"] || [evalType isEqualToString:@"JUMP_SEQUENCE"]))
        [usersService notifyStartingFeatureKey:@"NLINE_MULTI_TARGET_JUMP"];
}

-(void)problemStateChanged
{
    if(evalMode==kProblemEvalAuto)
    {
        [self evalProblem];
        
        if(!self.ProblemComplete) 
        {
            toolHost.flagResetProblem=YES;
        }
        else {
            [toolHost doWinning];
        }
    }
}

-(void)showComplete
{
    //[problemCompleteLabel setVisible:YES];
    [toolHost showProblemCompleteMessage];
}

-(void)evalProblem
{
    BOOL Complete=NO;
    
    if([evalType isEqualToString:@"TARGET"] && evalAbsTarget)
    {
        Complete=(abs(evalTarget)==abs(lastBubbleValue));
    }
    else if([evalType isEqualToString:@"TARGET"])
    {
        Complete = (evalTarget==lastBubbleValue);
    }
    else if([evalType isEqualToString:@"REPEATED_ADDITION"])
    {
        //evaltarget met, and all jumps of same interval
        if(evalTarget==lastBubbleValue)
        {
            
            //look at right count of invervals from initstartval
            int range=lastBubbleValue - initStartVal;
            int correctSteps=range / evalInterval;
            if (correctSteps != [rambler.UserJumps count]) {
                Complete=NO;
            }
            else
            {
                Complete=YES;
            
                for(NSValue *jumpval in rambler.UserJumps)
                {
                    CGPoint jump=[jumpval CGPointValue];
                    if(jump.y!=evalInterval)
                    {
                        //this jump isn't the right interval, bail complete
                        Complete=NO;
                        break;
                    }
                }
            }
        }
    }
    else if([evalType isEqualToString:@"JUMP_SEQUENCE"])
    {
        //check sequence of jump sizes and eval target
        if(evalTarget==lastBubbleValue)
        {
            if(rambler.UserJumps.count < evalJumpSequence.count)
            {
                Complete=NO;
            }
            else {
                    
                Complete=YES;
                for(int i=0; i<[evalJumpSequence count]; i++)
                {
                    CGPoint jump=[[rambler.UserJumps objectAtIndex:i] CGPointValue];
                    int sequenceJumpSize=[[evalJumpSequence objectAtIndex:i] integerValue];
                    if(jump.y!=sequenceJumpSize)
                    {
                        //this jump isn't the right interval, bail complete
                        Complete=NO;
                        break;
                    }
                }
            }
        }
    }

    
    if(Complete)
    {
        self.ProblemComplete=YES;
        [self showComplete];
    }
    else
    {
        [toolHost showProblemIncompleteMessage];
        [toolHost resetProblem];
    }
    
}

-(void)resetBubble
{
    //set last bubble loc
    lastBubbleLoc=rambler.StartValue;
    
    //set bubble pos on ramber to start
    rambler.BubblePos=lastBubbleLoc;
    
    //reset flags
    bubbleAtBounds=0;
    
    //animate bubble to start equiv pos
    float distFromCentre= bubbleSprite.position.x - cx;
    
    CCMoveBy *mt=[CCMoveBy actionWithDuration:0.5f position:ccp(-distFromCentre, 0)];
    
    CCEaseInOut *easemove=[CCEaseInOut actionWithAction:mt rate:2.0f];
    
    CCScaleTo *s1=[CCScaleTo actionWithDuration:0.25f scaleX:1.0f scaleY:0.9f];
    CCScaleTo *s2=[CCScaleTo actionWithDuration:0.25f scaleX:1.0f scaleY:1.0f];
    CCSequence *seq=[CCSequence actions:s1, s2, nil];

    CCEaseInOut *easescale=[CCEaseInOut actionWithAction:seq rate:2.0f];
    
    CCTintTo *t1=[CCTintTo actionWithDuration:0.05f red:255 green:50 blue:50];
    CCDelayTime *d=[CCDelayTime actionWithDuration:0.4f];
    CCTintTo *t2=[CCTintTo actionWithDuration:0.05f red:255 green:255 blue:255];
    
    CCSequence *seqtint=[CCSequence actions:t1, d, t2, nil];
    CCEaseInOut *easetint=[CCEaseInOut actionWithAction:seqtint rate:2.0f];
    
    [bubbleSprite runAction:easemove];
    [bubbleSprite runAction:easescale];
    [bubbleSprite runAction:easetint];
    
    //animate line itself (through rambler) to start at centre
    if (rambler.TouchXOffset!=0) {
        if(rambler.TouchXOffset<0)touchResetDir=1;
        else touchResetDir=-1;
        
         touchResetX=fabsf(rambler.TouchXOffset);
    }
}

-(void)animPickupBubble
{
    [bubbleSprite stopAllActions];
    
//    [bubbleSprite setTexture:bubbleTexSelected];
//    [bubbleSprite setTextureRect:CGRectMake(0, 0, bubbleTexSelected.contentSize.width, bubbleTexSelected.contentSize.height)];
    
    [bubbleSprite setScale:0.87f];
    [bubbleSprite runAction:[InteractionFeedback enlargeTo1xAction]];
    
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_line_general_pick_bubble_up.wav")];
}

-(void)animReleaseBubble
{
//    [bubbleSprite setTexture:bubbleTexRegular];
//    [bubbleSprite setTextureRect:CGRectMake(0, 0, bubbleTexRegular.contentSize.width, bubbleTexRegular.contentSize.height)];
    
    [bubbleSprite setScale:1.15f];
    [bubbleSprite runAction:[InteractionFeedback reduceTo1xAction]];    
    
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_line_general_drop_button.wav")];
}

-(void)animShakeBubble
{
    [bubbleSprite runAction:[InteractionFeedback shakeAction]];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_line_interaction_feedback_bubble_shaking.wav")];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lasttouch=location;
    
    if(frogMode)
    {
        if(frogTargetSprite.opacity>0 && CGRectContainsPoint(frogTargetSprite.boundingBox, location) && timerIgnoreFrog<=0.0f)
        {
            [self hopFrog];
        }
    }


    if([BLMath DistanceBetween:location and:bubbleSprite.position]<kBubbleProx)
    {
        if(!usedBubble)usedBubble=YES;
        holdingBubbleOffset=location.x - bubbleSprite.position.x;
        holdingBubble=YES;
        
        [self animPickupBubble];
        
        [loggingService logEvent:BL_PA_NL_TOUCH_BEGIN_PICKUP_BUBBLE withAdditionalData:[NSNumber numberWithInt:logLastBubblePos]];
        
        //retain current pos to incr/decr log
        logLastBubblePos=lastBubbleLoc;
        [loggingService logEvent:BL_PA_NL_TOUCH_BEGIN_PICKUP_BUBBLE withAdditionalData:[NSNumber numberWithInt:logLastBubblePos]];
        
        timeSinceInteractionOrShake=0;
        
        if(jumpMode)
        {
            //retain start pos for stitch draw
            stitchStartPos=bubbleSprite.position;
        }
        
        //hide target
        [self hideFrogTarget];
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lasttouch=location;
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    bubblePushDir=0;
    
    if(holdingBubbleOffset)
    {
        timeSinceInteractionOrShake=0;
        
        //[gw handleMessage:kDWnlineReleaseRamblerAtOffset andPayload:nil withLogLevel:0];
        holdingBubbleOffset=0;
        
        float distFromCentre=-rambler.TouchXOffset + (bubbleSprite.position.x - cx);
        float stepsFromCentre=distFromCentre / rambler.DefaultSegmentSize;
        
        int roundedStepsFromCentre=(int)(stepsFromCentre + 0.5f);
        if(stepsFromCentre<0) roundedStepsFromCentre=(int)(stepsFromCentre - 0.5f);
        
        int startOffset=initStartVal / initSegmentVal;
        lastBubbleLoc = (roundedStepsFromCentre+startOffset);
        lastBubbleValue=lastBubbleLoc*initSegmentVal;
        
        //int adjustedStepsFromCentre=roundedStepsFromCentre * rambler.CurrentSegmentValue;
        int adjustedStepsFromCentre=roundedStepsFromCentre;
        
        if (lastBubbleValue>[rambler.MaxValue intValue]) adjustedStepsFromCentre = ([rambler.MaxValue intValue] / initSegmentVal)  - startOffset;
        
        if(lastBubbleValue<[rambler.MinValue intValue]) adjustedStepsFromCentre = ([rambler.MinValue intValue] / initSegmentVal) - startOffset;
        
        //mod this to closest valid segment value
        //adjustedStepsFromCentre=rambler.CurrentSegmentValue * ((int)(adjustedStepsFromCentre / rambler.CurrentSegmentValue));

        float diffy=0.0f;
        
        if(jumpMode)  // === stitching stuff ======================================
        {
            diffy=cy - bubbleSprite.position.y;
            drawStitchLine=NO;
            drawStitchCurve=NO;
            
            if(hasSetJumpStartValue && lastBubbleValue!=jumpStartValue)
            {
                //add a segment
                [rambler.UserJumps addObject:[NSValue valueWithCGPoint:ccp(jumpStartValue, lastBubbleValue - jumpStartValue)]];
            }
            
        }  // =====================================================================
        
        
        //update the rambler value & last bubble location, using any offset
        lastBubbleLoc=adjustedStepsFromCentre + startOffset;
        lastBubbleValue=lastBubbleLoc*initSegmentVal;
        
        rambler.BubblePos=lastBubbleValue;
        
        
        [self resetTouchParams];
        
        //diff (moveby)
        float diffx=(adjustedStepsFromCentre * rambler.DefaultSegmentSize)-distFromCentre;
        
        //decrement the adjusted steps if this would take us off the screen
        if(bubbleSprite.position.x + diffx - 512 > kBubbleScrollBoundary)
        {
            adjustedStepsFromCentre--;
            lastBubbleLoc=adjustedStepsFromCentre + startOffset;
            lastBubbleValue=lastBubbleLoc*initSegmentVal;
            
            rambler.BubblePos=lastBubbleValue;
            diffx=(adjustedStepsFromCentre * rambler.DefaultSegmentSize)-distFromCentre;
        }
        
        //increment if offscreen left
        if(bubbleSprite.position.x + diffx < (512 - kBubbleScrollBoundary))
        {
            adjustedStepsFromCentre++;
            lastBubbleLoc=adjustedStepsFromCentre + startOffset;
            lastBubbleValue=lastBubbleLoc*initSegmentVal;
            
            rambler.BubblePos=lastBubbleValue;
            diffx=(adjustedStepsFromCentre * rambler.DefaultSegmentSize)-distFromCentre;
        }
        
        [bubbleSprite runAction:[CCMoveBy actionWithDuration:0.2f position:ccp(diffx, diffy)]];
        
        //play some audio -- only for non decimal numbers at the moment
        if(enableAudioCounting && lastBubbleLoc!=logLastBubblePos)
        {
            int readNumber=lastBubbleValue+rambler.DisplayNumberOffset;
//            if(countOutLoudFromInitStartVal)
            readNumber=lastBubbleLoc;
            
            if(initSegmentVal!=1)
                readNumber*=initSegmentVal;
            
            NSString *writeText=[NSString stringWithFormat:@"%d", readNumber];
            float multDisplayNum=readNumber * rambler.DisplayNumberMultiplier;
            if(rambler.DisplayNumberDP>0 && rambler.DisplayNumberMultiplier!=1)
            {
                NSString *fmt=[NSString stringWithFormat:@"%%.%df", rambler.DisplayNumberDP];
                writeText=[NSString stringWithFormat:fmt, multDisplayNum];
            }
            
            if(readNumber>0 && countOutLoudFromInitStartVal)
                writeText=[NSString stringWithFormat:@"plus %@", writeText];
            
            if(readNumber<0)
                writeText=[NSString stringWithFormat:@"negative %g", fabsf([writeText floatValue])];
            
            if(readNumber>0&&rambler.DisplayDenominator!=0){
                NSLog(@"do stuff");
                writeText=[NSString stringWithFormat:@"%d", readNumber];
                
                NSNumber *denominator=[NSNumber numberWithInt:rambler.DisplayDenominator];
                NSString *denom=@"";
                
                if([denominator isEqualToNumber:[NSNumber numberWithInt:2]])
                    denom=@"halve";
                else if([denominator intValue]==3)
                    denom=@"third";
                else if([denominator intValue]==4)
                    denom=@"quarter";
                else if([denominator intValue]==5)
                    denom=@"fifth";
                else if([denominator intValue]==6)
                    denom=@"sixth";
                else if([denominator intValue]==7)
                    denom=@"seventh";
                else if([denominator intValue]==8)
                    denom=@"eighth";
                else if([denominator intValue]==9)
                    denom=@"ninth";
                else if([denominator intValue]==10)
                    denom=@"tenth";
                else if([denominator intValue]==11)
                    denom=@"eleventh";
                else if([denominator intValue]==12)
                    denom=@"twelfth";
                else if([denominator intValue]==13)
                    denom=@"thirteenth";
                else if([denominator intValue]>13 && [denominator intValue]<=19)
                    denom=[NSString stringWithFormat:@"%d teenth", [denominator intValue]-10];
                else if([denominator intValue]==20)
                    denom=@"twentieth";
                
                if([denominator intValue]>20){
                    denom=[NSString stringWithFormat:@" over %d", [denominator intValue]];
                }
                
                if(readNumber>1)
                    denom=[NSString stringWithFormat:@"%@s",denom];
                
                if(readNumber==rambler.DisplayDenominator){ writeText=@"1"; }
                else
                {
                    writeText=[writeText stringByAppendingFormat:@" %@", denom];
                }
            }
            
            NSLog(@"speakstring is %@", writeText);
            
            AppController *ac=(AppController*)[UIApplication sharedApplication].delegate;
            [ac speakString:writeText];
        }
        
        //release the bubble
        [self animReleaseBubble];
        
        
        //determine whether or not to show the frog target
        if(lastBubbleLoc!=lastFrogLoc)
        {
            NSLog(@"lastBubbleLoc = %d, logLastBubblePos = %d, lastFrogLoc = %d", lastBubbleLoc, logLastBubblePos, lastFrogLoc);
            
            if(lastBubbleLoc>logLastBubblePos && lastBubbleLoc>lastFrogLoc)
                [frogTargetSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/numberline/NL_MoveButton.png")]];
            else if(lastBubbleLoc<logLastBubblePos && lastBubbleLoc<lastFrogLoc)
                [frogTargetSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/numberline/NL_MoveButtonBack.png")]];
            
            [self showFrogTarget];
        }
        else
        {
            [self hideFrogTarget];
        }
        
        //do some logging
        [loggingService logEvent:BL_PA_NL_TOUCH_END_RELEASE_BUBBLE withAdditionalData:[NSNumber numberWithInt:lastBubbleLoc]];
        
        if(lastBubbleLoc>logLastBubblePos)
        {
            [loggingService logEvent:BL_PA_NL_TOUCH_END_INCREASE_SELECTION withAdditionalData:nil];
        }
        else if(lastBubbleLoc<logLastBubblePos)
        {
            [loggingService logEvent:BL_PA_NL_TOUCH_END_DECREASE_SELECTION withAdditionalData:nil];
        }
        
        //did we move the bubble, the line
        if(logBubbleDidMove)
        {
            float moveDistance=fabsf(lastBubbleLoc-logLastBubblePos);
            [loggingService logEvent:BL_PA_NL_TOUCH_MOVE_MOVE_BUBBLE withAdditionalData:[NSNumber numberWithFloat:moveDistance]];
        }
        if(logBubbleDidMoveLine)
        {
            [loggingService logEvent:BL_PA_NL_TOUCH_MOVE_MOVE_LINE withAdditionalData:nil];
        }
        
        logBubbleDidMove=NO;
        logBubbleDidMoveLine=NO;
        
    }
    
//    NSLog(@"lastBubbleLoc: %d lastFrogLoc: %d", lastBubbleLoc, lastFrogLoc);
    

}

-(void)resetTouchParams
{
    holdingBubbleOffset=0;
    holdingBubble=NO;
    touching=NO;
    inRamblerArea=NO;
    hasSetJumpStartValue=NO;
    jumpStartValue=0;
    stitchOffsetX=0;
    rambler.HeldMoveOffsetX=0;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self ccTouchesEnded:touches withEvent:event];
}

#pragma mark - meta question
-(float)metaQuestionTitleYLocation
{
    return kLabelTitleYOffsetHalfProp*cy;
}

-(float)metaQuestionAnswersYLocation
{
    return 150;
}

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    
}

-(void)dealloc
{
    [bubbleTexRegular release];
    [bubbleTexSelected release];
    [rambler release];
    [selector release];
    [evalType release];
    
    [gw release];

    
    [super dealloc];
}

@end
