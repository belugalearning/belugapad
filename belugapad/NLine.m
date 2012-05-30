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
#import "UsersService.h"
#import "AppDelegate.h"

@interface NLine()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

static float kBubbleProx=100.0f;
static float kBubbleScrollBoundary=350;
static float kBubblePushSpeed=400.0f;

static float kTimeToBubbleShake=7.0f;

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
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        
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
    bubbleTexRegular=[[CCTexture2D alloc] initWithCGImage:[UIImage imageWithContentsOfFile:BUNDLE_FULL_PATH(@"/images/numberline/bubble.png")].CGImage resolutionType:kCCResolutioniPad];
    bubbleTexSelected=[[CCTexture2D alloc] initWithCGImage:[UIImage imageWithContentsOfFile:BUNDLE_FULL_PATH(@"/images/numberline/bubble_selected.png")].CGImage resolutionType:kCCResolutioniPad];
    
    bubbleSprite=[CCSprite spriteWithTexture:bubbleTexRegular];
    [bubbleSprite setPosition:ccp(cx, cy)];
    [self.ForeLayer addChild:bubbleSprite];
    
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
    
//    float distFromCentre=-rambler.TouchXOffset + ((bubbleSprite.position.x + holdingBubbleOffset) - cx);
//    if (distFromCentre <= ([rambler.MaxValue floatValue] * rambler.DefaultSegmentSize)
//        && distFromCentre >= ([rambler.MinValue floatValue] * rambler.DefaultSegmentSize)) {
        
        rambler.TouchXOffset+=bubblePushDir * kBubblePushSpeed * delta;
//    }    
    
    
    timeSinceInteractionOrShake+=delta;
    if(timeSinceInteractionOrShake>kTimeToBubbleShake)
    {
        [self animShakeBubble];
        timeSinceInteractionOrShake=0;
    }
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

    //positioning
    rambler.DefaultSegmentSize=115;
    rambler.Pos=ccp(cx,cy);
    
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
    
    //stiching -- should we render stitches?
    if ([problemDef objectForKey:@"RENDER_STITCHES"]) {
        rambler.RenderStitches=[[problemDef objectForKey:@"RENDER_STITCHES"] boolValue];
    }
    
    //sould the line auto stitch -- non zero values will cause the values
    if([problemDef objectForKey:@"AUTO_STITCH_INCREMENT"])
    {
        rambler.AutoStitchIncrement=[[problemDef objectForKey:@"AUTO_STITCH_INCREMENT"] intValue];
    }
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
    
    initStartVal=[[pdef objectForKey:START_VALUE] intValue];
    
    initMinVal=(NSNumber*)[pdef objectForKey:MIN_VALUE];
    initMaxVal=(NSNumber*)[pdef objectForKey:MAX_VALUE];
    
    initSegmentVal=[[pdef objectForKey:SEGMENT_VALUE] intValue];
    
    //this stuff still works -- direct parse is okay, but it's redundant as the toolhost will create dynamic content anyway
//    evalTarget=[toolHost.DynProblemParser parseIntFromValueWithKey:@"EVAL_TARGET" inDef:pdef];
//    
//    initStartVal=[toolHost.DynProblemParser parseIntFromValueWithKey:START_VALUE inDef:pdef];
//    initMinVal=[NSNumber numberWithInt:[toolHost.DynProblemParser parseIntFromValueWithKey:MIN_VALUE inDef:pdef]];
//    initMaxVal=[NSNumber numberWithInt:[toolHost.DynProblemParser parseIntFromValueWithKey:MAX_VALUE inDef:pdef]];
//    initSegmentVal=[toolHost.DynProblemParser parseIntFromValueWithKey:SEGMENT_VALUE inDef:pdef];
    
    //force default on segment value if not specified
    if(initSegmentVal==0)initSegmentVal=1;
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
    return (evalTarget==lastBubbleLoc);
    
