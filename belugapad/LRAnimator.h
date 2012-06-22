//
//  LRAnimator.h
//  belugapad
//
//  Created by Gareth Jenkins on 19/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
@interface LRAnimator : NSObject
{
    float cy, cx, lx, ly;
    
    CCLayer *backgroundLayer;
}

-(void) animateBackgroundIn;
-(void)doUpdate:(ccTime)delta;
-(void) moveToTool0: (ccTime) delta;
-(void) moveToTool1: (ccTime) delta;
-(void) moveToTool2: (ccTime) delta;
-(void) moveToTool3: (ccTime) delta;
-(void)setBackground:(CCLayer *)bkg withCx:(float)cxin withCy:(float)cyin;


@end
