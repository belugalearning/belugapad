//
//  RewardStars.m
//  belugapad
//
//  Created by Dave Amphlett on 11/01/2013.
//
//

#import "RewardStars.h"
#import "UsersService.h"
#import "ToolHost.h"

#import "Daemon.h"
#import "global.h"
#import "BLMath.h"
#import "JMap.h"
#import "AppDelegate.h"
#import "UsersService.h"
#import "ContentService.h"
#import "ToolHost.h"
#import "SimpleAudioEngine.h"


@implementation RewardStars

#pragma mark - init

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    CCLayer *stars=[RewardStars node];
    [scene addChild:stars];
    return scene;
}



-(id) init
{
    if(self=[super init])
    {
        self.touchEnabled=YES;
        [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx = lx / 2.0f;
        cy = ly / 2.0f;
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        usersService = ac.usersService;
        
        [self setupStars];
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    if(fireStar1)
        timeSinceFired+=delta;
    
    if(!stopScore && timeSinceFired>0.3f){
        scoreCounter+=scoreIncrementer;
    }
    
    if(scoreCounter>scoreAchieved)
    {
        scoreCounter=scoreAchieved;
        stopScore=YES;
    }
    
    NSString *sScore=@"";
    NSNumberFormatter *nf = [NSNumberFormatter new];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *thisNumber=[NSNumber numberWithFloat:(int)scoreCounter];
    sScore = [nf stringFromNumber:thisNumber];
    [nf release];
    
    [scoreLabel setString:sScore];
    
    if(fireStar1 && timeSinceFired>0.5f)
    {
        [s1 setVisible:YES];
        [s1 runAction:[self scaleTo1x]];
        [s1 runAction:[self rotateTo0]];
        [s1 runAction:[self moveTo:ccp(376,411)]];
        
        if(stars>1)
            countStar2=YES;
        
        fireStar1=NO;
        timeParticle1=YES;
    }
    
    if(countStar2||timeParticle1)
        timeSinceStar1+=delta;
    
    if(timeParticle1 && timeSinceStar1>0.5f)
    {
        [self setupParticleAt:ccp(376,411)];
        timeParticle1=NO;
    }
    
    if(countStar2 && timeSinceStar1>0.5f)
    {
        [s2 setVisible:YES];
        [s2 runAction:[self scaleTo1x]];
        [s2 runAction:[self rotateTo0]];
        [s2 runAction:[self moveTo:ccp(510,446)]];
        
        if(stars>2)
            countStar3=YES;
        
        countStar2=NO;
        timeParticle2=YES;
    }
    
    if(countStar3||timeParticle2)
        timeSinceStar2+=delta;
    
    if(timeParticle2 && timeSinceStar2>0.5f)
    {
        [self setupParticleAt:ccp(510,446)];
        timeParticle2=NO;
    }
    
    if(countStar3 && timeSinceStar2>0.5f)
    {
        [s3 setVisible:YES];
        [s3 runAction:[self scaleTo1x]];
        [s3 runAction:[self rotateTo0]];
        [s3 runAction:[self moveTo:ccp(643,411)]];
        //shownStar3=YES;
        countStar3=NO;
        timeParticle3=YES;
    }
    
    if(timeParticle3)
        timeSinceStar3+=delta;
    
    if(timeParticle3 && timeSinceStar3>0.5f)
    {
        [self setupParticleAt:ccp(643,411)];
        timeParticle3=NO;
    }
    
//    if(shownStar3 && timeSinceStar3>0.5f)
//    {
//        [self setupParticleAt:ccp(643,411)];
//        shownStar3=NO;
//    }
}

#pragma mark - setup and parse

-(void) setupStars;
{
    CCSprite *toolBg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/background.png")];
    [toolBg setPosition:ccp(cx,cy)];
    [self addChild:toolBg];
    
    stars=usersService.lastStarAchieved;
    //stars=3;
    scoreAchieved=usersService.lastScoreAchieved;
    //scoreAchieved=223523;
    
    scoreCounter=0;
    scoreIncrementer=scoreAchieved/30;
    
    CCSprite *starBkg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_bg.png")];
    [starBkg setPosition:ccp(-lx,cy)];
    [self addChild:starBkg];
    
    [starBkg runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp(cx,cy)] rate:0.5f]];
    
    scoreLabel=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:36.0f];
    [scoreLabel setPosition:ccp(510,340)];
    [self addChild:scoreLabel];
    [scoreLabel runAction:[CCFadeIn actionWithDuration:0.5f]];
    
    s1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_1.png")];
    s2=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_2.png")];
    s3=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_3.png")];
    
    replayNode=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_replay.png")];
    [replayNode setPosition:ccp(350-lx,278)];
    [self addChild:replayNode];
    [replayNode runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp(350,278)] rate:0.5f]];
    
    returnToMap=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_map.png")];
    [returnToMap setPosition:ccp(668-lx,278)];
    [self addChild:returnToMap];
    [returnToMap runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp(668,278)] rate:0.5f]];
    

    
    [s1 setScale:4.0f];
    [s2 setScale:4.0f];
    [s3 setScale:4.0f];
    
    [s1 setRotation:-90.0f];
    [s2 setRotation:-90.0f];
    [s3 setRotation:-90.0f];
    
    [s1 setPosition:ccp(0,ly)];
    [s2 setPosition:ccp(0,ly)];
    [s3 setPosition:ccp(0,ly)];
    
    [s1 setVisible:NO];
    [s2 setVisible:NO];
    [s3 setVisible:NO];
    
    [self addChild:s1];
    [self addChild:s2];
    [self addChild:s3];

    fireStar1=YES;
    
