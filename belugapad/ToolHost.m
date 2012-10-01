//
//  ToolHost.m
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolHost.h"
#import "ToolConsts.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "BLMath.h"
#import "Daemon.h"
#import "ToolScene.h"
#import "AppDelegate.h"
#import "BAExpressionHeaders.h"
#import "BATio.h"
#import "LoggingService.h"
#import "TouchLogger.h"
#import "ContentService.h"
#import "UsersService.h"
#import "JMap.h"
#import "DProblemParser.h"
#import "Problem.h"
#import "Pipeline.h"
#import "NordicAnimator.h"
#import "LRAnimator.h"
#import "BLFiles.h"
#import "InteractionFeedback.h"
#import "SGGameWorld.h"
#import "SGBtxeRow.h"
#import "SGBtxeProtocols.h"

#define HD_HEADER_HEIGHT 65.0f
#define HD_BUTTON_INSET 40.0f
#define HD_SCORE_INSET 40.0f

//CCPickerView
#define kComponentWidth 54
#define kComponentHeight 32
#define kComponentSpacing 10

#define SHOW_NUMBER_WHEEL NO

@interface ToolHost()
{
    @private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation ToolHost

@synthesize Zubi;
@synthesize PpExpr;
@synthesize flagResetProblem;
@synthesize DynProblemParser;
@synthesize pickerView;

static float kMoveToNextProblemTime=0.5f;
static float kDisableInteractionTime=0.5f;
static float kTimeToShakeNumberPickerButtons=7.0f;

#pragma mark - init and setup

+(CCScene *) scene
{
    CCScene *scene=[CCScene node];
    
    ToolHost *layer=[ToolHost node];
    
    
    [scene addChild:layer];
    
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        multiplierStage=1;
        scoreMultiplier=1;
        
        //setup layer sequence
        backgroundLayer=[[CCLayer alloc] init];
        [self addChild:backgroundLayer z:-2];
        perstLayer=[[CCLayer alloc] init];
        [self addChild:perstLayer z:0];
        
        animator=[[LRAnimator alloc] init];
        [animator setBackground:backgroundLayer withCx:cx withCy:cy];
        
        [animator animateBackgroundIn];
        animPos=1;
        
        //[self scheduleOnce:@selector(moveToTool1:) delay:1.5f];
        
        //add a pause button but keep it hidden -- to be brought in by the fader
        //CCSprite *pause=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/button-pause.png")];
        //[pause setPosition:ccp(lx-(kPropXPauseButtonPadding*lx), ly-(kPropXPauseButtonPadding*lx))];
        //[perstLayer addChild:pause z:3];
        
        //add header
        CCSprite *hd=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_HeaderBar.png")];
        hd.position=ccp(cx, 2*cy - HD_HEADER_HEIGHT / 2.0f);
        [perstLayer addChild:hd z:3];
        
        //add disabled commit
        CCSprite *commdis=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Disabled.png")];
        commdis.position=ccp(2*cx-HD_BUTTON_INSET, 2*cy - 30);
        [perstLayer addChild:commdis z:3];

        metaQuestionLayer=[[CCLayer alloc] init];
        [self addChild:metaQuestionLayer z:2];
        problemDefLayer=[[CCLayer alloc] init];
        [self addChild:problemDefLayer z:3];
        
        btxeDescLayer=[[CCLayer alloc] init];
        [self addChild:btxeDescLayer z:3];
        
        pauseLayer=[[CCLayer alloc]init];
        [self addChild:pauseLayer z:4];
        
        contextProgressLayer=[[CCLayer alloc] init];
        [self addChild:contextProgressLayer z:6];
        
        [self populatePerstLayer];
        
        //dynamic problem parser (persists to end of pipeline)
        DynProblemParser=[[DProblemParser alloc] init];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        loggingService = ac.loggingService;
        contentService = ac.contentService;
        usersService = ac.usersService;
        
        [self scheduleOnce:@selector(gotoFirstProblem:) delay:0.0f];
        //[self gotoNewProblem];
        
        [self schedule:@selector(doUpdateOnTick:) interval:1.0f/60.0f];
        [self schedule:@selector(doUpdateOnSecond:) interval:1.0f];
        [self schedule:@selector(doUpdateOnQuarterSecond:) interval:1.0f/40.0f];
        
    }
    
    return self;
}

#pragma mark animation and transisitons

-(void)moveToCurrentToolDepth
{
    if(currentToolDepth==0)[self moveToTool0:0];
    else if(currentToolDepth==1)[self moveToTool1:0];
    else if(currentToolDepth==2)[self moveToTool2:0];
    else if(currentToolDepth==3)[self moveToTool3:0];
}

-(void)moveToTool0: (ccTime) delta
{
    [animator moveToTool0:delta];
}

-(void) moveToTool1: (ccTime) delta
{
    [animator moveToTool1:delta];
}

-(void) moveToTool2: (ccTime) delta
{
    [animator moveToTool2:delta];
}

-(void) moveToTool3: (ccTime) delta
{
    [animator moveToTool3:delta];
}

-(void) shakeCommitButton
{
    [commitBtn runAction:[InteractionFeedback dropAndBounceAction]];
}

-(void)stageIntroActions
{
    //TODO tags are currently fixed to 2 phases -- either parse tool tree or pre-populate with design-fixed max
    
    isAnimatingIn=YES;
    
    for (int i=1; i<=3; i++) {
        
        int time=i;
        if(skipNextStagedIntroAnim) time=0;
        timeBeforeUserInteraction=time;
        
        if(toolBackLayer) [self recurseSetIntroFor:toolBackLayer withTime:time forTag:i];
        if(toolForeLayer)[self recurseSetIntroFor:toolForeLayer withTime:time forTag:i];
        if(toolNoScaleLayer)[self recurseSetIntroFor:toolNoScaleLayer withTime:time forTag:i];
        if(metaQuestionLayer)[self recurseSetIntroFor:metaQuestionLayer withTime:time forTag:i];
        if(problemDefLayer)[self recurseSetIntroFor:problemDefLayer withTime:time forTag:i];
        if(numberPickerLayer)[self recurseSetIntroFor:numberPickerLayer withTime:time forTag:i];
    }
    
    
    skipNextStagedIntroAnim=NO;
}

-(void)recurseSetIntroFor:(CCNode*)node withTime:(float)time forTag:(int)tag
{
    for (CCNode *cn in [node children]) {
        if([cn tag]==tag)
        {
            CCDelayTime *d=[CCDelayTime actionWithDuration:time];
            CCFadeIn *f=[CCFadeIn actionWithDuration:0.1f];
            CCSequence *s=[CCSequence actions:d, f, nil];
            [cn runAction:s];
        }
        [self recurseSetIntroFor:cn withTime:time forTag:tag];
    }
}


#pragma mark

#pragma mark audio generic methods

-(void)playAudioClick
{
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/integrated/Click B.aac")];
}

-(void)playAudioPress
{
    //play a blpress
    int i=arc4random() % 5 + 1;
    NSString *file=[NSString stringWithFormat:@"/sfx/integrated/blpress-%d.wav", i];
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(file)];
}

-(void)playAudioFlourish
{
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/integrated/blpress-flourish.wav")];
}

#pragma mark draw and ticks



-(void)draw
{
    [currentTool draw];
}

-(void)doUpdateOnTick:(ccTime)delta
{
    //do internal mgmt updates
    [self.Zubi doUpdate:delta];
    
    //animator
    [animator doUpdate:delta];
    
    if(showingProblemComplete) shownProblemStatusFor+=delta;
    if(showingProblemIncomplete) shownProblemStatusFor+=delta;
 
    if(shownProblemStatusFor>kTimeToShowProblemStatus)
    {
        if(showingProblemComplete)
        {
            [problemComplete runAction:[CCFadeOut actionWithDuration:kTimeToFadeProblemStatus]];
            showingProblemComplete=NO;
        }
        if(showingProblemIncomplete)
        {
            [problemIncomplete runAction:[CCFadeOut actionWithDuration:kTimeToFadeProblemStatus]];
            showingProblemIncomplete=NO;
            if(metaQuestionForThisProblem)[self deselectAnswersExcept:-1];
        }
            shownProblemStatusFor=0.0f;
    }
    
    if(autoMoveToNextProblem)
    {
        moveToNextProblemTime-=delta;
        if(moveToNextProblemTime<0)
        {
            autoMoveToNextProblem=NO;
            
            [self gotoNewProblem];
        }
    }
    else if(isAnimatingIn){
        timeBeforeUserInteraction-=delta;
        
        if(timeBeforeUserInteraction<0)
        {
            isAnimatingIn=NO;
            timeBeforeUserInteraction=kDisableInteractionTime;
        }
    }
    
    if(numberPickerForThisProblem)timeSinceInteractionOrShakeNP+=delta;
    
    if(timeSinceInteractionOrShakeNP>kTimeToShakeNumberPickerButtons && numberPickerForThisProblem && !hasUsedNumber)
    {
        
        for(CCSprite *s in numberPickerButtons)
        {
            [s runAction:[InteractionFeedback dropAndBounceAction]];
        }
        
        timeSinceInteractionOrShakeNP=0.0f;
    }
    

    
    //let tool do updates
    if(!isPaused)[currentTool doUpdateOnTick:delta];
}

