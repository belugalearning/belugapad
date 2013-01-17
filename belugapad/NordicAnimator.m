//
//  NordicAnimator.m
//  belugapad
//
//  Created by Gareth Jenkins on 25/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NordicAnimator.h"
#import "global.h"
#import "SimpleAudioEngine.h"

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
    
    baseColor=[CCLayerColor layerWithColor:ccc4(40, 40, 80, 255) width:lx height:5*ly];
    [baseColor setPosition:ccp(0, -4*ly)];
    [backgroundLayer addChild:baseColor];
    
    
    baseSky=[CCLayerColor layerWithColor:ccc4(255, 255, 255, 255) width:lx height:ly];
    [baseSky setPosition:ccp(0, 0)];
    [backgroundLayer addChild:baseSky];
    
    bgLeftUpperLedge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/left-upper-ledge.png")];
    [bgLeftUpperLedge setPosition:ccp(0, -1.75f * ly)];
    [bgLeftUpperLedge setOpacity:180];
    [bgLeftUpperLedge setScale:4.0f];
    [backgroundLayer addChild:bgLeftUpperLedge];
    
    bgLeftLowerLedge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/left-lower-ledge.png")];
    [bgLeftLowerLedge setPosition:ccp(0, -3.0f * ly)];
    [bgLeftLowerLedge setScale:4.0f];
    [backgroundLayer addChild:bgLeftLowerLedge];
    
    bgRightLowerLedge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/right-lower-ledge.png")];
    [bgRightLowerLedge setPosition:ccp(lx, -2.75f * ly)];
    [bgRightLowerLedge setScale:4.0f];
    [backgroundLayer addChild:bgRightLowerLedge];
    
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
     
        int offset=0;
        if(camPos==0) offset=-2 * ly;
        if(camPos==1) offset=-0.5f*ly;
        
        
        int cpick=arc4random()%6;
        if (cpick==0) {
            [self animateSunfishWithYOffset:offset];
        }
        else if (cpick==1)
        {
            [self animateAnglerWithYOffset:offset];
        }
        else if (cpick==2 && camPos>1) // jelly fish
        {
            [self animateJellyfishWithYOffset:offset];
        }
        else if(cpick==3) // school
        {
            [self animateSchoolWithYOffset:offset];
        }
        else if(cpick==4 && camPos==3) //eel
        {
            [self animateEelWithYOffset:offset];
        }
        else if(cpick==5 && camPos>1) // blow fish
        {
            [self animateBlowfishWithYOffset:offset];
        }
        
        //play a random whale sample
        int whaleno=arc4random() % 7 + 1;
        NSString *whalefile=[NSString stringWithFormat:@"/sfx/integrated/creature%d.wav", whaleno];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(whalefile)];
        
        timeToNextCreature=(arc4random()%40) + 5;
        //timeToNextCreature=(arc4random()%2) + 2;
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
    if (camPos<4) {
        
        int sizeDown=100-(arc4random()%50);
        float propDown=sizeDown/100.0f;
        
        [creature setScale:propDown];
        
        if(camPos<3)
        {
            [creature setOpacity:10+ (30*propDown)];
        }
        else {
            [creature setOpacity:5+(20*propDown)];
            //[creature setScale:0.3f*creature.scale];
        }
    }
}

