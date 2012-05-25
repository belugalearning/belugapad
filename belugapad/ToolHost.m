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
#import "ContentService.h"
#import "UsersService.h"
#import "JourneyScene.h"
#import "DProblemParser.h"
#import "Problem.h"
#import "Pipeline.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchModelFactory.h>
#import "NordicAnimator.h"

@interface ToolHost()
{
    @private
    ContentService *contentService;
}

@end

@implementation ToolHost

@synthesize Zubi;
@synthesize PpExpr;
@synthesize flagResetProblem;
@synthesize DynProblemParser;

static float kMoveToNextProblemTime=2.0f;

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
        
        animator=[[NordicAnimator alloc] init];
        [animator setBackground:backgroundLayer withCx:cx withCy:cy];
        
        [animator animateBackgroundIn];
        animPos=1;
        
        [self scheduleOnce:@selector(moveToTool1:) delay:1.5f];
        
        //add a pause button but keep it hidden -- to be brought in by the fader
        CCSprite *pause=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/button-pause.png")];
        [pause setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), ly-(kPropXCommitButtonPadding*lx))];
        [backgroundLayer addChild:pause z:3];        


        metaQuestionLayer=[[CCLayer alloc] init];
        [self addChild:metaQuestionLayer z:2];
        problemDefLayer=[[CCLayer alloc] init];
        [self addChild:problemDefLayer z:3];
        
        pauseLayer=[[CCLayer alloc]init];
        [self addChild:pauseLayer z:4];
        
        [self populatePerstLayer];
        
        //dynamic problem parser (persists to end of pipeline)
        self.DynProblemParser=[[DProblemParser alloc] init];
        
        contentService = ((AppController*)[[UIApplication sharedApplication] delegate]).contentService;        
        
        [self scheduleOnce:@selector(gotoFirstProblem:) delay:3.0f];
        //[self gotoNewProblem];
        
        [self schedule:@selector(doUpdateOnTick:) interval:1.0f/60.0f];
        [self schedule:@selector(doUpdateOnSecond:) interval:1.0f];
        [self schedule:@selector(doUpdateOnQuarterSecond:) interval:1.0f/40.0f];
        
    }
    
    return self;
}

#pragma mark animation and transisitons

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

-(void)draw
{
    [currentTool draw];
}

-(void)doUpdateOnTick:(ccTime)delta
{
    //do internal mgmt updates
    [self.Zubi doUpdate:delta];
    
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
    
    //let tool do updates
    [currentTool doUpdateOnTick:delta];
}

-(void)doUpdateOnSecond:(ccTime)delta
{
    if(showMetaQuestionIncomplete) shownMetaQuestionIncompleteFor+=delta;
    
    //do internal mgmt updates
    //don't eval if we're in an auto move to next problem
    if((currentTool.ProblemComplete || metaQuestionForceComplete) && !autoMoveToNextProblem)
    {
        UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
        [us endProblemAttempt:YES];

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
        
        /********
         * Gareth:
         * Note from Nick - what used to happen, and probably should again as soon as is convenient, is that completion events (then topic/module/element, now pipeline/node) were stored on the associated ProblemAttempt document.
         * What had been completed was calculated in UsersService#endProblemAttempt.
         * The events strings were taken form UsersService#userEventsString
        ********/
        
        
        //assume completion
        [contentService setPipelineNodeComplete];
        contentService.fullRedraw=YES;
        contentService.lightUpProgressFromLastNode=YES;
        
        [[CCDirector sharedDirector] replaceScene:[JourneyScene scene]];
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

    //not often used, but retain local ref to the content service's loaded ppexpr
    self.PpExpr = contentService.currentPExpr;
    
    
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
    
    //initialize tool scene
    currentTool=[NSClassFromString(toolKey) alloc];
    [currentTool initWithToolHost:self andProblemDef:pdef];
    
    //read our tool specific options
    [self readToolOptions:toolKey];
    
    
    //setup background png / underlay
    NSString *hostBackgroundFile=[pdef objectForKey:@"HOST_BACKGROUND_IMAGE"];
    if(hostBackgroundFile)
    {
        hostBackground=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(hostBackgroundFile)];
        [hostBackground setPosition:ccp(cx, cy)];
        [self addChild:hostBackground];
    }
    
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
        [self setupNumberPicker:np];
    }
    else {
        [self setupProblemOnToolHost:pdef];
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
    
    UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
    [us startProblemAttempt];
}

-(void) resetProblem
{
    skipNextStagedIntroAnim=YES;
    
    UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
    [us endProblemAttempt:NO];
    
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
        NSLog(@"pausing in problem document %@ in pipeline %@", contentService.currentProblem.document.documentID, contentService.currentPipeline.document.documentID);
    }
    
    UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
    [us togglePauseProblemAttempt];
}

