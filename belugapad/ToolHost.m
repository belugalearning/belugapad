//
//  ToolHost.m
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolHost.h"
#import "ToolConsts.h"
#import "BlockFloating.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "BLMath.h"
#import "Daemon.h"
#import "ToolScene.h"
#import "AppDelegate.h"
#import "BAExpressionHeaders.h"
#import "BATio.h"
#import "LoggingService.h"
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

static float kMoveToNextProblemTime=2.0f;
static float kTimeToShakeNumberPickerButtons=7.0f;

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
        
        //setup layer sequence
        backgroundLayer=[[CCLayer alloc] init];
        [self addChild:backgroundLayer z:-2];
        perstLayer=[[CCLayer alloc] init];
        [self addChild:perstLayer z:0];
        
        animator=[[LRAnimator alloc] init];
        [animator setBackground:backgroundLayer withCx:cx withCy:cy];
        
        [animator animateBackgroundIn];
        animPos=1;
        
        [self setupTouchLogging];
        
        //[self scheduleOnce:@selector(moveToTool1:) delay:1.5f];
        
        //add a pause button but keep it hidden -- to be brought in by the fader
        CCSprite *pause=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/button-pause.png")];
        [pause setPosition:ccp(lx-(kPropXPauseButtonPadding*lx), ly-(kPropXPauseButtonPadding*lx))];
        [perstLayer addChild:pause z:3];        


        metaQuestionLayer=[[CCLayer alloc] init];
        [self addChild:metaQuestionLayer z:2];
        problemDefLayer=[[CCLayer alloc] init];
        [self addChild:problemDefLayer z:3];
        
        pauseLayer=[[CCLayer alloc]init];
        [self addChild:pauseLayer z:4];
        
        [self populatePerstLayer];
        
        //dynamic problem parser (persists to end of pipeline)
        DynProblemParser=[[[DProblemParser alloc] init] retain];
        
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

#pragma mark



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
    if((currentTool.ProblemComplete || metaQuestionForceComplete) && !autoMoveToNextProblem)
    {   
        [Zubi createXPshards:100 fromLocation:ccp(cx, cy)];

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
    Zubi=[[Daemon alloc] initWithLayer:perstLayer andRestingPostion:ccp(50,50) andLy:ly];
    [Zubi hideZubi];
}

-(void) shakeCommitButton
{
    [commitBtn runAction:[InteractionFeedback dropAndBounceAction]];
}

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
    
    [contentService gotoNextProblemInPipeline];
    
    //check that the content service found a pdef (this will be the raw dynamic one)
    if(contentService.currentPDef)
    {
        [self loadProblem];
    }
    else
    {
        //no more problems in this sequence, bail to menu
        
        //assume completion
        [contentService setPipelineNodeComplete];
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
        [self removeChild:toolBackLayer cleanup:YES];
        [self removeChild:toolForeLayer cleanup:YES];
        [self removeChild:toolNoScaleLayer cleanup:YES];
        [currentTool release];
        currentTool=nil;
    }
    
    //reset multitouch
    //if tool requires multitouch, it will need to reset accordingly
    //for multi-touch scaling we need to force this on
    [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
    
    //reset scale
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
    
    
    //glossary mockup
    if([pdef objectForKey:@"GLOSSARY"])
    {
        isGlossaryMock=YES;
        glossary1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/glossary/GlossaryExample.png")];
        [glossary1 setPosition:ccp(cx,cy)];
        [self addChild:glossary1];
        [problemDescLabel setVisible:NO];
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
    
    //write the problem attempt id into the touch log for reconciliation
    [self logTouchProblemAttemptID:loggingService.currentProblemAttemptID];
}

-(void) resetProblem
{
    if(problemDescLabel)[problemDescLabel removeFromParentAndCleanup:YES];
    if(commitBtn)[commitBtn removeFromParentAndCleanup:YES];
    
    skipNextStagedIntroAnim=YES;
    
    [self loadProblem];
}

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
    if(CGRectContainsPoint(kPauseMenuLogOut, location))
    {
        [loggingService logEvent:BL_USER_LOGOUT withAdditionalData:nil];
        [usersService setCurrentUserToUserWithId:nil];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [(AppController*)[[UIApplication sharedApplication] delegate] returnToLogin];
    }
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    if (!ac.ReleaseMode && location.x>cx && location.y < 768 - kButtonToolbarHitBaseYOffset)
    {
        [loggingService logEvent:BL_PA_SKIP_DEBUG withAdditionalData:nil];
        isPaused=NO;
        [pauseLayer setVisible:NO];
        [self gotoNewProblem];
    }
}

