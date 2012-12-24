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
#import "DebugViewController.h"
#import "EditPDefViewController.h"
#import "TestFlight.h"
#import "ExprBuilder.h"
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
static float kTimeToHintToolTray=7.0f;

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
        
        //[self scheduleOnce:@selector(moveToTool1:) delay:1.5f];
        
        //add a pause button but keep it hidden -- to be brought in by the fader
        //CCSprite *pause=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/button-pause.png")];
        //[pause setPosition:ccp(lx-(kPropXPauseButtonPadding*lx), ly-(kPropXPauseButtonPadding*lx))];
        //[perstLayer addChild:pause z:3];
        

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
        pbtn.position=ccp(HD_BUTTON_INSET-30, 2*cy - 30);
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
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_state_correct_answer_1.wav")];
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
        
        for(int i=0;i<[metaQuestionAnswerLabels count];i++)
        {
            SGBtxeRow *row=[metaQuestionAnswerLabels objectAtIndex:i];
            
            [row setupDraw];
            [row inflateZindex];
            [row tagMyChildrenForIntro];
        }
        timeToMetaStart=0.0f;
        delayShowMeta=NO;
    }
    
    if(numberPickerForThisProblem||metaQuestionForThisProblem)timeSinceInteractionOrShake+=delta;
    
    if(timeSinceInteractionOrShake>kTimeToHintToolTray)
    {
        
        if(numberPickerForThisProblem && !hasUsedWheelTray){
            [traybtnWheel runAction:[InteractionFeedback dropAndBounceAction]];
        }
        if(metaQuestionForThisProblem && !hasUsedMetaTray){
            [metaArrow runAction:[InteractionFeedback dropAndBounceAction]];
        }
        timeSinceInteractionOrShake=0.0f;
    }
    

    if(CurrentBTXE)
    {
        if(!pickerView){
            [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_Available.png")]];
            hasTrayWheel=YES;
            [self showWheel];
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
    if(!(m==2 || m==4 || m==8 || m==16)) return; // because there isn't a corresponding image in the project to display
    
    if(multiplierBadge)
    {
        [self removeChild:multiplierBadge cleanup:YES];
    }
    
    NSString *bf=[NSString stringWithFormat:@"/images/menu/HR_Multiplier_%d.png", m];
    multiplierBadge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(bf)];
    multiplierBadge.position=ccp(cx-95, 2*cy-multiplierBadge.contentSize.height/1.7);
    //multiplierBadge.position=ccp(cx,cy);
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

-(void) debugSkipToProblem:(int)skipby
{
    //effectively a skipping version of gotoNewProblem, ignores triggers, little exception / flow handling
    [self tearDownProblemDef];
    self.PpExpr=nil;
    
    hasResetMultiplier=NO;
    
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
    
    //reset trigger data -- a fresh view on user progress in this problem
    [self resetTriggerData];
    
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
    
    [self returnToMap];
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

-(void) resetProblem
{
    //if(problemDescLabel)[problemDescLabel removeFromParentAndCleanup:YES];
    
    TFLog(@"resetting problem");
    
    [self tearDownQuestionTray];
    
    [self tearDownNumberPicker];
    [self tearDownMetaQuestion];

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
        [self stopAllSpeaking];
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
//    if(CGRectContainsPoint(kPauseMenuLogOut, location))
//    {
//        [loggingService logEvent:BL_USER_LOGOUT withAdditionalData:nil];
//        [usersService setCurrentUserToUserWithId:nil];
//        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
//        [(AppController*)[[UIApplication sharedApplication] delegate] returnToLogin];
//    }
    
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
    
    // check the answer mode and assign
    NSNumber *aMode=[pdefMQ objectForKey:META_QUESTION_ANSWER_MODE];
    if (aMode) mqAnswerMode=[aMode intValue];
    
    if(mqAnswerMode==kMetaQuestionAnswerSingle)
        [usersService notifyStartingFeatureKey:@"METAQUESTION_ANSWER_MODE_SINGLE"];
    else if(mqAnswerMode==kMetaQuestionAnswerMulti)
        [usersService notifyStartingFeatureKey:@"METAQUESTION_ANSWER_MODE_MULTI"];
    
    // check the eval mode and assign
//    NSNumber *eMode=[pdefMQ objectForKey:META_QUESTION_EVAL_MODE];
//    if(eMode) mqEvalMode=[eMode intValue];
    mqEvalMode=kMetaQuestionEvalOnCommit;
    [self addCommitButton];
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
    
//    if(currentTool)
//        [metaQuestionIncompleteLabel setPosition:ccp(cx, answersY*kMetaIncompleteLabelYOffset)];
//    else
//        [metaQuestionIncompleteLabel setPosition:ccp(cx, cy*0.25)];
    
    NSString *mqBar=[NSString stringWithFormat:@"/images/metaquestions/MQ_Bar_%d.png",metaQuestionAnswerCount];
    metaQuestionBanner=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(mqBar)];
    [metaQuestionBanner setPosition:ccp(cx,answersY)];
    [trayLayerMq addChild:metaQuestionBanner];
    
    // render answer labels and buttons for each answer
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        NSMutableDictionary *a=[NSMutableDictionary dictionaryWithDictionary:[pdefAnswers objectAtIndex:i]];
        [metaQuestionAnswers addObject:a];
        
        CCSprite *answerBtn;
        SGBtxeRow *row;
//        CCLabelTTF *answerLabel;
        NSString *raw=nil;
        NSString *answerLabelString=nil;
        // sort out the labels and buttons if there's an answer text
        if([[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT])
        {
            // sort out the buttons
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")];
//            answerLabel=[CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(answerBtn.contentSize.width-10,answerBtn.contentSize.height-6) alignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeWordWrap fontName:CHANGO fontSize:16.0f];

//            [answerLabel setAnchorPoint:ccp(0.5,0.5)];
            
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
            
//            if(answerLabelString.length>9)
//                [answerLabel setFontSize:16.0f];
//            else
//                [answerLabel setFontSize:22.0f];
        }
        // there should never be both an answer text and custom sprite defined - so if no answer text, only render the SPRITE_FILENAME
        else
        {
            // sort out the button with a custom sprite 
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[metaQuestionAnswers objectAtIndex:i] objectForKey:SPRITE_FILENAME])];
        }
        
        int s=fabsf(metaQuestionAnswerCount-5);
//        float adjLX=lx-(lx*((24*s)/lx));
        
        // render buttons
        //float sectionW=adjLX / metaQuestionAnswerCount;
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
        [trayLayerMq addChild:answerBtn];
        [metaQuestionAnswerButtons addObject:answerBtn];
        
        if(answerLabelString){
            row=[[SGBtxeRow alloc] initWithGameWorld:descGw andRenderLayer:trayLayerMq];
            
            row.forceVAlignTop=NO;
            row.rowWidth=answerBtn.contentSize.width-10;
            [row parseXML:answerLabelString];
            [metaQuestionAnswerLabels addObject:row];
        }
        // check for text, render if nesc
        if(row)
        {
            row.position=answerBtn.position;
        }
    
        // set a new value in the array so we can see that it's not currently selected
        [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
    }
    
    

    
}


