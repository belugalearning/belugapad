//
//  NordicAnimator.m
//  belugapad
//
//  Created by Gareth Jenkins on 25/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NordicAnimator.h"
#import "global.h"

@implementation NordicAnimator

-(void)setBackground:(CCLayer *)bkg withCx:(float)cxin withCy:(float)cyin
{
    backgroundLayer=bkg;
    
    cx=cxin;
    cy=cyin;
    lx=2.0f*cx;
    ly=2.0f*cy;
}

-(void) animateBackgroundIn
{
    //all -top2 images are loaded at -1.5*cy to place top1 of the top2 in centre frame on start with bg layer at 0,0
    
    //add bases to background layer
    bgBase1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-base-layer-1x-top2.png")];
    [bgBase1 setPosition:ccp(cx, ly * -0.0f)];
    [backgroundLayer addChild:bgBase1 z:0];
    
    
    //manually offsetting this
    bgWater1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-water-1x-top2.png")];
    [bgWater1 setPosition:ccp(cx, ly * -0.15)];
    [backgroundLayer addChild:bgWater1 z:0];
    
    //needs offset built in as 0.5*ly bigger
    bgSun1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-sun-1x-top2.5.png")];
    [bgSun1 setPosition:ccp(cx, ly * -0.25f)];
    [bgSun1 setOpacity:50];
    [backgroundLayer addChild:bgSun1 z:0];
    
    CCRotateBy *r1=[CCRotateBy actionWithDuration:6.0f angle:7.0f];
    CCEaseInOut *sunease1=[CCEaseInOut actionWithAction:r1 rate:2.0f];
    CCRotateBy *r2=[CCRotateBy actionWithDuration:6.0f angle:-7.0f];
    CCEaseInOut *sunease2=[CCEaseInOut actionWithAction:r2 rate:2.0f];
    CCSequence *s=[CCSequence actions:sunease1, sunease2, nil];
    CCRepeatForever *rp=[CCRepeatForever actionWithAction:s];
    [bgSun1 runAction:rp];
    
    bgMountain1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-mountains-1x.png")];
    [bgMountain1 setPosition:ccp(lx, cy)];
    [backgroundLayer addChild:bgMountain1 z:0];
    
}

-(void) moveToTool1: (ccTime) delta
{
    CCMoveBy *mv=[CCMoveBy actionWithDuration:1.5f position:ccp(0, ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    //move the sun quicker still
    CCMoveBy *mvSun=[CCMoveBy actionWithDuration:1.5f position:ccp(0, 0.25*ly)];
    [bgSun1 runAction:mvSun];
    
    //move the mountain
    CCMoveBy *mvMountain=[CCMoveBy actionWithDuration:1.5f position:ccp(cx, 0)];
    [bgMountain1 runAction:mvMountain];
    
}

-(void) moveToTool2: (ccTime) delta
{
    
}

-(void) moveToTool3: (ccTime) delta
{
    
}

@end
