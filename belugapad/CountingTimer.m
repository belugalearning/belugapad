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
#import "SimpleAudioEngine.h"
#import "NumberLayout.h"


#define kEarliestHit 1.2
#define kLatestHit 1.0

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

static float kTimeToButtonShake=7.0f;

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
        
        debugLogging=NO;
        
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
    if(!expired){
        if(started){
            if(!showCount)[currentNumber setVisible:NO];
            timeElapsed+=numIncrement*delta;
            timeKeeper+=delta;
        }
    }
    
    if(!started)
        timeSinceInteractionOrShake+=delta;
    
    if(timeSinceInteractionOrShake>kTimeToButtonShake)
    {
        [buttonOfWin runAction:[InteractionFeedback shakeAction]];
        timeSinceInteractionOrShake=0.0f;
    }
    
    if([buttonOfWin numberOfRunningActions]==0)
    {
        if(!CGPointEqualToPoint(buttonOfWin.position, ccp(cx,cy)))
            buttonOfWin.position=ccp(cx,cy);
    }
    
    if(debugLogging)
        [tLabel setString:[NSString stringWithFormat:@"%f",timeElapsed]];
    
    // update our tool variables
    if((int)timeKeeper!=trackNumber && started)
    {
        if(buttonFlash){
//            CCFadeOut *ffo=[CCFadeOut actionWithDuration:0.2f];
//            CCFadeIn *ffi=[CCFadeIn actionWithDuration:0.3f];
//            
//            CCSequence *ff=[CCSequence actionOne:ffo two:ffi];
//
//            [flasher runAction:ff];

            CCFadeIn *fffi=[CCFadeIn actionWithDuration:0.1f];
            CCFadeOut *fffo=[CCFadeOut actionWithDuration:0.3f];
        
            CCSequence *fff=[CCSequence actionOne:fffi two:fffo];
            
            [flashingFlasher runAction:fff];
            
//            [buttonOfWin runAction:[InteractionFeedback dropAndBounceAction]];
        }
        
        trackNumber=(int)timeKeeper;
        
        lastNumber+=numIncrement;
        
        if(displayNumicon)
        {
            NSArray *dotLayout=nil;
            if(lastNumber<=100){
                dotLayout=[NumberLayout physicalLayoutAcrossToNumber:lastNumber withSpacing:15.0f];
                
                for(CCSprite *s in activeDots)
                {
                    [s removeFromParentAndCleanup:YES];
                }
                
                [activeDots removeAllObjects];
                
                for(int i=lastNumber-1;i>=0;i--)
                {
                    CGPoint thisPos=[[dotLayout objectAtIndex:i]CGPointValue];
                    thisPos=ccp(thisPos.x+cx+((lastNumber/2)*7.5f),thisPos.y+130);
                    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/Number_Dot_Standard.png")];
                    [s setPosition:thisPos];
                    [renderLayer addChild:s];
                    if(!activeDots)activeDots=[[NSMutableArray alloc]init];
                    [activeDots addObject:s];
                }
            }
//            if(lastNumber<=10.0f)
//            {
//                CCSpriteFrame *frame=[frameCache spriteFrameByName:[NSString stringWithFormat:@"%d.png", lastNumber]];
//                [numiconOne setOpacity:255];
//                [numiconOne setDisplayFrame:frame];
//            }
//            else
//            {
//                [numiconOne setVisible:NO];
//            }
        }
        
//        if(flashNumicon)
//        {
//            [numiconOne setOpacity:255];
//            [numiconOne runAction:[CCFadeOut actionWithDuration:0.5f]];
//            
//        }
        
        // play sound if required
        if(countType==kCountBeep){
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_counting_timer_general_counter_incremented.wav")];
        }
        else if(countType==kCountNumbers){
            AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
            [ac speakString:[NSString stringWithFormat:@"%d",lastNumber]];
            //NSString *file=[NSString stringWithFormat:@"/sfx/numbers/%d.wav", lastNumber];
            //[[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(file)];
        }

    }
    
    // if we're showing the count - update the label
    if(showCount && !expired)[currentNumber setString:[NSString stringWithFormat:@"%d",lastNumber]];
    
    // problem expiring clauses
    if(numIncrement<0 && lastNumber<countMin && !expired)
    {
        NSLog(@"reach the end of the problem (hit count min on count-back number");
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_counting_timer_general_counter_ended_(got_to_max_without_press_-_reset).wav")];
        [loggingService logEvent:BL_PA_CT_TIMER_EXPIRED withAdditionalData:nil];
        [currentNumber setString:[NSString stringWithFormat:@"%d",lastNumber+numIncrement]];
        [self expireProblemForRestart];
    }
    
    else if(numIncrement>=0 && lastNumber>countMax && !expired)
    {
        NSLog(@"reach the end of the problem (hit count max on count-on number");
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_counting_timer_general_counter_ended_(got_to_max_without_press_-_reset).wav")];
        [loggingService logEvent:BL_PA_CT_TIMER_EXPIRED withAdditionalData:nil];
        [currentNumber setString:[NSString stringWithFormat:@"%d",lastNumber-numIncrement]];
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
    
    if([pdef objectForKey:USE_NUMICON_NUMBERS])
        displayNumicon=[[pdef objectForKey:USE_NUMICON_NUMBERS]boolValue];
    else if([pdef objectForKey:USE_NUMICON_NUMBER])
        displayNumicon=[[pdef objectForKey:USE_NUMICON_NUMBER]boolValue];
    
    flashNumicon=[[pdef objectForKey:NUMICON_FLASH]boolValue];
    showCount=[[pdef objectForKey:SHOW_COUNT]boolValue];
    countType=[[pdef objectForKey:COUNT_TYPE]intValue];
    buttonFlash=[[pdef objectForKey:FLASHING_BUTTON]boolValue];
    isIntroPlist=[[pdef objectForKey:IS_INTRO_PLIST]boolValue];
    
    if(!showCount)buttonFlash=YES;
    
    if(isIntroPlist)
    {
        countMin=0;
        countMax=999;
        numIncrement=1;
        displayNumicon=YES;
        showCount=YES;
        countType=1;
        solutionNumber=1000;
    }
    
    if(numIncrement>=0)
    {
        lastNumber=countMin;
        trackNumber=lastNumber;
        timeElapsed=lastNumber;
        //timeKeeper=timeElapsed;
        timeKeeper=0.0f;
        
        if(countMax<=countMin)
            countMax=countMin+4;
    }
    else
    {
        lastNumber=countMax;
        trackNumber=lastNumber;
        timeElapsed=lastNumber;
//        timeKeeper=timeElapsed;
        timeKeeper=0.0f;
        
        if(countMin>=countMax)
            countMin=countMax-4;
    }
    
    if(trackNumber==0)
        [usersService notifyStartingFeatureKey:@"COUNTINGTIMER_COUNT_START_0"];
    else if(trackNumber>0)
        [usersService notifyStartingFeatureKey:@"COUNTINGTIMER_COUNT_START_GREATER_0"];
}

