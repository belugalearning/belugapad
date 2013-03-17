//
//  LRAnimator.m
//  belugapad
//
//  Created by Gareth Jenkins on 19/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LRAnimator.h"
#import "AppDelegate.h"
#import "global.h"

@implementation LRAnimator

-(void)setBackground:(CCLayer *)bkg withCx:(float)cxin withCy:(float)cyin
{
    backgroundLayer=bkg;
    
    cx=cxin;
    cy=cyin;
    lx=2.0f*cx;
    ly=2.0f*cy;
    
//    CCLayerGradient *gbkg=[CCLayerGradient layerWithColor:ccc4(181, 45, 153, 255) fadingTo:ccc4(156, 15, 153, 255)];
//    [backgroundLayer addChild:gbkg];
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    
    int appType=[ac returnAppType];
    
    CCSprite *b=nil;
    
    if(appType==0)
        [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/background.png")];
    else if(appType==0)
        [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/sand_background.png")];
    
    [b setPosition:ccp(cx, cy)];
    [backgroundLayer addChild:b];
}

-(void)animateBackgroundIn
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)moveToTool0:(ccTime)delta
{
    
}

-(void)moveToTool1:(ccTime)delta
{
    
}

-(void)moveToTool2:(ccTime)delta
{
    
}

-(void)moveToTool3:(ccTime)delta
{
    
}

@end
