//
//  JourneyScene.h
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class Daemon;

@interface JourneyScene : CCLayer
{
    float cx, cy, lx, ly;
    
    //Daemon *daemon;
    
    CCLayer *mapLayer;
    CCLayer *foreLayer;
    
    CGPoint lastTouch;
}

+(CCScene *)scene;

-(void)startTransitionToToolHostWithPos:(CGPoint)pos;

@end
