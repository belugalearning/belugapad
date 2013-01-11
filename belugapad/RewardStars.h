//
//  RewardStars.h
//  belugapad
//
//  Created by Dave Amphlett on 11/01/2013.
//
//

#import "cocos2d.h"
#import "AppDelegate.h"

@interface RewardStars : CCLayer
{
    float lx, ly, cx, cy;
    CCLayer *starLayer;
}

+(CCScene *)scene;



@end
