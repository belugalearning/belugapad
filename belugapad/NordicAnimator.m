//
//  NordicAnimator.m
//  belugapad
//
//  Created by Gareth Jenkins on 25/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NordicAnimator.h"
#import "global.h"

static CGPoint hill1Pos={100, 0};
static CGPoint hill2Pos={900, 0};
static CGPoint hill1Pos2={-50, 0};
static CGPoint hill2Pos2={1200, 0};

@implementation NordicAnimator

-(void)setBackground:(CCLayer *)bkg withCx:(float)cxin withCy:(float)cyin
{
    backgroundLayer=bkg;
    
    cx=cxin;
    cy=cyin;
    lx=2.0f*cx;
    ly=2.0f*cy;
    
    [self setupBases];

    timeToNextCreature=6.0f;
    camPos=0;
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
    
    
    baseSky=[CCLayerColor layerWithColor:ccc4(255, 255, 255, 255) width:lx height:ly];
    [baseSky setPosition:ccp(0, 0)];
    [backgroundLayer addChild:baseSky];
    

    
    subLinesSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/subsurface-lines.png")];
    [subLinesSprite setPosition:ccp(cx, (-2.5f*ly)+385.5f)];
    [subLinesSprite setOpacity:75];
    [subLinesSprite setScale:4];
    [backgroundLayer addChild:subLinesSprite];
    
    
    waterLayer=[[CCLayer alloc] init];
    [waterLayer setPosition:ccp(0, -4.0f*ly)];
    
    for (int i=0; i<5; i++) {
        
        //NSString *fp=[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat: @"/images/ttbg/tx-water_0%d.png", i+1]];
        NSString *fp=[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat: @"/images/ttbg/tx-water-half_0%d.png", i+1]];

        waterSprite[i]=[CCSprite spriteWithFile:fp];
        NSLog(@"loading %@", fp);
        [waterSprite[i] setScale:2.0f];
        [waterSprite[i] setPosition:ccp(cx, ((5-i)*ly - cy))];
        [waterLayer addChild:waterSprite[i]];
    }
    
    [backgroundLayer addChild:waterLayer];
    
    creatureLayer=[[CCLayer alloc] init];
    [backgroundLayer addChild:creatureLayer];
    
    bgMountain1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/mountain.png")];
    [bgMountain1 setPosition:ccp(lx, 0.83f*cy)];
    [bgMountain1 setScale:4];
    [backgroundLayer addChild:bgMountain1 z:0];

    
    hill1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-left-hill.png")];
    [hill1 setPosition:hill1Pos];
    [backgroundLayer addChild:hill1];
    
    hill2=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/tx-right-hill.png")];
    [hill2 setPosition:hill2Pos];
    [backgroundLayer addChild:hill2];
    
    
    //needs offset built in as 0.5*ly bigger
    bgSun1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/sun.png")];
    [bgSun1 setPosition:ccp(0.75f*cx, (ly * -1))];
    [bgSun1 setOpacity:75];
    [bgSun1 setScale:4];
    [backgroundLayer addChild:bgSun1 z:0];
    
    //[bgSun1 setAnchorPoint:ccp(-256, ly)];
    
    CCRotateBy *r1=[CCRotateBy actionWithDuration:6.0f angle:7.0f];
    CCEaseInOut *sunease1=[CCEaseInOut actionWithAction:r1 rate:2.0f];
    CCRotateBy *r2=[CCRotateBy actionWithDuration:6.0f angle:-7.0f];
    CCEaseInOut *sunease2=[CCEaseInOut actionWithAction:r2 rate:2.0f];
    CCSequence *s=[CCSequence actions:sunease1, sunease2, nil];
    CCRepeatForever *rp=[CCRepeatForever actionWithAction:s];
    [bgSun1 runAction:rp];

    //move the sun quicker still
    CCMoveBy *mvSun=[CCMoveBy actionWithDuration:1.5f position:ccp(0, 0.25*ly)];
    [bgSun1 runAction:mvSun];
    
    skySprite1=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/sky-01.png")];
    [skySprite1 setPosition:ccp(cx, cy-25.5f)];
    [backgroundLayer addChild:skySprite1];
    
}

