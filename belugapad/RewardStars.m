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
    {
        [s1 setVisible:YES];
        [s1 runAction:[self scaleTo1x]];
        [s1 runAction:[self rotateTo0]];
        [s1 runAction:[self moveTo:ccp(376,411)]];
        
        if(stars>1)
            countStar2=YES;
        fireStar1=NO;
    }
    
    if(countStar2)
        timeSinceStar1+=delta;
    
    if(countStar2 && timeSinceStar1>0.5f)
    {
        [self setupParticleAt:ccp(376,411)];
        [s2 setVisible:YES];
        [s2 runAction:[self scaleTo1x]];
        [s2 runAction:[self rotateTo0]];
        [s2 runAction:[self moveTo:ccp(510,446)]];
        countStar3=YES;
        countStar2=NO;
    }
    
    if(countStar3)
        timeSinceStar2+=delta;
    
    if(countStar3 && timeSinceStar2>0.5f)
    {
        [self setupParticleAt:ccp(510,446)];
        [s3 setVisible:YES];
        [s3 runAction:[self scaleTo1x]];
        [s3 runAction:[self rotateTo0]];
        [s3 runAction:[self moveTo:ccp(643,411)]];
        shownStar3=YES;
        countStar3=NO;
    }
    
    if(shownStar3)
        timeSinceStar3+=delta;
    
    if(shownStar3 && timeSinceStar3>0.5f)
    {
        [self setupParticleAt:ccp(643,411)];
        shownStar3=NO;
    }
}

#pragma mark - setup and parse

-(void) setupStars;
{
    stars=usersService.lastStarAcheived;
    CCSprite *starBkg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_bg.png")];
    [starBkg setPosition:ccp(cx,cy)];
    [self addChild:starBkg];
    
    s1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_1.png")];
    s2=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_2.png")];
    s3=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_3.png")];
    
    replayNode=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_replay.png")];
    [replayNode setPosition:ccp(762,227)];
    [self addChild:replayNode];
    
    returnToMap=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_map.png")];
    [returnToMap setPosition:ccp(351,227)];
    [self addChild:returnToMap];
    

    
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

-(void)setupParticleAt:(CGPoint)position
{
    CCParticleSystemQuad *primaryParticle=[CCParticleSystemQuad particleWithFile:@"star_explosion2.plist"];
    [primaryParticle setPosition:position];
    [self addChild:primaryParticle];
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
    
    if(CGRectContainsPoint(returnToMap.boundingBox, location))
    {
        [[CCDirector sharedDirector] replaceScene:[JMap scene]];
    }
    else if(CGRectContainsPoint(replayNode.boundingBox, location))
    {
        NSLog(@"replay");
    }
}


#pragma mark - tear down

-(void)dealloc
{
    [super dealloc];
}

@end