-(void)doUpdateOnSecond:(ccTime)delta
{
    if(showMetaQuestionIncomplete) shownMetaQuestionIncompleteFor+=delta;
    
    //do internal mgmt updates
    //don't eval if we're in an auto move to next problem
    
    //if the problem is complete and we aren't already moving to the next one
    if((currentTool.ProblemComplete || metaQuestionForceComplete) && !autoMoveToNextProblem)
    {   
        [self incrementScoreAndMultiplier];
        
        moveToNextProblemTime=kMoveToNextProblemTime;
        autoMoveToNextProblem=YES;
    }
    
    //if the problem is to be skipped b/c of triggered insertion and we aren't already moving to the next one
    if(adpSkipProblemAndInsert && !autoMoveToNextProblem)
    {
        moveToNextProblemTime=kMoveToNextProblemTime;
        autoMoveToNextProblem=YES;
    }
    
    if(self.flagResetProblem)
    {
        [self resetProblem];
        self.flagResetProblem=NO;
    }
    
    if(shownMetaQuestionIncompleteFor>kTimeToAutoMove)
    {
        [metaQuestionIncompleteLabel setVisible:NO];
        showMetaQuestionIncomplete=NO;
        shownMetaQuestionIncompleteFor=0;
        [self deselectAnswersExcept:-1];
    }
    
    //let tool do updates
    [currentTool doUpdateOnSecond:delta];
}

-(void)doUpdateOnQuarterSecond:(ccTime)delta
{
    [currentTool doUpdateOnQuarterSecond:delta];
}

#pragma mark - add layers

-(void) addToolNoScaleLayer:(CCLayer *) noScaleLayer
{
    toolNoScaleLayer=noScaleLayer;
    [self addChild:toolNoScaleLayer];
}

-(void) addToolBackLayer:(CCLayer *) backLayer
{
    toolBackLayer=backLayer;
    [self addChild:toolBackLayer z:-1];
}

-(void) addToolForeLayer:(CCLayer *) foreLayer
{
    toolForeLayer=foreLayer;
    [self addChild:toolForeLayer z:1];
}

-(void) populatePerstLayer
{
    Zubi=[[Daemon alloc] initWithLayer:contextProgressLayer andRestingPostion:ccp(cx, 2*cy-HD_SCORE_INSET) andLy:ly];
    [Zubi hideZubi];
    
    //score labels
//    multiplierLabel=[CCLabelTTF labelWithString:@"(1x)" dimensions:CGSizeMake(100, 50) alignment:UITextAlignmentLeft fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
//    [multiplierLabel setOpacity:75];
//    [multiplierLabel setPosition:ccp(300, 20)];
//    [perstLayer addChild:multiplierLabel];
    
    scoreLabel=[CCLabelTTF labelWithString:@"0" fontName:@"Chango" fontSize:18];;
    [scoreLabel setPosition:ccp(cx, 2*cy-HD_SCORE_INSET)];
    [perstLayer addChild:scoreLabel z:4];
}

#pragma mark - scoring

-(void)incrementScoreAndMultiplier
{
    //increment the score if we're past init (e.g. in first scoring problem)
    if(multiplierStage>0)
    {
        [self scoreProblemSuccess];
    }
    
    //increment the multiplier
    if(multiplierStage==0)
    {
        scoreMultiplier=1;
        
        //reject any current multiplier
        [self rejectMultiplierButton];
        
    }
    else if (multiplierStage<SCORE_STAGE_CAP && !hasResetMultiplier)
    {
        scoreMultiplier*=SCORE_STAGE_MULTIPLIER;
        
        [self setMultiplierButtonTo:(int)scoreMultiplier];
        
        //[multiplierLabel runAction:[InteractionFeedback highlightIncreaseAction]];
    }

    multiplierStage++;
    
    [self updateScoreLabels];
}

-(void)setMultiplierButtonTo:(int)m
{
    if(!(m==2 || m==4 || m==8 || m==16)) return;
    
    if(multiplierBadge)
    {
        [self removeChild:multiplierBadge cleanup:YES];
    }
    
    NSString *bf=[NSString stringWithFormat:@"/images/menu/HR_Multiplier_%d.png", m];
    multiplierBadge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(bf)];
    multiplierBadge.position=ccp(700, 2*cy-32);
    //multiplierBadge.position=ccp(cx,cy);
    [self addChild:multiplierBadge z:4];
    
    [multiplierBadge runAction:[InteractionFeedback dropAndBounceAction]];
}

-(void)rejectMultiplierButton
{
    if(multiplierBadge)
    {
        [multiplierBadge runAction:[InteractionFeedback delaySpinFast]];
        [multiplierBadge runAction:[InteractionFeedback delayMoveOutAndDown]];
    }
}

-(void)resetScoreMultiplier
{
    scoreMultiplier=1;
    multiplierStage=1;
    hasResetMultiplier=YES;
    
    [self scheduleOnce:@selector(updateScoreLabels) delay:0.5f];
    
    [self rejectMultiplierButton];
    
    //[multiplierLabel runAction:[InteractionFeedback fadeOutInTo:75]];
    //[multiplierLabel runAction:[InteractionFeedback scaleOutReturn]];
}

-(void)scoreProblemSuccess
{
    int newScore=scoreMultiplier * SCORE_BASE_AWARD;
    pipelineScore+=newScore;

    int shards=(int)((float)newScore*SCORE_SHARDS_PER_SCORE);
    displayPerShard=(int)((float)newScore / (float)shards);
    int rem=newScore - displayPerShard*shards;
    
    //get the remainder on the display score right away
    displayScore+=rem;
    
    [Zubi createXPshards:shards fromLocation:ccp(cx, cy) withCallback:@selector(incrementDisplayScore:) fromCaller:(NSObject*)self];
}


-(void)updateScoreLabels
{
    //[multiplierLabel setString:[NSString stringWithFormat:@"(%dx)", (int)scoreMultiplier]];
    
    //show correct multiplier
    if(multiplierBadge)[perstLayer removeChild:multiplierBadge cleanup:YES];
    
    
    
    //this isn't going to do this ultiamtely -- it'll be based on shards
    [scoreLabel setString:[NSString stringWithFormat:@"%d", displayScore]];
}

-(void)incrementDisplayScore: (id)sender
{
    displayScore+=displayPerShard;
    [self updateScoreLabels];
}


#pragma mark - tool and problem load

-(void) loadTool
{
    //reset multitouch
    //if tool requires multitouch, it will need to reset accordingly
        [[CCDirector sharedDirector] view].multipleTouchEnabled=NO;
}

-(void) gotoFirstProblem: (ccTime) delta
{
    [self gotoNewProblem];
}

-(void) gotoNewProblem
{
    if (pdef) [pdef release];

    [self tearDownProblemDef];
    self.PpExpr = nil;
    
    //score and increment multiplier if appropriate
    //[self incrementScoreAndMultiplier];
    
    //this problem will award multiplier if not subsequently reset
    hasResetMultiplier=NO;
    
    NSLog(@"score: %d multiplier: %f hasReset: %d multiplierStage: %d", pipelineScore, scoreMultiplier, hasResetMultiplier, multiplierStage);
    
    if(adpSkipProblemAndInsert)
    {
        //user failed problem past commit threshold, indicate as such, insert problems and then progress
        //todo: contentservice fail problem call
        
        //request that we insert problems in the pipeline
        [contentService adaptPipelineByInsertingWithTriggerData:triggerData];
        
        adpSkipProblemAndInsert=NO;
    }
    
    //this is the goto next problem bit -- actually next problem in episode, as there's no effetive success/fail thing
    [contentService gotoNextProblemInPipeline];
    
    
    //check that the content service found a pdef (this will be the raw dynamic one)
    if(contentService.currentPDef)
    {
        [self loadProblem];
    }
    else
    {
        //no more problems in this sequence, bail to menu
        
        //todo: completion shouldn't be assumed here -- we can get here by progressing into an inserter that produces no viable insertions
        
        //assume completion
        [contentService setPipelineNodeComplete];
        [contentService setPipelineScore:pipelineScore];
        
        contentService.fullRedraw=YES;
        contentService.lightUpProgressFromLastNode=YES;
        
        [contentService quitPipelineTracking];
        
        //[contentService.currentStaticPdef release];
        
        [[CCDirector sharedDirector] replaceScene:[JMap scene]];
    }
}

