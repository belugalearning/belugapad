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

#define kEarliestHit 0.8
#define kLatestHit 0.8

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
        
        debugLogging=YES;
        
        
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
        if(buttonFlash)
            [buttonOfWin runAction:[InteractionFeedback dropAndBounceAction]];
        
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
    if(showCount && !expired)[currentNumber setString:[NSString stringWithFormat:@"%d",lastNumber]];
    
    // problem expiring clauses
    if(numIncrement<0 && lastNumber<countMin && !expired)
    {
        NSLog(@"reach the end of the problem (hit count min on count-back number");
        [loggingService logEvent:BL_PA_CT_TIMER_EXPIRED withAdditionalData:nil];
        [self expireProblemForRestart];
    }
    
    else if(numIncrement>=0 && lastNumber>countMax && !expired)
    {
        NSLog(@"reach the end of the problem (hit count max on count-on number");
        [loggingService logEvent:BL_PA_CT_TIMER_EXPIRED withAdditionalData:nil];
        [self expireProblemForRestart];
    }
        
//    if([buttonOfWin numberOfRunningActions]==0 && !CGPointEqualToPoint([buttonOfWin position], ccp(cx,cy)))
//    {
//        [buttonOfWin setPosition:ccp(cx,cy)];
//    }
    
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
    {
        lastNumber=countMin;
        trackNumber=lastNumber;
        timeElapsed=lastNumber;
        
        if(countMax<=countMin)
            countMax=countMin+4;
    }
    else
    {
        lastNumber=countMax;
        trackNumber=lastNumber;
        timeElapsed=0;
        
        if(countMin>=countMax)
            countMin=countMax-4;
    }
    

}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;
    buttonOfWin=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/countingtimer/counter_start.png")];
    [buttonOfWin setPosition:ccp(cx,cy-80)];
    [buttonOfWin setOpacity:0];
    [buttonOfWin setTag:2];
    [renderLayer addChild:buttonOfWin];
    
    if(showCount)
    {
        currentNumber=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:50.0f];
        [currentNumber setPosition:ccp(cx,cy+100)];
        [currentNumber setOpacity:0];
        [currentNumber setTag:3];
        [renderLayer addChild:currentNumber];
    }
}

#pragma mark - problem state
-(void)startProblem
{
    [buttonOfWin setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/countingtimer/counter_stop.png")]];
    started=YES;
    expired=NO;
}

-(void)expireProblemForRestart
{
    expired=YES;
    started=NO;
    timeElapsed=0.0f;
    trackNumber=0;
    [buttonOfWin setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/countingtimer/counter_start.png")]];
    
    if(numIncrement>=0){
        lastNumber=countMin;
        trackNumber=lastNumber;
        timeElapsed=lastNumber;
    }
    else{
        lastNumber=countMax;
        trackNumber=lastNumber;
        timeElapsed=lastNumber;
    }
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
        if(!started){
            [self startProblem];
            [loggingService logEvent:BL_PA_CT_TOUCH_START_START_TIMER withAdditionalData:nil];
        }
        else{
            [self evalProblem];
            [loggingService logEvent:BL_PA_CT_TOUCH_START_STOP_TIMER withAdditionalData:nil];
        }
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
    
    
    isTouching=NO;
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    float earliestHit=0.0f;
    float latestHit=0.0f;
    
    NSLog(@"time elapsed %f", timeElapsed);
    
    if(numIncrement>=0)
    {
        float adjTimeElapsed=timeElapsed*numIncrement;
        // count up
        earliestHit=solutionNumber-(kEarliestHit*numIncrement);
        latestHit=solutionNumber+(kLatestHit*numIncrement);
        
        if(debugLogging)
            NSLog(@"(EVAL-UP) earliestHit: %f / latestHit: %f / timeElapsed %f", earliestHit, latestHit, adjTimeElapsed);
        
        if((adjTimeElapsed>=earliestHit) && (adjTimeElapsed<=latestHit))
            return YES;
        else
            return NO;
    }
    else
    {
        // count down
        float adjTimeElapsed=fabsf(timeElapsed-countMax);
        earliestHit=solutionNumber+(kEarliestHit*numIncrement);
        latestHit=solutionNumber-(kLatestHit*numIncrement);
        
        if(debugLogging)
            NSLog(@"(EVAL-DOWN) earliestHit: %f / latestHit: %f / timeElapsed %f", earliestHit, latestHit, adjTimeElapsed);
        
        if(adjTimeElapsed<=latestHit && adjTimeElapsed>=earliestHit)
            return YES;

        else
            return NO;

    }
    
    return NO;
    
}

-(void)evalProblem
{
    BOOL isWinning=[self evalExpression];
    
    if(isWinning)
    {
        expired=YES;
        [currentNumber setString:[NSString stringWithFormat:@"%d",solutionNumber]];
        [toolHost doWinning];
    }
    else {
//        if(evalMode==kProblemEvalOnCommit)[self resetProblem];
        
        [toolHost doIncomplete];
        [toolHost resetProblem];
        
        //if([buttonOfWin numberOfRunningActions]==0)
 //           [buttonOfWin runAction:[InteractionFeedback shakeAction]];
        
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