-(void) animateSunfishWithYOffset:(int)yoffset //sunfish
{
    if(!sunfishBatch)
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/sunfish.plist")];
        sunfishBatch=[CCSpriteBatchNode batchNodeWithFile: BUNDLE_FULL_PATH(@"/images/ttbg/sunfish.png")];
        [creatureLayer addChild:sunfishBatch];
    }
    
    CCSprite *sprite=[CCSprite spriteWithSpriteFrameName:@"sun fish0001.png"];
    [sunfishBatch addChild:sprite];
    
    CCAnimation *baseAnim=[[CCAnimation alloc] init];
    [baseAnim setDelayPerUnit:1.0f/24.0f];
    
    for (int fi=1; fi<=59; fi++) {
        NSString *fname=[NSString stringWithFormat:@"sun fish%04d.png", fi];
        [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];
        
    }
    
    CCAnimate *animate=[CCAnimate actionWithAnimation:baseAnim];
    CCRepeatForever *rf=[CCRepeatForever actionWithAction:animate];
    
    [sprite runAction:rf];
    
    //start position (l or r)
    int ry1=arc4random()%(int)ly;
    //offset up or down on other side
    int ry2=arc4random()%(int)(ly / 3.0f);
    
    //flip up or down randomly
    if((arc4random()%2)==1) ry2=ry1+ry2;
    else ry2=ry1-ry2;
    
    CGPoint p1, p2;
    
    //flip left to right, right to left
    if ((arc4random()%2)==1) {
        p1=ccp(-100, ry1+yoffset);
        p2=ccp(lx+100, ry2+yoffset);
        [sprite setFlipX:YES];
    }
    else {
        p1=ccp(lx+100, ry1+yoffset);
        p2=ccp(-100, ry2+yoffset);
    }
    
    //bezier the path
    ccBezierConfig b;
    b.controlPoint_1=ccp((arc4random()%300) + 350, p2.y + (arc4random()%150) + yoffset);
    b.controlPoint_2=b.controlPoint_1;
    b.endPosition=p2;

    //now translate all coordinates into layer space
    p1=[backgroundLayer convertToNodeSpace:p1];
    //p2=[backgroundLayer convertToNodeSpace:p2];
    b.controlPoint_1=[backgroundLayer convertToNodeSpace:b.controlPoint_1];
    b.controlPoint_2=[backgroundLayer convertToNodeSpace:b.controlPoint_2];
    b.endPosition=[backgroundLayer convertToNodeSpace:b.endPosition];

    //wheee!
    [sprite setPosition:p1];
    [sprite runAction:[CCBezierTo actionWithDuration:80.0f bezier:b]];
    
    //general config -- handles position tinting, size etc
    [self doCreatureSetupFor:sprite];
}


-(void) animateAnglerWithYOffset:(int)yoffset //angler fish
{
    if(!anglerBatch)
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/anglerswim.plist")];
        anglerBatch=[CCSpriteBatchNode batchNodeWithFile: BUNDLE_FULL_PATH(@"/images/ttbg/anglerswim.png")];
        [creatureLayer addChild:anglerBatch];
    }
    
    CCSprite *sprite=[CCSprite spriteWithSpriteFrameName:@"anglerswim0001.png"];
    [anglerBatch addChild:sprite];
    
    CCAnimation *baseAnim=[[CCAnimation alloc] init];
    [baseAnim setDelayPerUnit:1.0f/24.0f];
    
    for (int fi=1; fi<=74; fi++) {
        NSString *fname=[NSString stringWithFormat:@"anglerswim%04d.png", fi];
        [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];
        
    }
    
    CCAnimate *animate=[CCAnimate actionWithAnimation:baseAnim];
    CCRepeatForever *rf=[CCRepeatForever actionWithAction:animate];
    
    [sprite runAction:rf];
    
    //start position (l or r)
    int ry1=arc4random()%(int)ly;
    //offset up or down on other side
    int ry2=arc4random()%(int)(ly / 3.0f);
    
    //flip up or down randomly
    if((arc4random()%2)==1) ry2=ry1+ry2;
    else ry2=ry1-ry2;
    
    CGPoint p1, p2;
    
    //flip left to right, right to left
    if ((arc4random()%2)==1) {
        p1=ccp(-100, ry1+yoffset);
        p2=ccp(lx+100, ry2+yoffset);
    }
    else {
        p1=ccp(lx+100, ry1+yoffset);
        p2=ccp(-100, ry2+yoffset);
        [sprite setFlipX:YES];
    }
    
    //bezier the path
    ccBezierConfig b;
    b.controlPoint_1=ccp((arc4random()%300) + 350, p2.y + (arc4random()%150) + yoffset);
    b.controlPoint_2=b.controlPoint_1;
    b.endPosition=p2;
    
    //now translate all coordinates into layer space
    p1=[backgroundLayer convertToNodeSpace:p1];
    //p2=[backgroundLayer convertToNodeSpace:p2];
    b.controlPoint_1=[backgroundLayer convertToNodeSpace:b.controlPoint_1];
    b.controlPoint_2=[backgroundLayer convertToNodeSpace:b.controlPoint_2];
    b.endPosition=[backgroundLayer convertToNodeSpace:b.endPosition];
    
    //wheee!
    [sprite setPosition:p1];
    [sprite runAction:[CCBezierTo actionWithDuration:70.0f bezier:b]];
    
    //general config -- handles position tinting, size etc
    [self doCreatureSetupFor:sprite];
}