//    //not possible to eval without expression
//    if(!toolHost.PpExpr) return NO;
//    
//    //copy, sub eval and compare the expression
//    BAExpressionTree *evalTree=[toolHost.PpExpr copy];
//    
//    //set subs & execute
//    evalTree.VariableSubstitutions=gw.Blackboard.ProblemVariableSubstitutions;
//    [evalTree substitueVariablesForIntegersOnNode:evalTree.root];
//
//    NSLog(@"problem expression: %@", [toolHost.PpExpr expressionString]);
//    NSLog(@"substituted expression: %@", [evalTree expressionString]);
//    
//    //evaluate
//    [evalTree evaluateTree];
//    
//    NSLog(@"evaluated expression: %@", [evalTree expressionString]);
//    
//    //query comparison for equality (currently has to assume as a top level eq using query layer
//    BATQuery *q=[[BATQuery alloc] initWithExpr:evalTree.root andTree:evalTree];
//    BOOL result=[q assumeAndEvalEqualityAtRoot];
//    
//    return result;
}

-(void)animPickupBubble
{
    [bubbleSprite stopAllActions];
    [bubbleSprite setTexture:bubbleTexSelected];
    [bubbleSprite runAction:[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.15f scale:1.15f] rate:2.0f]];
    
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/nline/pickup.wav")];
}

-(void)animReleaseBubble
{
    [bubbleSprite setTexture:bubbleTexRegular];
    [bubbleSprite runAction:[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.15f scale:1.0f] rate:2.0f]];    
    
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/nline/release.wav")];
}

-(void)animShakeBubble
{
    CCEaseInOut *ml1=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.05f position:ccp(-10, 0)] rate:2.0f];
    CCEaseInOut *mr1=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.1f position:ccp(20, 0)] rate:2.0f];
    CCEaseInOut *ml2=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.05f position:ccp(-10, 0)] rate:2.0f];
    CCSequence *s=[CCSequence actions:ml1, mr1, ml2, nil];
    CCRepeat *r=[CCRepeat actionWithAction:s times:4];
    
    CCEaseInOut *oe=[CCEaseInOut actionWithAction:r rate:2.0f];
    