-(void) loadProblem
{
    // ---------------- TEAR DOWN ------------------------------------
    //tear down meta question stuff
    [self tearDownMetaQuestion];
    
    [self tearDownNumberPicker];
    //tear down host background
    if(hostBackground)
    {
        [self removeChild:hostBackground cleanup:YES];
        hostBackground=nil;
    }
    // ---------------- END TEAR DOWN --------------------------------
    
    
    //parse dynamic problem stuff -- needs to be done before toolscene is init'd AND before tool host or scene tried to do anything with the pdef
    [self.DynProblemParser startNewProblemWithPDef:contentService.currentPDef];
    
    //local copy of pdef is parsed to static (this may be identical to original, but supports dynamic population if specified in plist)
    pdef=[self.DynProblemParser createStaticPdefFromPdef:contentService.currentPDef];
    
    //keep reference to the current static definition on the content service -- for logging etc
    contentService.currentStaticPdef=pdef;
    
    // TODO: maybe this, and dynamic pdef generation above, should really be coming from ContentService I think? Check with G
    // TODO: moreover is it writing this out to plist better than storing as json?
    NSArray *docsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tempPDefPath = [[docsPaths objectAtIndex:0] stringByAppendingPathComponent:@"temp-pdef.plist"];
    [pdef writeToFile:tempPDefPath atomically:YES];
    NSString *pdefString = [[[NSString alloc] initWithContentsOfFile:tempPDefPath encoding:NSUTF8StringEncoding error:nil] autorelease];
    [loggingService logEvent:BL_PA_START withAdditionalData:[NSDictionary dictionaryWithObject:pdefString forKey:@"pdef"]];
    
    NSString *toolKey=[pdef objectForKey:TOOL_KEY];
    
    if(currentTool)
    {
        if(toolBackLayer)
        {
            [self removeChild:toolBackLayer cleanup:YES];
            toolBackLayer=nil;
        }
        
        if(toolForeLayer)
        {
            [self removeChild:toolForeLayer cleanup:YES];            
            toolForeLayer=nil;
        }
        
        if(toolNoScaleLayer)
        {
            [self removeChild:toolNoScaleLayer cleanup:YES];
            //stop looking at it -- tool should clean it up
            toolNoScaleLayer=nil;
        }
        
        [currentTool release];
        currentTool=nil;
    }
    
    //reset multitouch
    //if tool requires multitouch, it will need to reset accordingly
    //for multi-touch scaling we need to force this on
    [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
    
    //reset scale
    if([pdef objectForKey:DEFAULT_SCALE])
        scale=[[pdef objectForKey:DEFAULT_SCALE]floatValue];
    else
        scale=1.0f;
    
    
    if(toolKey)
    {
        //initialize tool scene
        currentTool=[NSClassFromString(toolKey) alloc];
        [currentTool initWithToolHost:self andProblemDef:pdef];
    }
    
    //read our tool specific options
    [self readToolOptions:toolKey];

    //move to correct depth
    [self moveToCurrentToolDepth];
    
    //setup background png / underlay
//    NSString *hostBackgroundFile=[pdef objectForKey:@"HOST_BACKGROUND_IMAGE"];
//    if(hostBackgroundFile)
//    {
//        hostBackground=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(hostBackgroundFile)];
//        [hostBackground setPosition:ccp(cx, cy)];
//        [self addChild:hostBackground];
//    }
    
    //playback sound assocaited with problem
    NSString *playsound=[pdef objectForKey:PLAY_SOUND];
    if(playsound) [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/sfx/%@", playsound]))];
    
    //setup meta question (if there is one)
    NSDictionary *mq=[pdef objectForKey:META_QUESTION];
    NSDictionary *np=[pdef objectForKey:NUMBER_PICKER];
    if (mq)
    {
        [self setupMetaQuestion:mq];
    }
    else if(np)
    {
        evalMode=1;
        [self setupNumberPicker:np];
    }
    else {
        [self setupProblemOnToolHost:pdef];
    }
    
    //setup number wheel if required
    if (SHOW_NUMBER_WHEEL) {
        [self setupNumberWheel];
    }
    
    // set scale using the value we got earlier
    [toolBackLayer setScale:scale];
    [toolForeLayer setScale:scale];
    
    //glossary mockup
    if([pdef objectForKey:@"GLOSSARY"])
    {
        isGlossaryMock=YES;
        glossary1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/glossary/GlossaryExample.png")];
        [glossary1 setPosition:ccp(cx,cy)];
        [self addChild:glossary1];
        [self setProblemDescriptionVisible:NO];
    }
    else {
        isGlossaryMock=NO;
        if(glossary1)[self removeChild:glossary1 cleanup:YES];
        if(glossary2)[self removeChild:glossary2 cleanup:YES];
        if(glossaryPopup)[self removeChild:glossaryPopup cleanup:YES];
    }
    
    [self stageIntroActions];        

    [self.Zubi dumpXP];
    
    //zubi is fixed off by default
    if ([pdef objectForKey:@"SHOW_ZUBI"]) {
        [self.Zubi showZubi];
    }
    else {
        [self.Zubi hideZubi];
    }
    
}

-(void)setupProblemOnToolHost:(NSDictionary *)curpdef
{
    NSNumber *eMode=[curpdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    else if(eMode && numberPickerForThisProblem) evalMode=kProblemEvalOnCommit;
    else evalMode=kProblemEvalAuto;
    
    NSString *labelDesc=[self.DynProblemParser parseStringFromValueWithKey:PROBLEM_DESCRIPTION inDef:curpdef];
        
    [self setProblemDescription:labelDesc];
    
    if(evalMode==kProblemEvalOnCommit)
    {
        commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Enabled.png")];
        commitBtn.position=ccp(2*cx-HD_BUTTON_INSET, 2*cy - 30);
        //[commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [problemDefLayer addChild:commitBtn z:2];
    }
    else
    {
        if(commitBtn)
        {
            //[commitBtn removeFromParentAndCleanup:YES];
            commitBtn=nil;
        }
    }
}


-(void) resetProblem
{
    //if(problemDescLabel)[problemDescLabel removeFromParentAndCleanup:YES];
    
    if(evalMode==kProblemEvalOnCommit)
    {
        [commitBtn removeFromParentAndCleanup:YES];
        commitBtn=nil;
    }
    
    [self resetScoreMultiplier];
    
    skipNextDescDraw=YES;
    skipNextStagedIntroAnim=YES;
    
    [self loadProblem];
}

-(void)readToolOptions:(NSString *)currentToolKey
{
    if(currentToolKey)
    {
        NSDictionary *toolDef=[NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(@"/tooldef.plist")];
        
        NSDictionary *toolOpt=[toolDef objectForKey:currentToolKey];
        
        if([toolOpt objectForKey:SCALE_MAX])
            currentTool.ScaleMax=[[toolOpt objectForKey:SCALE_MAX] floatValue];
        else
            currentTool.ScaleMax=1.0f;
        
        if([toolOpt objectForKey:SCALE_MIN])
            currentTool.ScaleMin=[[toolOpt objectForKey:SCALE_MIN] floatValue];
        else
            currentTool.ScaleMin=1.0f;
        
        if([toolOpt objectForKey:SCALING_PASS_THRU])
            currentTool.PassThruScaling=[[toolOpt objectForKey:SCALING_PASS_THRU] boolValue];
        else 
            currentTool.PassThruScaling=NO;
        
        
        //get tool depth
        if([toolOpt objectForKey:@"TOOL_DEPTH"])
        {
            currentToolDepth=[(NSNumber *)[toolOpt objectForKey:@"TOOL_DEPTH"] intValue];
        }
        else {
            currentToolDepth=2; // put tool default in middle
        }
        
    }
    else {
        currentToolDepth=2;
    }
}

-(void)tearDownProblemDef
{
    [problemDefLayer removeAllChildrenWithCleanup:YES];
    [btxeDescLayer removeAllChildrenWithCleanup:YES];
    
    [descGw release];
    descGw=nil;
    
    //nil pointers to things on there
    problemDescLabel=nil;
    
}

#pragma mark - pause show and touch handling

-(void) showPauseMenu
{
    isPaused = YES;
    
    if(!pauseMenu)
    {
        pauseMenu = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/pause-overlay.png")];
        [pauseMenu setPosition:ccp(cx, cy)];
        [pauseLayer addChild:pauseMenu z:10];
        
        if(contentService.pathToTestDef)
        {
            
            pauseTestPathLabel=[CCLabelTTF labelWithString:@"" fontName:TITLE_FONT fontSize:12];
            [pauseTestPathLabel setPosition:ccp(cx, ly-20)];
            [pauseTestPathLabel setColor:ccc3(255, 255, 255)];
            [pauseLayer addChild:pauseTestPathLabel z:11];
        }
    }
    else {
        [pauseLayer setVisible:YES];
    }
    
    if(contentService.pathToTestDef)
    {
        [pauseTestPathLabel setString:contentService.pathToTestDef];
        NSLog(@"pausing in test problem %@", contentService.pathToTestDef);
    }
    else {
        //just log document id for the problem & pipeline
        NSLog(@"pausing in problem document %@ in pipeline %@", contentService.currentProblem._id, contentService.currentPipeline._id);
    }
    
    [loggingService logEvent:BL_PA_PAUSE withAdditionalData:nil];
}

-(void) checkPauseTouches:(CGPoint)location
{
    if(CGRectContainsPoint(kPauseMenuContinue, location))
    {
        //resume
        [loggingService logEvent:BL_PA_RESUME withAdditionalData:nil];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [pauseLayer setVisible:NO];
        isPaused=NO;
    }
    if(CGRectContainsPoint(kPauseMenuReset, location))
    {
        //reset
        [loggingService logEvent:BL_PA_USER_RESET withAdditionalData:nil];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self resetProblem];
        [pauseLayer setVisible:NO];
        isPaused=NO;
    }
    if(CGRectContainsPoint(kPauseMenuMenu, location))
    {
        [loggingService logEvent:BL_PA_EXIT_TO_MAP withAdditionalData:nil];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self returnToMenu];
    }
//    if(CGRectContainsPoint(kPauseMenuLogOut, location))
//    {
//        [loggingService logEvent:BL_USER_LOGOUT withAdditionalData:nil];
//        [usersService setCurrentUserToUserWithId:nil];
//        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
//        [(AppController*)[[UIApplication sharedApplication] delegate] returnToLogin];
//    }
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    
    //bottom right tap for debug skip problem
    if (!ac.ReleaseMode && location.x>cx && location.y < 768 - kButtonToolbarHitBaseYOffset)
    {
        [loggingService logEvent:BL_PA_SKIP_DEBUG withAdditionalData:nil];
        isPaused=NO;
        [pauseLayer setVisible:NO];
        [self gotoNewProblem];
        
        if(debugShowingPipelineState) [self debugHidePipelineState];
    }
    
    if(!ac.ReleaseMode && location.x<cx && location.y < 768 - kButtonToolbarHitBaseYOffset)
    {
        if(debugShowingPipelineState)
        {
            [self debugHidePipelineState];
        }
        else
        {
            [self debugShowPipelineState];
        }
    }
}

#pragma mark - completion and user flow

-(void)returnToMenu
{
    [[CCDirector sharedDirector] replaceScene:[JMap scene]];
}

-(void)showProblemCompleteMessage
{
    NSLog(@"show problem complete");
    problemComplete = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/Question_Status/stamp_tick.png")];
    [problemComplete setPosition:ccp(cx, cy)];
    [problemComplete runAction:[InteractionFeedback stampAction]];
    [contextProgressLayer addChild:problemComplete];
    showingProblemComplete=YES;
    
    [self showBlackOverlay];
}

-(void)showProblemIncompleteMessage
{
    if(showingProblemIncomplete) return;
    
    if(problemIncomplete) [problemDefLayer removeChild:problemIncomplete cleanup:YES];
    
    problemIncomplete = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/Question_Status/stamp_cross.png")];
    [problemIncomplete setPosition:ccp(cx,cy)];
    [problemIncomplete runAction:[InteractionFeedback stampAction]];
    [contextProgressLayer addChild:problemIncomplete];
    showingProblemIncomplete=YES;
    
    [self showBlackOverlay];
    
    //reject multiplier
    [self resetScoreMultiplier];
}

-(void)showBlackOverlay
{
    if(!blackOverlay)
    {
        blackOverlay=[CCLayerColor layerWithColor:ccc4(0, 0, 0, 100) width:2*cx height:2*cy];
        [self addChild:blackOverlay z:5]; // fits between everything else and the context progress layer
    }
    
    [blackOverlay runAction:[InteractionFeedback fadeInOutHoldFor:1.0f to:200]];
}

#pragma mark - meta question

-(NSMutableArray*)randomizeAnswers:(NSMutableArray*)thisArray
{
    NSUInteger count = [thisArray count];
    for (int i=0; i<count; i++) {
        // Select a random element between i and end of array to swap with.
        int nElements = count - i;
        int n = (arc4random() % nElements) + i;
        [thisArray exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    return thisArray;
}

-(void)setupMetaQuestion:(NSDictionary *)pdefMQ
{
    metaQuestionForThisProblem=YES;
    shownMetaQuestionIncompleteFor=0;
    
    metaQuestionAnswers = [[NSMutableArray alloc] init];
    metaQuestionAnswerButtons = [[NSMutableArray alloc] init];
    metaQuestionAnswerLabels = [[NSMutableArray alloc] init];
    
    //float titleY=cy*1.75f;
    float answersY=cy*0.40;
    if(currentTool)
    {
        //titleY=[currentTool metaQuestionTitleYLocation];
        answersY=[currentTool metaQuestionAnswersYLocation];
    }
    
    [self setProblemDescription:[pdefMQ objectForKey:META_QUESTION_TITLE]];
    
    // check the answer mode and assign
    NSNumber *aMode=[pdefMQ objectForKey:META_QUESTION_ANSWER_MODE];
    if (aMode) mqAnswerMode=[aMode intValue];
    
    // check the eval mode and assign
//    NSNumber *eMode=[pdefMQ objectForKey:META_QUESTION_EVAL_MODE];
//    if(eMode) mqEvalMode=[eMode intValue];
    mqEvalMode=kMetaQuestionEvalOnCommit;
    
    // put our array of answers in an ivar
//    metaQuestionAnswers = [pdefMQ objectForKey:META_QUESTION_ANSWERS];
    metaQuestionAnswerCount = [[pdefMQ objectForKey:META_QUESTION_ANSWERS] count];
    
    if([pdefMQ objectForKey:META_QUESTION_RANDOMISE_ANSWERS])
        metaQuestionRandomizeAnswers = [[pdefMQ objectForKey:META_QUESTION_RANDOMISE_ANSWERS]boolValue];
    else
        metaQuestionRandomizeAnswers = YES;
    
    NSMutableArray *pdefAnswers=[pdefMQ objectForKey:META_QUESTION_ANSWERS];;
    
    if(metaQuestionRandomizeAnswers)
        pdefAnswers=[self randomizeAnswers:pdefAnswers];
    
    // assign our complete and incomplete text to show later
    metaQuestionCompleteText = [pdefMQ objectForKey:META_QUESTION_COMPLETE_TEXT];
    metaQuestionIncompleteText = [pdefMQ objectForKey:META_QUESTION_INCOMPLETE_TEXT];
    
    metaQuestionIncompleteLabel = [CCLabelTTF labelWithString:metaQuestionIncompleteText fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    
    if(currentTool)
        [metaQuestionIncompleteLabel setPosition:ccp(cx, answersY*kMetaIncompleteLabelYOffset)];
    else
        [metaQuestionIncompleteLabel setPosition:ccp(cx, cy*0.25)];
    
    [metaQuestionIncompleteLabel setColor:kMetaQuestionLabelColor];
    [metaQuestionIncompleteLabel setVisible:NO];
    [metaQuestionLayer addChild:metaQuestionIncompleteLabel];
    
    // render answer labels and buttons for each answer
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        NSMutableDictionary *a=[NSMutableDictionary dictionaryWithDictionary:[pdefAnswers objectAtIndex:i]];
        [metaQuestionAnswers addObject:a];
        
        CCSprite *answerBtn;
        CCLabelTTF *answerLabel = [CCLabelTTF labelWithString:@"" fontName:@"Chango" fontSize:16.0f];
        
        // sort out the labels and buttons if there's an answer text
        if([[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT])
        {
            // sort out the buttons
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")];
            
            // then the answer label
            NSString *raw=[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT];
            
            //reading this value directly causes issue #161 - in which the string is no longer a string post copy, so forcing it through a string formatter back to a string
            NSString *answerLabelString=[NSString stringWithFormat:@"%@", raw];
            
            [answerLabel setString:answerLabelString];
            NSLog(@"before answerLabelString: %@", answerLabelString);
            
            if(answerLabelString.length>9)
                [answerLabel setFontSize:16.0f];
            else
                [answerLabel setFontSize:22.0f];
        }
        // there should never be both an answer text and custom sprite defined - so if no answer text, only render the SPRITE_FILENAME
        else
        {
            // sort out the button with a custom sprite 
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[metaQuestionAnswers objectAtIndex:i] objectForKey:SPRITE_FILENAME])];
        }
        
        // render buttons
        float sectionW=lx / metaQuestionAnswerCount;
        
        [answerBtn setPosition:ccp((i+0.5) * sectionW, answersY)];
        [answerBtn setTag:3];
        //[answerBtn setScale:0.5f];
        [answerBtn setOpacity:0];
        [metaQuestionLayer addChild:answerBtn];
        [metaQuestionAnswerButtons addObject:answerBtn];
        
        
        // check for text, render if nesc
        if(![answerLabel.string isEqualToString:@""])
        {
            [answerLabel setPosition:ccp((i+0.5) * sectionW, answersY)];
            [answerLabel setColor:kMetaAnswerLabelColorSelected];
            [answerLabel setOpacity:0];
            [answerLabel setTag: 3];
            [metaQuestionLayer addChild:answerLabel];
            [metaQuestionAnswerLabels addObject:answerLabel];
        }
        
        // set a new value in the array so we can see that it's not currently selected
        [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
    }
    
    // if eval mode is commit, render a commit button
    if(mqEvalMode==kMetaQuestionEvalOnCommit)
    {
        commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Enabled.png")];
        commitBtn.position=ccp(2*cx-HD_BUTTON_INSET, 2*cy - 30);
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [metaQuestionLayer addChild:commitBtn z:2];
    }
    else
    {
        commitBtn=nil;
    }
    
}


-(void)tearDownMetaQuestion
{
    [metaQuestionLayer removeAllChildrenWithCleanup:YES];
    
    metaQuestionForThisProblem=NO;
    metaQuestionForceComplete=NO;
}

-(void)checkMetaQuestionTouchesAt:(CGPoint)location andTouchEnd:(BOOL)touchEnd
{
    
    if(isAnimatingIn)
        return;
    
    if (CGRectContainsPoint(kRectButtonCommit, location) && mqEvalMode==kMetaQuestionEvalOnCommit)
    {
        //effective user commit
        [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
        
        [self evalMetaQuestion];
        return;
    }
    if(metaQuestionForThisProblem)
    {
        for(int i=0; i<metaQuestionAnswerCount; i++)
        {
            CCSprite *answerBtn=[metaQuestionAnswerButtons objectAtIndex:i];
            CCLabelTTF *answerLabel=[metaQuestionAnswerLabels objectAtIndex:i];
            
            float aLabelPosXLeft = answerBtn.position.x-((answerBtn.contentSize.width*answerBtn.scale)/2);
            float aLabelPosYleft = answerBtn.position.y-((answerBtn.contentSize.height*answerBtn.scale)/2);
            
            CGRect hitBox = CGRectMake(aLabelPosXLeft, aLabelPosYleft, (answerBtn.contentSize.width*answerBtn.scale), (answerBtn.contentSize.height*answerBtn.scale));
            // create a dynamic hitbox
            if(CGRectContainsPoint(hitBox, location))
            {
                // and check its current selected value
                BOOL isSelected=[[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_SELECTED] boolValue];
                
                // then if it's an answer and isn't currently selected
                
                //if(isSelected && touchEnd)
                //{
                    // if this is an auto eval, run the eval now
                //    if(mqAnswerMode==kMetaQuestionAnswerSingle && mqEvalMode==kMetaQuestionEvalAuto)
                //        [self evalMetaQuestion];
                //}
                
                if(!isSelected && !touchEnd)
                {
                    // the user has changed their answer (even if they didn't have one before)
                    [loggingService logEvent:BL_PA_MQ_CHANGE_ANSWER
                          withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"selection"]];
                    // check what answer mode we have
                    // if single, we should only only be able to select one so we need to deselect the others and change the selected value
                    if(mqAnswerMode==kMetaQuestionAnswerSingle)
                    {
                        [self deselectAnswersExcept:i];
                        
                        
                    }
                    
                    // otherwise we can select multiple
                    else if(mqAnswerMode==kMetaQuestionAnswerMulti)
                    {
                        [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-button-selected.png")]];
                        [answerLabel setColor:kMetaAnswerLabelColorSelected];
                        //                        [answerBtn setColor:kMetaQuestionButtonSelected];
                        [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
                    }
                    return;
                }
                else if(isSelected && !touchEnd)
                {
                    // return to full button colour and set the dictionary selected value to no
                    [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")]];
                    [answerLabel setColor:kMetaAnswerLabelColorDeselected];
                    //                    [answerBtn setColor:kMetaQuestionButtonDeselected];
                    [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
                }
            }
            else
            {
                if(mqAnswerMode==kMetaQuestionAnswerSingle && !touchEnd)
                {
                    [self deselectAnswersExcept:-1];
                }
            }
            
        }
    }
    
    return;
    
}

-(void)evalMetaQuestion
{
    if(metaQuestionForThisProblem)
    {
        
        
        int countRequired=0;
        int countFound=0;
        int countSelected=0;
        
        for(int i=0; i<metaQuestionAnswerCount; i++)
        {
            // check whether the hit answer is an answer
            BOOL isAnswer=[[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_VALUE] boolValue];
            
            // and check its current selected value
            BOOL isSelected=[[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_SELECTED] boolValue];
            
            // check current iteration is an answer and is selected
            if(isAnswer)
            {
                countRequired++;
            }
            if(isSelected)
            {
                countSelected++;
            }
            // if it's an answer and selected then it's been found by the user
            if(isAnswer && isSelected)
            {
                countFound++;
            }
        }
        
        
        
        if(countRequired==countFound && countFound==countSelected)
        {
            [self doWinning];
        }
        else
        {
            [self doIncomplete];
        }
        
    }
}
-(void)deselectAnswersExcept:(int)answerNumber
{
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        CCSprite *answerBtn=[metaQuestionAnswerButtons objectAtIndex:i];
        CCLabelTTF *answerLabel=[metaQuestionAnswerLabels objectAtIndex:i];
        if(i == answerNumber)
        {
            NSLog(@"answer %d selected", answerNumber);
            [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-button-selected.png")]];
            [answerLabel setColor:kMetaAnswerLabelColorSelected];
//            [answerBtn setColor:kMetaQuestionButtonSelected];
            [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
        }
        else
        {
            NSLog(@"answer %d deselected", answerNumber);
            [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")]];
            [answerLabel setColor:kMetaAnswerLabelColorDeselected];
//            [answerBtn setColor:kMetaQuestionButtonDeselected];
            [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
        }
    }
}
-(void)doWinning
{
    timeBeforeUserInteraction=kDisableInteractionTime;
    isAnimatingIn=YES;
    [loggingService logEvent:BL_PA_SUCCESS withAdditionalData:nil];
    
    if(metaQuestionForThisProblem)
    {
        [self removeMetaQuestionButtons];
        metaQuestionForceComplete=YES;
    }
    [self showProblemCompleteMessage];
    currentTool.ProblemComplete=YES;
}
-(void)doIncomplete
{   
    [loggingService logEvent:BL_PA_FAIL withAdditionalData:nil];
    [self showProblemIncompleteMessage];
    //[self deselectAnswersExcept:-1];
}
-(void)removeMetaQuestionButtons
{
    for(int i=0;i<metaQuestionAnswerLabels.count;i++)
    {
        [metaQuestionLayer removeChild:[metaQuestionAnswerLabels objectAtIndex:i] cleanup:YES];
    } 
    for(int i=0;i<metaQuestionAnswerButtons.count;i++)
    {
        [metaQuestionLayer removeChild:[metaQuestionAnswerButtons objectAtIndex:i] cleanup:YES];
    } 
    
}

#pragma mark - number picker

-(void)setupNumberPicker:(NSDictionary *)pdefNP
{
    numberPickerForThisProblem=YES;
    shownProblemStatusFor=0;
    
    float npOriginX=[[pdefNP objectForKey:PICKER_ORIGIN_X]floatValue];
    float npOriginY=[[pdefNP objectForKey:PICKER_ORIGIN_Y]floatValue];
    
    BOOL npShowDropbox=[[pdefNP objectForKey:SHOW_DROPBOX]boolValue];
    
    numberPickerType=[[pdefNP objectForKey:PICKER_LAYOUT]intValue];
    numberPickerEvalMode=[[pdefNP objectForKey:EVAL_MODE]intValue];
    animatePickedButtons=[[pdefNP objectForKey:ANIMATE_FROM_PICKER]boolValue];
    
    npEval=[[pdefNP objectForKey:EVAL_VALUE]floatValue];
    
    numberPickerEvalMode=[[pdefNP objectForKey:PICKER_EVAL_MODE]intValue];
    
    if([pdefNP objectForKey:MAX_NUMBERS])
        npMaxNoInDropbox=[[pdefNP objectForKey:MAX_NUMBERS]intValue];
    else
        npMaxNoInDropbox=4;

    numberPickerButtons=[[NSMutableArray alloc]init];
    numberPickedSelection=[[NSMutableArray alloc]init];
    numberPickedValue=[[NSMutableArray alloc]init];
        
    nPicker=[[CCNode alloc]init];
    [nPicker setPosition:ccp(npOriginX,npOriginY)];
    
    numberPickerLayer=[[CCLayer alloc]init];
    [self addChild:numberPickerLayer z:2];
    [numberPickerLayer addChild:nPicker];
    
    [self setProblemDescription: [pdefNP objectForKey:NUMBER_PICKER_DESCRIPTION]];
    
    //[numberPickerLayer addChild:problemDescLabel];

    // if we have the dropbox defined, then we need to set it up here
    npDropbox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberpicker/np_dropbox.png")];
    [npDropbox setPosition:ccp(cx,cy+50)];
    [numberPickerLayer addChild:npDropbox z:0];
    if(!npShowDropbox)[npDropbox setVisible:NO];
    
    // then continue and make our awesome picker dood
    if(numberPickerType==kNumberPickerCalc)
    {
        int h=0;
        
        for(int i=0;i<3;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45+(i*75), 265)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
        }
        h=0;
        for(int i=3;i<6;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45+(h*75), 190)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }        
        h=0;
        for(int i=6;i<9;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45+(h*75), 115)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }
        h=0;
        for(int i=9;i<11;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45+(h*75), 40)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }
        
    }
    else if(numberPickerType==kNumberPickerSingleLine)
    {
        for(int i=0;i<11;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45+(i*75), 40)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            
        }
    }
    else if(numberPickerType==kNumberPickerDoubleLineHoriz)
    {
        for (int i=0;i<6;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45+(i*75), 115)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
        }
        
        int h=0;
        for (int i=6;i<11;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45+(h*75), 40)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }
    }
    else if(numberPickerType==kNumberPickerDoubleColumnVert)
    {
        for (int i=0;i<6;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(45, 415-(i*75))];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
        }
        int h=0;
        for (int i=6;i<11;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(120, 415-(h*75))];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }    
    }
    
    // create a picker bounding box so we can drag items back off to it later
    pickerBox=CGRectNull;
    
    for (int i=0; i<[numberPickerButtons count];i++)
    {
        CCSprite *s=[numberPickerButtons objectAtIndex:i];
        pickerBox=CGRectUnion(pickerBox, s.boundingBox);
    }
    
    // if eval mode is commit, render a commit button
    if(numberPickerEvalMode==kNumberPickerEvalOnCommit)
    {
        commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Enabled.png")];
        commitBtn.position=ccp(2*cx-HD_BUTTON_INSET, 2*cy - 30);
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [metaQuestionLayer addChild:commitBtn z:2];
    }
    else
    {
        commitBtn=nil;
    }
}