-(void) animateJellyfishWithYOffset:(int)yoffset //jelly fish
{
    if(!jellyfishBatch)
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/jellyfish.plist")];
        jellyfishBatch=[CCSpriteBatchNode batchNodeWithFile: BUNDLE_FULL_PATH(@"/images/ttbg/jellyfish.png")];
        [creatureLayer addChild:jellyfishBatch];
    }
    
    CCSprite *sprite=[CCSprite spriteWithSpriteFrameName:@"jellyfishswim0001.png"];
    [jellyfishBatch addChild:sprite];
    
    CCAnimation *baseAnim=[[CCAnimation alloc] init];
    [baseAnim setDelayPerUnit:1.0f/24.0f];
    
    for (int fi=1; fi<=53; fi++) {
        NSString *fname=[NSString stringWithFormat:@"jellyfishswim%04d.png", fi];
        [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];
        
    }
    
    CCAnimate *animate=[CCAnimate actionWithAnimation:baseAnim];
    CCRepeatForever *rf=[CCRepeatForever actionWithAction:animate];
    
    [sprite runAction:rf];
    
    //start bottom
    int rx1=arc4random()%(int)lx;
    
    CGPoint p1=ccp(rx1, -100);
    CGPoint pmv1=ccp(0, 10);
    CGPoint pmv2=ccp(0, 90);
    
    //CGPoint p2=ccp(rx2, ly+100);
    
    //now translate all coordinates into layer space
    p1=[backgroundLayer convertToNodeSpace:p1];

    CCMoveBy *mv1=[CCMoveBy actionWithDuration:(1/24.0f * 22) position:pmv1];
    CCMoveBy *mv2=[CCMoveBy actionWithDuration:(1/24.0f * 31) position:pmv2];
    CCEaseInOut *ease2=[CCEaseInOut actionWithAction:mv2 rate:2.0f];
    CCSequence *seq=[CCSequence actions:mv1, ease2, nil];
    CCRepeat *r=[CCRepeat actionWithAction:seq times:10];
    CCFadeTo *fo=[CCFadeTo actionWithDuration:1.0f opacity:0];
    CCSequence *runout=[CCSequence actions:r, fo, nil];
    
    
    //wheee!
    [sprite setPosition:p1];
    [sprite runAction:runout];
    
    //general config -- handles position tinting, size etc
    [self doCreatureSetupFor:sprite];
}

