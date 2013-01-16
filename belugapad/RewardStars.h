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
    
    float scoreAchieved;
    float scoreCounter;
    float scoreIncrementer;
    
    BOOL fireStar1;
    BOOL countStar2;
    BOOL countStar3;
    BOOL shownStar3;
    BOOL stopScore;
    
    BOOL returningToMap;
    
    BOOL timeParticle1;
    BOOL timeParticle2;
    BOOL timeParticle3;
    
    int stars;
    
    CCSprite *s1;
    CCSprite *s2;
    CCSprite *s3;
    
    CCLabelTTF *scoreLabel;
}

+(CCScene *)scene;



@end