-(void)checkNumberPickerTouches:(CGPoint)location
{
    if(isAnimatingIn)return;
    
    CGPoint origloc=location;
    location=[nPicker convertToNodeSpace:location];
    timeSinceInteractionOrShakeNP=0.0f;
    
    if(numberPickerEvalMode==kNumberPickerEvalOnCommit)
    {
        if(CGRectContainsPoint(kRectButtonCommit, origloc))
        {
            [self playAudioPress];
            
            //effective user commit of number picker
            [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
            
            [self evalNumberPicker];
        }
    }
    // if we haven't met our max number on the number picker then carry on adding more
    if([numberPickedSelection count] <npMaxNoInDropbox) {
        for(int i=0;i<[numberPickerButtons count];i++)
        {
            if(i==10)
            {
                for(NSNumber *n in numberPickedValue)
                {
                    if([n intValue]==10)return;
                }
            }
            // check each of the buttons to see if it was them that were hit
            CCSprite *s=[numberPickerButtons objectAtIndex:i];

            if(CGRectContainsPoint(s.boundingBox, location))
            {
                hasUsedNumber=YES;
                //a valid click?
                [self playAudioPress];
                
                CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
                [numberPickerLayer addChild:curSprite];
                
                // log pickup from register/dropbox
                [loggingService logEvent:BL_PA_NP_NUMBER_FROM_PICKER
                    withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"number"]];
                
                // check if we're animating our buttons or fading them in
                if(animatePickedButtons) {
                    // and set the position/actions
                    [curSprite setPosition:[nPicker convertToWorldSpace:s.position]];                
                    [curSprite runAction:[CCMoveTo actionWithDuration:kNumberPickerNumberAnimateInTime position:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/kNumberPickerSpacingFromDropboxEdge)+([numberPickedSelection count]*75),cy+50)]];
                }
                else {
                    [curSprite setPosition:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/kNumberPickerSpacingFromDropboxEdge)+([numberPickedSelection count]*75),cy+50)];                
                    [curSprite runAction:[CCFadeIn actionWithDuration:kNumberPickerNumberFadeInTime]];

                }
                
                // then add them to our selection and value arrays
                [numberPickedSelection addObject:curSprite];
                [numberPickedValue addObject:[NSNumber numberWithInt:i]];
                        
                
                return;
            }
        }
    }
    for(int i=0;i<[numberPickedSelection count];i++)
    {
        CCSprite *s=[numberPickedSelection objectAtIndex:i];
        if(CGRectContainsPoint(s.boundingBox, origloc))
        {
            [self playAudioPress];
            [loggingService logEvent:BL_PA_NP_NUMBER_FROM_REGISTER
                withAdditionalData:[NSDictionary dictionaryWithObject:[numberPickedValue objectAtIndex:[numberPickedSelection indexOfObject:s]]
                                                               forKey:@"number"]];
            npMove=s;
            npMoveStartPos=npMove.position;
            return;
        }
    }
    
    
}