-(void) animateSchoolWithYOffset:(int)yoffset //school of fish
{
    if(!schoolBatch)
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/schoolswim.plist")];
        schoolBatch=[CCSpriteBatchNode batchNodeWithFile: BUNDLE_FULL_PATH(@"/images/ttbg/schoolswim.png")];
        [creatureLayer addChild:schoolBatch];
    }
    
    CCSprite *sprite=[CCSprite spriteWithSpriteFrameName:@"schoolswim0001.png"];
    [schoolBatch addChild:sprite];
    
    CCAnimation *baseAnim=[[CCAnimation alloc] init];
    [baseAnim setDelayPerUnit:1.0f/15.0f];
    
    for (int fi=1; fi<=19; fi++) {
        NSString *fname=[NSString stringWithFormat:@"schoolswim%04d.png", fi];
        [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];
        
    }
    
    CCAnimate *animate=[CCAnimate actionWithAnimation:baseAnim];
    CCRepeatForever *rf=[CCRepeatForever actionWithAction:animate];
    
    [sprite runAction:rf];
    
    //start position (l or r)
    int ry1=arc4random()%(int)ly;
    //offset up or down on other side
    int ry2=arc4random()%(int)(ly / 3.0f);
    
    //flip up or down randomly
    if((arc4random()%2)==1) ry2=ry1+ry2;
    else ry2=ry1-ry2;
    
    CGPoint p1, p2;
    
    //flip left to right, right to left
    if ((arc4random()%2)==1) {
        p1=ccp(-100, ry1+yoffset);
        p2=ccp(lx+100, ry2+yoffset);
        [sprite setFlipX:YES];
    }
    else {
        p1=ccp(lx+100, ry1+yoffset);
        p2=ccp(-100, ry2+yoffset);
    }
    
    //bezier the path
    ccBezierConfig b;
    b.controlPoint_1=ccp((arc4random()%300) + 350, p2.y + (arc4random()%150) + yoffset);
    b.controlPoint_2=b.controlPoint_1;
    b.endPosition=p2;
    
    //now translate all coordinates into layer space
    p1=[backgroundLayer convertToNodeSpace:p1];
    //p2=[backgroundLayer convertToNodeSpace:p2];
    b.controlPoint_1=[backgroundLayer convertToNodeSpace:b.controlPoint_1];
    b.controlPoint_2=[backgroundLayer convertToNodeSpace:b.controlPoint_2];
    b.endPosition=[backgroundLayer convertToNodeSpace:b.endPosition];
    
    //wheee!
    [sprite setPosition:p1];
    [sprite runAction:[CCBezierTo actionWithDuration:110.0f bezier:b]];
    
    //general config -- handles position tinting, size etc
    [self doCreatureSetupFor:sprite];
}

-(void) animateEelWithYOffset:(int)yoffset //eel
{
    if(!eelBatch)
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/pelicaneel.plist")];
        eelBatch=[CCSpriteBatchNode batchNodeWithFile: BUNDLE_FULL_PATH(@"/images/ttbg/pelicaneel.png")];
        [creatureLayer addChild:eelBatch];
    }
    
    CCSprite *sprite=[CCSprite spriteWithSpriteFrameName:@"pelican eel v20001.png"];
    [eelBatch addChild:sprite];
    
    CCAnimation *baseAnim=[[CCAnimation alloc] init];
    [baseAnim setDelayPerUnit:1.0f/15.0f];
    
    for (int fi=1; fi<=30; fi++) {
        NSString *fname=[NSString stringWithFormat:@"pelican eel v2%04d.png", fi];
        [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];
        
    }
    
    CCAnimate *animate=[CCAnimate actionWithAnimation:baseAnim];
    CCRepeatForever *rf=[CCRepeatForever actionWithAction:animate];
    
    [sprite runAction:rf];
    
    //start position (l or r)
    int ry1=arc4random()%(int)ly;
    //offset up or down on other side
    int ry2=arc4random()%(int)(ly / 5.0f);
    
    //flip up or down randomly
    if((arc4random()%2)==1) ry2=ry1+ry2;
    else ry2=ry1-ry2;
    
    CGPoint p1, p2;
    
    //flip left to right, right to left
    if ((arc4random()%2)==1) {
        p1=ccp(-300, ry1+yoffset);
        p2=ccp(lx+300, ry2+yoffset);
        [sprite setFlipX:YES];
    }
    else {
        p1=ccp(lx+300, ry1+yoffset);
        p2=ccp(-300, ry2+yoffset);
    }
    
    //bezier the path
    ccBezierConfig b;
    b.controlPoint_1=ccp((arc4random()%300) + 350, p2.y + (arc4random()%50) + yoffset);
    b.controlPoint_2=b.controlPoint_1;
    b.endPosition=p2;
    
    //now translate all coordinates into layer space
    p1=[backgroundLayer convertToNodeSpace:p1];
    //p2=[backgroundLayer convertToNodeSpace:p2];
    b.controlPoint_1=[backgroundLayer convertToNodeSpace:b.controlPoint_1];
    b.controlPoint_2=[backgroundLayer convertToNodeSpace:b.controlPoint_2];
    b.endPosition=[backgroundLayer convertToNodeSpace:b.endPosition];
    
    //wheee!
    [sprite setPosition:p1];
    [sprite runAction:[CCBezierTo actionWithDuration:20.0f bezier:b]];
    
    //general config -- handles position tinting, size etc
    [self doCreatureSetupFor:sprite];
}

