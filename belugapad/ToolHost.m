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
    //do internal mgmt updates
    if(currentTool.ProblemComplete)
    {
        [self gotoNewProblem];
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
    //tear down meta question stuff
    [self tearDownMetaQuestion];
    
    NSDictionary *pdef=[self getNextProblem];
    
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

-(void)setupMetaQuestion:(NSDictionary *)pdefMQ
{
    DLog(@"setting up a meta question");
    
    metaQuestionForThisProblem=YES;
    
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
    metaQuestionAnswers = [pdefMQ objectForKey:META_QUESTION_ANSWERS];
    metaQuestionAnswerCount = metaQuestionAnswers.count;
    
    // assign our complete and incomplete text to show later
    metaQuestionCompleteText = [pdefMQ objectForKey:META_QUESTION_COMPLETE_TEXT];
    metaQuestionIncompleteText = [pdefMQ objectForKey:META_QUESTION_INCOMPLETE_TEXT];
    
    //render answer labels
    for(int i=0; i<metaQuestionAnswerCount; i++)
    {
        NSString *answerLabelString=[[metaQuestionAnswers objectAtIndex:i] objectForKey:META_ANSWER_TEXT];
        CCLabelTTF *answerLabel=[CCLabelTTF labelWithString:answerLabelString fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        [answerLabel setPosition:ccp((i+1)*(lx/(metaQuestionAnswerCount+1)), [currentTool metaQuestionAnswersYLocation])];
        [answerLabel setColor:kMetaQuestionLabelColor];
        [answerLabel setOpacity:0];
        [answerLabel setTag: 3];
        [metaQuestionLayer addChild:answerLabel];
    }
    
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
    //TODO: test-specific -- pulls fixed problem list from plist
    problemList=[[NSArray arrayWithContentsOfFile:BUNDLE_FULL_PATH(@"/pipeline-testing/pipeline-test.plist")] retain];
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

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if (location.x<cx && location.y > kButtonToolbarHitBaseYOffset)
        [self gotoNewProblem];
    
    // otherwise check for a meta question
    else if(metaQuestionForThisProblem)
        {
            // check the eval mode
            if(mqEvalMode==kMetaQuestionEvalOnCommit)
            {
                
            }
            else if(mqEvalMode==kMetaQuestionEvalAuto)
            {
                
            }
        }
    
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
    
    [super dealloc];
}

@end
