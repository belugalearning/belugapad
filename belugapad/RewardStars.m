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

#import "AppDelegate.h"
#import "ToolHost.h"
#import "SimpleAudioEngine.h"


@implementation RewardStars

#pragma mark - init

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    CCLayer *stars=[CCLayer node];
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
        
        [self setupStars];
    }
    
    return self;
}

#pragma mark - setup and parse

-(void) setupStars;
{
    int stars=3;
    CCSprite *starBkg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_bg.png")];
    [starBkg setPosition:ccp(cx,cy)];
    [self addChild:starBkg];
    
    CCSprite *s1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_1.png")];
    CCSprite *s2=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_2.png")];
    CCSprite *s3=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/rewards/final_score_star_3.png")];
    
    [s1 setPosition:ccp(376,411)];
    [s2 setPosition:ccp(510,444)];
    [s3 setPosition:ccp(643,411)];
    
    if(stars==1)
    {
        [self addChild:s1];
    }
    else if(stars==2)
    {
        [self addChild:s1];
        [self addChild:s2];
    }
    else if(stars==3)
    {
        [self addChild:s1];
        [self addChild:s2];
        [self addChild:s3];
    }
    
}




#pragma mark - tear down

-(void)dealloc
{
    [super dealloc];
}

@end