-(void) animateBlowfishWithYOffset:(int)yoffset //blow fish
{
    if(!blowfishBatch)
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/blowfish.plist")];
        blowfishBatch=[CCSpriteBatchNode batchNodeWithFile: BUNDLE_FULL_PATH(@"/images/ttbg/blowfish.png")];
        [creatureLayer addChild:blowfishBatch];
    }
    
    CCSprite *sprite=[CCSprite spriteWithSpriteFrameName:@"blowfish0001.png"];
    [blowfishBatch addChild:sprite];
    
    CCAnimation *baseAnim=[[CCAnimation alloc] init];
    [baseAnim setDelayPerUnit:1.0f/24.0f];
    
    int swimCount=arc4random()%30 + 1;
    
    //swim
    for (int i=0; i<swimCount; i++)
    {
        for (int fi=1; fi<=105; fi++) {
            NSString *fname=[NSString stringWithFormat:@"blowfish%04d.png", fi];
            [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];
            
        }
    }
    //explode
    for (int fci=106; fci<=220; fci++) {
        NSString *fname=[NSString stringWithFormat:@"blowfish%04d.png", fci];
        [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];        
    }
    //rotate
    for (int i=0; i<10; i++)
    {
        for (int fci=138; fci<=220; fci++) {
            NSString *fname=[NSString stringWithFormat:@"blowfish%04d.png", fci];
            [baseAnim addSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:fname]];        
        }   
    }
    CCAnimate *animate=[CCAnimate actionWithAnimation:baseAnim];
    [sprite runAction:animate];
    
    
    
    //start y
    int ry1=arc4random()%(int)ly;
    CGPoint p1, p2;
    int swimLengthX=50;
    
    //flip left to right, right to left
    if ((arc4random()%2)==1) {
        p1=ccp(-100, ry1+yoffset);
        p2=ccp(swimLengthX*swimCount, ry1+yoffset);
        [sprite setFlipX:YES];
    }
    else {
        p1=ccp(lx+100, ry1+yoffset);
        p2=ccp(lx-(swimLengthX*swimCount), ry1+yoffset);
    }
    
    //now translate all coordinates into layer space
    p1=[backgroundLayer convertToNodeSpace:p1];
    p2=[backgroundLayer convertToNodeSpace:p2];
    
    CCMoveTo *mv1=[CCMoveTo actionWithDuration:1/24.0f * 105 * swimCount position:p2];
    CCMoveBy *mv2=[CCMoveBy actionWithDuration:12.5f position:ccp(0, 800)];
    CCEaseOut *ease2=[CCEaseInOut actionWithAction:mv2 rate:2.0f];
    CCFadeTo *fo=[CCFadeTo actionWithDuration:1.0f opacity:0];
    CCSequence *seq=[CCSequence actions:mv1, ease2, fo, nil];
    
    //wheee!
    [sprite setPosition:p1];
    [sprite runAction:seq];
    
    //general config -- handles position tinting, size etc
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