-(void)tearDownMetaQuestion
{
    [trayLayerMq removeAllChildrenWithCleanup:YES];
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
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_commit_tap.wav")];
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
            //CCLabelTTF *answerLabel=[metaQuestionAnswerLabels objectAtIndex:i];
            
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
                        //[answerLabel setColor:kMetaAnswerLabelColorSelected];
                        //                        [answerBtn setColor:kMetaQuestionButtonSelected];
                        [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
                    }
                    return;
                }
                else if(isSelected && !touchEnd)
                {
                    // return to full button colour and set the dictionary selected value to no
                    [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")]];
                    //[answerLabel setColor:kMetaAnswerLabelColorDeselected];
                    //                    [answerBtn setColor:kMetaQuestionButtonDeselected];
                    [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
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
        autoMoveToNextProblem=YES;
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
            //[answerLabel setColor:kMetaAnswerLabelColorSelected];
//            [answerBtn setColor:kMetaQuestionButtonSelected];
            [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
        }
        else
        {
            //NSLog(@"answer %d deselected", answerNumber);
            [answerBtn setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")]];
            //[answerLabel setColor:kMetaAnswerLabelColorDeselected];
//            [answerBtn setColor:kMetaQuestionButtonDeselected];
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
        metaQuestionForceComplete=YES;
    }
    if(numberPickerForThisProblem)
    {
        [self tearDownNumberPicker];
        metaQuestionForceComplete=YES;
    }
    
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_state_correct_answer.wav")];
    [self showProblemCompleteMessage];
    currentTool.ProblemComplete=YES;
}
-(void)doIncomplete
{
    evalShowCommit=NO;
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_state_incorrect_answer.wav")];
    timeBeforeUserInteraction=kDisableInteractionTime;
    isAnimatingIn=YES;
    [loggingService logEvent:BL_PA_FAIL withAdditionalData:nil];
    [self showProblemIncompleteMessage];
    //[self deselectAnswersExcept:-1];
}
-(void)removeMetaQuestionButtons
{
//    for(int i=0;i<metaQuestionAnswerLabels.count;i++)
//    {
//        [trayLayerMq removeChild:[metaQuestionAnswerLabels objectAtIndex:i] cleanup:YES];
//    } 
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
    
    //float npOriginX=[[pdefNP objectForKey:PICKER_ORIGIN_X]floatValue];
    //float npOriginY=[[pdefNP objectForKey:PICKER_ORIGIN_Y]floatValue];
    
    //BOOL npShowDropbox=[[pdefNP objectForKey:SHOW_DROPBOX]boolValue];
    
    //numberPickerType=[[pdefNP objectForKey:PICKER_LAYOUT]intValue];
    //numberPickerEvalMode=[[pdefNP objectForKey:EVAL_MODE]intValue];
    //animatePickedButtons=[[pdefNP objectForKey:ANIMATE_FROM_PICKER]boolValue];
    

    
    //if([pdefNP objectForKey:MAX_NUMBERS])
    //    npMaxNoInDropbox=[[pdefNP objectForKey:MAX_NUMBERS]intValue];
    //else
    //    npMaxNoInDropbox=4;
    
    //numberPickerButtons=[[NSMutableArray alloc]init];
    //numberPickedSelection=[[NSMutableArray alloc]init];
    //numberPickedValue=[[NSMutableArray alloc]init];
    
    //nPicker=[[CCNode alloc]init];
    //[nPicker setPosition:ccp(npOriginX,npOriginY)];
    
    //numberPickerLayer=[[CCLayer alloc]init];
    //[self addChild:numberPickerLayer z:2];
    //[numberPickerLayer addChild:nPicker];
    
    //[numberPickerLayer addChild:problemDescLabel];
    
    // if we have the dropbox defined, then we need to set it up here
    //npDropbox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberpicker/np_dropbox.png")];
    //[npDropbox setPosition:ccp(cx,cy+50)];
    //[numberPickerLayer addChild:npDropbox z:0];
    //if(!npShowDropbox)[npDropbox setVisible:NO];
    
    // then continue and make our awesome picker dood
//    if(numberPickerType==kNumberPickerCalc)
//    {
//        int h=0;
//        
//        for(int i=0;i<3;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45+(i*75), 265)];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//        }
//        h=0;
//        for(int i=3;i<6;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45+(h*75), 190)];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//            h++;
//        }
//        h=0;
//        for(int i=6;i<9;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45+(h*75), 115)];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//            h++;
//        }
//        h=0;
//        for(int i=9;i<12;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45+(h*75), 40)];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//            h++;
//        }
//        
//    }
//    else if(numberPickerType==kNumberPickerSingleLine)
//    {
//        for(int i=0;i<12;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45+(i*75), 40)];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//            
//        }
//    }
//    else if(numberPickerType==kNumberPickerDoubleLineHoriz)
//    {
//        for (int i=0;i<6;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45+(i*75), 115)];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//        }
//        
//        int h=0;
//        for (int i=6;i<12;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45+(h*75), 40)];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//            h++;
//        }
//    }
//    else if(numberPickerType==kNumberPickerDoubleColumnVert)
//    {
//        for (int i=0;i<6;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(45, 415-(i*75))];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//        }
//        int h=0;
//        for (int i=6;i<12;i++)
//        {
//            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
//            [curSprite setPosition:ccp(120, 415-(h*75))];
//            [nPicker addChild:curSprite];
//            [numberPickerButtons addObject:curSprite];
//            h++;
//        }
//    }
//    
//    // create a picker bounding box so we can drag items back off to it later
//    pickerBox=CGRectNull;
//    
//    for (int i=0; i<[numberPickerButtons count];i++)
//    {
//        CCSprite *s=[numberPickerButtons objectAtIndex:i];
//        pickerBox=CGRectUnion(pickerBox, s.boundingBox);
//    }
    
    // if eval mode is commit, render a commit button
}

-(void)checkNumberPickerTouches:(CGPoint)location
{
    if(isAnimatingIn)return;
    
    CGPoint origloc=location;
    location=[nPicker convertToNodeSpace:location];
    
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
    // if we haven't met our max number on the number picker then carry on adding more
    if([numberPickedSelection count] <npMaxNoInDropbox) {
        BOOL isValid=YES;
        
        for(int i=0;i<[numberPickerButtons count];i++)
        {
            if(i==10||i==11)
            {
                for(NSNumber *n in numberPickedValue)
                {
                    if([n intValue]==10 && i==10)isValid=NO;
                    if([n intValue]==11 && i==11)isValid=NO;
                }
            }
            // check each of the buttons to see if it was them that were hit
            CCSprite *s=[numberPickerButtons objectAtIndex:i];
            if(CGRectContainsPoint(s.boundingBox, location) && isValid)
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
                    
                    if(i==11)
                    {
                        [curSprite runAction:[CCMoveTo actionWithDuration:kNumberPickerNumberAnimateInTime position:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/kNumberPickerSpacingFromDropboxEdge),cy+50)]];
                    }
                    else {
                        [curSprite runAction:[CCMoveTo actionWithDuration:kNumberPickerNumberAnimateInTime position:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/kNumberPickerSpacingFromDropboxEdge)+([numberPickedSelection count]*75),cy+50)]];
                    }
                }
                else {
                    if(i==11)
                    {
                        [curSprite setPosition:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/kNumberPickerSpacingFromDropboxEdge),cy+50)];
                    }
                    else
                    {
                        [curSprite runAction:[CCMoveTo actionWithDuration:kNumberPickerNumberAnimateInTime position:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/kNumberPickerSpacingFromDropboxEdge)+([numberPickedSelection count]*75),cy+50)]];
                    }
                    
                    [curSprite runAction:[CCFadeIn actionWithDuration:kNumberPickerNumberFadeInTime]];
                    
                }
                
                // then add them to our selection and value arrays
                if(i==11)
                {
                    [numberPickedSelection insertObject:curSprite atIndex:0];
                    [numberPickedValue insertObject:[NSNumber numberWithInt:i] atIndex:0];
                }
                else
                {
                    [numberPickedSelection addObject:curSprite];
                    [numberPickedValue addObject:[NSNumber numberWithInt:i]];
                }
                
                
                [self reorderNumberPickerSelections];
                
                return;
            }
        }
    }
    for(int i=0;i<[numberPickedSelection count];i++)
    {
        CCSprite *s=[numberPickedSelection objectAtIndex:i];
        int n=[[numberPickedValue objectAtIndex:i]intValue];
        if(CGRectContainsPoint(s.boundingBox, origloc))
        {
            [self playAudioPress];
            [loggingService logEvent:BL_PA_NP_NUMBER_FROM_REGISTER
                  withAdditionalData:[NSDictionary dictionaryWithObject:[numberPickedValue objectAtIndex:[numberPickedSelection indexOfObject:s]] forKey:@"number"]];
            npMove=s;
            npMoveStartPos=npMove.position;
            if(n==11)canMoveNumber=NO;
            else canMoveNumber=YES;
            
            return;
        }
    }
    
    
}

