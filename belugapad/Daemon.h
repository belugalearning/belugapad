//
//  Daemon.h
//  belugapad
//
//  Created by Gareth Jenkins on 30/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum {
    kDaemonModeResting,
    kDaemonModeFollowing,
    kDaemonModeChasing,
    kDaemonModeWaiting
} DaemonMode;


@interface Daemon : NSObject
{
    CCParticleSystemQuad *primaryParticle;
    CCLayer *hostLayer;
    
    DaemonMode mode;
    CGPoint restingPos;
    CGPoint target;

    float maxForce;
    float maxSpeed;
    float mass;
    float slowingDist;
    float effectiveRadius;
    
    CGPoint velocity;
    CCNode *followObject;
    
    float standbyTime;
    float incrBreathe;
}

-(id)initWithLayer:(CCLayer*)theHostLayer andRestingPostion:(CGPoint)theRestingPos;

-(void)doUpdate:(ccTime)delta;
-(void)resetToRestAtPoint:(CGPoint)newRestingPoint;
-(void)setMode:(DaemonMode)newMode;
-(void)setTarget:(CGPoint)theTarget;
-(void)followObject:(CCNode *)objTarget;

-(void)updateBreatheVars:(ccTime)delta;

-(CGPoint)getSteeringVelocity;
-(CGPoint)getSeekArriveSV;
-(CGPoint)getNewPositionWithDesiredSteer:(CGPoint)desiredSteer andDelta:(ccTime)delta;

@end