-(void)populateGW
{
    if(debugLogging){
        tLabel=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:20.0f];
        [tLabel setPosition:ccp(cx,40)];
        [renderLayer addChild:tLabel];
    }
    gw.Blackboard.RenderLayer = renderLayer;
    buttonOfWin=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/countingtimer/counter_start.png")];
    [buttonOfWin setPosition:ccp(cx,cy)];
    [buttonOfWin setOpacity:0];
    [buttonOfWin setTag:2];
    [renderLayer addChild:buttonOfWin];
    
    flasher=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/countingtimer/counter.png")];
    [flasher setPosition:ccp(cx,buttonOfWin.position.x-(buttonOfWin.contentSize.height)-(flasher.contentSize.height))];
    [flasher setOpacity:0];
    [flasher setTag:2];
    [renderLayer addChild:flasher];
    
    flashingFlasher=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/countingtimer/counter_flash.png")];
    [flashingFlasher setPosition:ccp(cx,buttonOfWin.position.x-(buttonOfWin.contentSize.height)-(flasher.contentSize.height))];
    [flashingFlasher setOpacity:0];
    [renderLayer addChild:flashingFlasher];

    
//    if(showCount)
//    {
    int startNo=0;
    if(numIncrement>=0)
        startNo=countMin;
    else
        startNo=countMax;
    
    currentNumber=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:50.0f];
    [currentNumber setString:[NSString stringWithFormat:@"%d", startNo]];
    [currentNumber setPosition:ccp(flasher.position.x,flasher.position.y-8)];
    [currentNumber setOpacity:0];
    [currentNumber setTag:3];
    [renderLayer addChild:currentNumber];
//    }
    if(displayNumicon||flashNumicon)
    {
//        frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
//        [frameCache addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/btxe/iconsets/goo_things.plist") textureFilename:BUNDLE_FULL_PATH(@"/images/btxe/iconsets/goo_things.png")];
//        CCSpriteFrame *frame=[frameCache spriteFrameByName:@"1.png"];
//        numiconOne=[CCSprite spriteWithSpriteFrame:frame];
//        //[numiconOne setDisplayFrame:frame];
//        [numiconOne setPosition:ccp(cx,100)];
//        [numiconOne setOpacity:0];
//        [renderLayer addChild:numiconOne];

    }
}