//    CCMoveBy *left1=[CCMoveBy actionWithDuration:0.05f position:ccp(00, 0)];
//    CCMoveBy *right=[CCMoveBy actionWithDuration:0.1f position:ccp(40, 0)];
//    CCMoveBy *left2=[CCMoveBy actionWithDuration:0.05f position:ccp(0, 0)];
//    CCSequence *seq=[CCSequence actions:left1, right, left2, nil];
    
    [bubbleSprite runAction:oe];
    
    
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
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
//    else if (location.y < kRamblerYMax)
//    {
//        inRamblerArea=YES;
//    }
//    else 
//    {
//        NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
//        [gw handleMessage:kDWhandleTap andPayload:pl withLogLevel:-1];
//    }
    
    else if([BLMath DistanceBetween:location and:bubbleSprite.position]<kBubbleProx)
    {
        holdingBubbleOffset=location.x - bubbleSprite.position.x;
        holdingBubble=YES;
        
        [self animPickupBubble];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        [ac.usersService logProblemAttemptEvent:kProblemAttemptNumberLineTouchBeginPickupBubble withOptionalNote:nil];
        
        //retain current pos to incr/decr log
        logLastBubblePos=lastBubbleLoc;
        
        timeSinceInteractionOrShake=0;
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    if(holdingBubble)
    {            
        timeSinceInteractionOrShake=0;
        
        float offsetFromCX=location.x-cx;
        if(fabsf(offsetFromCX)>kBubbleScrollBoundary)
        {
            if(offsetFromCX>0)bubblePushDir=-1;
            if(offsetFromCX<0)bubblePushDir=1;
            
            logBubbleDidMoveLine=YES;
            logBubbleDidMove=YES;
        }
        else {

//            float distFromCentre=-rambler.TouchXOffset + ((bubbleSprite.position.x + holdingBubbleOffset) - cx);
//            if (distFromCentre <= ([rambler.MaxValue floatValue] * rambler.DefaultSegmentSize)
//                && distFromCentre >= ([rambler.MinValue floatValue] * rambler.DefaultSegmentSize)) {

                [bubbleSprite setPosition:ccp(location.x + holdingBubbleOffset, bubbleSprite.position.y)];
                
//            }
            
            bubblePushDir=0;
            
            logBubbleDidMove=YES;
        }
    }
    
//    if(inRamblerArea)
//    {
//        CGPoint a = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView:touch.view]];
//        CGPoint b = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
//    
//        rambler.TouchXOffset+=b.x-a.x;
//    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    bubblePushDir=0;
    
    if(holdingBubbleOffset)
    {
        timeSinceInteractionOrShake=0;
        
        //[gw handleMessage:kDWnlineReleaseRamblerAtOffset andPayload:nil withLogLevel:0];
        holdingBubbleOffset=NO;
        
        float distFromCentre=-rambler.TouchXOffset + (bubbleSprite.position.x - cx);
        float stepsFromCentre=distFromCentre / rambler.DefaultSegmentSize;
        
        int roundedStepsFromCentre=(int)(stepsFromCentre + 0.5f);
        if(stepsFromCentre<0) roundedStepsFromCentre=(int)(stepsFromCentre - 0.5f);
        
        NSLog(@"bubble pos %d", roundedStepsFromCentre);
        
        
        int startOffset=initStartVal;
        lastBubbleLoc = roundedStepsFromCentre+startOffset;
        int adjustedStepsFromCentre=roundedStepsFromCentre;
        
        if (lastBubbleLoc>[rambler.MaxValue intValue]) adjustedStepsFromCentre = [rambler.MaxValue intValue] - startOffset;
        
        if(lastBubbleLoc<[rambler.MinValue intValue]) adjustedStepsFromCentre = [rambler.MinValue intValue] - startOffset;

        //diff (moveby)
        float diffx=(adjustedStepsFromCentre * rambler.DefaultSegmentSize)-distFromCentre;
        [bubbleSprite runAction:[CCMoveBy actionWithDuration:0.2f position:ccp(diffx, 0)]];
        
        
        //release the bubble
        [self animReleaseBubble];
        
        //do some logging
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        [ac.usersService logProblemAttemptEvent:kProblemAttemptNumberLineTouchEndedReleaseBubble withOptionalNote:nil];
        
        if(lastBubbleLoc>logLastBubblePos)
        {
            [ac.usersService logProblemAttemptEvent:kProblemAttemptNumberLineTouchEndedIncreaseSelection withOptionalNote:nil];
        }
        else if(lastBubbleLoc<logLastBubblePos)
        {
            [ac.usersService logProblemAttemptEvent:kProblemAttemptNumberLineTouchEndedDecreaseSelection withOptionalNote:nil];            
        }
        
        //did we move the bubble, the line
        if(logBubbleDidMove)
        {
            [ac.usersService logProblemAttemptEvent:kProblemAttemptNumberLineTouchMovedMoveBubble withOptionalNote:nil];
        }
        if(logBubbleDidMoveLine)
        {
            [ac.usersService logProblemAttemptEvent:kProblemAttemptNumberLineTouchMovedMoveBubble withOptionalNote:nil];            
        }
        
        logBubbleDidMove=NO;
        logBubbleDidMoveLine=NO;
        
//        int roundedStepsFromActualCentre=roundedStepsFromCentre;
//        
//        roundedStepsFromCentre += [[problemDef objectForKey:START_VALUE] intValue];
//        
//        if(roundedStepsFromCentre>[rambler.MaxValue intValue])roundedStepsFromCentre=[rambler.MaxValue intValue] - [[problemDef objectForKey:START_VALUE] intValue];
//        if(roundedStepsFromCentre<[rambler.MinValue intValue])roundedStepsFromCentre=[rambler.MinValue intValue] - [[problemDef objectForKey:START_VALUE] intValue];
//        
//        //lastBubbleLoc=roundedStepsFromCentre + [[problemDef objectForKey:START_VALUE] intValue];
//        lastBubbleLoc=roundedStepsFromCentre;
        
//        //diff (moveby)
//        float diffx=(roundedStepsFromActualCentre * rambler.DefaultSegmentSize)-distFromCentre;
//        [bubbleSprite runAction:[CCMoveBy actionWithDuration:0.2f position:ccp(diffx, 0)]];
    }
    
//    if(inRamblerArea)
//    {
//        [rambler handleMessage:kDWnlineReleaseRamblerAtOffset];
//        
//        inRamblerArea=NO;
//        rambler.TouchXOffset=0;
//    }

    
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