-(void)checkNumberPickerTouchOnRegister:(CGPoint)location
{
    for(int i=0;i<[numberPickedSelection count];i++)
    {
        CCSprite *s=[numberPickedSelection objectAtIndex:i];
        if(s==npMove||s==npLastMoved)continue;
        if(CGRectContainsPoint(s.boundingBox, location))
        {
            NSLog(@"hit block index %d, index of moving block %d", i, [numberPickedSelection indexOfObject:npMove]);
            // log pickup from register/dropbox
            [loggingService logEvent:BL_PA_NP_NUMBER_FROM_REGISTER
                withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"number"]];
            
            CCSprite *repSprite=[numberPickedSelection objectAtIndex:i];
            [repSprite runAction:[CCMoveTo actionWithDuration:0.2 position:npMoveStartPos]];
            npMoveStartPos=repSprite.position;
            npLastMoved=s;
            
            NSLog(@"s position %@, repsprite pos %@", NSStringFromCGPoint(s.position), NSStringFromCGPoint(repSprite.position));
            
            int obValue=[[numberPickedValue objectAtIndex:[numberPickedSelection indexOfObject:npMove]]intValue];
            [numberPickedValue removeObjectAtIndex:[numberPickedSelection indexOfObject:npMove]];
            [numberPickedSelection removeObject:npMove];
            [numberPickedValue insertObject:[NSNumber numberWithInt:obValue] atIndex:i];
            [numberPickedSelection insertObject:npMove atIndex:i];
            
            //[repSprite runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/1.25)+([numberPickedSelection count]*55),cy+50)
            
        }
    }
    
    if(!hasMovedNumber) hasMovedNumber=YES;
    // TODO: moveNumber isn't declared - what is it? Following was commented out b/c poor performance with CBM
    // N.B. if after restoration performance is still poor, we can try having certain event types not immediately written to disk
    /*    [loggingService logEvent:BL_PA_NP_NUMBER_MOVE 
     withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:moveNumber] forKey:@"number"]];
     */  
    npMove.position=location;

}

