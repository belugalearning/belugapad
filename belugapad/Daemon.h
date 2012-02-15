//
//  Daemon.h
//  belugapad
//
//  Created by Gareth Jenkins on 30/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@class CXMLDocument;

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
    
    float ly;
    
    CGPoint velocity;
    CCNode *followObject;
    
    float standbyTime;
    float incrBreathe;
}

-(id)initWithLayer:(CCLayer*)theHostLayer andRestingPostion:(CGPoint)theRestingPos andLy:(float)hostLy;

-(void)doUpdate:(ccTime)delta;
-(void)resetToRestAtPoint:(CGPoint)newRestingPoint;
-(void)setMode:(DaemonMode)newMode;
-(void)setTarget:(CGPoint)theTarget;
-(void)followObject:(CCNode *)objTarget;

-(void)updateBreatheVars:(ccTime)delta;

-(CGPoint)getSteeringVelocity;
-(CGPoint)getSeekArriveSV;
-(CGPoint)getNewPositionWithDesiredSteer:(CGPoint)desiredSteer andDelta:(ccTime)delta;

-(NSMutableArray*)getAnimationPathsFor:(NSString *)animKey;
-(NSMutableArray*)getAnimationPath:(int)pathIndex onSVG:(CXMLDocument *)doc withMappings:(NSDictionary *)nsMappings;

@end