-(void)checkNumberPickerTouchOnRegister:(CGPoint)location
{
    if(!canMoveNumber)return;
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
    
    npMove.position=location;
    
}

-(void)evalNumberPicker
{
//    NSString *strEval=@"";
//    
//    for (int i=0;i<[numberPickedValue count];i++)
//    {
//        NSNumber *thisNo=[numberPickedValue objectAtIndex:i];
//        int iThisNo=[thisNo intValue];
//        NSString *strThisNo;
//        
//        if(iThisNo==10)strThisNo=@".";
//        else if(iThisNo==11)strThisNo=@"-";
//        else strThisNo=[NSString stringWithFormat:@"%d", iThisNo];
//        //strEval=[NSString stringWithFormat:@"%d", iThisNo];
//        
//        strEval=[NSString stringWithFormat:@"%@%@", strEval, strThisNo];
//        
//        NSLog(@"eval %@", strEval);
//    }
//    
//    float onDropbox=[strEval floatValue];
//    if(onDropbox==npEval)
//    {
//        [self doWinning];
//    }
//    else
//    {
//        [self doIncomplete];
//    }

    if(trayWheelShowing){
        NSString *pickerValue=[self returnPickerNumber];
        NSString *strNpEval=[NSString stringWithFormat:@"%g", npEval];
        
        if([pickerValue isEqualToString:strNpEval])
            [self doWinning];
        else
            [self doIncomplete];
    }
}