-(void)evalNumberPicker
{
    NSString *strEval=@"";
    
    for (int i=0;i<[numberPickedValue count];i++)
    {
        NSNumber *thisNo=[numberPickedValue objectAtIndex:i];
        int iThisNo=[thisNo intValue];
        NSString *strThisNo;
        
        if(iThisNo==10)strThisNo=@".";
        else strThisNo=[NSString stringWithFormat:@"%d", iThisNo];
        //strEval=[NSString stringWithFormat:@"%d", iThisNo];
        
        strEval=[NSString stringWithFormat:@"%@%@", strEval, strThisNo];
        
        NSLog(@"eval %@", strEval);
    }
    
    float onDropbox=[strEval floatValue];
    if(onDropbox==npEval)
        [self doWinning];
    else
        [self doIncomplete];
}

-(void)reorderNumberPickerSelections
{
    for(int i=0;i<[numberPickedSelection count];i++)
    {
        CCSprite *s=[numberPickedSelection objectAtIndex:i];
        NSLog(@"sprite %d position %@", i, NSStringFromCGPoint(s.position));
        [s setPosition:ccp(cx-(npDropbox.contentSize.width/2)+(s.contentSize.width/kNumberPickerSpacingFromDropboxEdge)+(i*75),cy+50)];

    }
}
-(void)tearDownNumberPicker
{
    [numberPickerLayer removeAllChildrenWithCleanup:YES];
    numberPickerForThisProblem=NO;
    [numberPickerLayer release];
    numberPickerLayer=nil;
}