-(void) checkPauseTouches:(CGPoint)location
{
    if(CGRectContainsPoint(kPauseMenuContinue, location))
    {
        //resume
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [pauseLayer setVisible:NO];
        isPaused=NO;
        
        UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
        [us togglePauseProblemAttempt];
    }
    if(CGRectContainsPoint(kPauseMenuReset, location))
    {
       //reset
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self resetProblem];
        [pauseLayer setVisible:NO];
        isPaused=NO;
    }
    if(CGRectContainsPoint(kPauseMenuMenu,location))
    {

        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self returnToMenu];


    }
    if (location.x<cx && location.y > kButtonToolbarHitBaseYOffset)
    {
        isPaused=NO;
        [pauseLayer setVisible:NO];
        [self gotoNewProblem];
    }      
}

-(void) returnToMenu
{
    [[CCDirector sharedDirector] replaceScene:[JourneyScene scene]];
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
    else evalMode=kProblemEvalAuto;
    
    if([curpdef objectForKey:DEFAULT_SCALE])
        scale=[[curpdef objectForKey:DEFAULT_SCALE]floatValue];
    else 
        scale=1.0f;
    
    [toolBackLayer setScale:scale];
    [toolForeLayer setScale:scale];
    
    NSString *labelDesc=[self.DynProblemParser parseStringFromValueWithKey:PROBLEM_DESCRIPTION inDef:curpdef];
    
    problemDescLabel=[CCLabelTTF labelWithString:labelDesc fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    //[problemDescLabel setColor:kLabelTitleColor];
    [problemDescLabel setTag:3];
    [problemDescLabel setOpacity:0];
    [problemDefLayer addChild:problemDescLabel];
    
    if(evalMode==kProblemEvalOnCommit)
    {
        CCSprite *commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/commit.png")];
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
    
    float titleY=cy*1.75f;
    float answersY=cy*0.40;
    if(currentTool)
    {
        titleY=[currentTool metaQuestionTitleYLocation];
        answersY=[currentTool metaQuestionAnswersYLocation];
    }
    
    //render problem label
    problemDescLabel=[CCLabelTTF labelWithString:[pdefMQ objectForKey:META_QUESTION_TITLE] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, titleY)];
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
        
        CCSprite *answerBtn = [[CCSprite alloc]init];
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
        CCSprite *commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/commit.png")];
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
        npMaxNoInDropbox=5;

    
    
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
    
    float titleY=cy*1.75f;
    //render problem label
    problemDescLabel=[CCLabelTTF labelWithString:[pdefNP objectForKey:NUMBER_PICKER_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, titleY)];
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
            [curSprite setPosition:ccp(30+(i*55), 200)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
        }
        h=0;
        for(int i=3;i<6;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(30+(h*55), 145)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }        
        h=0;
        for(int i=6;i<9;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(30+(h*55), 90)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }
        h=0;
        for(int i=9;i<11;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(30+(h*55), 35)];
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
            [curSprite setPosition:ccp(30+(i*55), 30)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            
        }
    }
    else if(numberPickerType==kNumberPickerDoubleLineHoriz)
    {
        for (int i=0;i<6;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(30+(i*55), 100)];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
        }
        
        int h=0;
        for (int i=6;i<11;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(30+(h*55), 45)];
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
            [curSprite setPosition:ccp(30, 300-(i*55))];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
        }
        int h=0;
        for (int i=6;i<11;i++)
        {
            CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
            [curSprite setPosition:ccp(85, 300-(h*55))];
            [nPicker addChild:curSprite];
            [numberPickerButtons addObject:curSprite];
            h++;
        }    
    }
    // if eval mode is commit, render a commit button
    if(numberPickerEvalMode==kNumberPickerEvalOnCommit)
    {
        CCSprite *commitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/commit.png")];
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
    
    if(numberPickerEvalMode==kNumberPickerEvalOnCommit)
    {
        if(CGRectContainsPoint(kRectButtonCommit, origloc))
        {
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
                CCSprite *curSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/numberpicker/%d.png"), i]];
                [numberPickerLayer addChild:curSprite];
                
                // check if we're animating our buttons or fading them in
                if(animatePickedButtons) {
                    // and set the position/actions
                    [curSprite setPosition:[nPicker convertToWorldSpace:s.position]];                
                    [curSprite runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/1.25)+([numberPickedSelection count]*55),cy+50)]];
                }
                else {
                    [curSprite setPosition:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/1.25)+([numberPickedSelection count]*55),cy+50)];                
                    [curSprite runAction:[CCFadeIn actionWithDuration:0.5f]];

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
            npMove=s;
            npMoveStartPos=npMove.position;
            return;
        }
    }
    
    
}