-(void)reorderNumberPickerSelections
{
    for(int i=0;i<[numberPickedSelection count];i++)
    {
        NSLog(@"value at %d is %d", i, [[numberPickedValue objectAtIndex:i]intValue]);
        CCSprite *s=[numberPickedSelection objectAtIndex:i];
        [s setPosition:ccp(cx-(npDropbox.contentSize.width/2)+(s.contentSize.width/kNumberPickerSpacingFromDropboxEdge)+(i*75),cy+50)];
        NSLog(@"sprite %d position %@", i, NSStringFromCGPoint(s.position));
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
    if(CurrentBTXE)CurrentBTXE=nil;
    toolCanEval=YES;
//    if(traybtnWheel){
//        [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_NotAvailable.png")]];
//        [traybtnWheel setColor:ccc3(255,255,255)];
//        [trayLayerWheel removeAllChildrenWithCleanup:YES];
//    }

    if(trayLayerWheel)
        [trayLayerWheel removeAllChildrenWithCleanup:YES];

    trayLayerWheel=nil;
        
//    [numberPickerLayer removeAllChildrenWithCleanup:YES];
    //numberPickerForThisProblem=NO;

    hasUsedPicker=NO;
    pickerViewSelection=nil;
    pickerView=nil;
    hasUsedWheelTray=NO;
    trayWheelShowing=NO;
//    [numberPickerLayer release];
    numberPickerLayer=nil;
}

- (void)checkUserCommit
{
    //effective user commit
    [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
    
    [currentTool evalProblem];
    
    if(currentTool.ProblemComplete)
    {
        //[self playAudioFlourish];
        
        timeBeforeUserInteraction=kDisableInteractionTime;
    }
    else {
        [self playAudioPress];
        
        //check commit threshold for insertion
        
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
        [btxeDescLayer removeAllChildrenWithCleanup:YES];
        [descGw release];
        descGw=nil;
    }
    
    descGw=[[SGGameWorld alloc] initWithGameScene:self];
    descGw.Blackboard.inProblemSetup=YES;
    
    descGw.Blackboard.RenderLayer = btxeDescLayer;
    
    //create row
    SGBtxeRow *row=[[SGBtxeRow alloc] initWithGameWorld:descGw andRenderLayer:btxeDescLayer];
    descRow=row;
    row.position=ccp(cx, (cy*2) - 130);

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
//    [readProblemDesc setOpacity:0];
//    [readProblemDesc setTag:2];
    
    qTrayTop=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/questiontray/Question_tray_Top.png")];
    qTrayMid=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/questiontray/Question_tray_Middle.png")];
    qTrayBot=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/questiontray/Question_tray_Bottom.png")];
    
    [qTrayMid setPosition:ccp(row.position.x,row.position.y+200)];
    
    [qTrayTop setPosition:ccp(qTrayMid.position.x,qTrayMid.position.y+(qTrayTop.contentSize.height/2)+qTrayMid.contentSize.height/2)];
    [qTrayBot setPosition:ccp(qTrayMid.position.x,qTrayMid.position.y-(qTrayBot.contentSize.height/2)-(qTrayMid.contentSize.height/2))];
    
    [readProblemDesc setPosition:ccp(qTrayMid.position.x+(qTrayMid.contentSize.width/2)-readProblemDesc.contentSize.width,qTrayMid.position.y-(qTrayBot.contentSize.height*1.3)-(qTrayMid.contentSize.height/2))];
    
    [qTrayTop runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayTop.position.x, qTrayTop.position.y-200)]];
    [qTrayMid runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayMid.position.x, qTrayMid.position.y-200)]];
    [qTrayBot runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayBot.position.x, qTrayBot.position.y-200)]];
    [readProblemDesc runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(readProblemDesc.position.x, readProblemDesc.position.y-200)]];
    
    
    [backgroundLayer addChild:readProblemDesc];
    [backgroundLayer addChild:qTrayTop];
    [backgroundLayer addChild:qTrayBot];
    [backgroundLayer addChild:qTrayMid];
    
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

    timeSinceInteractionOrShake=0.0f;
    
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
    
    //delegate touch handling for trays here
    if(((location.x>CORNER_TRAY_POS_X && location.y>CORNER_TRAY_POS_Y)&&(trayCalcShowing||trayPadShowing)) || (trayMqShowing && CGRectContainsPoint(metaQuestionBanner.boundingBox, location))||location.y>ly-HD_HEADER_HEIGHT)
    {
        if (location.x < 100 && location.y > 688 && !isPaused)
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
        if(trayPadShowing)
        {
            if(CGRectContainsPoint(traybtnPad.boundingBox, location))
            {
                [self removeAllTrays];
            }
            else
            {
                return;
            }
        }
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
    
    if(traybtnPad && CGRectContainsPoint(bbPad, location))
    {
        if(trayPadShowing)
        {
            [self hidePad];
            //[self hideCornerTray];
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

-(void)showCornerTray
{
    if(!trayCornerShowing)
    {
        //do stuff
        //descRow.position=ccp(350.0f, (cy*2)-95);
        [descRow animateAndMoveToPosition:ccp(360.0f, (cy*2)-130)];
        
        [descRow relayoutChildrenToWidth:625];
        
        [qTrayTop runAction:[CCScaleTo actionWithDuration:0.2f scaleX:0.7f scaleY:qTrayTop.scaleY]];
        [qTrayMid runAction:[CCScaleTo actionWithDuration:0.2f scaleX:0.7f scaleY:qTrayMid.scaleY]];
        [qTrayBot runAction:[CCScaleTo actionWithDuration:0.2f scaleX:0.7f scaleY:qTrayBot.scaleY]];
        
        [qTrayTop runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayTop.position.x-(cx/3.1), qTrayTop.position.y)]];
        [qTrayMid runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayMid.position.x-(cx/3.1), qTrayMid.position.y)]];
        [qTrayBot runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayBot.position.x-(cx/3.1), qTrayBot.position.y)]];
        [readProblemDesc runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(readProblemDesc.position.x-(cx/1.65), qTrayMid.position.y-(qTrayBot.contentSize.height*1.3)-(qTrayMid.contentSize.height/2))]];
        
