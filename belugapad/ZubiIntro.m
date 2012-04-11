//
//  ZubiIntro.m
//  belugapad
//
//  Created by Gareth Jenkins on 17/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZubiIntro.h"
#import "Daemon.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "global.h"

#import "ToolHost.h"

static float kPropYZubiPos=0.35f;
static float kPropYOverlayPos=0.65f;

@implementation ZubiIntro

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    
    ZubiIntro *layer=[ZubiIntro node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id)init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        CCSprite *b=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/zubi/intro/zbkg.png")];
        [b setPosition:ccp(cx, cy)];
        [self addChild:b];
        
        bkgLayer=[[CCLayer alloc] init];
        [self addChild:bkgLayer];
        
        zubiLayer=[[CCLayer alloc] init];
        [self addChild:zubiLayer];
        
        [self schedule:@selector(doUpdate:) interval:1.0f/60.0f];
        
        daemon=[[Daemon alloc] initWithLayer:zubiLayer andRestingPostion:ccp(cx, kPropYZubiPos * ly) andLy:ly];
        
        slideIndex=1;
        
        slideTime=2.0f;
     }
    
    return self;
}

-(void) showSlide
{
    [bkgLayer removeAllChildrenWithCleanup:YES];
    
    slideImage=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/zubi/intro/zlay%d.png", slideIndex]))];
    [bkgLayer addChild:slideImage];
    
    [slideImage setPosition:ccp(cx, ly * kPropYOverlayPos)];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if(enableZubiTaps) [daemon setTarget:location];
    lastTouch=location;
    
    hasTapped=YES;
    
    if(location.x>kButtonNextToolHitXOffset && location.y>kButtonToolbarHitBaseYOffset)
    {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.3f scene:[ToolHost scene]]];
    }
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;
    
    if(enableZubiTaps) [daemon setTarget:location];
}

-(void)doUpdate:(ccTime)delta
{
    [daemon doUpdate:delta];
    
    slideTime-=delta;
    
    //if the timer's at 0 and we're either not waiting for a tap, or we're waiting for a tap and the user has tapped
    if(slideTime<=0.0f && ((waitForTap && hasTapped) || !waitForTap))
    {
        if(slideIndex<14) slideIndex++;
        
        //default to 2s wait
        slideTime=3.0f;
        
        //auto-incrementing slides, that need reset to 1s
        if(slideIndex == 2 || slideIndex == 4 || slideIndex == 5 || slideIndex == 6 || slideIndex == 8 || slideIndex == 9 || slideIndex == 10 || slideIndex == 11 || slideIndex == 12)
        {
            slideTime=1.5f;
        }
        
        //slides that require tap
        waitForTap=NO;
        if(slideIndex == 7 || slideIndex == 13)
        {
            waitForTap=YES;
            slideTime=0.0f;
        }
        
        //enable zubi at this point onward
        if(slideIndex==7)
        {
            enableZubiTaps=YES;
        }
        
        //finish scene
        if(slideIndex==14 && [BLMath DistanceBetween:lastTouch and:ccp(cx, 440)] < 50.0f )
        {
            [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.3f scene:[ToolHost scene]]];
            return;
        }
        
        if(slideIndex == 2 || slideIndex == 4 || slideIndex == 5 || slideIndex == 7 || slideIndex == 9 || slideIndex == 11 || slideIndex == 13)
        {
            [self showSlide];
        }
        else if(slideIndex<14)
        {
            [bkgLayer removeAllChildrenWithCleanup:YES];
            lastTouch=ccp(0,0);
        }

    }
    
    hasTapped=NO;
}

@end
