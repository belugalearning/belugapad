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
#import "MenuScene.h"

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
        
        //add background to background layer
        CCSprite *bkg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/bg/bg-ipad.png")];
        [bkg setPosition:ccp(cx, cy)];
        [backgroundLayer addChild:bkg z:0];
        
        //add a pause button but keep it hidden -- to be brought in by the fader
        CCSprite *pause=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/button-pause.png")];
        [pause setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), ly-(kPropXCommitButtonPadding*lx))];
        [backgroundLayer addChild:pause z:3];        


        metaQuestionLayer=[[CCLayer alloc] init];
        [self addChild:metaQuestionLayer z:2];
        
        [self populatePerstLayer];
        
        contentService = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).contentService;        
        [self gotoNewProblem];
        
        [self schedule:@selector(doUpdateOnTick:) interval:1.0f/60.0f];
        [self schedule:@selector(doUpdateOnSecond:) interval:1.0f];
        [self schedule:@selector(doUpdateOnQuarterSecond:) interval:1.0f/40.0f];
        
    }
    
    return self;
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
            showingProblemComplete=NO;
            [problemComplete runAction:[CCFadeOut actionWithDuration:kTimeToFadeProblemStatus]];
        }
        if(showingProblemIncomplete)
        {
            showingProblemIncomplete=NO;
            [problemIncomplete runAction:[CCFadeOut actionWithDuration:kTimeToFadeProblemStatus]];
        }
            shownProblemStatusFor=0.0f;
    }
    
    //let tool do updates
    [currentTool doUpdateOnTick:delta];
}

-(void)doUpdateOnSecond:(ccTime)delta
{
    if(showMetaQuestionIncomplete) shownMetaQuestionIncompleteFor+=delta;
    
    //do internal mgmt updates
    if(currentTool.ProblemComplete || metaQuestionForceComplete)
    {
        UsersService *us = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService;
        [us endProblemAttempt:YES];
        
        [self gotoNewProblem];
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
}

-(void) loadTool
{
    //reset multitouch
    //if tool requires multitouch, it will need to reset accordingly
    [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=NO;

    
}

-(void) gotoNewProblem
{
    if (pdef) [pdef release];
    self.PpExpr = nil;
    
    [contentService gotoNextProblemInElement];
    
    pdef = [contentService.currentPDef retain];
    
    if(!pdef)
    {
        //no more problems in this sequence, bail to menu
        [[CCDirector sharedDirector] replaceScene:[MenuScene scene]];
    }
    
    self.PpExpr = contentService.currentPExpr;
    
    [self loadProblem];
}

-(void) loadProblem
{
    //tear down meta question stuff
    [self tearDownMetaQuestion];
    
    //tear down host background
    if(hostBackground)
    {
        [self removeChild:hostBackground cleanup:YES];
        hostBackground=nil;
    }
    
    NSString *toolKey=[pdef objectForKey:TOOL_KEY];
    
    if(currentTool)
    {
        [self removeChild:toolBackLayer cleanup:YES];
        [self removeChild:toolForeLayer cleanup:YES];
        [currentTool release];
        currentTool=nil;
    }
    
    //reset multitouch
    //if tool requires multitouch, it will need to reset accordingly
    [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=NO;
    
    //initialize tool scene
    currentTool=[NSClassFromString(toolKey) alloc];
    [currentTool initWithToolHost:self andProblemDef:pdef];    
    
    
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
    if (mq)
    {
        [self setupMetaQuestion:mq];
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
    
    UsersService *us = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService;
    [us startProblemAttempt];
}

-(void) resetProblem
{
    skipNextStagedIntroAnim=YES;
    
    UsersService *us = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService;
    [us endProblemAttempt:NO];
    
    [self loadProblem];
}

-(void) showPauseMenu
{
    isPaused = YES;
    
    pauseMenu = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/pause-overlay.png")];
    [pauseMenu setPosition:ccp(cx, cy)];
    [toolForeLayer addChild:pauseMenu z:10];
    
    UsersService *us = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService;
    [us togglePauseProblemAttempt];
}

-(void) checkPauseTouches:(CGPoint)location
{
    if(CGRectContainsPoint(kPauseMenuContinue, location))
    {
        //resume
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [toolForeLayer removeChild:pauseMenu cleanup:YES];
        isPaused=NO;
        
        UsersService *us = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService;
        [us togglePauseProblemAttempt];
    }
    if(CGRectContainsPoint(kPauseMenuReset, location))
    {
       //reset
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self resetProblem];
        isPaused=NO;
    }
    if(CGRectContainsPoint(kPauseMenuMenu,location))
    {

        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/menutap.wav")];
        [self returnToMenu];


    }
            
}

-(void) returnToMenu
{
    [[CCDirector sharedDirector] replaceScene:[MenuScene scene]];
}

-(void) showProblemCompleteMessage
{
    problemComplete = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/complete-overlay.png")];
    [problemComplete setPosition:ccp(cx, cy)];
    [metaQuestionLayer addChild:problemComplete];
    showingProblemComplete=YES;
    [problemComplete retain];
}

-(void) showProblemIncompleteMessage
{
    problemIncomplete = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/failed-overlay.png")];
    [problemIncomplete setPosition:ccp(cx,cy)];
    [toolForeLayer addChild:problemIncomplete];
    showingProblemIncomplete=YES;
    [problemIncomplete retain];
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
    CCLabelTTF *problemDescLabel=[CCLabelTTF labelWithString:[pdefMQ objectForKey:META_QUESTION_TITLE] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
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

-(void)tearDownMetaQuestion
{
    [metaQuestionLayer removeAllChildrenWithCleanup:YES];
    
    metaQuestionForceComplete=NO;
}

-(void)stageIntroActions
{
    //TODO tags are currently fixed to 2 phases -- either parse tool tree or pre-populate with design-fixed max
    for (int i=1; i<=3; i++) {
        
        int time=i;
        if(skipNextStagedIntroAnim) time=0;
        
        [self recurseSetIntroFor:toolBackLayer withTime:time forTag:i];
        [self recurseSetIntroFor:toolForeLayer withTime:time forTag:i];
        [self recurseSetIntroFor:metaQuestionLayer withTime:time forTag:i];
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
    
    [self checkMetaQuestionTouches:location];
    if(isPaused)
    {
        return;
    }  
    if (location.x > 944 && location.y > 688 && !isPaused)
    {
        [self showPauseMenu];
        return;
    }
    
    if (location.x<cx && location.y > kButtonToolbarHitBaseYOffset)
        [self gotoNewProblem];
    else
        [currentTool ccTouchesBegan:touches withEvent:event];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isPaused)
    {
        return;
    }  
    [currentTool ccTouchesMoved:touches withEvent:event];
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
    [currentTool ccTouchesEnded:touches withEvent:event];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
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
    [currentTool ccTouchCancelled:touch withEvent:event];
}

-(void) dealloc
{
    [pdef release];
    [metaQuestionAnswers release];
    [metaQuestionAnswerButtons release];
    [metaQuestionAnswerLabels release];
    [metaQuestionCompleteText release];
    [metaQuestionIncompleteText release];
    [problemComplete release];
    [problemIncomplete release];
    
    [super dealloc];
}

@end
