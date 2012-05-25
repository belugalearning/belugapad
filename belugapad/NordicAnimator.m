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
    
    [self setupBases];
    
}

-(void) setupBases
{
    //setup bases
    baseLayer=[[CCLayer alloc] init];
    [baseLayer setPosition:ccp(0, -4.0f*ly)];
    
//    for (int i=0; i<5; i++) {
//
//        NSString *fp=[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat: @"/images/ttbg/tx-base-0%d.png", i+1]];
//        baseSprite[i]=[CCSprite spriteWithFile:fp];
//        NSLog(@"loading %@", fp);
//        [baseSprite[i] setPosition:ccp(cx, ((5-i)*ly - cy))];
//        [baseLayer addChild:baseSprite[i]];
//    }
//    
//    [backgroundLayer addChild:baseLayer];
    
    baseColor=[CCLayerColor layerWithColor:ccc4(100, 100, 100, 255) width:lx height:5*ly];
    [baseColor setPosition:ccp(0, -4*ly)];
    [backgroundLayer addChild:baseColor];
    
    
    waterLayer=[[CCLayer alloc] init];
    [waterLayer setPosition:ccp(0, -4.0f*ly)];
    
    for (int i=0; i<5; i++) {
        
        NSString *fp=[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat: @"/images/ttbg/tx-water-0%d.png", i+1]];
        waterSprite[i]=[CCSprite spriteWithFile:fp];
        NSLog(@"loading %@", fp);
        [waterSprite[i] setPosition:ccp(cx, ((5-i)*ly - cy))];
        [waterLayer addChild:waterSprite[i]];
    }
    
    [backgroundLayer addChild:waterLayer];
    
    
    hill1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-left-hill.png")];
    [hill1 setPosition:ccp(150, 0)];
    [backgroundLayer addChild:hill1];
    
    hill2=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-right-hill.png")];
    [hill2 setPosition:ccp(lx-250, 0)];
    [backgroundLayer addChild:hill2];
    
    skySprite1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/sky-01.png")];
    [skySprite1 setPosition:ccp(cx, cy-25.5f)];
    [backgroundLayer addChild:skySprite1];
}

-(void) animateBackgroundIn
{
    //all -top2 images are loaded at -1.5*cy to place top1 of the top2 in centre frame on start with bg layer at 0,0
    
    //add bases to background layer
//    bgBase1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-base-layer-1x-top2.png")];
//    [bgBase1 setPosition:ccp(cx, ly * -0.0f)];
//    [backgroundLayer addChild:bgBase1 z:0];
        
//    //manually offsetting this
//    bgWater1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-water-1x-top2.png")];
//    [bgWater1 setPosition:ccp(cx, ly * -0.15)];
//    [backgroundLayer addChild:bgWater1 z:0];
    
    //needs offset built in as 0.5*ly bigger
//    bgSun1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-sun-1x-top2.5.png")];
//    [bgSun1 setPosition:ccp(cx, ly * -0.25f)];
//    [bgSun1 setOpacity:50];
//    [backgroundLayer addChild:bgSun1 z:0];
    
    CCRotateBy *r1=[CCRotateBy actionWithDuration:6.0f angle:7.0f];
    CCEaseInOut *sunease1=[CCEaseInOut actionWithAction:r1 rate:2.0f];
    CCRotateBy *r2=[CCRotateBy actionWithDuration:6.0f angle:-7.0f];
    CCEaseInOut *sunease2=[CCEaseInOut actionWithAction:r2 rate:2.0f];
    CCSequence *s=[CCSequence actions:sunease1, sunease2, nil];
    CCRepeatForever *rp=[CCRepeatForever actionWithAction:s];
//    [bgSun1 runAction:rp];
    
//    bgMountain1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-mountains-1x.png")];
//    [bgMountain1 setPosition:ccp(lx, cy)];
//    [backgroundLayer addChild:bgMountain1 z:0];
    
    //move the sun quicker still
    CCMoveBy *mvSun=[CCMoveBy actionWithDuration:1.5f position:ccp(0, 0.25*ly)];
    [bgSun1 runAction:mvSun];
    
    
}

-(void) moveToTool1: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 0.85f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveAwaySurface];
}

-(void) moveAwaySurface
{
    //move the mountain
    CCMoveTo *mvMountain=[CCMoveTo actionWithDuration:1.5f position:ccp(lx+cx, 0)];
    [bgMountain1 runAction:mvMountain];
    
    //move the hills
    [hill1 runAction:[CCMoveTo actionWithDuration:1.5f position:ccp(0, 0)]];
    [hill2 runAction:[CCMoveTo actionWithDuration:1.5f position:ccp(lx, 0)]];
    
}

-(void) moveToSurface
{
    //move the mountain
    CCMoveBy *mvMountain=[CCMoveBy actionWithDuration:1.5f position:ccp(lx, 0)];
    [bgMountain1 runAction:mvMountain];
    
    //move the hills
    [hill1 runAction:[CCMoveBy actionWithDuration:1.5f position:ccp(150, 0)]];
    [hill2 runAction:[CCMoveBy actionWithDuration:1.5f position:ccp(lx-250, 0)]];
    
}

-(void) moveToTool2: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 2.25f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveAwaySurface];
    
}

-(void) moveToTool3: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 4.0f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];

    [self moveAwaySurface];
}

-(void) moveToTool0: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 0)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveToSurface];
}

@end