//        [qTrayTop setScaleX:0.7];
//        [qTrayMid setScaleX:0.7];
//        [qTrayBot setScaleX:0.7];
        
//        [qTrayTop setPosition:ccp(qTrayTop.position.x-(cx/3.1), qTrayTop.position.y)];
//        [qTrayMid setPosition:ccp(qTrayTop.position.x, qTrayMid.position.y)];
//        [qTrayBot setPosition:ccp(qTrayTop.position.x, qTrayBot.position.y)];
        
        trayCornerShowing=YES;
    }
}

-(void)hideCornerTray
{
    if(trayCornerShowing)
    {
        //do stuff
        //descRow.position=ccp(cx, (cy*2) - 95);

//        [qTrayTop setScaleX:1.0];
//        [qTrayMid setScaleX:1.0];
//        [qTrayBot setScaleX:1.0];
//        
//        [qTrayTop setPosition:ccp(qTrayTop.position.x+(cx/3.1), qTrayTop.position.y)];
//        [qTrayMid setPosition:ccp(qTrayTop.position.x, qTrayMid.position.y)];
//        [qTrayBot setPosition:ccp(qTrayTop.position.x, qTrayBot.position.y)];

        [qTrayTop runAction:[CCScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:qTrayTop.scaleY]];
        [qTrayMid runAction:[CCScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:qTrayMid.scaleY]];
        [qTrayBot runAction:[CCScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:qTrayBot.scaleY]];
        
        [qTrayTop runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayTop.position.x+(cx/3.1), qTrayTop.position.y)]];
        [qTrayMid runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayMid.position.x+(cx/3.1), qTrayMid.position.y)]];
        [qTrayBot runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(qTrayBot.position.x+(cx/3.1), qTrayBot.position.y)]];
        [readProblemDesc runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(readProblemDesc.position.x+(cx/1.65), qTrayMid.position.y-(qTrayBot.contentSize.height*1.3)-(qTrayMid.contentSize.height/2))]];
        
        [descRow animateAndMoveToPosition:ccp(cx, (cy*2) - 130)];
        
        [descRow relayoutChildrenToWidth:BTXE_ROW_DEFAULT_MAX_WIDTH];
        
        trayCornerShowing=NO;
    }
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
        
        //CCLabelTTF *lbl=[CCLabelTTF labelWithString:@"Wheel" fontName:@"Source Sans Pro" fontSize:24.0f];
        //lbl.position=ccp(150,112.5f);
        //[trayLayerWheel addChild:lbl];
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
    
    if(hasTrayWheel)
        [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_Available.png")]];
    else
        [traybtnWheel setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_NumberWheel_NotAvailable.png")]];
}

-(void)showPad
{
    if(!trayLayerPad)
    {
        //trayLayerPad=[CCLayerColor layerWithColor:ccc4(255, 255, 255, 100) width:300 height:225];
        trayLayerPad=[[CCLayer alloc]init];
        [trayLayerPad addChild:[LineDrawer node]];
        [problemDefLayer addChild:trayLayerPad z:-1];
        //trayLayerPad.position=ccp(CORNER_TRAY_POS_X, CORNER_TRAY_POS_Y);
        
        CCLabelTTF *lbl=[CCLabelTTF labelWithString:@"Notepad" fontName:@"Source Sans Pro" fontSize:24.0f];
        lbl.position=ccp(150,112.5f);
        [trayLayerPad addChild:lbl];
    }
    [btxeDescLayer setVisible:NO];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_notepad_tool_appears.wav")];
    trayLayerPad.visible=YES;
    trayPadShowing=YES;
//    [traybtnPad setColor:ccc3(247,143,6)];
    [traybtnPad setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Notepad_Selected.png")]];
}

-(void)hidePad
{
    if(doPlaySound)
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_tray_notepad_tool_disappears.wav")];

    trayLayerPad.visible=NO;
    trayPadShowing=NO;
//    [traybtnPad setColor:ccc3(255,255,255)];
    [traybtnPad setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/tray/Tray_Button_Notepad_Available.png")]];
    //[btxeDescLayer setVisible:YES];
}

//-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    if(isPaused||autoMoveToNextProblem)
//    {
//        return NO;
//    }  
//    return [currentTool ccTouchBegan:touch withEvent:event];
//}
//
//-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    if(isPaused||autoMoveToNextProblem)
//    {
//        return;
//    }  
//    [currentTool ccTouchMoved:touch withEvent:event];
//}
//
//-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    if(isPaused||autoMoveToNextProblem)
//    {
//        return;
//    }  
//    [currentTool ccTouchEnded:touch withEvent:event];
//}
//
//-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    if(npMove)npMove=nil;
//    [currentTool ccTouchCancelled:touch withEvent:event];
//}

#pragma mark - CCPickerView for number wheel

-(void)setupNumberWheel
{
    if(self.pickerView) return;
    
    NSString *strSprite=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_bg.png",[self numberOfComponentsInPickerView:self.pickerView]];
//    NSString *strULSprite=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ul.png",[self numberOfComponentsInPickerView:self.pickerView]];
    CCSprite *ovSprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(strSprite)];
//    CCSprite *ulSprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(strULSprite)];
    
    self.pickerView = [CCPickerView node];
    if(currentTool)
        pickerView.position=ccp(lx-kComponentSpacing-(ovSprite.contentSize.width/2),ly-180);
    else
        pickerView.position=ccp(cx,cy);
    pickerView.dataSource = self;
    pickerView.delegate = self;

    
    if(CurrentBTXE && ([((id<Text>)CurrentBTXE).text floatValue]>0 || [((id<Text>)CurrentBTXE).text floatValue]<0))
        [self updatePickerNumber:((id<Text>)CurrentBTXE).text];
    

    
//    [ulSprite setPosition:pickerView.position];

    
    
    [ovSprite setPosition:pickerView.position];
    [trayLayerWheel addChild:ovSprite z:18];
//    [trayLayerWheel addChild:ulSprite z:19];
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
    
    //        [w.pickerViewSelection removeAllObjects];
    
    int thisComponent=[self numberOfComponentsInPickerView:self.pickerView]-1;
    int numberOfComponents=thisComponent;
    
    for(int i=[thisNumber length]-1;i>=0;i--)
    {
        NSString *thisStr=[NSString stringWithFormat:@"%c",[thisNumber characterAtIndex:i]];
        int thisInt=[thisStr intValue];
        
        [pickerViewSelection replaceObjectAtIndex:thisComponent withObject:[NSNumber numberWithInt:thisInt]];
        
        //            [w.pickerViewSelection addObject:[NSNumber numberWithInt:thisInt]];
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
//    CGRect f=CGRectMake(100, 100, (2*cx)-200, (2*cy)-200);
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
    
    if(self.pickerView)[self.pickerView release];
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
    
    [super dealloc];
}

@end
