//
//  ZubiIntro.h
//  belugapad
//
//  Created by Gareth Jenkins on 17/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class Daemon;

@interface ZubiIntro : CCLayer
{
    float cx, cy, lx, ly;
    CGPoint winL;
    
    Daemon *daemon;
    
    int slideIndex;
    float slideTime;
    
    CCSprite *slideImage;
    
    CCLayer *bkgLayer;
    CCLayer *zubiLayer;
    
    BOOL waitForTap;
    BOOL enableZubiTaps;
    BOOL hasTapped;
    CGPoint lastTouch;
}

-(void) showSlide;
+(CCScene *)scene;

@end
