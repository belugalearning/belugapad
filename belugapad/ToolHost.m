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

@implementation ToolHost

@synthesize Zubi;

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

        metaQuestionLayer=[[CCLayer alloc] init];
        [self addChild:metaQuestionLayer z:2];
        
        [self populatePerstLayer];
        
        [self loadTestPipeline];
        
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
    
    //let tool do updates
    [currentTool doUpdateOnTick:delta];
}

-(void)doUpdateOnSecond:(ccTime)delta
{
    if(showMetaQuestionIncomplete) shownMetaQuestionIncompleteFor+=delta;
    
    //do internal mgmt updates
    if(currentTool.ProblemComplete)
    {
        [self gotoNewProblem];
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

    pdef=[self getNextProblem];
    [pdef retain];
    [self loadProblem];
}

-(void) loadProblem
{
    //tear down meta question stuff
    [self tearDownMetaQuestion];
    
    NSString *toolKey=[pdef objectForKey:TOOL_KEY];
    
    if(currentTool)
    {
        [self removeChild:toolBackLayer cleanup:YES];
        [self removeChild:toolForeLayer cleanup:YES];
        [currentTool release];
    }
    
    //reset multitouch
    //if tool requires multitouch, it will need to reset accordingly
    [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=NO;
    
    currentTool=[NSClassFromString(toolKey) alloc];
    [currentTool initWithToolHost:self andProblemDef:pdef];    
    
    NSDictionary *mq=[pdef objectForKey:META_QUESTION];
    if (mq)
    {
        [self setupMetaQuestion:mq];
    }
    
    [self stageIntroActions];
    
    [self.Zubi dumpXP];
}

-(void) resetProblem
{
    [self loadProblem];
}


-(void)setupMetaQuestion:(NSDictionary *)pdefMQ
{
    metaQuestionForThisProblem=YES;
    shownMetaQuestionIncompleteFor=0;
    
    metaQuestionAnswers = [[NSMutableArray alloc] init];
    metaQuestionAnswerButtons = [[NSMutableArray alloc] init];
    metaQuestionAnswerLabels = [[NSMutableArray alloc] init];
    
    //render problem label
    CCLabelTTF *problemDescLabel=[CCLabelTTF labelWithString:[pdefMQ objectForKey:META_QUESTION_TITLE] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, [currentTool metaQuestionTitleYLocation])];
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
    [metaQuestionIncompleteLabel setPosition:ccp(cx, [currentTool metaQuestionAnswersYLocation]*kMetaIncompleteLabelYOffset)];
    [metaQuestionIncompleteLabel setColor:kMetaQuestionLabelColor];
    [metaQuestionIncompleteLabel setVisible:NO];
    [metaQuestionLayer addChild:metaQuestionIncompleteLabel];
    
    // render answer labels and buttons for each answer
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        NSMutableDictionary *a=[NSMutableDictionary dictionaryWithDictionary:[pdefAnswers objectAtIndex:i]];
        [metaQuestionAnswers addObject:a];
        
        // sort out the buttons
        CCSprite *answerBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/metaquestions/meta-answerbutton.png")];
        [answerBtn setPosition:ccp((i+1)*(lx/(metaQuestionAnswerCount+1)), [currentTool metaQuestionAnswersYLocation])];
        [answerBtn setTag:3];
        [answerBtn setScale:0.5f];
        [answerBtn setOpacity:0];
        [metaQuestionLayer addChild:answerBtn];
        [metaQuestionAnswerButtons addObject:answerBtn];
        
        // sort out the labels
        NSString *answerLabelString=[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT];
        CCLabelTTF *answerLabel=[CCLabelTTF labelWithString:answerLabelString fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        [answerLabel setPosition:ccp((i+1)*(lx/(metaQuestionAnswerCount+1)), [currentTool metaQuestionAnswersYLocation])];
        [answerLabel setColor:kMetaAnswerLabelColor];
        [answerLabel setOpacity:0];
        [answerLabel setTag: 3];
        [metaQuestionLayer addChild:answerLabel];
        [metaQuestionAnswerLabels addObject:answerLabel];
        
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
}

-(void)stageIntroActions
{
    //TODO tags are currently fixed to 2 phases -- either parse tool tree or pre-populate with design-fixed max
    for (int i=1; i<=3; i++) {
        [self recurseSetIntroFor:toolBackLayer withTime:i forTag:i];
        [self recurseSetIntroFor:toolForeLayer withTime:i forTag:i];
        [self recurseSetIntroFor:metaQuestionLayer withTime:i forTag:i];
    }
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

-(void)loadTestPipeline
{
    //load problem pipeline path from app settings
    AppDelegate *ad =(AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *ppath=[ad.LocalSettings objectForKey:@"PROBLEM_PIPELINE"];
    
    problemList=[[NSArray arrayWithContentsOfFile:BUNDLE_FULL_PATH(ppath)] retain];
}

-(NSDictionary*)getNextProblem
{
    //TODO: effectively test specific, as it only loads data from problem file, no user context etc
    NSString *pfilename=[problemList objectAtIndex:problemIndex];
    NSString *broot=[[NSBundle mainBundle] bundlePath];
    NSString *pfilepath=[broot stringByAppendingPathComponent:pfilename];
    NSDictionary *pdef=[NSDictionary dictionaryWithContentsOfFile:pfilepath];

    //TODO: this is test-specific, just loops the problem list
    problemIndex++;
    if(problemIndex>=[problemList count])problemIndex=0;
    
    return pdef;
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
        // if it's an answer and selected then it's been found by the user
        if(isAnswer && isSelected)
        {
            countFound++;
        }
    }
    DLog(@"Count required %d, count found %d", countRequired, countFound);
    
    
    
    if(countRequired==countFound)
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
    CCLabelTTF *pcLabel = [CCLabelTTF labelWithString:metaQuestionCompleteText fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [pcLabel setPosition:ccp(cx, [currentTool metaQuestionAnswersYLocation])];
    [pcLabel setColor:kMetaQuestionLabelColor];
    [metaQuestionLayer addChild:pcLabel];
    currentTool.ProblemComplete=YES;
    
}
-(void)doIncomplete
{
    [metaQuestionIncompleteLabel setVisible:YES];
    showMetaQuestionIncomplete=YES;
    //[self deselectAnswersExcept:-1];
}
-(void)removeMetaQuestionButtons
{
    for(int i=0;i<metaQuestionAnswerCount;i++)
    {
        [metaQuestionLayer removeChild:[metaQuestionAnswerLabels objectAtIndex:i] cleanup:YES];
        [metaQuestionLayer removeChild:[metaQuestionAnswerButtons objectAtIndex:i] cleanup:YES];
    } 
}
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
     
    [self checkMetaQuestionTouches:location];
    
    if (location.x<cx && location.y > kButtonToolbarHitBaseYOffset)
        [self gotoNewProblem];
    else
        [currentTool ccTouchesBegan:touches withEvent:event];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [currentTool ccTouchesMoved:touches withEvent:event];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [currentTool ccTouchesEnded:touches withEvent:event];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [currentTool ccTouchesCancelled:touches withEvent:event];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return [currentTool ccTouchBegan:touch withEvent:event];
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    [currentTool ccTouchMoved:touch withEvent:event];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    [currentTool ccTouchEnded:touch withEvent:event];
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    [currentTool ccTouchCancelled:touch withEvent:event];
}

-(void) dealloc
{
    [problemList release];
    
    [pdef release];
    [metaQuestionAnswers release];
    [metaQuestionAnswerButtons release];
    [metaQuestionAnswerLabels release];
    [metaQuestionCompleteText release];
    [metaQuestionIncompleteText release];
    
    [super dealloc];
}

@end