-(void) returnToMenu
{
    [[CCDirector sharedDirector] replaceScene:[JMap scene]];
}

-(void) showProblemCompleteMessage
{
    problemComplete = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/complete-overlay.png")];
    [problemComplete setPosition:ccp(cx, cy)];
    [problemDefLayer addChild:problemComplete];
    showingProblemComplete=YES;
    [problemComplete retain];
}

-(void) showProblemIncompleteMessage
{
    BOOL addToLayer=NO;
    if(!problemIncomplete)
    {
        problemIncomplete = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/failed-overlay.png")];
        addToLayer=YES;
    }
    [problemIncomplete setPosition:ccp(cx,cy)];
    [problemIncomplete setOpacity:255];
    if(addToLayer) [problemDefLayer addChild:problemIncomplete];
    showingProblemIncomplete=YES;
    [problemIncomplete retain];
}

-(void)setupProblemOnToolHost:(NSDictionary *)curpdef
{
    NSNumber *eMode=[curpdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    else if(eMode && numberPickerForThisProblem) evalMode=kProblemEvalOnCommit;
    else evalMode=kProblemEvalAuto;
    
    if([curpdef objectForKey:DEFAULT_SCALE])
        scale=[[curpdef objectForKey:DEFAULT_SCALE]floatValue];
    else 
        scale=1.0f;
    
    [toolBackLayer setScale:scale];
    [toolForeLayer setScale:scale];
    
    NSString *labelDesc=[self.DynProblemParser parseStringFromValueWithKey:PROBLEM_DESCRIPTION inDef:curpdef];
    
    //problemDescLabel=[CCLabelTTF labelWithString:labelDesc fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    problemDescLabel=[CCLabelTTF labelWithString:labelDesc dimensions:CGSizeMake(lx*kLabelTitleXMarginProp, cy) alignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeWordWrap fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    //[problemDescLabel setPosition:ccp(cx, cy)];
    //[problemDescLabel setColor:kLabelTitleColor];
    [problemDescLabel setTag:3];
    [problemDescLabel setOpacity:0];
    [problemDefLayer addChild:problemDescLabel];
    
    if(evalMode==kProblemEvalOnCommit)
    {
        commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/commit.png")];
        [commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [problemDefLayer addChild:commitBtn z:2];
    }
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
    
    //render problem label
    //problemDescLabel=[CCLabelTTF labelWithString:[pdefMQ objectForKey:META_QUESTION_TITLE] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    problemDescLabel=[CCLabelTTF labelWithString:[pdefMQ objectForKey:META_QUESTION_TITLE] dimensions:CGSizeMake(lx*kLabelTitleXMarginProp, cy) alignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeWordWrap fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    [problemDescLabel setColor:kMetaQuestionLabelColor];
    [problemDescLabel setOpacity:0];
    [problemDescLabel setTag:3];
    
    [metaQuestionLayer addChild:problemDescLabel];
    
    // check the answer mode and assign
    NSNumber *aMode=[pdefMQ objectForKey:META_QUESTION_ANSWER_MODE];
    if (aMode) mqAnswerMode=[aMode intValue];
    
    // check the eval mode and assign
    NSNumber *eMode=[pdefMQ objectForKey:META_QUESTION_EVAL_MODE];
    if(eMode) mqEvalMode=[eMode intValue];
    
    // put our array of answers in an ivar
//    metaQuestionAnswers = [pdefMQ objectForKey:META_QUESTION_ANSWERS];
    metaQuestionAnswerCount = [[pdefMQ objectForKey:META_QUESTION_ANSWERS] count];
    NSArray *pdefAnswers=[pdefMQ objectForKey:META_QUESTION_ANSWERS];
    
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
        CCLabelTTF *answerLabel = [CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        
        // sort out the labels and buttons if there's an answer text
        if([[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT])
        {
            // sort out the buttons
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")];
            
            // then the answer label
            NSString *answerLabelString=[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT];
            [answerLabel setString:answerLabelString];
        }
        // there should never be both an answer text and custom sprite defined - so if no answer text, only render the SPRITE_FILENAME
        else
        {
            // sort out the button with a custom sprite 
            answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[metaQuestionAnswers objectAtIndex:i] objectForKey:SPRITE_FILENAME])];
        }
        
        // render buttons
        [answerBtn setPosition:ccp((i+1)*(lx/(metaQuestionAnswerCount+1)), answersY)];
        [answerBtn setTag:3];
        [answerBtn setScale:0.5f];
        [answerBtn setOpacity:0];
        [metaQuestionLayer addChild:answerBtn];
        [metaQuestionAnswerButtons addObject:answerBtn];
        
        
        // check for text, render if nesc
        if(![answerLabel.string isEqualToString:@""])
        {
            [answerLabel setPosition:ccp((i+1)*(lx/(metaQuestionAnswerCount+1)), answersY)];
            [answerLabel setColor:kMetaAnswerLabelColor];
            [answerLabel setOpacity:0];
            [answerLabel setTag: 3];
            [metaQuestionLayer addChild:answerLabel];
            [metaQuestionAnswerLabels addObject:answerLabel];
        }
        
        // set a new value in the array so we can see that it's not currently selected
        [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
    }
        
    [metaQuestionAnswers retain];
    [metaQuestionAnswerButtons retain];
    [metaQuestionAnswerLabels retain];
    [metaQuestionCompleteText retain];
    [metaQuestionIncompleteText retain];
    
    // if eval mode is commit, render a commit button
    if(mqEvalMode==kMetaQuestionEvalOnCommit)
    {
        commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/commit.png")];
        [commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [metaQuestionLayer addChild:commitBtn z:2];
    }
    
}

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
    [numberPickerButtons retain];
    
    numberPickedSelection=[[NSMutableArray alloc]init];
    [numberPickedSelection retain];
    
    numberPickedValue=[[NSMutableArray alloc]init];
    [numberPickedValue retain];
    

    
    nPicker=[[CCNode alloc]init];
    [nPicker setPosition:ccp(npOriginX,npOriginY)];
    
    numberPickerLayer=[[CCLayer alloc]init];
    [self addChild:numberPickerLayer z:2];
    [numberPickerLayer addChild:nPicker];
    
    //render problem label
    //problemDescLabel=[CCLabelTTF labelWithString:[pdefNP objectForKey:NUMBER_PICKER_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    problemDescLabel=[CCLabelTTF labelWithString:[pdefNP objectForKey:NUMBER_PICKER_DESCRIPTION] dimensions:CGSizeMake(lx*kLabelTitleXMarginProp, cy) alignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeWordWrap fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    [problemDescLabel setColor:kMetaQuestionLabelColor];
    [problemDescLabel setOpacity:0];
    [problemDescLabel setTag:3];
    
    [numberPickerLayer addChild:problemDescLabel];

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
        commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/commit.png")];
        [commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [commitBtn setTag:3];
        [commitBtn setOpacity:0];
        [metaQuestionLayer addChild:commitBtn z:2];
    }
    
}

-(void)checkNumberPickerTouches:(CGPoint)location
{
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
}

-(void)tearDownMetaQuestion
{
    [metaQuestionLayer removeAllChildrenWithCleanup:YES];
    
    metaQuestionForThisProblem=NO;
    metaQuestionForceComplete=NO;
}

-(void)tearDownProblemDef
{
    [problemDefLayer removeAllChildrenWithCleanup:YES];
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

-(void)stageIntroActions
{
    //TODO tags are currently fixed to 2 phases -- either parse tool tree or pre-populate with design-fixed max
    for (int i=1; i<=3; i++) {
        
        int time=i;
        if(skipNextStagedIntroAnim) time=0;
        
        [self recurseSetIntroFor:toolBackLayer withTime:time forTag:i];
        [self recurseSetIntroFor:toolForeLayer withTime:time forTag:i];
        [self recurseSetIntroFor:toolNoScaleLayer withTime:time forTag:i];
        [self recurseSetIntroFor:metaQuestionLayer withTime:time forTag:i];
        [self recurseSetIntroFor:problemDefLayer withTime:time forTag:i];
        [self recurseSetIntroFor:numberPickerLayer withTime:time forTag:i];
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

-(void)checkMetaQuestionTouches:(CGPoint)location
{
    if (CGRectContainsPoint(kRectButtonCommit, location) && mqEvalMode==kMetaQuestionEvalOnCommit)
    {
        //effective user commit
        [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
        
        [self evalMetaQuestion];
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
                
                // then if it's an answer and isn't currently selected
                if(!isSelected)
                {
                    // the user has changed their answer (even if they didn't have one before)
                    [loggingService logEvent:BL_PA_MQ_CHANGE_ANSWER
                        withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"selection"]];
                    // check what answer mode we have
                    // if single, we should only only be able to select one so we need to deselect the others and change the selected value
                    if(mqAnswerMode==kMetaQuestionAnswerSingle)
                    {
                        [self deselectAnswersExcept:i];
                        
                        // if this is an auto eval, run the eval now
                        if(mqEvalMode==kMetaQuestionEvalAuto)
                        {
                            [self evalMetaQuestion];
                        }
                    }
                    
                    // otherwise we can select multiple
                    else if(mqAnswerMode==kMetaQuestionAnswerMulti)
                    {
                        [answerBtn setColor:kMetaQuestionButtonSelected];
                        [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
                    }
                }
                else
                {
                    // return to full button colour and set the dictionary selected value to no
                    [answerBtn setColor:kMetaQuestionButtonDeselected];
                    [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
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
        if(i == answerNumber)
        {
            [answerBtn setColor:kMetaQuestionButtonSelected];
            [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:YES] forKey:META_ANSWER_SELECTED];
        }
        else 
        {
            [answerBtn setColor:kMetaQuestionButtonDeselected];
            [[metaQuestionAnswers objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:META_ANSWER_SELECTED];
        }
    }
}
-(void)doWinning
{
    [loggingService logEvent:BL_PA_SUCCESS withAdditionalData:nil];
    [self removeMetaQuestionButtons];
    [self showProblemCompleteMessage];
    currentTool.ProblemComplete=YES;
    metaQuestionForceComplete=YES;
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

-(void)setupTouchLogging
{
    //get logging path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    touchLogPath=[documentsDirectory stringByAppendingPathComponent:[[BLFiles generateUuidString] stringByAppendingString:@".log"]];
    [touchLogPath retain];
    
    NSString *header=[NSString stringWithFormat:@"logging at %f: ", [[NSDate date] timeIntervalSince1970]];
    [header writeToFile:touchLogPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void)logTouchProblemAttemptID:(NSString*)paid
{
    NSString *item=[NSString stringWithFormat:@" problemattempt %@ ", paid];
    
    NSFileHandle *myHandle = [NSFileHandle fileHandleForUpdatingAtPath:touchLogPath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[item dataUsingEncoding:NSUTF8StringEncoding]];
    [myHandle closeFile];
}

-(void)logTouches:(NSSet*)touches forEvent:(NSString*)event
{
    NSString *item=[NSString stringWithFormat:@" %@ %f ", event, [[NSDate date] timeIntervalSince1970]];
    
    for (UITouch *t in touches) {
        item=[item stringByAppendingString:[NSString stringWithFormat:@"{%@,%@},", NSStringFromCGPoint([t locationInView:t.view]), NSStringFromCGPoint([t previousLocationInView:t.view])]];
    }
    
    NSFileHandle *myHandle = [NSFileHandle fileHandleForUpdatingAtPath:touchLogPath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[item dataUsingEncoding:NSUTF8StringEncoding]];
    [myHandle closeFile];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;

    [self logTouches:touches forEvent:@"b"];

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
    if(isPaused)
    {
        return;
    }  
    
    if(isGlossaryMock)
    {
        if (glossaryShowing) {
            [self removeChild:glossaryPopup cleanup:YES];
            glossaryShowing=NO;
        }
        
        else if(CGRectContainsPoint(CGRectMake(450, 650, 200, 150), location))
        {
            glossaryPopup=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/glossary/GlossaryPopup.png")];
            [glossaryPopup setPosition:ccp(cx, cy)];
            [self addChild:glossaryPopup z:10];
            glossaryShowing=YES;
            
            //swap to stage two?
            if(!isGloassryDone1)
            {
                [self removeChild:glossary1 cleanup:YES];
                glossary2=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/glossary/GlossaryExampleTapped.png")];
                [glossary2 setPosition:ccp(cx,cy)];
                [self addChild:glossary2];
                isGloassryDone1=YES;
            }
        }
    }
    
    if(metaQuestionForThisProblem)
        [self checkMetaQuestionTouches:location];
    else if(numberPickerForThisProblem)
        [self checkNumberPickerTouches:location];
    
    
    // TODO: This should be made proportional
    
    if (CGRectContainsPoint(kRectButtonCommit, location) && evalMode==kProblemEvalOnCommit)
    {
        
        
        //effective user commit
        [loggingService logEvent:BL_PA_USER_COMMIT withAdditionalData:nil];
        
        [currentTool evalProblem];
        
        if(currentTool.ProblemComplete)
        {
            [self playAudioFlourish];
        }
        else {
            [self playAudioPress];
        }
    }
    if (location.x > 944 && location.y > 688 && !isPaused)
    {
        [self showPauseMenu];
        return;
    }
    
    [currentTool ccTouchesBegan:touches withEvent:event];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    [self logTouches:touches forEvent:@"m"];
    
    if(isPaused)
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
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    [self logTouches:touches forEvent:@"e"];
    
    // if we're paused - check if any menu options were valid.
    // touches ended event becase otherwise these touches go through to the tool
    if(isPaused)
    {
        [self checkPauseTouches:location];
        return;
    }
    if(npMove)
    {
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
        if(hasMovedNumber)
        {
            [loggingService logEvent:BL_PA_NP_NUMBER_MOVE
                withAdditionalData:[NSDictionary dictionaryWithObject:[numberPickedValue objectAtIndex:[numberPickedSelection indexOfObject:npMove]]
                                                               forKey:@"number"]];
        }
        
        npMove=nil;
        npLastMoved=nil;
        hasMovedNumber=NO;
    }
    
    [currentTool ccTouchesEnded:touches withEvent:event];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    hasMovedNumber=NO;
    if(npMove)npMove=nil;
    npLastMoved=nil;
    [currentTool ccTouchesCancelled:touches withEvent:event];
    
    [self logTouches:touches forEvent:@"c"];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(isPaused)
    {
        return NO;
    }  
    return [currentTool ccTouchBegan:touch withEvent:event];
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(isPaused)
    {
        return;
    }  
    [currentTool ccTouchMoved:touch withEvent:event];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(isPaused)
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
    if(metaQuestionCompleteText)[metaQuestionCompleteText release];
    if(metaQuestionIncompleteLabel)[metaQuestionIncompleteText release];
    if(problemComplete)[problemComplete release];
    if(problemIncomplete)[problemIncomplete release];
    //if(problemDescLabel)[problemDescLabel release];
    if(numberPickerButtons)[numberPickerButtons release];
    if(numberPickedSelection)[numberPickedSelection release];
    if(numberPickedValue)[numberPickedValue release];
    
    [DynProblemParser release];
    
    [super dealloc];
}

@end