-(void) doUpdate:(ccTime) delta;
{
    timeToNextCreature -= delta;
    
    if (timeToNextCreature<=0) {
        
        [self animateCreature1];
        
        timeToNextCreature=(arc4random()%30) + 20;
    }
}

-(CCLayer*)getCurrentCreatureLayer;
{
    if (camPos<3) {
        return creatureLayer;
    }
    else {
        return backgroundLayer;
    }
}

-(void)doCreatureSetupFor:(CCSprite *)creature
{
    if (camPos<3) {
        [creature setOpacity:50];
    }
    else {
        [creature setOpacity:150];
    }
}

-(void) animateCreature1 //sunfish
{
    if(!creature1Batch)
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/sunfish.plist")];
        creature1Batch=[CCSpriteBatchNode batchNodeWithFile: BUNDLE_FULL_PATH(@"/images/ttbg/sunfish.png")];
        [creatureLayer addChild:creature1Batch];
    }
    
    CCSprite *sprite=[CCSprite spriteWithSpriteFrameName:@"sun fish0001.png"];
    [creature1Batch addChild:sprite];
    
    CCAnimation *baseAnim=[[CCAnimation alloc] init];
    [baseAnim setDelayPerUnit:1.0f/24.0f];
    
    for (int fi=1; fi<=59; fi++) {
        NSString *fname=[NSString stringWithFormat:@"sun fish%04d.png", fi];
        [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];
        
    }
    
    CCAnimate *animate=[CCAnimate actionWithAnimation:baseAnim];
    CCRepeatForever *rf=[CCRepeatForever actionWithAction:animate];
    
    [sprite runAction:rf];
    
    
    int ry1=arc4random()%(int)ly;
    int ry2=arc4random()%(int)ly;
    
    if((arc4random()%2)==1) ry2=ry1+ry2;
    else ry2=ry1-ry2;
    
    CGPoint p1, p2;
    
    if ((arc4random()%2)==1) {
        p1=ccp(-100, ry1);
        p2=ccp(lx+100, ry2);
        [sprite setFlipX:YES];
    }
    else {
        p1=ccp(lx+100, ry1);
        p2=ccp(-100, ry2);
    }
    
    ccBezierConfig b;
    b.controlPoint_1=ccp((arc4random()%300) + 350, p2.y + (arc4random()%150));
    b.endPosition=p2;

    p1=[backgroundLayer convertToNodeSpace:p1];
    p2=[backgroundLayer convertToNodeSpace:p2];
    b.controlPoint_1=[backgroundLayer convertToNodeSpace:b.controlPoint_1];
    b.endPosition=[backgroundLayer convertToNodeSpace:b.endPosition];

    [sprite setPosition:p1];
    [sprite runAction:[CCBezierTo actionWithDuration:25.0f bezier:b]];
    
    [self doCreatureSetupFor:sprite];
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
    
    


    CCMoveTo *mv=[CCMoveTo actionWithDuration:0.5f position:ccp(0, 0.15f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
        
}

-(void) moveToTool1: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 0.85f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveAwaySurface];
    
    camPos=1;
}

-(void) moveAwaySurface
{
    //move the mountain
    CCMoveTo *mvMountain=[CCMoveTo actionWithDuration:1.5f position:ccp(lx+(cx*0.25f), 0.83f*cy)];
    [bgMountain1 runAction:mvMountain];
    
    //move the hills
    [hill1 runAction:[CCMoveTo actionWithDuration:1.5f position:hill1Pos2]];
    [hill2 runAction:[CCMoveTo actionWithDuration:1.5f position:hill2Pos2]];
    
}

-(void) moveToSurface
{
    //move the mountain
    CCMoveBy *mvMountain=[CCMoveTo actionWithDuration:1.5f position:ccp(lx,0.83*cy)];
    [bgMountain1 runAction:mvMountain];
    
    //move the hills
    [hill1 runAction:[CCMoveTo actionWithDuration:1.5f position:hill1Pos]];
    [hill2 runAction:[CCMoveTo actionWithDuration:1.5f position:hill2Pos]];
    
}

-(void) moveToTool2: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 2.25f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveAwaySurface];
    
    camPos=2;
    
}

-(void) moveToTool3: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 4.0f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];

    [self moveAwaySurface];
    
    camPos=3;
}

-(void) moveToTool0: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 0.15f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveToSurface];
    
    camPos=0;
}

@end
