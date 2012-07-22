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
    CCParticleSystemQuad *secondParticle;
    CCParticleSystemQuad *thirdParticle;
    
    CCLayer *hostLayer;

    DaemonMode mode;
    CGPoint restingPos;
    CGPoint target;
    CGPoint animBaseTarget;

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

    BOOL animationsEnabled;
    
    NSString *animKey;
    NSArray *animPaths;
    BOOL isAnimating;
    int animationIndex;
    
    float baseEmitterRate;
    float baseLife;
    
    float baseStartSize;
    
    NSMutableArray *shardsActive;
    NSMutableArray *shardsExpiring;
    float expireShardsCooldown;
    int retainedXP;
    
    BOOL hidden;
    
    SEL shardCollectCallback;
    NSObject *shardCollectCaller;
}

-(id)initWithLayer:(CCLayer*)theHostLayer andRestingPostion:(CGPoint)theRestingPos andLy:(float)hostLy;
-(void)setColor:(ccColor4F)aColor;

-(void)doUpdate:(ccTime)delta;
-(void)setRestingPoint:(CGPoint)newRestingPoint;
-(void)resetToRestAtPoint:(CGPoint)newRestingPoint;
-(void)setMode:(DaemonMode)newMode;
-(void)setTarget:(CGPoint)theTarget;
-(void)followObject:(CCNode *)objTarget;

-(void)updateBreatheVars:(ccTime)delta;

-(CGPoint)getSteeringVelocity;
-(CGPoint)getSeekArriveSV;
-(CGPoint)getNewPositionWithDesiredSteer:(CGPoint)desiredSteer andDelta:(ccTime)delta;

-(void)enableAnimations;
-(NSMutableArray*)getAnimationPathsFor:(NSString *)animKey;
-(NSMutableArray*)getAnimationPath:(int)pathIndex onSVG:(CXMLDocument *)doc withMappings:(NSDictionary *)nsMappings;

-(void)animationOver;

-(void)createXPshards:(int)numShards fromLocation:(CGPoint)baseLocation;
-(void)createXPshards:(int)numShards fromLocation:(CGPoint)baseLocation withCallback:(SEL)callback fromCaller:(NSObject*)caller;
-(void)dumpXP;
-(void)tickManageShards:(ccTime)delta;

-(void)hideZubi;
-(void)showZubi;

-(CGPoint)currentPosition;

@end