-(void)setupIntroOverlay
{
    started=NO;
    introOverlay=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/countingtimer/ct_intro_overlay.png")];
    introCommit=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Enabled.png")];
    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"You stopped the timer at %d. Press the commit button to continue.", lastNumber] fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
    
    [introCommit setPosition:ccp(2*cx-65, 2*cy - 30)];
    
    [l setPosition:ccp(cx,cy)];
    [introOverlay setPosition:ccp(cx,cy)];
    
    [renderLayer addChild:introOverlay];
    [renderLayer addChild:introCommit];
    [renderLayer addChild:l];
    showingIntroOverlay=YES;
}

#pragma mark - problem state
-(void)startProblem
{
    if(showingIntroOverlay)return;
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    [ac stopAllSpeaking];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_counting_timer_general_counter_start_button_tapped.wav")];
    [buttonOfWin setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/countingtimer/counter_stop.png")]];
    started=YES;
    expired=NO;
}

-(void)expireProblemForRestart
{
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_counting_timer_general_counter_ended_(got_to_max_without_press_-_reset).wav")];
    
    expired=YES;
    started=NO;
    timeElapsed=0.0f;
    trackNumber=0;
    
//    if(numiconOne)
//        [numiconOne setOpacity:0];
    
    [buttonOfWin setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/countingtimer/counter_start.png")]];
    
    [flasher setVisible:YES];
    [currentNumber setVisible:YES];
    [buttonOfWin setVisible:YES];
    [currentNumber setPosition:ccp(flasher.position.x,flasher.position.y-8)];
    [currentNumber setFontSize:50.0f];
    
    
    if(numIncrement>=0){
        lastNumber=countMin;
        trackNumber=lastNumber;
        timeElapsed=lastNumber;
//        timeKeeper=timeElapsed;
        timeKeeper=0.0f;
    }
    else{
        lastNumber=countMax;
        trackNumber=lastNumber;
        timeElapsed=lastNumber;
//        timeKeeper=timeElapsed;
        timeKeeper=0.0f;
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
    
    timeSinceInteractionOrShake=0.0f;
    
    if(CGRectContainsPoint(buttonOfWin.boundingBox, location))
    {
        if(!started){
            [self startProblem];
            [loggingService logEvent:BL_PA_CT_TOUCH_START_START_TIMER withAdditionalData:nil];
        }
        else{
            [loggingService logEvent:BL_PA_CT_TOUCH_START_STOP_TIMER withAdditionalData:[NSNumber numberWithInt:trackNumber]];
            [self evalProblem];
        }
    }
    
    if(CGRectContainsPoint(introCommit.boundingBox, location) && showingIntroOverlay)
    {
        [self evalProblem];
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
        // count up
        earliestHit=solutionNumber-(kEarliestHit*numIncrement);
        latestHit=solutionNumber+(kLatestHit*numIncrement);
        
        if(debugLogging)
            NSLog(@"(EVAL-UP) earliestHit: %f / latestHit: %f / timeElapsed %f", earliestHit, latestHit, timeElapsed);
        
        if((timeElapsed>=earliestHit) && (timeElapsed<=latestHit))
            return YES;
        else
            return NO;
    }
    else
    {
        // count down

        earliestHit=solutionNumber+(kEarliestHit*numIncrement);
        latestHit=solutionNumber-(kLatestHit*numIncrement);
        
        
        if(debugLogging)
            NSLog(@"(EVAL-DOWN) earliestHit: %f / latestHit: %f / timeElapsed %f", earliestHit, latestHit, timeElapsed);
        
        if(timeElapsed<=latestHit && timeElapsed>=earliestHit)
            return YES;

        else
            return NO;

    }
    
    return NO;
    
}

-(void)evalProblem
{
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_counting_timer_general_counter_stop_button_tapped.wav")];
    
    if(!toolHost.toolCanEval)return;
    
    BOOL isWinning=NO;
    
    if(!isIntroPlist)isWinning=[self evalExpression];
    
    if(isIntroPlist && !showingIntroOverlay && started)
    {
        solutionNumber=trackNumber;
        [self setupIntroOverlay];
        return;
    }
    if(isIntroPlist && showingIntroOverlay)isWinning=YES;
    
    if(isWinning)
    {
        expired=YES;
        [buttonOfWin setVisible:NO];
        [flasher setVisible:NO];
        [flashingFlasher setOpacity:0];
        [currentNumber setPosition:ccp(cx,cy)];
        [currentNumber setString:[NSString stringWithFormat:@"%d",solutionNumber]];
        [currentNumber setFontSize:400.0f];
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

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    
}

#pragma mark - dealloc
-(void) dealloc
{
    //write log on problem switch
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    [renderLayer release];
    //tear down
    [gw release];
    
    [super dealloc];
}
@end

