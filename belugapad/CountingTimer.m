//
//  CountingTimer.m
//  belugapad
//
//  Created by David Amphlett on 14/08/2012.
//
//

#import "CountingTimer.h"
#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"
#import "LoggingService.h"
#import "AppDelegate.h"
#import "SimpleAudioEngine.h"
#import "SGGameWorld.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "InteractionFeedback.h"

@interface CountingTimer()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
}

@end

@implementation CountingTimer

#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    
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
        
        gw = [[SGGameWorld alloc] initWithGameScene:renderLayer];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        renderLayer = [[CCLayer alloc] init];
        [self.ForeLayer addChild:renderLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        loggingService = ac.loggingService;
        
        
        [self readPlist:pdef];
        [self populateGW];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

#pragma mark - loops

-(void)doUpdateOnTick:(ccTime)delta
{
    // increase our overall timer
    // if the problem hasn't expired - increase
    if(!expired)
        if(started)timeElapsed+=delta;
    
    // update our tool variables
    if((int)timeElapsed!=trackNumber && started)
    {
        trackNumber=(int)timeElapsed;
        
        lastNumber+=numIncrement;
        
        // play sound if required
        if(countType==kCountBeep){
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/click_b1.wav")];
        }
        else if(countType==kCountNumbers && lastNumber>0<20){
            NSString *file=[NSString stringWithFormat:@"/sfx/numbers/%d.wav", lastNumber];
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(file)];
        }

    }
    
    // if we're showing the count - update the label
    if(showCount)[currentNumber setString:[NSString stringWithFormat:@"%d",lastNumber]];
    
    // problem expiring clauses
    if(numIncrement<0 && lastNumber<=countMin && !expired)
    {
        NSLog(@"reach the end of the problem (hit count min on count-back number");
        [self expireProblemForRestart];
    }
    
    else if(numIncrement>=0 && lastNumber>=countMax && !expired)
    {
        NSLog(@"reach the end of the problem (hit count max on count-on number");
        [self expireProblemForRestart];
    }
        
    if(autoMoveToNextProblem)
    {
        timeToAutoMoveToNextProblem+=delta;
        if(timeToAutoMoveToNextProblem>=kTimeToAutoMove)
        {
            self.ProblemComplete=YES;
            autoMoveToNextProblem=NO;
            timeToAutoMoveToNextProblem=0.0f;
        }
    }
}

-(void)draw
{
    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    started=NO;
    
    countMin=[[pdef objectForKey:COUNT_MIN]intValue];
    countMax=[[pdef objectForKey:COUNT_MAX]intValue];
    
    if([pdef objectForKey:INCREMENT])
        numIncrement=[[pdef objectForKey:INCREMENT]intValue];
    else
        numIncrement=1;
    
    solutionNumber=[[pdef objectForKey:SOLUTION]intValue];
    displayNumicon=[[pdef objectForKey:USE_NUMICON_NUMBERS]boolValue];
    showCount=[[pdef objectForKey:SHOW_COUNT]boolValue];
    countType=[[pdef objectForKey:COUNT_TYPE]intValue];
    buttonFlash=[[pdef objectForKey:FLASHING_BUTTON]boolValue];
    
    if(numIncrement>=0)
        lastNumber=countMin;
    else
        lastNumber=countMax;
}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;
    buttonOfWin=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/countingtimer/button-red.png")];
    [buttonOfWin setPosition:ccp(cx,cy)];
    [buttonOfWin setColor:ccc3(0,255,0)];
    [renderLayer addChild:buttonOfWin];
    
    if(showCount)
    {
        currentNumber=[CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        [currentNumber setPosition:ccp(50,50)];
        [renderLayer addChild:currentNumber];
    }
}

#pragma mark - problem state
-(void)startProblem
{
    [buttonOfWin setColor:ccc3(255,255,255)];
    started=YES;
    expired=NO;
}

-(void)expireProblemForRestart
{
    expired=YES;
    started=NO;
    timeElapsed=0.0f;
    trackNumber=0;
    [buttonOfWin setColor:ccc3(0,255,0)];
    
    if(numIncrement>=0)
        lastNumber=countMin;
    else
        lastNumber=countMax;
}

#pragma mark - touches events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    lastTouch=location;
    touchStartPos=location;
    
    if(CGRectContainsPoint(buttonOfWin.boundingBox, location))
    {
        if(!started)[self startProblem];
        else[self evalProblem];
    }
    
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;
    
    // if we have these things, handle them differently

}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    float distFromStartToEnd=[BLMath DistanceBetween:touchStartPos and:location];
    
    isTouching=NO;
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    if(lastNumber==solutionNumber)
        return YES;
    else
        return NO;
}

-(void)evalProblem
{
    BOOL isWinning=[self evalExpression];
    
    if(isWinning)
    {
        expired=YES;
        autoMoveToNextProblem=YES;
        [toolHost showProblemCompleteMessage];
    }
    else {
//        if(evalMode==kProblemEvalOnCommit)[self resetProblem];
        [buttonOfWin runAction:[InteractionFeedback shakeAction]];
    }
    
}

#pragma mark - problem state
-(void)resetProblem
{
    [toolHost showProblemIncompleteMessage];
    [toolHost resetProblem];
}

#pragma mark - meta question
-(float)metaQuestionTitleYLocation
{
    return kLabelTitleYOffsetHalfProp*cy;
}

-(float)metaQuestionAnswersYLocation
{
    return kMetaQuestionYOffsetPlaceValue*cy;
}

#pragma mark - dealloc
-(void) dealloc
{
    //write log on problem switch
    
    [renderLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end