//    [s1 runAction:[self scaleTo1xRotateAndPlace:ccp(376,411)]];
//    [s2 runAction:[self scaleTo1xRotateAndPlace:ccp(510,446)]];
//    [s3 runAction:[self scaleTo1xRotateAndPlace:ccp(643,411)]];
    
}

-(void)playThud
{
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_reward_thud.wav")];
}

-(void)setupParticleAt:(CGPoint)position
{
    [self playThud];
    CCParticleSystemQuad *primaryParticle=[CCParticleSystemQuad particleWithFile:@"star_explosion2.plist"];
    [primaryParticle setPosition:position];
    [self addChild:primaryParticle];
    
    CCParticleSystemQuad *secondaryParticle=[CCParticleSystemQuad particleWithFile:@"glitter_explosion2.plist"];
    [secondaryParticle setPosition:position];
    [self addChild:secondaryParticle];
}

-(CCScaleTo*)scaleTo1x
{
    CCScaleTo *scale=[CCScaleTo actionWithDuration:0.5f scale:1.0f];
    return scale;
}

-(CCRotateTo*)rotateTo0
{
    CCRotateTo *rotate=[CCRotateTo actionWithDuration:0.5f angle:0.0f];
    return rotate;
}

-(CCMoveTo*)moveTo:(CGPoint)here
{
    CCMoveTo *move=[CCMoveTo actionWithDuration:0.5f position:here];
    return move;
}

#pragma mark - touches

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if(CGRectContainsPoint(returnToMap.boundingBox, location) && !returningToMap)
    {
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_pause_tap.wav")];
        [[CCDirector sharedDirector] replaceScene:[JMap scene]];
        returningToMap=YES;
    }
    else if(CGRectContainsPoint(replayNode.boundingBox, location))
    {
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_header_pause_tap.wav")];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        ContentService *cs = ac.contentService;
        [cs createAndStartFunnelForNode:ac.lastViewedNodeId];
        
        if(ac.IsIpad1)
        {
            [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
        }
        else {
            [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:0.5f scene:[ToolHost scene]]];
        }
    }
}


#pragma mark - tear down

-(void)dealloc
{
//    [[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
//    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    
    [super dealloc];
}

@end
