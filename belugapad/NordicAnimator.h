//
//  NordicAnimator.h
//  belugapad
//
//  Created by Gareth Jenkins on 25/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@interface NordicAnimator : NSObject
{
    float cy, cx, lx, ly;
    
    CCLayer *backgroundLayer;
    
    CCLayer *baseLayer;
    CCSprite *baseSprite[4];
    
    CCLayerColor *baseColor;
    CCLayerColor *baseSky;
    
    CCSprite *subLinesSprite;
    
    CCLayer *creatureLayer;
    
    CCLayer *waterLayer;
    CCSprite *waterSprite[4];
    
    CCSprite *skySprite1;
    CCSprite *hill1;
    CCSprite *hill2;
        
    
    CCSprite *bgWater1;
    CCSprite *bgSun1;
    
    CCSprite *bgMountain1;
    
    CCSprite *bgLeftUpperLedge;
    CCSprite *bgLeftLowerLedge;
    CCSprite *bgRightLowerLedge;
    
    float timeToNextCreature;
    
    CCSpriteBatchNode *sunfishBatch;
    CCSpriteBatchNode *anglerBatch;
    CCSpriteBatchNode *jellyfishBatch;
    CCSpriteBatchNode *schoolBatch;
    CCSpriteBatchNode *eelBatch;
    CCSpriteBatchNode *blowfishBatch;
    
    int camPos;
}

-(void) animateBackgroundIn;
-(void) moveToTool0: (ccTime) delta;
-(void) moveToTool1: (ccTime) delta;
-(void) moveToTool2: (ccTime) delta;
-(void) moveToTool3: (ccTime) delta;
-(void)setBackground:(CCLayer *)bkg withCx:(float)cxin withCy:(float)cyin;

-(void) doUpdate:(ccTime) delta;

@end
