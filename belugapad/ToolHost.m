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
#import "RewardStars.h"
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
#import "DebugViewController.h"
#import "EditPDefViewController.h"
#import "TestFlight.h"
#import "ExprBuilder.h"
#import "LongDivision.h"
#import "LineDrawer.h"


#define HD_HEADER_HEIGHT 65.0f
#define HD_BUTTON_INSET 65.0f
#define TRAY_BUTTON_SPACE 80.0f
#define TRAY_BUTTON_INSET -35.0f
#define HD_SCORE_INSET 40.0f
#define BACKGROUND_MUSIC_FILE_NAME @"/sfx/go/sfx_journey_map_general_background_score.mp3"
#define PAUSE_MENU_BACKGROUND_MUSIC_FILE_NAME @"/sfx/go/sfx_journey_map_general_muffled_background_score_for_pause_menu.mp3"

//CCPickerView
//#define kComponentWidth 54
#define kComponentWidth 71
#define kComponentHeight 62
#define kComponentSpacing 6

#define CORNER_TRAY_POS_X 700.0f
#define CORNER_TRAY_POS_Y 460.0f

@interface ToolHost()
{
    @private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
    
    EditPDefViewController *editPDefViewController;
    BOOL nowEditingPDef;
    CCSprite *unsavedEditsImage;
    
    BOOL isHoldingObject;
    id<MovingInteractive> heldObject;
}
-(void)returnToMap;
@end

@implementation ToolHost

@synthesize Zubi;
@synthesize PpExpr;
@synthesize flagResetProblem;
@synthesize toolCanEval;
@synthesize DynProblemParser;
@synthesize pickerView;
@synthesize CurrentBTXE;
@synthesize thisProblemDescription;

static float kMoveToNextProblemTime=0.5f;
static float kDisableInteractionTime=0.5f;
static float kTimeToHintToolTray=0.0f;

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
        self.touchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        multiplierStage=1;
        scoreMultiplier=1;
        
        [TestFlight passCheckpoint:@"STARTING_TOOLHOST"];
        
        //setup layer sequence
        backgroundLayer=[[CCLayer alloc] init];
        [self addChild:backgroundLayer z:-2];
        perstLayer=[[CCLayer alloc] init];
        [self addChild:perstLayer z:0];
        
        animator=[[LRAnimator alloc] init];
        [animator setBackground:backgroundLayer withCx:cx withCy:cy];
        
        [animator animateBackgroundIn];
        animPos=1;
        

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
        
        
        //add header
        CCSprite *hd=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_HeaderBar_NoPause.png")];
        hd.position=ccp(cx, 2*cy - HD_HEADER_HEIGHT / 2.0f);
        [perstLayer addChild:hd z:3];
        
        [self populatePerstLayer];
        
        pbtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_PauseButton.png")];
        pbtn.position=ccp(HD_BUTTON_INSET, 2*cy - 30);
        pbtn.tag=3;
        pbtn.opacity=0;
        [perstLayer addChild:pbtn z:3];
        
        //add disabled commit
        CCSprite *commdis=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Disabled.png")];
        commdis.position=ccp(2*cx-HD_BUTTON_INSET, 2*cy - 30);
        [perstLayer addChild:commdis z:3];
        
        unsavedEditsImage = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/unsaved-edits.png")];
        unsavedEditsImage.position=ccp(250.0f, 2*cy - HD_HEADER_HEIGHT / 2.0f);
        [perstLayer addChild:unsavedEditsImage z:3];
        unsavedEditsImage.visible = NO;
        
        //dynamic problem parser (persists to end of pipeline)
        DynProblemParser=[[DProblemParser alloc] init];
        
        ac = (AppController*)[[UIApplication sharedApplication] delegate];
        loggingService = ac.loggingService;
        contentService = ac.contentService;
        usersService = ac.usersService;
        
        [ac tearDownUI];
        
        [self scheduleOnce:@selector(gotoFirstProblem:) delay:0.0f];
        //[self gotoNewProblem];
        
        [self schedule:@selector(doUpdateOnTick:) interval:1.0f/60.0f];
        [self schedule:@selector(doUpdateOnSecond:) interval:1.0f];
        [self schedule:@selector(doUpdateOnQuarterSecond:) interval:1.0f/40.0f];
        
        [TestFlight passCheckpoint:@"STARTED_TOOLHOST"];
    
        doPlaySound=YES;
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
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_interaction_feedback_commit_button_shaking.wav")];
}

-(void)stageIntroActions
{
    //TODO tags are currently fixed to 2 phases -- either parse tool tree or pre-populate with design-fixed max
    
    isAnimatingIn=YES;
    
    for (int i=1; i<=3; i++) {
        
        int time=i;
        if(skipNextStagedIntroAnim) time=0;
        timeBeforeUserInteraction=time;
        
        if(toolBackLayer)[self recurseSetIntroFor:toolBackLayer withTime:time forTag:i];
        if(toolForeLayer)[self recurseSetIntroFor:toolForeLayer withTime:time forTag:i];
        if(toolNoScaleLayer)[self recurseSetIntroFor:toolNoScaleLayer withTime:time forTag:i];
        if(metaQuestionLayer)[self recurseSetIntroFor:metaQuestionLayer withTime:time forTag:i];
        if(trayLayerMq)[self recurseSetIntroFor:trayLayerMq withTime:time forTag:i];
        if(descGw.Blackboard.RenderLayer)[self recurseSetIntroFor:descGw.Blackboard.RenderLayer withTime:time forTag:i];
        if(problemDefLayer)[self recurseSetIntroFor:problemDefLayer withTime:time forTag:i];
        if(numberPickerLayer)[self recurseSetIntroFor:numberPickerLayer withTime:time forTag:i];
        if(perstLayer)[self recurseSetIntroFor:perstLayer withTime:time forTag:i];
        
    }
    
    if(timeBeforeUserInteraction>2.0f)timeBeforeUserInteraction=2.0f;
    skipNextStagedIntroAnim=NO;
}