-(void) moveAwaySurface
{
    //move the mountain
    CCMoveTo *mvMountain=[CCMoveTo actionWithDuration:1.5f position:ccp(lx+(cx*0.25f), 0.83f*cy)];
    [bgMountain1 runAction:mvMountain];
    
    //move the hills
    [hill1 runAction:[CCMoveTo actionWithDuration:1.5f position:hill1Pos2]];
    [hill2 runAction:[CCMoveTo actionWithDuration:1.5f position:hill2Pos2]];
    
}

-(void)moveAwayUpperLedges
{
    CCMoveTo *mvLeft=[CCMoveTo actionWithDuration:2.5f position:ccp(-400, bgLeftUpperLedge.position.y )];
    [bgLeftUpperLedge runAction:mvLeft];
    
    //small move for lower ledges
    CCMoveTo *mvLeftLower=[CCMoveTo actionWithDuration:3.0f position:ccp(-100, bgLeftLowerLedge.position.y )];
    CCEaseIn *ei1=[CCEaseIn actionWithAction:mvLeftLower rate:0.5f];
    [bgLeftLowerLedge runAction:ei1];
    
    CCMoveTo *mvRight=[CCMoveTo actionWithDuration:3.0f position:ccp(lx+100, bgRightLowerLedge.position.y )];
    CCEaseIn *ei2=[CCEaseIn actionWithAction:mvRight rate:0.5f];
    [bgRightLowerLedge runAction:ei2];
}

-(void)moveAwayLowerLedges
{
    CCMoveTo *mvLeft=[CCMoveTo actionWithDuration:2.5f position:ccp(-400, bgLeftLowerLedge.position.y )];
    [bgLeftLowerLedge runAction:mvLeft];
    
    CCMoveTo *mvRight=[CCMoveTo actionWithDuration:2.5f position:ccp(lx+400, bgRightLowerLedge.position.y )];
    [bgRightLowerLedge runAction:mvRight];
}

-(void)moveInLedges
{
    CCMoveTo *mvLeft=[CCMoveTo actionWithDuration:1.5f position:ccp(0, bgLeftUpperLedge.position.y )];
    [bgLeftUpperLedge runAction:mvLeft];
    
    //small move for lower ledges
    CCMoveTo *mvLeftLower=[CCMoveTo actionWithDuration:1.5f position:ccp(0, bgLeftLowerLedge.position.y )];
    [bgLeftLowerLedge runAction:mvLeftLower];
    
    CCMoveTo *mvRight=[CCMoveTo actionWithDuration:1.5f position:ccp(lx, bgRightLowerLedge.position.y )];
    [bgRightLowerLedge runAction:mvRight];
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

-(void) moveToTool1: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 0.85f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveAwaySurface];
    
    [self moveInLedges];
    
    camPos=1;
    
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/integrated/Beach Ambience.aac") loop:YES];
}

-(void) moveToTool2: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 2.25f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveAwaySurface];
    
    [self moveAwayUpperLedges];
    
    camPos=2;

    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/integrated/Ambience deep with music theme.aac") loop:YES];
}

-(void) moveToTool3: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 4.0f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];

    [self moveAwaySurface];
    
    [self moveAwayUpperLedges];
    [self moveAwayLowerLedges];
    
    camPos=3;
    
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/integrated/Ambience deep no music theme.aac") loop:YES];
}

-(void) moveToTool0: (ccTime) delta
{
    CCMoveTo *mv=[CCMoveTo actionWithDuration:1.5f position:ccp(0, 0.15f*ly)];
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:mv rate:2.0f];
    [backgroundLayer runAction:ease];
    
    [self moveToSurface];
    
    [self moveInLedges];
    
    camPos=0;
}

@end
