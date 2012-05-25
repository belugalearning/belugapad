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
    
    CCSprite *bgBase1;
    CCSprite *bgWater1;
    CCSprite *bgSun1;
    
    CCSprite *bgMountain1;
}

-(void) animateBackgroundIn;
-(void) moveToTool1: (ccTime) delta;
-(void) moveToTool2: (ccTime) delta;
-(void) moveToTool3: (ccTime) delta;
-(void)setBackground:(CCLayer *)bkg withCx:(float)cxin withCy:(float)cyin;

@end
