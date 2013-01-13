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
    CCSprite *returnToMap;
    CCSprite *replayNode;
    UsersService *usersService;
    
    float timeSinceFired;
    float timeSinceStar1;
    float timeSinceStar2;
    float timeSinceStar3;
    
    BOOL fireStar1;
    BOOL countStar2;
    BOOL countStar3;
    BOOL shownStar3;
    
    int stars;
    
    CCSprite *s1;
    CCSprite *s2;
    CCSprite *s3;
}

+(CCScene *)scene;



@end
