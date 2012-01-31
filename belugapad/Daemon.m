//
//  Daemon.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Daemon.h"
#import "BLMath.h"

const float kBaseMaxForce=500.0f;

const float kBaseMaxSpeed=150.0f;
const float kFollowMaxSpeed=600.0f;

const float kChaseMaxSpeed=2000.0f;
const float kChaseMaxForce=2000.0f;

const float kBaseMass=15.0f;
const float kBaseSlowingDistance=50.0f;
const float kBaseEffectiveRadius=15.0f;

const float kMinLengthThreshold=1.0f;

const float kBreatheSimMax=500.0f;
const float kBreatheSimScalarDown=20.0f;

const CGPoint kDefaultStart={-25, 25};

const float standbyExpiry=7.0f;

@implementation Daemon

-(id)initWithLayer:(CCLayer*)theHostLayer andRestingPostion:(CGPoint)theRestingPos
{
    hostLayer=theHostLayer;

    [self resetToRestAtPoint:theRestingPos];
    
    maxForce=kBaseMaxForce;
    maxSpeed=kBaseMaxSpeed;
    mass=kBaseMass;
    slowingDist=kBaseSlowingDistance;
    effectiveRadius=kBaseEffectiveRadius;
    velocity=CGPointMake(0, 0);

    primaryParticle=[CCParticleSystemQuad particleWithFile:@"dm3.plist"];
    
    //initial position is defaulted to offscreen;
    [primaryParticle setPosition:kDefaultStart];
    
    [hostLayer addChild:primaryParticle];

    
    return self;
}

-(void)setTarget:(CGPoint)theTarget
{
    target=theTarget;
    standbyTime=0.0f;
}

-(void)followObject:(CCNode *)objTarget
{
    mode=kDaemonModeChasing;
    followObject=objTarget;
    
    maxSpeed=kChaseMaxSpeed;
    maxForce=kChaseMaxForce;
}

-(void)setMode:(DaemonMode)newMode
{
    //reset to base
    mode=newMode;
    followObject=nil;
    maxForce=kBaseMaxForce;
    maxSpeed=kBaseMaxSpeed;
    
    //reset expiry -- something happened
    standbyTime=0.0f;

    //mode specific changes
    if(mode==kDaemonModeResting)
    {
        target=restingPos;
    }
    else if(mode==kDaemonModeWaiting)
    {
        target=[primaryParticle position];
    }
    else if(mode==kDaemonModeFollowing)
    {
        maxSpeed=kFollowMaxSpeed;
    }
    else if(mode==kDaemonModeChasing)
    {
        maxSpeed=kChaseMaxSpeed;
        maxForce=kChaseMaxForce;
    }
    
}

-(void)resetToRestAtPoint:(CGPoint)newRestingPoint
{
    restingPos=newRestingPoint;
    mode=kDaemonModeResting;
    target=newRestingPoint;
}

-(void)doUpdate:(ccTime)delta
{
    standbyTime+=delta;
    
    //keep in sync with targetted follow object -- if one present
    if(followObject)
    {
        target=[followObject position];
        standbyTime=0.0f;
    }
    
    CGPoint desiredSteer=[self getSteeringVelocity];
    
    CGPoint pos=[self getNewPositionWithDesiredSteer:desiredSteer andDelta:delta];
    
    //shouldn't ever be a need to move to position -- so long as this is running on tick delta
    [primaryParticle setPosition:pos];
    
    //update breathing ryhthm
    [self updateBreatheVars:delta];
    
    if(standbyTime>standbyExpiry)
    {
        [self setMode:kDaemonModeResting];
    }
}

-(void)updateBreatheVars:(ccTime)delta
{
    incrBreathe++;
    if (incrBreathe>kBreatheSimMax) incrBreathe=0;
    
    float newStartSize=(sin(incrBreathe/kBreatheSimScalarDown)) * kBreatheSimMax;
    [primaryParticle setStartSize:newStartSize];
}

-(CGPoint)getSteeringVelocity
{
    CGPoint seekArriveSV=[self getSeekArriveSV];
    
    //todo: insert weighted behaviour for avoid / other activity based steering

    return seekArriveSV;

}

-(CGPoint)getSeekArriveSV
{
    BOOL cancelVelocity=NO;
    
    CGPoint pos=[primaryParticle position];
    
    //get the vector between pos and target and normalize
    CGPoint dv=[BLMath NormalizeVector:[BLMath SubtractVector:pos from:target]];
    
    //length of vector is currently max speed -- could be based on current speed?
    dv=[BLMath MultiplyVector:dv byScalar:maxSpeed];
    
    float lv=[BLMath LengthOfVector:[BLMath SubtractVector:pos from:target]];
    
    //check if length of that vector < min relevant value, if so stop movement
    if(lv<kMinLengthThreshold)
    {
        dv=CGPointMake(0, 0);
        cancelVelocity=YES;
    }
    //check if length of that vector < slowingDistance, if so ramp it down
    else if(lv<slowingDist)
    {
        //ramp toward zero
        dv=[BLMath MultiplyVector:dv byScalar:(lv / slowingDist)];
    }
    
    //steering is difference between current vector velocity and desired velocity
    CGPoint steering=[BLMath SubtractVector:velocity from:dv];
    
    //unless we're to cancel it
    if(cancelVelocity)steering=dv;
    
    return steering;    
}

-(CGPoint)getNewPositionWithDesiredSteer:(CGPoint)desiredSteer andDelta:(ccTime)delta
{
    //todo: what affect of using primary pos of pquad over hosting all pquad (if more than one used) on this pos
    CGPoint pos=[primaryParticle position];
    
    //bail if desired steer is zero
    if(desiredSteer.x==0 && desiredSteer.y==0) return pos;
    
    CGPoint steerForce=[BLMath TruncateVector:desiredSteer toMaxLength:maxForce];
    CGPoint acc=[BLMath DivideVector:steerForce byScalar:mass];
    
    //track velocity to automate external animation -- or other actions reliant on future position
    velocity=[BLMath TruncateVector:[BLMath AddVector:velocity toVector:acc] toMaxLength:maxSpeed];
    
    //don't add velocity directly -- add this time step's velocity
    CGPoint tsVel=[BLMath MultiplyVector:velocity byScalar:delta];
    
    pos=[BLMath AddVector:pos toVector:tsVel];
    return pos;
}


@end