- (void)checkUserCommit
{
    //effective user commit
    [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
    
    [currentTool evalProblem];
    
    if(currentTool.ProblemComplete)
    {
        [self playAudioFlourish];
        
        timeBeforeUserInteraction=kDisableInteractionTime;
    }
    else {
        [self playAudioPress];
        
        //check commit threshold for insertion
        AppController *ac=(AppController*)[UIApplication sharedApplication].delegate;
        
        //only assess triggers if the insertion mode is enabled, and if we're at the episode head (e.g. don't nest insertions)
        if([(NSNumber*)[ac.AdplineSettings objectForKey:@"USE_INSERTERS"] boolValue] && contentService.isUserAtEpisodeHead && ![contentService isUsingTestPipeline])
        {
            //increment the number of commits
            commitCount++;
            
            //see if the number of commits is past the threshold (threshold of 1 means the 2nd incorrect commit will bail it)
            int threshold=[[ac.AdplineSettings objectForKey:@"TRIGGER_COMMIT_INCORRECT_THRESHOLD"] intValue];
            if(commitCount>threshold)
            {
                if(triggerData)[triggerData release];
                
                //create the trigger data -- passed for contextual ref to what caused this insertion trigger
                triggerData=@{ @"TRIGGER_TYPE" : @"COMMIT_THRESHOLD", @"COMMIT_COUNT" : [NSNumber numberWithInt:commitCount] };
                
                [triggerData retain];
                
                //we'll skip this problem
                adpSkipProblemAndInsert=YES;
                
                //reset the commit count trigger
                commitCount=0;
            }
        }
    }
}

#pragma mark - problem description

-(void)setProblemDescription:(NSString*)descString
{
    if(skipNextDescDraw)
    {
        skipNextDescDraw=NO;
        return;
    }
    
    //always re-create the game world
    if(descGw)
    {
        [descGw release];
        descGw=nil;
    }
    
    descGw=[[SGGameWorld alloc] initWithGameScene:self];
    descGw.Blackboard.inProblemSetup=YES;
    
    descGw.Blackboard.RenderLayer = btxeDescLayer;
    
    //create row
    id<Container, Bounding, Parser, FadeIn> row=[[SGBtxeRow alloc] initWithGameWorld:descGw andRenderLayer:btxeDescLayer];
    row.position=ccp(cx, (cy*2) - 80);
    
    if(descString.length<5)
    {
        //this can't have a <b:t> at the begining
        
        //assume the string needs wrapping in b:t
        descString=[NSString stringWithFormat:@"<b:t>%@</b:t>", descString];
    }
    else if([[descString substringToIndex:5] isEqualToString:@"<b:t>"])
    {
        //doesn't need wrapping
    }
    else
    {
        //assume the string needs wrapping in b:t
        descString=[NSString stringWithFormat:@"<b:t>%@</b:t>", descString];
    }

    
    [row parseXML:descString];
    [row setupDraw];
    
    [row fadeInElementsFrom:1.0f andIncrement:0.1f];
    
    descGw.Blackboard.inProblemSetup=NO;
}

-(void)setProblemDescriptionVisible:(BOOL)visible
{
    //hide everything int he btxe gw
}

//-(void)setProblemDescription:(NSString*)descString
//{
//    if(!problemDescLabel)
//    {
//        problemDescLabel=[CCLabelTTF labelWithString:descString dimensions:CGSizeMake(lx*kLabelTitleXMarginProp, cy) alignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeWordWrap fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
//        [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
//        [problemDescLabel setTag:3];
//        [problemDescLabel setOpacity:0];
//        [problemDefLayer addChild:problemDescLabel];
//    }
//    else {
//        [problemDescLabel setString:descString];
//
//        //assume it should be visible
//        problemDescLabel.visible=YES;
//    }
//}

//-(void)setProblemDescriptionVisible:(BOOL)visible
//{
//    if(problemDescLabel) [problemDescLabel setVisible:visible];
//}


#pragma mark - touch handling

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [loggingService.touchLogger logTouches:touches];
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;

    //testing block for stepping between tool positions
//    if(animPos==0)
//    {
//        animPos++;
//        [self moveToTool1:0];
//    }
//    
//    else if(animPos==1)
//    {
//        animPos++;
//        [self moveToTool2:0];
//    }
//    else if(animPos==2)
//    {
//        animPos++;
//        [self moveToTool3:0];
//    }
//    else if (animPos==3) {
//        animPos=0;
//        [self moveToTool0:0];
//    }
    if(isPaused||autoMoveToNextProblem||isAnimatingIn)
    {
        return;
    }
    
    if(metaQuestionForThisProblem)
        [self checkMetaQuestionTouchesAt:location andTouchEnd:NO];

    else if(numberPickerForThisProblem)
        [self checkNumberPickerTouches:location];
    
    // TODO: This should be made proportional
    
    if (CGRectContainsPoint(kRectButtonCommit, location) && evalMode==kProblemEvalOnCommit && !metaQuestionForThisProblem && !numberPickerForThisProblem && !isAnimatingIn)
    {
        //user pressed commit button
        [self checkUserCommit];
    }
    if (location.x < 100 && location.y > 688 && !isPaused)
    {
        [self showPauseMenu];
        return;
    }
    
    [currentTool ccTouchesBegan:touches withEvent:event];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [loggingService.touchLogger logTouches:touches];
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if(isPaused||autoMoveToNextProblem||isAnimatingIn)
    {
        return;
    } 
    
    if(npMove && numberPickerForThisProblem)[self checkNumberPickerTouchOnRegister:location];
    
    //pinch handling
    if([touches count]>1)
    {
        UITouch *t1=[[touches allObjects] objectAtIndex:0];
        UITouch *t2=[[touches allObjects] objectAtIndex:1];
        
        CGPoint t1a=[[CCDirector sharedDirector] convertToGL:[t1 previousLocationInView:t1.view]];
        CGPoint t1b=[[CCDirector sharedDirector] convertToGL:[t1 locationInView:t1.view]];
        CGPoint t2a=[[CCDirector sharedDirector] convertToGL:[t2 previousLocationInView:t2.view]];
        CGPoint t2b=[[CCDirector sharedDirector] convertToGL:[t2 locationInView:t2.view]];
        
        float da=[BLMath DistanceBetween:t1a and:t2a];
        float db=[BLMath DistanceBetween:t1b and:t2b];
        
        float scaleChange=db-da;
        
        
        scale+=(scaleChange / cx);
        
        [loggingService logEvent:BL_PA_TH_PINCH withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:scale] forKey:@"scale"]];
        
        if(currentTool.PassThruScaling) [currentTool handlePassThruScaling:scale];
        else {
            if(scale<currentTool.ScaleMin) scale=currentTool.ScaleMin;
            if(scale>currentTool.ScaleMax) scale=currentTool.ScaleMax;
            
            [toolBackLayer setScale:scale];
            [toolForeLayer setScale:scale];
        }
        
        //NSLog(@"scale: %f", scale);
    }
    else {
        [currentTool ccTouchesMoved:touches withEvent:event];
    }
    

}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [loggingService.touchLogger logTouches:touches];
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    // if we're paused - check if any menu options were valid.
    // touches ended event becase otherwise these touches go through to the tool
    if(isPaused||autoMoveToNextProblem||isAnimatingIn)
    {
        [self checkPauseTouches:location];
        return;
    }
    if(metaQuestionForThisProblem)
    {
        [self checkMetaQuestionTouchesAt:location andTouchEnd:YES];
    }
    if(npMove)
    {
        if(hasMovedNumber)
        {
            [loggingService logEvent:BL_PA_NP_NUMBER_MOVE
                  withAdditionalData:[NSDictionary dictionaryWithObject:[numberPickedValue objectAtIndex:[numberPickedSelection indexOfObject:npMove]]
                                                                 forKey:@"number"]];
        }
        
        float distance=[BLMath DistanceBetween:lastTouch and:location];
        //if([BLMath DistanceBetween:myLoc and:hitLoc] <= (kPropXDropProximity*[gameWorld Blackboard].hostLX))
        if(!CGRectContainsPoint(npDropbox.boundingBox, location) || (CGRectContainsPoint(npDropbox.boundingBox, location) && distance<7.0f))
        {
            
            [loggingService logEvent:BL_PA_NP_NUMBER_DELETE
                withAdditionalData:[NSDictionary dictionaryWithObject:[numberPickedValue objectAtIndex:[numberPickedSelection indexOfObject:npMove]]
                                                               forKey:@"number"]];
            
            [numberPickedValue removeObjectAtIndex:[numberPickedSelection indexOfObject:npMove]];
            [numberPickedSelection removeObject:npMove];
            [npMove removeFromParentAndCleanup:YES];
        }
        [self reorderNumberPickerSelections];
        
        // previously removed b/c performance hit. Restored for testing with sans-Couchbase logging
        // N.B. if performance still poor, we can try not writing certain log events to disk immediately
        
        npMove=nil;
        npLastMoved=nil;
        hasMovedNumber=NO;
    }
    
    [currentTool ccTouchesEnded:touches withEvent:event];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [loggingService.touchLogger logTouches:touches];
    
    hasMovedNumber=NO;
    if(npMove)npMove=nil;
    npLastMoved=nil;
    [currentTool ccTouchesCancelled:touches withEvent:event];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(isPaused||autoMoveToNextProblem)
    {
        return NO;
    }  
    return [currentTool ccTouchBegan:touch withEvent:event];
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(isPaused||autoMoveToNextProblem)
    {
        return;
    }  
    [currentTool ccTouchMoved:touch withEvent:event];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(isPaused||autoMoveToNextProblem)
    {
        return;
    }  
    [currentTool ccTouchEnded:touch withEvent:event];
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(npMove)npMove=nil;
    [currentTool ccTouchCancelled:touch withEvent:event];
}