-(void)evalNumberPicker
{
    NSString *strEval=[[NSString alloc]init];
    
    for (int i=0;i<[numberPickedValue count];i++)
    {
        NSNumber *thisNo=[numberPickedValue objectAtIndex:i];
        int iThisNo=[thisNo intValue];
        NSString *strThisNo=[[NSString alloc] init];
        
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
        [s setPosition:ccp(cx-(npDropbox.contentSize.width/2)+(s.contentSize.width/1.25)+(i*55),cy+50)];

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
    [self removeMetaQuestionButtons];
    [self showProblemCompleteMessage];
    currentTool.ProblemComplete=YES;
    metaQuestionForceComplete=YES;
}
-(void)doIncomplete
{   
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
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;
    
    if(animPos==0)
    {
        animPos++;
        [self moveToTool1:0];
    }
    
    if(animPos==1)
    {
        animPos++;
        [self moveToTool2:0];
    }
    else if(animPos==2)
    {
        animPos++;
        [self moveToTool3:0];
    }
    else if (animPos==3) {
        animPos=1;
        [self moveToTool0:0];
    }
    
    if(metaQuestionForThisProblem)
        [self checkMetaQuestionTouches:location];
    else if(numberPickerForThisProblem)
        [self checkNumberPickerTouches:location];
    
    
    if(isPaused)
    {
        return;
    }  
    // TODO: This should be made proportional
    
    if (CGRectContainsPoint(kRectButtonCommit, location) && evalMode==kProblemEvalOnCommit)
    {
        [currentTool evalProblem];
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
    
    if(isPaused)
    {
        return;
    } 
    
    if(npMove && numberPickerForThisProblem){
        for(int i=0;i<[numberPickedSelection count];i++)
        {
            CCSprite *s=[numberPickedSelection objectAtIndex:i];
            if(s==npMove)continue;
            if(CGRectContainsPoint(s.boundingBox, location))
            {
                CCSprite *repSprite=[numberPickedSelection objectAtIndex:i];
                //CGPoint repSpritePos=repSprite.position;
                [repSprite runAction:[CCMoveTo actionWithDuration:0.2 position:npMoveStartPos]];
                //npMoveStartPos=repSprite.position;
                
                
                int obValue=[[numberPickedValue objectAtIndex:[numberPickedSelection indexOfObject:npMove]]intValue];
                [numberPickedValue removeObjectAtIndex:[numberPickedSelection indexOfObject:npMove]];
                [numberPickedSelection removeObject:npMove];
                [numberPickedValue insertObject:[NSNumber numberWithInt:obValue] atIndex:i];
                [numberPickedSelection insertObject:npMove atIndex:i];
                
                //[repSprite runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(cx-(npDropbox.contentSize.width/2)+(curSprite.contentSize.width/1.25)+([numberPickedSelection count]*55),cy+50)

            }
        }
        npMove.position=location;
    }
    
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
        if(!CGRectContainsPoint(npDropbox.boundingBox, location) || (CGRectContainsPoint(npDropbox.boundingBox, location) && distance<5.0f))
        {
            [numberPickedValue removeObjectAtIndex:[numberPickedSelection indexOfObject:npMove]];
            [numberPickedSelection removeObject:npMove];
            [npMove removeFromParentAndCleanup:YES];
            [self reorderNumberPickerSelections];
        }
        [self reorderNumberPickerSelections];
        npMove=nil;
    }
    
    [currentTool ccTouchesEnded:touches withEvent:event];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(npMove)npMove=nil;
    [currentTool ccTouchesCancelled:touches withEvent:event];
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
    [pdef release];
    if(metaQuestionAnswers)[metaQuestionAnswers release];
    if(metaQuestionAnswerButtons)[metaQuestionAnswerButtons release];
    if(metaQuestionAnswerLabels)[metaQuestionAnswerLabels release];
    if(metaQuestionCompleteText)[metaQuestionCompleteText release];
    if(metaQuestionIncompleteLabel)[metaQuestionIncompleteText release];
    if(problemComplete)[problemComplete release];
    if(problemIncomplete)[problemIncomplete release];
    if(problemDescLabel)[problemDescLabel release];
    if(numberPickerButtons)[numberPickerButtons release];
    if(numberPickedSelection)[numberPickedSelection release];
    if(numberPickedValue)[numberPickedValue release];
    
    [super dealloc];
}

@end