-(void)recurseSetIntroFor:(CCNode*)node withTime:(float)time forTag:(int)tag
{
    
    for (CCNode *cn in [node children]) {
        if([cn tag]==tag && [cn isKindOfClass:[CCSprite class]])
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
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_state_correct_answer.wav")];
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
 
    if(animateQuestionBox)
    {
        timeToQuestionBox+=delta;
        if(timeToQuestionBox>1.0f)
        {
            [self animateQuestionBoxIn];
            animateQuestionBox=NO;
            timeToQuestionBox=0.0f;
        }
    }
    
    if(shownProblemStatusFor>kTimeToShowProblemStatus)
    {
        if(showingProblemComplete)
        {
            [problemComplete runAction:[CCFadeTo actionWithDuration:kTimeToFadeProblemStatus opacity:0]];
            showingProblemComplete=NO;
        }
        if(showingProblemIncomplete)
        {
            [problemIncomplete runAction:[CCFadeTo actionWithDuration:kTimeToFadeProblemStatus opacity:0]];
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
    
    if(delayShowWheel)timeToWheelStart+=delta;
    if(delayShowMeta)timeToMetaStart+=delta;
    
    if(delayShowWheel&&timeToWheelStart>2.0f){
        [self showWheel];
        timeToWheelStart=0.0f;
        delayShowWheel=NO;
    }
    
    if(delayShowMeta&&timeToMetaStart>2.0f){
        [self showMq];
        
        timeToMetaStart=0.0f;
        delayShowMeta=NO;
    }
    
    if(numberPickerForThisProblem||metaQuestionForThisProblem)timeSinceInteractionOrShake+=delta;
    
    if(timeSinceInteractionOrShake>kTimeToHintToolTray)
    {
        if(numberPickerForThisProblem && !hasUsedWheelTray && !hasRunInteractionFeedback && [traybtnWheel numberOfRunningActions]==0){
            [traybtnWheel setZOrder:10];
            [traybtnWheel runAction:[InteractionFeedback dropAndBounceAction]];
            hasRunInteractionFeedback=YES;
        }
        if(metaQuestionForThisProblem && !hasUsedMetaTray && !hasRunInteractionFeedback && [traybtnMq numberOfRunningActions]==0){
            [traybtnMq setZOrder:10];
            [traybtnMq runAction:[InteractionFeedback dropAndBounceAction]];
            hasRunInteractionFeedback=YES;
        }
        
        if(hasRunInteractionFeedback && timeSinceInteractionOrShake>kTimeToHintToolTray+2.0f && [traybtnMq numberOfRunningActions]==0 && [traybtnWheel numberOfRunningActions]==0){
            hasRunInteractionFeedback=NO;
            timeSinceInteractionOrShake=0.0f;
        }
    }
    

    if(CurrentBTXE)
    {
        if(!pickerView){
            [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_Available.png")]];
            [self showWheel];
            [self showCornerTray];
        }
        else
        {
            [(id<Text>)CurrentBTXE setText:[self returnPickerNumber]];
        }
        
    }
    
    if(countUpToJmap)
    {
        if(!hasShownComplete){
            [self doWinning];
            hasShownComplete=YES;
        }
        timeToReturnToJmap+=delta;
        
        if(timeToReturnToJmap>2.9f)
        {
            countUpToJmap=NO;
            [self showCompleteAndReturnToMap];
        }
    }
    
    if(evalShowCommit)[self showHideCommit];
    
    //let tool do updates
    if(!isPaused)[currentTool doUpdateOnTick:delta];
}

-(void)doUpdateOnSecond:(ccTime)delta
{
    if(showMetaQuestionIncomplete) shownMetaQuestionIncompleteFor+=delta;
    
    //do internal mgmt updates
    //don't eval if we're in an auto move to next problem
    
    //if the problem is complete and we aren't already moving to the next one
    if((currentTool.ProblemComplete || metaQuestionForceComplete) && !autoMoveToNextProblem && !hasUpdatedScore)
    {
        autoMoveToNextProblem=YES;
        hasUpdatedScore=YES;
        
        if(!breakOutIntroProblemFK)
            [self incrementScoreAndMultiplier];
        
        moveToNextProblemTime=kMoveToNextProblemTime;
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
    if(!(m==2 || m==4 || m==8 || m==16)) return; // because there isn't a corresponding image in the project to display
    
    if(multiplierBadge)
    {
        [self removeChild:multiplierBadge cleanup:YES];
    }
    
    NSString *bf=[NSString stringWithFormat:@"/images/menu/HR_Multiplier_%d.png", m];
    multiplierBadge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(bf)];
    multiplierBadge.position=ccp(cx-95, 2*cy-multiplierBadge.contentSize.height/1.7);
    [self addChild:multiplierBadge z:4];
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_multiplier_incremented.wav")];
    
    [multiplierBadge runAction:[InteractionFeedback dropAndBounceAction]];
}

-(void)rejectMultiplierButton
{
    if(multiplierBadge)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_multiplier_lost.wav")];
        [multiplierBadge runAction:[InteractionFeedback delaySpinFast]];
        [multiplierBadge runAction:[InteractionFeedback delayMoveOutAndDown]];
    }
}

-(void)resetScoreMultiplier
{
    if(breakOutIntroProblemFK)return;
    scoreMultiplier=1;
    multiplierStage=1;
    hasResetMultiplier=YES;
    
    [self scheduleOnce:@selector(updateScoreLabels) delay:0.5f];
    
    [self rejectMultiplierButton];
}

-(void)scoreProblemSuccess
{
    if(breakOutIntroProblemFK)return;
    
    int newScore = ceil(scoreMultiplier * contentService.pipelineProblemAttemptBaseScore);
    newScore = min(newScore, SCORE_EPISODE_MAX - pipelineScore);
    
    pipelineScore += newScore;
    
    int shards = SCORE_MAX_SHARDS * newScore / contentService.pipelineProblemAttemptMaxScore;
    
    displayPerShard = (int) (newScore / (float)shards);
    
    int rem = newScore - displayPerShard * shards;
    
    //get the remainder on the display score right away
    displayScore += rem;
    
    [Zubi createXPshards:shards fromLocation:ccp(cx, cy) withCallback:@selector(incrementDisplayScore:) fromCaller:(NSObject*)self];
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_state_points_accumulating.wav")];
}


-(void)updateScoreLabels
{
    //[multiplierLabel setString:[NSString stringWithFormat:@"(%dx)", (int)scoreMultiplier]];
    
    //show correct multiplier
    if(multiplierBadge)[perstLayer removeChild:multiplierBadge cleanup:YES];
    
    int showScore=displayScore;
    if(showScore>999999) showScore=999999;
    if(showScore<0) showScore=0;
    
    //this isn't going to do this ultiamtely -- it'll be based on shards
    [scoreLabel setString:[NSString stringWithFormat:@"%d", showScore]];
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

-(void) debugSkipToProblem:(int)skipby
{
    //effectively a skipping version of gotoNewProblem, ignores triggers, little exception / flow handling
    [self tearDownProblemDef];
    self.PpExpr=nil;
    
    hasResetMultiplier=NO;
    
    //manually reset any intro problem state
    breakOutIntroProblemFK=nil;
    breakOutIntroProblemHasLoaded=NO;
    
    [self resetTriggerData];
    
    [contentService gotoNextProblemInPipelineWithSkip:skipby];
    
    if(contentService.currentPDef)
    {
        [self loadProblem];
    }
    else
    {
        [self returnToMap];
    }
}

-(void)resetTriggerData
{
    commitCount=0;
}

-(void) gotoNewProblem
{
    [self tearDownProblemDef];
    self.PpExpr = nil;
    
    
    //this problem will award multiplier if not subsequently reset
    hasResetMultiplier=NO;
    
    
    if(adpSkipProblemAndInsert)
    {
        //user failed problem past commit threshold, indicate as such, insert problems and then progress
        //todo: contentservice fail problem call
        
        //request that we insert problems in the pipeline
        [contentService adaptPipelineByInsertingWithTriggerData:triggerData];
        
        adpSkipProblemAndInsert=NO;
    }
    
    //reset trigger data -- a fresh view on user progress in this problem
    [self resetTriggerData];
    
    if(!breakOutIntroProblemFK)
    {
        //this is the goto next problem bit -- actually next problem in episode, as there's no effetive success/fail thing
        [contentService gotoNextProblemInPipeline];
        
        
        //check that the content service found a pdef (this will be the raw dynamic one)
        if(contentService.currentPDef)
        {
            [self loadProblem];
        }
        else
        {
            countUpToJmap=YES;
        }
    }
    else
    {
        //just load the next problem -- which will actually be the last problem before the intro problem (e.g. the last real problem encountered)
        [self loadProblem];
    }
    
        
    autoMoveToNextProblem=NO;
}

-(void)showCompleteAndReturnToMap
{
    [TestFlight passCheckpoint:@"PIPELINE_COMPLETE_LEAVING_TO_JMAP"];
    
    //no more problems in this sequence, bail to menu
    
    //todo: completion shouldn't be assumed here -- we can get here by progressing into an inserter that produces no viable insertions
    
    //assume completion
    [loggingService logEvent:BL_EP_END withAdditionalData:@{ @"score": @(pipelineScore) }];
    
    contentService.fullRedraw=YES;
    contentService.lightUpProgressFromLastNode=YES;
    
    [self stopAllSpeaking];
    [contentService quitPipelineTracking];
    [self unscheduleAllSelectors];
    
    if(ac.IsIpad1)
    {
        [[CCDirector sharedDirector] replaceScene:[RewardStars scene]];
    }
    else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:0.5f scene:[RewardStars scene]]];
    }
    
}

-(NSDictionary*)loadIntroProblemFromFK
{
    NSString *problemPath=[NSString stringWithFormat:@"/intro-problems/%@.plist", breakOutIntroProblemFK];
    problemPath=BUNDLE_FULL_PATH(problemPath);
    
    return [NSDictionary dictionaryWithContentsOfFile:problemPath];
}

-(void) loadProblem
{
    hasUpdatedScore=NO;
    trayWheelShowing=NO;
    trayCornerShowing=NO;
    hasTrayWheel=NO;
    numberPickerForThisProblem=NO;
    metaQuestionForThisProblem=NO;
    self.thisProblemDescription=nil;
    introProblemSprite=nil;

    
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
    
    if(multiplierStage>0 && breakOutIntroProblemFK)
        [multiplierBadge setVisible:NO];
    
    if(breakOutIntroProblemFK && !breakOutIntroProblemHasLoaded)
    {
        NSLog(@"loading breakout problem %@", breakOutIntroProblemFK);
        
        //do not query content service, just load a static intro problem via dynamic parser
        NSDictionary *introProblem=[self loadIntroProblemFromFK];
        
        [self.DynProblemParser startNewProblemWithPDef:introProblem];
        
        pdef=[self.DynProblemParser createStaticPdefFromPdef:introProblem];
        
        //we've loaded this now, indicate as such so we don't get stuck in a loop
        breakOutIntroProblemHasLoaded=YES;
        
        introProblemSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_tutorial.png")];
        [introProblemSprite setPosition:ccp(cx,((cy*2)-introProblemSprite.contentSize.height/2))];
        [problemDefLayer addChild:introProblemSprite];
        [introProblemSprite runAction:[InteractionFeedback shakeAction]];
    }
    else
    {
        if(breakOutIntroProblemFK && breakOutIntroProblemHasLoaded)
        {
            [usersService addEncounterWithFeatureKey:breakOutIntroProblemFK date:[NSDate date]];

            if(multiplierStage>0)
                [multiplierBadge setVisible:YES];
            //reset state -- we've loaded, play and logged the breakout problem
            breakOutIntroProblemFK=nil;
            breakOutIntroProblemHasLoaded=NO;
        }
        
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
    }
    
    
    NSString *toolKey=[pdef objectForKey:TOOL_KEY];
    
    
    TFLog(@"starting a %@ problem", toolKey);
    
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
    
    
    //purge potential feature key cache
    [usersService purgePotentialFeatureKeys];
    
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
    
    unsavedEditsImage.visible = contentService.currentProblem && contentService.currentProblem.hasUnsavedEdits;
    
    //this will overrider above np/mq and possible th setup
    [self setupToolTrays:pdef];
    [self setupFollowParticle];
    
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
    
    NSString *breakOutToFK=[usersService shouldInsertWhatFeatureKey];
    //if were not already in a breakout, break out
    if(!breakOutIntroProblemFK && breakOutToFK && !contentService.isUsingTestPipeline)
    {
        NSLog(@"breaking out into intro problem with key %@", breakOutToFK);
        
        [loggingService logEvent:BL_PA_POSTPONE_FOR_INTRO_PROBLEM withAdditionalData:nil];
        
        //re-load with an FK problem, then resume on episode / pipeline
        breakOutIntroProblemFK=breakOutToFK;
        breakOutIntroProblemHasLoaded=NO;
        
        [self tearDownProblemDef];
        [self loadProblem];
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
    }
    else {
        isGlossaryMock=NO;
        if(glossary1)[self removeChild:glossary1 cleanup:YES];
        if(glossary2)[self removeChild:glossary2 cleanup:YES];
        if(glossaryPopup)[self removeChild:glossaryPopup cleanup:YES];
    }
    
    //hide pause again
    pbtn.opacity=0;
    
    [self stageIntroActions];

    [self.Zubi dumpXP];
    
    //zubi is fixed off by default
    if ([pdef objectForKey:@"SHOW_ZUBI"]) {
        [self.Zubi showZubi];
    }
    else {
        [self.Zubi hideZubi];
    }
    
    evalShowCommit=YES;
    
    if(!thisProblemDescription)
        self.thisProblemDescription=[descRow returnRowStringForSpeech];
    
    [self readOutProblemDescription];
    
    [[SimpleAudioEngine sharedEngine]playBackgroundMusic:BUNDLE_FULL_PATH(BACKGROUND_MUSIC_FILE_NAME) loop:YES];
}
-(void)addCommitButton
{
    if(evalMode==kProblemEvalOnCommit||mqEvalMode==kMetaQuestionEvalOnCommit||numberPickerEvalMode==kNumberPickerEvalOnCommit)
    {
        commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Enabled.png")];
        commitBtn.position=ccp(2*cx-HD_BUTTON_INSET, 2*cy - 30);
        //[commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [problemDefLayer addChild:commitBtn z:2];
        
        if(metaQuestionForThisProblem||numberPickerForThisProblem)
            [commitBtn setVisible:NO];
        else
            [commitBtn setVisible:YES];
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
-(void)addMetaHintArrow
{
    metaArrow=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_MQ_Tip.png")];
    [metaArrow setPosition:ccp(lx-124,2*cy-30)];
//    [metaArrow setTag:3];
//    [metaArrow setOpacity:0];
    [metaArrow setVisible:NO];
    [problemDefLayer addChild:metaArrow z:10];
}
-(void)setupProblemOnToolHost:(NSDictionary *)curpdef
{
    NSNumber *eMode=[curpdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    else if(eMode && numberPickerForThisProblem) evalMode=kProblemEvalOnCommit;
    else evalMode=kProblemEvalAuto;
    
    NSString *labelDesc=[self.DynProblemParser parseStringFromValueWithKey:PROBLEM_DESCRIPTION inDef:curpdef];
    

    [self setProblemDescription:labelDesc];
    
    [self addCommitButton];
}

-(void)readOutProblemDescriptionAndForce:(BOOL)forceRead
{
    if(ac.IsMuted && !forceRead)return;
    
    NSString *readString=[[thisProblemDescription copy] autorelease];
    
    [ac speakString:readString];
}

-(void)readOutProblemDescription
{
    [self readOutProblemDescriptionAndForce:NO];
}

-(void)stopAllSpeaking
{
    [ac stopAllSpeaking];
}

-(void)setupToolTrays:(NSDictionary*)withPdef
{
    hasTrayMq=NO;
    hasTrayCalc=NO;
    hasTrayWheel=NO;

    if([withPdef objectForKey:META_QUESTION])
        hasTrayMq=YES;
    else
        hasTrayMq=NO;
    
    if([withPdef objectForKey:ENABLE_CALCULATOR])
        hasTrayCalc=[[withPdef objectForKey:ENABLE_CALCULATOR]boolValue];
    else
        hasTrayCalc=NO;
    
    if([withPdef objectForKey:NUMBER_PICKER])
    {
        NSDictionary *np=[withPdef objectForKey:NUMBER_PICKER];
        
        if([np objectForKey:ENABLE_CALCULATOR])
            hasTrayCalc=[[np objectForKey:ENABLE_CALCULATOR]boolValue];
        else
            hasTrayCalc=NO;
        
        if([np objectForKey:ENABLE_WHEEL])
            hasTrayWheel=[[np objectForKey:ENABLE_WHEEL]boolValue];
        else
            hasTrayWheel=YES;
    }
    
    
    
    trayLayerCalc=nil;
    trayLayerPad=nil;
    trayLayerWheel=nil;
    
//    if(hasTrayCalc)
//        traybtnCalc=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Calculator_Available.png")];
//    else
//        traybtnCalc=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Calculator_NotAvailable.png")];
//    [problemDefLayer addChild:traybtnCalc z:2];
//    traybtnCalc.opacity=0;
//    traybtnCalc.tag=3;

    if(hasTrayMq)
        traybtnMq=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_MetaQuestion_Available.png")];
    else
        traybtnMq=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_MetaQuestion_NotAvailable.png")];
    [problemDefLayer addChild:traybtnMq z:2];
    traybtnMq.opacity=0;
    traybtnMq.tag=3;

    if(hasTrayWheel)
        traybtnWheel=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_Available.png")];
    else
        traybtnWheel=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_NotAvailable.png")];
    [problemDefLayer addChild:traybtnWheel];
    traybtnWheel.opacity=0;
    traybtnWheel.tag=3;

    traybtnPad=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Notepad_Available.png")];
    [problemDefLayer addChild:traybtnPad];
    traybtnPad.opacity=0;
    traybtnPad.tag=3;
    
    traybtnCalc.position=ccp(2*cx-(2*TRAY_BUTTON_SPACE+TRAY_BUTTON_INSET), 2*cy-30);
    traybtnMq.position=ccp(2*cx-(3*TRAY_BUTTON_SPACE+TRAY_BUTTON_INSET), 2*cy-30);
    traybtnWheel.position=ccp(2*cx-(4*TRAY_BUTTON_SPACE+TRAY_BUTTON_INSET), 2*cy-30);

    traybtnPad.position=ccp(2*cx-(5*TRAY_BUTTON_SPACE+TRAY_BUTTON_INSET), 2*cy-30);

    
}

-(void)setupFollowParticle
{
    followParticle=[CCParticleSystemQuad particleWithFile:@"bubble_trail.plist"];
    [self addChild:followParticle z:10];
    [followParticle setVisible:NO];
    
}

-(void) resetProblem
{
    //if(problemDescLabel)[problemDescLabel removeFromParentAndCleanup:YES];
    
    TFLog(@"resetting problem");
    
    [self tearDownProblemDef];
    
    [self tearDownQuestionTray];
    
    [self tearDownNumberPicker];
    [self tearDownMetaQuestion];
    
    //manually reset any intro problem state
    breakOutIntroProblemFK=nil;
    breakOutIntroProblemHasLoaded=NO;

    if(evalMode==kProblemEvalOnCommit)
    {
        if(commitBtn)[commitBtn removeFromParentAndCleanup:YES];
        commitBtn=nil;
    }
    
    [self resetScoreMultiplier];
    
    //problem's been reset -- we should redraw the btxe
    skipNextDescDraw=NO;
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
    [self tearDownQuestionTray];
    [problemDefLayer removeAllChildrenWithCleanup:YES];
    [btxeDescLayer removeAllChildrenWithCleanup:YES];
    traybtnCalc=nil;
    traybtnMq=nil;
    traybtnWheel=nil;
    traybtnPad=nil;
    commitBtn=nil;
    [descGw release];
    descGw=nil;
    
    //nil pointers to things on there
    problemDescLabel=nil;
    
}

#pragma mark - pause show and touch handling

-(void) showPauseMenu
{
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_pause_tap.wav")];
    [[SimpleAudioEngine sharedEngine]stopBackgroundMusic];
    [[SimpleAudioEngine sharedEngine]playBackgroundMusic:BUNDLE_FULL_PATH(PAUSE_MENU_BACKGROUND_MUSIC_FILE_NAME) loop:YES];
    isPaused = YES;
    
    if(!pauseMenu)
    {
        pauseMenu = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/pause-overlay.png")];
        [pauseMenu setPosition:ccp(cx, cy)];
        [pauseLayer addChild:pauseMenu z:10];
        
        muteBtn = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/pause_sound.png")];
        [muteBtn setPosition:ccp(250,250)];
        [pauseLayer addChild:muteBtn z:20];
        
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
    
    if(pickerView)pickerView.isLocked=YES;
    
    if(contentService.pathToTestDef)
    {
        [pauseTestPathLabel setString:contentService.pathToTestDef];
        NSLog(@"pausing in test problem %@", contentService.pathToTestDef);
    }
    else {
        //just log document id for the problem & pipeline
        NSLog(@"pausing in problem document %@", contentService.currentProblem._id);
    }
    
    [loggingService logEvent:BL_PA_PAUSE withAdditionalData:nil];
}

-(void)hidePauseMenu
{
    [[SimpleAudioEngine sharedEngine]stopBackgroundMusic];
    [[SimpleAudioEngine sharedEngine]playBackgroundMusic:BUNDLE_FULL_PATH(BACKGROUND_MUSIC_FILE_NAME) loop:YES];
    [pauseLayer setVisible:NO];
    isPaused=NO;
    
    if(pickerView)pickerView.isLocked=NO;
}

-(void) checkPauseTouches:(CGPoint)location
{
    if(CGRectContainsPoint(kPauseMenuContinue, location))
    {
        //resume
        [loggingService logEvent:BL_PA_RESUME withAdditionalData:nil];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self hidePauseMenu];
    }
    if(CGRectContainsPoint(kPauseMenuReset, location))
    {
        //reset
        [loggingService logEvent:BL_PA_USER_RESET withAdditionalData:nil];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self resetProblem];
        [self hidePauseMenu];
    }
    if(CGRectContainsPoint(kPauseMenuMenu, location))
    {
        [loggingService logEvent:BL_PA_EXIT_TO_MAP withAdditionalData:nil];
        [loggingService logEvent:BL_EP_END withAdditionalData:@{ @"score": @0 }];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self returnToMap];
    }
    if(CGRectContainsPoint(muteBtn.boundingBox, location))
    {
        if(ac.IsMuted)
        {
            ac.IsMuted=NO;
            [muteBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/menu/pause_sound.png")]];
            
            [[SimpleAudioEngine sharedEngine]playBackgroundMusic:BUNDLE_FULL_PATH(PAUSE_MENU_BACKGROUND_MUSIC_FILE_NAME) loop:YES];
        }
        else
        {
            ac.IsMuted=YES;
            [[SimpleAudioEngine sharedEngine]stopBackgroundMusic];
            [muteBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/menu/pause_mute.png")]];
        }
    }
    //top left tap for edit pdef
    if (!ac.ReleaseMode && !nowEditingPDef && CGRectContainsPoint(commitBtn.boundingBox, location))
    {
        [self editPDef];
    }
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

-(void)returnToMap
{
    if(quittingToMap)return;
    quittingToMap=YES;
    
    [self stopAllSpeaking];
    [TestFlight passCheckpoint:@"QUITTING_TOOLHOST_FOR_JMAP"];
    [contentService quitPipelineTracking];
    [self unscheduleAllSelectors];
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
    evalShowCommit=YES;
    
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
    
    if(!countUpToJmap)
        [blackOverlay runAction:[InteractionFeedback fadeInOutHoldFor:1.0f to:200]];
    else
        [blackOverlay runAction:[CCFadeIn actionWithDuration:1.0f]];
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
    toolCanEval=NO;
    
    if(!trayLayerMq)
    {
        trayLayerMq=[[CCLayer alloc]init];
        [problemDefLayer addChild:trayLayerMq z:2];
        trayLayerMq.visible=NO;
        trayMqShowing=NO;
    }
    
    if(!currentTool)
        delayShowMeta=YES;
    else
        [self addMetaHintArrow];
    

    shownMetaQuestionIncompleteFor=0;
    
    metaQuestionAnswers = [[NSMutableArray alloc] init];
    metaQuestionAnswerButtons = [[NSMutableArray alloc] init];
    metaQuestionAnswerLabels = [[NSMutableArray alloc] init];
    
    float answersY=0.0f;
    
    //float titleY=cy*1.75f;

    
    answersY=cy*1.30;
    
    [self setProblemDescription:[pdefMQ objectForKey:META_QUESTION_TITLE]];
    descGw.Blackboard.inProblemSetup=YES;
    
    // check the answer mode and assign
    NSNumber *aMode=[pdefMQ objectForKey:META_QUESTION_ANSWER_MODE];
    if (aMode) mqAnswerMode=[aMode intValue];
    
    if(mqAnswerMode==kMetaQuestionAnswerSingle)
        [usersService notifyStartingFeatureKey:@"METAQUESTION_ANSWER_MODE_SINGLE"];
    else if(mqAnswerMode==kMetaQuestionAnswerMulti)
        [usersService notifyStartingFeatureKey:@"METAQUESTION_ANSWER_MODE_MULTI"];
    
    // check the eval mode and assign

    mqEvalMode=kMetaQuestionEvalOnCommit;
    [self addCommitButton];
    // put our array of answers in an ivar

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
    
    NSString *mqBar=[NSString stringWithFormat:@"/images/metaquestions/MQ_Bar_%d.png",metaQuestionAnswerCount];
    metaQuestionBanner=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(mqBar)];
    [metaQuestionBanner setPosition:ccp(cx,answersY)];
    [trayLayerMq addChild:metaQuestionBanner z:-2];
    
    // render answer labels and buttons for each answer
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        NSMutableDictionary *a=[NSMutableDictionary dictionaryWithDictionary:[pdefAnswers objectAtIndex:i]];
        [metaQuestionAnswers addObject:a];
        
        CCSprite *answerBtn;
        SGBtxeRow *row=nil;
        NSString *raw=nil;
        NSString *answerLabelString=nil;
        // sort out the labels and buttons if there's an answer text
        if([[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT])
        {
            // sort out the buttons
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")];
            
            // then the answer label
            raw=[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT];
            
            if(raw.length<3)
            {
                //this can't have a <b:t> at the begining
                
                //assume the string needs wrapping in b:t
                raw=[NSString stringWithFormat:@"<b:t>%@</b:t>", raw];
            }
            else if([[raw substringToIndex:3] isEqualToString:@"<b:"])
            {
                //doesn't need wrapping
            }
            else
            {
                //assume the string needs wrapping in b:t
                raw=[NSString stringWithFormat:@"<b:t>%@</b:t>", raw];
            }
            
            //reading this value directly causes issue #161 - in which the string is no longer a string post copy, so forcing it through a string formatter back to a string
            answerLabelString=[NSString stringWithFormat:@"%@", raw];
            
            if(answerLabelString.length<3)
            {
                //this can't have a <b:t> at the begining
                
                //assume the string needs wrapping in b:t
                answerLabelString=[NSString stringWithFormat:@"<b:t>%@</b:t>", answerLabelString];
            }
            else if([[answerLabelString substringToIndex:3] isEqualToString:@"<b:"])
            {
                //doesn't need wrapping
            }
            else
            {
                //assume the string needs wrapping in b:t
                answerLabelString=[NSString stringWithFormat:@"<b:t>%@</b:t>", answerLabelString];
            }
            


            
//            [answerLabel setString:answerLabelString];
            NSLog(@"before answerLabelString: %@", answerLabelString);
            
        }
        // there should never be both an answer text and custom sprite defined - so if no answer text, only render the SPRITE_FILENAME
        else
        {
            // sort out the button with a custom sprite 
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[metaQuestionAnswers objectAtIndex:i] objectForKey:SPRITE_FILENAME])];
        }
        
        int s=fabsf(metaQuestionAnswerCount-5);
        
        // render buttons
        float sectionW=(metaQuestionBanner.contentSize.width / metaQuestionAnswerCount)-8;
        float startOffset=0;
        
        if(metaQuestionAnswerCount==2)
            startOffset=answerBtn.contentSize.width-19;
        else if(metaQuestionAnswerCount==3)
            startOffset=answerBtn.contentSize.width/2;
        else if(metaQuestionAnswerCount==4)
            startOffset=10;
        
        
        [answerBtn setPosition:ccp(startOffset+((24*s)/2)+((i+0.5) * sectionW), answersY)];
        [answerBtn setTag:3];
        //[answerBtn setScale:0.5f];
        [answerBtn setOpacity:0];
        [trayLayerMq addChild:answerBtn z:-1];
        [metaQuestionAnswerButtons addObject:answerBtn];
        
        if(answerLabelString){
            row=[[SGBtxeRow alloc] initWithGameWorld:descGw andRenderLayer:trayLayerMq];
            
            row.forceVAlignTop=NO;
            row.rowWidth=answerBtn.contentSize.width-10;
            row.tintMyChildren=NO;
            [row parseXML:answerLabelString];
        }
        // check for text, render if nesc
        if(row)
        {
            row.position=answerBtn.position;
            [metaQuestionAnswerLabels addObject:row];
            [row setupDraw];
            [row tagMyChildrenForIntro];
        }
    
        if(row)[row release];
        
        // set a new value in the array so we can see that it's not currently selected
        [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
    }
    
    

    descGw.Blackboard.inProblemSetup=NO;
}


-(void)tearDownMetaQuestion
{
    [trayLayerMq removeAllChildrenWithCleanup:YES];
    [traybtnMq setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_MetaQuestion_NotAvailable.png")]];
    toolCanEval=YES;
//    if(metaArrow)[metaArrow removeFromParentAndCleanup:YES];
    metaArrow=nil;
    metaQuestionAnswers=nil;
    metaQuestionAnswerButtons=nil;
    metaQuestionAnswerLabels=nil;
    metaQuestionBanner=nil;
    trayLayerMq=nil;
    metaQuestionForThisProblem=NO;
    metaQuestionForceComplete=NO;
    hasUsedMetaTray=NO;
    hasTrayMq=NO;
}

-(void)checkMetaQuestionTouchesAt:(CGPoint)location andTouchEnd:(BOOL)touchEnd
{
    
    if(isAnimatingIn)
        return;
    
    if (CGRectContainsPoint(commitBtn.boundingBox, location) && mqEvalMode==kMetaQuestionEvalOnCommit && commitBtn.visible && !autoMoveToNextProblem)
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
            
            float aLabelPosXLeft = answerBtn.position.x-((answerBtn.contentSize.width*answerBtn.scale)/2);
            float aLabelPosYleft = answerBtn.position.y-((answerBtn.contentSize.height*answerBtn.scale)/2);
            
            CGRect hitBox = CGRectMake(aLabelPosXLeft, aLabelPosYleft, (answerBtn.contentSize.width*answerBtn.scale), (answerBtn.contentSize.height*answerBtn.scale));
            // create a dynamic hitbox
            if(CGRectContainsPoint(hitBox, location))
            {
                // and check its current selected value
                BOOL isSelected=[[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_SELECTED] boolValue];
                
                
                if(!isSelected && !touchEnd)
                {
                    // the user has changed their answer (even if they didn't have one before)
                    [loggingService logEvent:BL_PA_MQ_CHANGE_ANSWER
                          withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"selection"]];
                    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_mq_selected.wav")];
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
                         [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
                    }
                    return;
                }
                else if(isSelected && !touchEnd)
                {
                    // return to full button colour and set the dictionary selected value to no
                    [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")]];
                    [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
                    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_mq_deselected.wav")];
                }
            }
            else
            {
                if(mqAnswerMode==kMetaQuestionAnswerSingle && !touchEnd)
                {
                    //[self deselectAnswersExcept:-1];
                }
            }
            
        }
    
    }
    
    return;
    
}

-(void)showHideCommit
{
    if(autoMoveToNextProblem)return;
    
    BOOL showCommit=NO;
    
    if(!metaQuestionForThisProblem && !numberPickerForThisProblem && evalMode==kProblemEvalOnCommit)
        showCommit=YES;
    
    if(currentTool && evalMode==kProblemEvalOnCommit && !metaQuestionForThisProblem && !numberPickerForThisProblem)
        showCommit=YES;
    
    if(trayPadShowing)
        showCommit=NO;
    
    if(hasTrayMq && trayMqShowing)
    {
        int countSelected=[self metaQuestionSelectedCount];
        
        if(countSelected>0)
            showCommit=YES;
        else
            showCommit=NO;
    }
    if(trayWheelShowing && numberPickerForThisProblem)
    {
        if(hasUsedPicker)
            showCommit=YES;
        else
            showCommit=NO;
    }
    
    
    if(showCommit && commitBtn)
        [commitBtn setVisible:YES];
    else
        [commitBtn setVisible:NO];
}

-(void)evalMetaQuestion
{
    if([self calcMetaQuestion])
    {
        [self doWinning];
        metaQuestionForceComplete=YES;
    }
    else
    {
        [self doIncomplete];
    }
}

-(int)metaQuestionSelectedCount
{
    int countSelected=0;
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        BOOL isSelected=[[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_SELECTED] boolValue];
        if(isSelected)countSelected++;
    }
    
    return countSelected;
}

-(BOOL)calcMetaQuestion
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
            return YES;
        }
        else
        {
            return NO;
        }
        
    }
    
    return NO;
}
-(void)deselectAnswersExcept:(int)answerNumber
{
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        CCSprite *answerBtn=[metaQuestionAnswerButtons objectAtIndex:i];
        //CCLabelTTF *answerLabel=[metaQuestionAnswerLabels objectAtIndex:i];
        if(i == answerNumber)
        {
            //NSLog(@"answer %d selected", answerNumber);
            [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-button-selected.png")]];
            [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
        }
        else
        {
            //NSLog(@"answer %d deselected", answerNumber);
            [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")]];
            [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
        }
    }
}
-(void)doWinning
{
    evalShowCommit=NO;
    timeBeforeUserInteraction=kDisableInteractionTime;
    isAnimatingIn=YES;
    hasShownComplete=YES;
    [loggingService logEvent:BL_PA_SUCCESS withAdditionalData:nil];
    
    if(metaQuestionForThisProblem)
    {
        [self removeMetaQuestionButtons];
        [metaQuestionBanner removeFromParentAndCleanup:YES];
        
        for(SGBtxeRow *r in metaQuestionAnswerLabels)
        {
            for(int i=0;i<r.children.count;i++)
            {
                if([[r.children objectAtIndex:i] conformsToProtocol:@protocol(MovingInteractive)])
                {
                    id<MovingInteractive> go=[r.children objectAtIndex:i];
                    [go destroy];
                }
            }
        }
        
        metaQuestionForceComplete=YES;
    }
    if(numberPickerForThisProblem)
    {
        [self tearDownNumberPicker];
        metaQuestionForceComplete=YES;
    }
    [self playAudioFlourish];
    [self showProblemCompleteMessage];
    currentTool.ProblemComplete=YES;
}
-(void)doIncomplete
{
    evalShowCommit=NO;
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_state_incorrect_answer_1.wav")];
    timeBeforeUserInteraction=kDisableInteractionTime;
    isAnimatingIn=YES;
    [loggingService logEvent:BL_PA_FAIL withAdditionalData:nil];
    [self showProblemIncompleteMessage];
    //[self deselectAnswersExcept:-1];
}
-(void)removeMetaQuestionButtons
{
    for(int i=0;i<metaQuestionAnswerButtons.count;i++)
    {
        [trayLayerMq removeChild:[metaQuestionAnswerButtons objectAtIndex:i] cleanup:YES];
    } 
    
}

#pragma mark - number picker

-(void)setupNumberPicker:(NSDictionary *)pdefNP
{
    [usersService notifyStartingFeatureKey:@"NUMBERPICKER_PROBLEM"];
    numberPickerForThisProblem=YES;
    toolCanEval=NO;
    shownProblemStatusFor=0;
    
    [self setProblemDescription: [pdefNP objectForKey:NUMBER_PICKER_DESCRIPTION]];
    npEval=[[pdefNP objectForKey:EVAL_VALUE]floatValue];
    numberPickerEvalMode=[[pdefNP objectForKey:PICKER_EVAL_MODE]intValue];
    
    
    [self addCommitButton];
    
    if(!currentTool)
        delayShowWheel=YES;
    
}

-(void)checkNumberPickerTouches:(CGPoint)location
{
    if(isAnimatingIn)return;
    
    CGPoint origloc=location;
//    location=[nPicker convertToNodeSpace:location];
    
    if(numberPickerEvalMode==kNumberPickerEvalOnCommit)
    {
        if(CGRectContainsPoint(commitBtn.boundingBox, origloc) && commitBtn.visible && !autoMoveToNextProblem)
        {
            //[self playAudioPress];
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_commit_tap.wav")];
            //effective user commit of number picker
            [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
            
            [self evalNumberPicker];
        }
    }
}
-(void)evalNumberPicker
{
    if(trayWheelShowing){
        NSString *pickerValue=[self returnPickerNumber];
        NSString *strNpEval=[NSString stringWithFormat:@"%g", npEval];
        
        if([pickerValue isEqualToString:strNpEval])
            [self doWinning];
        else
            [self doIncomplete];
    }
}

-(void)tearDownQuestionTray
{
    if(qTrayTop)[qTrayTop removeFromParentAndCleanup:YES];
    if(qTrayMid)[qTrayMid removeFromParentAndCleanup:YES];
    if(qTrayBot)[qTrayBot removeFromParentAndCleanup:YES];
    if(readProblemDesc)[readProblemDesc removeFromParentAndCleanup:YES];
    
    qTrayTop=nil;
    qTrayMid=nil;
    qTrayBot=nil;
    readProblemDesc=nil;
}

-(void)tearDownNumberPicker
{
    [self hideWheel];
    if(CurrentBTXE)CurrentBTXE=nil;
    toolCanEval=YES;
    [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_NotAvailable.png")]];

    if(trayLayerWheel)
        [trayLayerWheel removeAllChildrenWithCleanup:YES];

    trayLayerWheel=nil;
        

    hasUsedPicker=NO;
    pickerViewSelection=nil;
    pickerView=nil;
    hasUsedWheelTray=NO;
    trayWheelShowing=NO;
    numberPickerLayer=nil;
}

- (void)checkUserCommit
{
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_commit_tap.wav")];
    //effective user commit
    [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
    
    [currentTool evalProblem];
    
    if(currentTool.ProblemComplete)
    {
        timeBeforeUserInteraction=kDisableInteractionTime;
    }
    else {
        [self playAudioPress];
        
        //check commit threshold for insertion
        
        //only assess triggers if the insertion mode is enabled, and if we're at the episode head (e.g. don't nest insertions)
        if([(NSNumber*)[ac.AdplineSettings objectForKey:@"USE_INSERTERS"] boolValue] && contentService.isUserAtEpisodeHead && ![contentService isUsingTestPipeline] && !breakOutIntroProblemFK)
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

- (void)sizeQuestionDescription
{
    SGBtxeRow *row=qDescRow;
    
    qTrayBot.position=ccp(0,0);
    qTrayMid.position=ccp(0,0);
    qTrayTop.position=ccp(0,0);
    
    qTrayBot.zOrder=3;
    qTrayTop.zOrder=3;
    qTrayMid.zOrder=1;
    
    float rowHeight=0;

    [qTrayMid setAnchorPoint:ccp(0.5f, 0.0f)];
    
    if([currentTool isKindOfClass:[ExprBuilder class]])
    {
//        ExprBuilder *eb=(ExprBuilder*)currentTool;
        
        rowHeight=[(ExprBuilder*)currentTool getDescriptionAreaHeight] +15;
        qTrayMid.position=ccp(row.position.x, row.position.y);
    }
    else
    {
        rowHeight=row.size.height+35;
        [qTrayMid setPosition:ccp(row.position.x,row.position.y -10)];
    }
    
    if(rowHeight<68.0f)rowHeight=68.0f;
    


    //[qTrayMid setPosition:ccp(cx,row.position.y)];
    [qTrayMid setScaleY:(rowHeight-64)/16];

    
        NSLog(@"row height %f scaleY %f", rowHeight, qTrayMid.scaleY);
    
    
    [qTrayTop setPosition:ccp(qTrayMid.position.x,qTrayMid.position.y+((qTrayMid.contentSize.height*qTrayMid.scaleY)+qTrayTop.contentSize.height/2))];
    [qTrayBot setPosition:ccp(qTrayMid.position.x,qTrayMid.position.y-qTrayBot.contentSize.height/2)];
    
    NSLog(@"mid pos %@", NSStringFromCGPoint(qTrayMid.position));
    
    
    float topY=qTrayTop.position.y;
    
    float desiredY=680;
    float diffYToTop= desiredY-topY;
    
    //move everything by difftotoop
    qTrayMid.position=ccpAdd(qTrayMid.position, ccp(0, diffYToTop));
    qTrayBot.position=ccpAdd(qTrayBot.position, ccp(0, diffYToTop));
    qTrayTop.position=ccpAdd(qTrayTop.position, ccp(0, diffYToTop));
    
}

-(void)setReadProblemPosWithScale:(float)ascale
{
    if(ascale==1)
    {
        [readProblemDesc setPosition:ccp(975,
                                         qTrayBot.position.y-25)];
        
    }
    else
    {
        [readProblemDesc setPosition:ccp(qTrayMid.position.x+((qTrayMid.contentSize.width * ascale)/2)-readProblemDesc.contentSize.width+5,
                                 qTrayBot.position.y-25)];
    }
}

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
        [btxeDescLayer removeAllChildrenWithCleanup:YES];
        [descGw release];
        descGw=nil;
    }
    
    descGw=[[SGGameWorld alloc] initWithGameScene:self];
    descGw.Blackboard.inProblemSetup=YES;
    
    descGw.Blackboard.RenderLayer = btxeDescLayer;
    
    //create row
    
    qDescRow=[[SGBtxeRow alloc] initWithGameWorld:descGw andRenderLayer:btxeDescLayer];
    SGBtxeRow *row=qDescRow;
    
    descRow=row;
    row.position=ccp(cx, (cy*2) - 115);

    NSString *numberMode=[pdef objectForKey:@"NUMBER_MODE"];
    if(numberMode)
        row.defaultNumbermode=numberMode;
    
    //top down valign
    row.forceVAlignTop=YES;
    
    if(descString.length<3)
    {
        //this can't have a <b:t> at the begining
        
        //assume the string needs wrapping in b:t
        descString=[NSString stringWithFormat:@"<b:t>%@</b:t>", descString];
    }
    else if([[descString substringToIndex:3] isEqualToString:@"<b:"])
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
    
    readProblemDesc=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/Question_tray_play.png")];

    
    
    qTrayTop=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/questiontray/Question_tray_Top.png")];
    qTrayMid=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/questiontray/Question_tray_Middle.png")];
    qTrayBot=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/questiontray/Question_tray_Bottom.png")];

    [self sizeQuestionDescription];
    
    animateQuestionBox=YES;
    
    [self setReadProblemPosWithScale:1.0f];

    
    [backgroundLayer addChild:readProblemDesc];
    [backgroundLayer addChild:qTrayTop];
    [backgroundLayer addChild:qTrayBot];
    [backgroundLayer addChild:qTrayMid];
    
    descGw.Blackboard.inProblemSetup=NO;
    
    if([currentTool isKindOfClass:[LongDivision class]])
    {
//        [self scheduleOnce:@selector(showCornerTray) delay:3.5f];
        [self showCornerTray];
    }
}

-(void)animateQuestionBoxIn
{
//    [qTrayTop runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayTop.position.x, qTrayTop.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY)]];
//    [qTrayMid runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayMid.position.x, qTrayMid.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY)]];
//    [qTrayBot runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayBot.position.x, qTrayBot.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY)]];
//    [readProblemDesc runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(readProblemDesc.position.x, readProblemDesc.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY)]];
//    

//    qTrayTop.position=ccp(qTrayTop.position.x, qTrayTop.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY);
//    qTrayMid.position=ccp(qTrayMid.position.x, qTrayMid.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY);
//    qTrayBot.position=ccp(qTrayBot.position.x, qTrayBot.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY);
//    readProblemDesc.position=ccp(readProblemDesc.position.x, readProblemDesc.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY);
//    
    
}

#pragma mark - touch handling

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [loggingService.touchLogger logTouches:touches];
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;

    timeSinceInteractionOrShake=0.0f;
    
    if(isPaused||autoMoveToNextProblem||isAnimatingIn)
    {
        return;
    }
    
    if(trayPadShowing)
    {
        if(CGRectContainsPoint(trayPadClear.boundingBox, location))
        {
            [(LineDrawer*)lineDrawer clearSlate];
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_notepad_cleared.wav")];
        }
        return;
    }
    
    //delegate touch handling for trays here
    if(((location.x>CORNER_TRAY_POS_X && location.y>CORNER_TRAY_POS_Y)&&(trayCalcShowing)) || (trayMqShowing && CGRectContainsPoint(metaQuestionBanner.boundingBox, location))||location.y>ly-HD_HEADER_HEIGHT)
    {
        if (location.x < 120 && location.y > 688 && !isPaused)
        {
            [self showPauseMenu];
            return;
        }
        if(metaQuestionForThisProblem)
        {
            [self checkMetaQuestionTouchesAt:location andTouchEnd:NO];
            return;
        }
        if(numberPickerForThisProblem)
        {
            [self checkNumberPickerTouches:location];
            return;
        }
    }
    else if(CGRectContainsPoint(readProblemDesc.boundingBox, location))
    {
        [self readOutProblemDescriptionAndForce:YES];
        return;
    }
    else
    {
        if((trayMqShowing||trayWheelShowing||trayCalcShowing) && currentTool && !CurrentBTXE && !CGRectContainsPoint(CGRectMake(CORNER_TRAY_POS_X,CORNER_TRAY_POS_Y,324,308), location)){
            [self removeAllTrays];
            return;
        }
    }
    
    
    if(isHoldingObject) return;  // no multi-touch but let's be sure
    
    for(id<MovingInteractive, NSObject> o in descRow.children)
    {
        if([o conformsToProtocol:@protocol(MovingInteractive)])
        {
            if(!o.interactive)continue;
            id<Bounding> obounding=(id<Bounding>)o;
            
            CGRect hitbox=CGRectMake(obounding.worldPosition.x - (BTXE_OTBKG_WIDTH_OVERDRAW_PAD + obounding.size.width) / 2.0f, obounding.worldPosition.y-BTXE_VPAD-(obounding.size.height / 2.0f), obounding.size.width + BTXE_OTBKG_WIDTH_OVERDRAW_PAD, obounding.size.height + 2*BTXE_VPAD);
            

            if(o.enabled && CGRectContainsPoint(hitbox, location))
            {
                heldObject=o;
                isHoldingObject=YES;
                
                [(id<MovingInteractive>)o inflateZIndex];
                
            }
        }
    }
    
    if (CGRectContainsPoint(commitBtn.boundingBox, location) && evalMode==kProblemEvalOnCommit && !metaQuestionForThisProblem && !numberPickerForThisProblem && !isAnimatingIn && commitBtn.visible && !autoMoveToNextProblem)
    {
        doPlaySound=NO;
        //remove any trays
        [self removeAllTrays];
        doPlaySound=YES;
        
        //user pressed commit button
        [self checkUserCommit];
    }
    [followParticle resetSystem];
    [followParticle setPosition:location];
    [followParticle setVisible:YES];
    
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
    
    if(isHoldingObject)
    {
        //track that object's position
        heldObject.worldPosition=location;
    }
    
//    if(npMove && numberPickerForThisProblem)[self checkNumberPickerTouchOnRegister:location];
    
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
        [followParticle setPosition:location];
        [currentTool ccTouchesMoved:touches withEvent:event];
    }
    

}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [loggingService.touchLogger logTouches:touches];
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    [followParticle stopSystem];
    
    // if we're paused - check if any menu options were valid.
    // touches ended event becase otherwise these touches go through to the tool
    
    if(isAnimatingIn||autoMoveToNextProblem||showingProblemComplete||showingProblemIncomplete) return;
    
    if(isPaused)
    {
        [self checkPauseTouches:location];
        return;
    }
    
    CGRect bbCalc=CGRectMake(traybtnCalc.position.x-traybtnCalc.contentSize.width/2,traybtnCalc.position.y-(HD_HEADER_HEIGHT/2), traybtnCalc.contentSize.width, HD_HEADER_HEIGHT);
    CGRect bbMq=CGRectMake(traybtnMq.position.x-traybtnMq.contentSize.width/2,traybtnMq.position.y-(HD_HEADER_HEIGHT/2), traybtnMq.contentSize.width, HD_HEADER_HEIGHT);
    CGRect bbWheel=CGRectMake(traybtnWheel.position.x-traybtnWheel.contentSize.width/2,traybtnWheel.position.y-(HD_HEADER_HEIGHT/2), traybtnWheel.contentSize.width, HD_HEADER_HEIGHT);
    CGRect bbPad=CGRectMake(traybtnPad.position.x-traybtnPad.contentSize.width/2,traybtnPad.position.y-(HD_HEADER_HEIGHT/2), traybtnPad.contentSize.width, HD_HEADER_HEIGHT);
    
    
    if(heldObject)
    {
        //test new location for target / drop
        for(id<Interactive, NSObject> o in descRow.children)
        {
            if([o conformsToProtocol:@protocol(Interactive)])
            {
                if(!o.enabled
                   && [heldObject.tag isEqualToString:o.tag]
                   && [BLMath DistanceBetween:o.worldPosition and:location]<=BTXE_PICKUP_PROXIMITY)
                {
                    //this object is proximate, disabled and the same tag
                    [o activate];
                }
                
                if([o conformsToProtocol:@protocol(BtxeMount)] && [BLMath DistanceBetween:o.worldPosition and:location]<=BTXE_PICKUP_PROXIMITY)
                {
                    id<BtxeMount, Interactive> pho=(id<BtxeMount, Interactive>)o;
                    
                    //mount the object on the place holder
                    [pho duplicateAndMountThisObject:(id<MovingInteractive, NSObject>)heldObject];
                }
            }
        }
        
        [heldObject returnToBase];
        
        [heldObject deflateZindex];
        
        [currentTool userDroppedBTXEObject:heldObject atLocation:location];
        
        heldObject=nil;
        isHoldingObject=NO;
    }
    
    
    if(traybtnCalc && CGRectContainsPoint(bbCalc, location) && hasTrayCalc)
    {
        if(trayCalcShowing)
        {
            //hide this tray & general corner tray
            [self hideCalc];
            [self hideCornerTray];
        }
        else
        {
            //manually hide what this overrides
            [self hideMq];
            [self hideWheel];
            [self hidePad];
            
            //show this + show stuff in corner
            [self showCalc];
            
            //this might already be done -- but we've not explicitly hidden anything, so re-running will skip
            [self showCornerTray];
        }
    }
    
//    if(traybtnWheel && CGRectContainsPoint(bbWheel, location) && (hasTrayWheel||trayWheelShowing))
    if(traybtnWheel && CGRectContainsPoint(bbWheel, location) && hasTrayWheel)
    {
        if(trayWheelShowing)
        {
            //hide this tray & general corner tray
            [self hideWheel];
            [self hideCornerTray];
        }
        else
        {
            //manually hide what this overrides
            [self hideMq];
            [self hideCalc];
            [self hidePad];
            
            if(!currentTool)
                [self hideCornerTray];
            //show this + show stuff in corner
            [self showWheel];
            
            //this might already be done -- but we've not explicitly hidden anything, so re-running will skip
            if(currentTool)[self showCornerTray];
        }
    }
    if(trayPadShowing && location.y>cx+40.0f)
    {
        [self hidePad];
        return;
    }
    if(traybtnPad && CGRectContainsPoint(bbPad, location))
    {
        if(trayPadShowing)
        {
            [self hidePad];
        }
        else
        {
            [self hideMq];
            [self hideCalc];
            [self hideWheel];
            
            [self showPad];
            
            //[self showCornerTray];
        }
    }
    
    if(traybtnMq && CGRectContainsPoint(bbMq, location) && hasTrayMq)
    {
        if(trayMqShowing)
        {
            [self hideMq];
            [commitBtn setVisible:NO];
        }
        else
        {
            [self hideCornerTray];
            [self hideCalc];
            [self hideWheel];
            [self hidePad];
            
            [self showMq];
            
        }
        
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

#pragma mark - trays

-(void)removeAllTrays
{
    [commitBtn setVisible:NO];
    [self hideCalc];
    [self hideWheel];
    [self hideMq];
    [self hidePad];
    [self hideCornerTray];
}

-(void)sizeAndResetQuestionDescripion
{
    [self sizeQuestionDescription];
}

-(void)updateReadButtonPosAtScale:(float)scaleX
{
//    readProblemDesc.position=ccp((qTrayBot.contentSize.width * scaleX) / 2.0f + qTrayBot.position.x - 40.0f, readProblemDesc.position.y-200-qTrayMid.contentSize.height*qTrayMid.scaleY);
}

-(void)showCornerTray
{
    if(!trayCornerShowing)
    {
        //do stuff
        //descRow.position=ccp(350.0f, (cy*2)-95);

        [descRow animateAndMoveToPosition:ccp(345.0f, (cy*2)-115)];
        [descRow relayoutChildrenToWidth:600];
        
        [self sizeAndResetQuestionDescripion];

        
        qTrayTop.scaleX=0.65f;
        qTrayMid.scaleX=0.65f;
        qTrayBot.scaleX=0.65f;
        
        [self setReadProblemPosWithScale:0.65f];
        

        trayCornerShowing=YES;
    }
}

-(void)hideCornerTray
{
    if(trayCornerShowing)
    {
        qTrayTop.scaleX=1.0f;
        qTrayMid.scaleX=1.0f;
        qTrayBot.scaleX=1.0f;

        [self setReadProblemPosWithScale:1.0f];
        

        
        [descRow animateAndMoveToPosition:ccp(cx, (cy*2) - 115)];
        
        [descRow relayoutChildrenToWidth:BTXE_ROW_DEFAULT_MAX_WIDTH];
        
        [self sizeAndResetQuestionDescripion];
        
        [self updateReadButtonPosAtScale:1.0f];
        
        trayCornerShowing=NO;
    }
}

-(float)questionTrayWidth
{
    return (qTrayBot.contentSize.width*qTrayBot.scaleX)-15;
}

-(void)showCalc
{
    if(!trayLayerCalc)
    {
        trayLayerCalc=[CCLayerColor layerWithColor:ccc4(255, 255, 255, 100) width:300 height:225];
        [problemDefLayer addChild:trayLayerCalc z:2];
        trayLayerCalc.position=ccp(CORNER_TRAY_POS_X, CORNER_TRAY_POS_Y);
        
        CCLabelTTF *lbl=[CCLabelTTF labelWithString:@"Calculator" fontName:@"Source Sans Pro" fontSize:24.0f];
        lbl.position=ccp(150,112.5f);
        [trayLayerCalc addChild:lbl];
    }
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_calculator_tool_appears.wav")];
    trayLayerCalc.visible=YES;
    trayCalcShowing=YES;
    
    [traybtnCalc setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Calculator_Selected.png")]];
    //[traybtnCalc setColor:ccc3(247,143,6)];
}

-(void)hideCalc
{
    if(doPlaySound)
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_calculator_tool_disappears.wav")];
    
    trayLayerCalc.visible=NO;
    trayCalcShowing=NO;
    
    if(hasTrayCalc)
        [traybtnCalc setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Calculator_NotAvailable.png")]];
    else
        [traybtnCalc setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Calculator_NotAvailable.png")]];

}

-(void)showMq
{
    hasUsedMetaTray=YES;
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_mq_tool_appears.wav")];
    [trayLayerMq setVisible:YES];
    trayMqShowing=YES;
//    [traybtnMq setColor:ccc3(247,143,6)];
    [traybtnMq setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_MetaQuestion_Selected.png")]];

    if(metaArrow)[metaArrow setVisible:NO];
}

-(void)hideMq
{
    if(doPlaySound)
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_mq_tool_disappears.wav")];
    [commitBtn setVisible:NO];
    trayLayerMq.visible=NO;
    trayMqShowing=NO;
    
    if(hasTrayMq)
        [traybtnMq setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_MetaQuestion_Available.png")]];
    else
        [traybtnMq setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_MetaQuestion_NotAvailable.png")]];
    
    if(metaArrow && [self metaQuestionSelectedCount]==0)
        //[metaArrow setVisible:YES];
        [metaArrow setVisible:NO];
    
    if(metaQuestionForThisProblem){
        timeSinceInteractionOrShake=0.0f;
        hasUsedMetaTray=NO;
    }
}

-(void)disableWheel
{
    hasTrayWheel=NO;
    numberPickerForThisProblem=NO;
    [self hideWheel];
    [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_NotAvailable.png")]];
}

-(void)showWheel
{
    if(!trayLayerWheel)
    {
        //trayLayerWheel=[CCLayerColor layerWithColor:ccc4(255, 255, 255, 100) width:300 height:225];
        trayLayerWheel=[[CCLayer alloc]init];
        [problemDefLayer addChild:trayLayerWheel z:2];
        //trayLayerWheel.position=ccp(CORNER_TRAY_POS_X, CORNER_TRAY_POS_Y);
        [self setupNumberWheel];
        
        
        int pickerCols=[self numberOfComponentsInPickerView:pickerView];
        
        for(int i=0;i<pickerCols;i++)
        {
            [pickerView spinComponent:i speed:40 easeRate:5 repeat:2 stopRow:0];
        }
        
    }
    hasUsedWheelTray=YES;
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_number_wheel_tool_appears.wav")];
    trayLayerWheel.visible=YES;
    trayWheelShowing=YES;
//    [traybtnWheel setColor:ccc3(247,143,6)];
    [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_Selected.png")]];
}

-(void)hideWheel
{
    if(doPlaySound)
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_number_wheel_tool_disappears.wav")];

    trayLayerWheel.visible=NO;
    trayWheelShowing=NO;
//    [traybtnWheel setColor:ccc3(255,255,255)];
    
    if(hasTrayWheel && traybtnWheel)
        [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_Available.png")]];
    else
        [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_NotAvailable.png")]];
    
    if(numberPickerForThisProblem){
        timeSinceInteractionOrShake=0.0f;
        hasUsedWheelTray=NO;
    }
}

-(void)showPad
{
    if(!trayLayerPad)
    {
        trayLayerPad=[[CCLayer alloc]init];
        lineDrawer=[LineDrawer node];
        
        CCSprite *bg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/notepad/note_pad_frame.png")];
        [bg setPosition:ccp(512, 272)];

        
        
        [trayLayerPad addChild:lineDrawer];
        [problemDefLayer addChild:trayLayerPad z:10];
        [trayLayerPad addChild:bg z:15];
        
        trayPadClear=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/notepad/note_pad_bin.png")];
        [trayPadClear setPosition:ccp(963,460)];
        [trayLayerPad addChild:trayPadClear z:20];
        
    }
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_notepad_tool_appears.wav")];
    trayLayerPad.visible=YES;
    trayPadShowing=YES;
    [traybtnPad setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Notepad_Selected.png")]];
}

-(void)hidePad
{
    if(doPlaySound)
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_notepad_tool_disappears.wav")];

    trayLayerPad.visible=NO;
    trayPadShowing=NO;
    [traybtnPad setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Notepad_Available.png")]];
}

#pragma mark - CCPickerView for number wheel

-(void)setupNumberWheel
{
    if(self.pickerView) return;
    
    NSString *strSprite=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_bg.png",[self numberOfComponentsInPickerView:self.pickerView]];
    CCSprite *ovSprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(strSprite)];
    
    self.pickerView = [CCPickerView node];
    if(currentTool)
        pickerView.position=ccp(lx-kComponentSpacing-(ovSprite.contentSize.width/2),ly-180);
    else
        pickerView.position=ccp(cx,cy);
    pickerView.dataSource = self;
    pickerView.delegate = self;

    
    if(CurrentBTXE && ([((id<Text>)CurrentBTXE).text floatValue]>0 || [((id<Text>)CurrentBTXE).text floatValue]<0))
        [self updatePickerNumber:((id<Text>)CurrentBTXE).text];

    
    
    [ovSprite setPosition:pickerView.position];
    [trayLayerWheel addChild:ovSprite z:18];
    [trayLayerWheel addChild:self.pickerView z:20];
}

#pragma mark CCPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(CCPickerView *)pickerView {
    int length=0;
    
    if(CurrentBTXE)
    {
        length=3;
    }
    
    if(numberPickerForThisProblem) {
        NSString *strNpEval=[NSString stringWithFormat:@"%g", npEval];
        length=[strNpEval length];
    }
    
    if(!pickerViewSelection)
    {
        pickerViewSelection=[[[NSMutableArray alloc]init]retain];
        
        for(int i=0;i<length;i++)
            [pickerViewSelection addObject:[NSNumber numberWithInt:0]];
    }
    
    
    return length;
}

- (NSInteger)pickerView:(CCPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    NSInteger numRows = 0;
    
    switch (component) {
        case 0:
            numRows = 12;
            break;
        case 1:
            numRows = 11;
            break;
        case 2:
            numRows = 11;
            break;
        case 3:
            numRows = 11;
            break;
        case 4:
            numRows = 11;
            break;
        case 5:
            numRows = 11;
            break;
        case 6:
            numRows = 11;
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
    
    if(row<10)
    {
        CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", row]fontName:@"Chango" fontSize:32];
        [l setColor:ccc3(68,68,68)];

        return l;
    }
    else if(row==10)
    {
        CCLabelTTF *l=[CCLabelTTF labelWithString:@"." fontName:@"Chango" fontSize:32];
        [l setColor:ccc3(68,68,68)];
        return l;
    }
    else if(row==11)
    {
        CCLabelTTF *l=[CCLabelTTF labelWithString:@"-" fontName:@"Chango" fontSize:32];
        [l setColor:ccc3(68,68,68)];
        return l;        
    }
    
    return nil;
    
}

- (void)pickerView:(CCPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    CCLOG(@"didSelect row = %d, component = %d", row, component);
    [pickerViewSelection replaceObjectAtIndex:component withObject:[NSNumber numberWithInteger:row]];
    hasUsedPicker=YES;
    
}

- (CGFloat)spaceBetweenComponents:(CCPickerView *)pickerView {
    return kComponentSpacing;
}

- (CGSize)sizeOfPickerView:(CCPickerView *)pickerView {
    CGSize size = CGSizeMake(200, 100);
    
    return size;
}

- (CCNode *)underlayImage:(CCPickerView *)pickerView {
    
    NSString *strSprite=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ul.png",[self numberOfComponentsInPickerView:self.pickerView]];
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(strSprite)];
    return sprite;
}

- (CCNode *)overlayImage:(CCPickerView *)pickerView {

    NSString *strSprite=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ov.png",[self numberOfComponentsInPickerView:self.pickerView]];
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(strSprite)];
    return sprite;
}

- (void)onDoneSpinning:(CCPickerView *)pickerView component:(NSInteger)component {
//    [pickerViewSelection replaceObjectAtIndex:component withObject:[NSNumber numberWithInteger:row]];
    NSLog(@"Component %d stopped spinning.", component);
}

-(NSString*)returnPickerNumber
{
    NSString *fullNum=@"";
    
    for(int i=0;i<[pickerViewSelection count];i++)
    {
        int n=[[pickerViewSelection objectAtIndex:i]intValue];

        if(n<10)
        {
            fullNum=[NSString stringWithFormat:@"%@%d", fullNum, n];
        }
        else if(n==10)
        {
            fullNum=[NSString stringWithFormat:@"%@.", fullNum];
        }
        else if(n==11)
        {
            fullNum=[NSString stringWithFormat:@"%@-", fullNum];
        }
 
    }
    
    float thisNum=[fullNum floatValue];
    fullNum=[NSString stringWithFormat:@"%g",thisNum];
    
    return fullNum;
}

-(void)updatePickerNumber:(NSString*)thisNumber
{
    int thisComponent=[self numberOfComponentsInPickerView:self.pickerView]-1;
    int numberOfComponents=thisComponent;
    
    for(int i=[thisNumber length]-1;i>=0;i--)
    {
        NSString *thisStr=[NSString stringWithFormat:@"%c",[thisNumber characterAtIndex:i]];
        int thisInt=[thisStr intValue];
        
        [pickerViewSelection replaceObjectAtIndex:thisComponent withObject:[NSNumber numberWithInt:thisInt]];
        

        [self.pickerView spinComponent:thisComponent speed:15 easeRate:5 repeat:1 stopRow:thisInt];
        thisComponent--;
    }
    
    if([thisNumber length]<numberOfComponents)
    {
        int untouchedComponents=0;
        untouchedComponents=numberOfComponents-[thisNumber length];
        
        
        for(int i=untouchedComponents;i>=0;i--)
        {
            [pickerViewSelection replaceObjectAtIndex:thisComponent withObject:[NSNumber numberWithInt:0]];
            [pickerView spinComponent:thisComponent speed:15 easeRate:5 repeat:1 stopRow:0];
            thisComponent--;
        }
    }

}

#pragma mark - debug pipeline views

-(void)debugShowPipelineState
{
    CGRect f=CGRectMake(0, 0, lx, ly-30);
    debugWebView=[[UIWebView alloc] initWithFrame:f];
    debugWebView.backgroundColor=[UIColor whiteColor];
    debugWebView.opaque=NO;
    debugWebView.alpha=0.7f;
    
    //get the pipeline state
    NSString *pstate=[contentService debugPipelineString];
    
    [debugWebView loadHTMLString:[NSString stringWithFormat:@"<html><body style='font-family:Courier; color:black'>%@</body></html>", pstate] baseURL:[NSURL URLWithString:@""]];
    
    debugViewController=[[DebugViewController alloc] initWithNibName:nil bundle:nil];
    debugWebView.delegate=debugViewController;
    
    debugViewController.handlerInstance=self;
    debugViewController.skipProblemMethod=@selector(debugWebViewHandleSkipProblemsWithStep:);
    
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

-(void)debugWebViewHandleSkipProblemsWithStep:(NSNumber*)skips
{
    NSLog(@"skipping %d problems", [skips intValue]);
    
    [self debugSkipToProblem:[skips intValue]];
    
    [self debugHidePipelineState];
    
    [self hidePauseMenu];
}

#pragma mark - edit pdef
-(void)editPDef
{
    if (nowEditingPDef) return;
    nowEditingPDef = YES;
    
    editPDefViewController = [[EditPDefViewController alloc] initWithFrame:CGRectMake(0, 0, lx, ly)
                                                          handlderInstance:self
                                                 endEditAndTest:@selector(endEditPDefAndTestProblem:)];
    
    [[[CCDirector sharedDirector] view] addSubview:editPDefViewController.view];
}

-(void)endEditPDefAndTestProblem:(NSNumber*)reset
{
    nowEditingPDef = NO;
    if (!editPDefViewController) return;
    [editPDefViewController.view removeFromSuperview];
    [editPDefViewController release];
    [self hidePauseMenu];
    if ([reset boolValue])
    {
        unsavedEditsImage.visible = contentService.currentProblem && contentService.currentProblem.hasUnsavedEdits;
        [self resetProblem];
    }
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
    
    if(self.pickerView)self.pickerView=nil;
    
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
    if(pickerViewSelection)[pickerViewSelection release];
    if(debugWebView)[debugWebView release];
    if(debugViewController)[debugViewController release];
    
    if(editPDefViewController)[editPDefViewController release];
    
    self.Zubi=nil;
    
    //number wheel / picker view
    if(pickerView)[pickerView release];
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    
    [super dealloc];
}

@end