#pragma mark - CCPickerView for number wheel

-(void)setupNumberWheel
{
    if(self.pickerView) return;
    
    self.pickerView = [CCPickerView node];
    pickerView.position = ccp(2*cx-150, 2*cy-150);
    pickerView.dataSource = self;
    pickerView.delegate = self;
    
    [self addChild:self.pickerView z:20];
}

#pragma mark CCPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(CCPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(CCPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    NSInteger numRows = 0;
    
    switch (component) {
        case 0:
            numRows = 10;
            break;
        case 1:
            numRows = 10;
            break;
        case 2:
            numRows = 10;
            break;
        default:
            break;
    }
    
    return numRows;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return kComponentHeight;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView widthForComponent:(NSInteger)component {
    return kComponentWidth;
}

- (NSString *)pickerView:(CCPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"Not used";
}

- (CCNode *)pickerView:(CCPickerView *)pickerView nodeForRow:(NSInteger)row forComponent:(NSInteger)component reusingNode:(CCNode *)node {
    
    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", row]fontName:@"Chango" fontSize:24];
    return l;
    
//    temp.color = ccYELLOW;
//    temp.textureRect = CGRectMake(0, 0, kComponentWidth, kComponentHeight);
//    
//    NSString *rowString = [NSString stringWithFormat:@"%d", row];
//    CCLabelBMFont *label = [CCLabelBMFont labelWithString:rowString fntFile:@"bitmapFont.fnt"];
//    label.position = ccp(kComponentWidth/2, kComponentHeight/2-5);
//    [temp addChild:label];
//    return temp;
    
}

- (void)pickerView:(CCPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    CCLOG(@"didSelect row = %d, component = %d", row, component);
}

- (CGFloat)spaceBetweenComponents:(CCPickerView *)pickerView {
    return kComponentSpacing;
}

- (CGSize)sizeOfPickerView:(CCPickerView *)pickerView {
    CGSize size = CGSizeMake(200, 100);
    
    return size;
}

- (CCNode *)overlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberwheel/3slots.png")];
    return sprite;
}

- (void)onDoneSpinning:(CCPickerView *)pickerView component:(NSInteger)component {
    
    NSLog(@"Component %d stopped spinning.", component);
}


#pragma mark - debug pipeline views

-(void)debugShowPipelineState
{
//    CGRect f=CGRectMake(100, 100, (2*cx)-200, (2*cy)-200);
    CGRect f=CGRectMake(0, 0, lx, ly-30);
    debugWebView=[[UIWebView alloc] initWithFrame:f];
    debugWebView.backgroundColor=[UIColor whiteColor];
    debugWebView.opaque=NO;
    debugWebView.alpha=0.7f;
    
    //get the pipeline state
    NSString *pstate=[contentService debugPipelineString];
    
    [debugWebView loadHTMLString:[NSString stringWithFormat:@"<html><body style='font-family:Courier; color:black'>%@</body></html>", pstate] baseURL:[NSURL URLWithString:@""]];
    
    [[[CCDirector sharedDirector] view] addSubview:debugWebView];
    
    debugShowingPipelineState=YES;
}

-(void)debugHidePipelineState
{
    [debugWebView removeFromSuperview];
    [debugWebView release];
    debugWebView=nil;
    
    debugShowingPipelineState=NO;
}

#pragma mark - tear down

-(void) dealloc
{
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    
    if(currentTool)
    {
        [self removeChild:toolBackLayer cleanup:YES];
        [self removeChild:toolForeLayer cleanup:YES];
        [self removeChild:toolNoScaleLayer cleanup:YES];
        [currentTool release];
        currentTool=nil;
    }
    
    //[pdef release];
    if(metaQuestionAnswers)[metaQuestionAnswers release];
    if(metaQuestionAnswerButtons)[metaQuestionAnswerButtons release];
    if(metaQuestionAnswerLabels)[metaQuestionAnswerLabels release];
    if(numberPickerButtons)[numberPickerButtons release];
    if(numberPickedSelection)[numberPickedSelection release];
    if(numberPickedValue)[numberPickedValue release];
    if(nPicker)[nPicker release];
    
    //this is released and nil referenced in tear down -- but might not hit this on bail from toolhost
    if(numberPickerLayer)[numberPickerLayer release];
    
    if(touchLogPath)[touchLogPath release];
    
    self.DynProblemParser=nil;
    self.PpExpr=nil;
    
    [backgroundLayer release];
    [perstLayer release];
    [animator release];
    [metaQuestionLayer release];
    [problemDefLayer release];
    [pauseLayer release];
    [btxeDescLayer release];
    
    if(triggerData)[triggerData release];
    
    self.Zubi=nil;
    
    //number wheel / picker view
    if(pickerView)[pickerView release];
    
    [super dealloc];
}

@end
