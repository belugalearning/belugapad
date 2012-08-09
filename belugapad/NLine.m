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
    bubbleTexSelected=[[CCTexture2D alloc] initWithCGImage:[UIImage imageWithContentsOfFile:BUNDLE_FULL_PATH(@"/images/numberline/bubble_selected115.png")].CGImage resolutionType:kCCResolutioniPad];
    
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
    
    if(touchResetX>0)
    {
        float movex=1+((touchResetX-1) / 15.0f);
        rambler.TouchXOffset += movex * touchResetDir;
        touchResetX -=movex;
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
    rambler.BubblePos=lastBubbleLoc;
    
    enableAudioCounting = [rambler.MinValue intValue]>=0 && [rambler.MaxValue intValue]<=20;
    
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
    
    
    //positioning
    rambler.DefaultSegmentSize=115;
    rambler.Pos=ccp(cx,cy);
    
    selector=[DWSelectorGameObject alloc];
    [gw populateAndAddGameObject:selector withTemplateName:@"TnLineSelector"];
    
    //point the selector at the rambler
    selector.WatchRambler=rambler;
    selector.pos=ccp(cx,cy + 75.0f);
    
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
    lastBubbleLoc=initStartVal;
    
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
        [self evalProblem];
        
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

-(void)evalProblem
{
    self.ProblemComplete = (evalTarget==lastBubbleLoc);
    
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
    
    [bubbleSprite setTexture:bubbleTexSelected];
    [bubbleSprite setTextureRect:CGRectMake(0, 0, bubbleTexSelected.contentSize.width, bubbleTexSelected.contentSize.height)];
    
    [bubbleSprite setScale:0.87f];
    [bubbleSprite runAction:[InteractionFeedback enlargeTo1xAction]];
    
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/nline/pickup.wav")];
}

-(void)animReleaseBubble
{
    [bubbleSprite setTexture:bubbleTexRegular];
    [bubbleSprite setTextureRect:CGRectMake(0, 0, bubbleTexRegular.contentSize.width, bubbleTexRegular.contentSize.height)];
    
    [bubbleSprite setScale:1.15f];
    [bubbleSprite runAction:[InteractionFeedback reduceTo1xAction]];    
    
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/nline/release.wav")];
}

-(void)animShakeBubble
{
    [bubbleSprite runAction:[InteractionFeedback shakeAction]];
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
        [self evalProblem];
        
        if(!self.ProblemComplete) 
        {
            //automate reset here
            
            [self resetBubble];
            [toolHost resetScoreMultiplier];
            
            //toolHost.flagResetProblem=YES;
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
        if(!usedBubble)usedBubble=YES;
        holdingBubbleOffset=location.x - bubbleSprite.position.x;
        holdingBubble=YES;
        
        [self animPickupBubble];
        
        [loggingService logEvent:BL_PA_NL_TOUCH_BEGIN_PICKUP_BUBBLE withAdditionalData:nil];
        
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
        
        float offsetFromCX=location.x-cx-holdingBubbleOffset;
        if(fabsf(offsetFromCX)>kBubbleScrollBoundary)
        {
            if(offsetFromCX>0 && bubbleAtBounds<=0)bubblePushDir=-1;
            if(offsetFromCX<0 && bubbleAtBounds>=0)bubblePushDir=1;
            
            logBubbleDidMoveLine=YES;
            logBubbleDidMove=YES;
        }
        else {
            CGPoint newloc=ccp(location.x - holdingBubbleOffset, bubbleSprite.position.y);
            //CGPoint newloc=ccp(location.x, bubbleSprite.position.y);
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
                
        int startOffset=initStartVal;
        
        
        //lastBubbleLoc = roundedStepsFromCentre+startOffset;
        lastBubbleLoc=(roundedStepsFromCentre+startOffset) * rambler.CurrentSegmentValue;
        
        int adjustedStepsFromCentre=roundedStepsFromCentre;
        
        BOOL stopLine=NO;
        
        if (lastBubbleLoc>[rambler.MaxValue intValue]) 
        {
            adjustedStepsFromCentre = [rambler.MaxValue intValue] - startOffset;
            stopLine=YES;
            bubbleAtBounds=1;
            bubblePushDir=0;
        }
        
        if(lastBubbleLoc<[rambler.MinValue intValue]) 
        {
            adjustedStepsFromCentre = [rambler.MinValue intValue] - startOffset;
            stopLine=YES;
            bubbleAtBounds=-1;
            bubblePushDir=0;
        }
        
        if(stopLine)
        {
            //diff (moveby)
            float diffx=(adjustedStepsFromCentre * rambler.DefaultSegmentSize)-distFromCentre;
            [bubbleSprite runAction:[CCMoveBy actionWithDuration:0.2f position:ccp(diffx, 0)]];
        }
        
        
        
        //update the rambler value
        rambler.BubblePos=lastBubbleLoc;

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
        holdingBubbleOffset=0;
        
        float distFromCentre=-rambler.TouchXOffset + (bubbleSprite.position.x - cx);
        float stepsFromCentre=distFromCentre / rambler.DefaultSegmentSize;
        
        int roundedStepsFromCentre=(int)(stepsFromCentre + 0.5f);
        if(stepsFromCentre<0) roundedStepsFromCentre=(int)(stepsFromCentre - 0.5f);
        
        int startOffset=initStartVal;
        lastBubbleLoc = (roundedStepsFromCentre+startOffset) * rambler.CurrentSegmentValue;
        int adjustedStepsFromCentre=roundedStepsFromCentre * rambler.CurrentSegmentValue;
        
        if (lastBubbleLoc>[rambler.MaxValue intValue]) adjustedStepsFromCentre = [rambler.MaxValue intValue]  - startOffset;
        
        if(lastBubbleLoc<[rambler.MinValue intValue]) adjustedStepsFromCentre = [rambler.MinValue intValue] - startOffset;
        
        //mod this to closest valid segment value
        adjustedStepsFromCentre=rambler.CurrentSegmentValue * ((int)(adjustedStepsFromCentre / rambler.CurrentSegmentValue));

        //diff (moveby)
        float diffx=((adjustedStepsFromCentre / rambler.CurrentSegmentValue) * rambler.DefaultSegmentSize)-distFromCentre;
        [bubbleSprite runAction:[CCMoveBy actionWithDuration:0.2f position:ccp(diffx, 0)]];
        
        
        //update the rambler value & last bubble location, using any offset
        lastBubbleLoc=adjustedStepsFromCentre + startOffset;
        rambler.BubblePos=lastBubbleLoc;
        
        
        //play some audio
        if(enableAudioCounting && lastBubbleLoc!=logLastBubblePos)
        {
            NSString *path=[NSString stringWithFormat:@"/sfx/numbers/%d.wav", lastBubbleLoc];
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(path)];
        }
        
        //release the bubble
        [self animReleaseBubble];
        
        //do some logging
        [loggingService logEvent:BL_PA_NL_TOUCH_END_RELEASE_BUBBLE withAdditionalData:nil];
        
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
            [loggingService logEvent:BL_PA_NL_TOUCH_MOVE_MOVE_BUBBLE withAdditionalData:nil];
        }
        if(logBubbleDidMoveLine)
        {
            [loggingService logEvent:BL_PA_NL_TOUCH_MOVE_MOVE_LINE withAdditionalData:nil];
        }
        
        logBubbleDidMove=NO;
        logBubbleDidMoveLine=NO;
        
    }
    
    holdingBubbleOffset=0;
    holdingBubble=NO;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    inRamblerArea=NO;
}

-(void)dealloc
{
    [bubbleTexRegular release];
    [bubbleTexSelected release];
    [rambler release];
    [selector release];
    
    [gw release];

    
    [super dealloc];
}

@end
