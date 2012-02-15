//
//  Daemon.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Daemon.h"
#import "BLMath.h"
#import "TouchXML.h"

const float kBaseMaxForce=1500.0f;

const float kBaseMaxSpeed=200.0f;

const float kFollowMaxSpeed=900.0f;

const float kChaseMaxSpeed=2500.0f;
const float kChaseMaxForce=2500.0f;

const float kBaseMass=5.0f;

const float kBaseSlowingDistance=50.0f;
const float kBaseEffectiveRadius=15.0f;

const float kMinLengthThreshold=1.0f;
const float kMinLenthAnimThreshold=20.0f;

//const float kBreatheSimMax=500.0f;
//const float kBreatheSimScalarDown=20.0f;
const float kBreatheSimMax=500.0f;
const float kBreatheSimScalarDown=2.0f;

//const float kBaseMaxForce=500.0f;
//
//const float kBaseMaxSpeed=150.0f;
//const float kFollowMaxSpeed=600.0f;
//
//const float kChaseMaxSpeed=2000.0f;
//const float kChaseMaxForce=2000.0f;
//
////const float kBaseMass=15.0f;
//const float kBaseMass=5.0f;
//
//const float kBaseSlowingDistance=50.0f;
//const float kBaseEffectiveRadius=15.0f;
//
//const float kMinLengthThreshold=1.0f;
//
////const float kBreatheSimMax=500.0f;
////const float kBreatheSimScalarDown=20.0f;
//const float kBreatheSimMax=50.0f;
//const float kBreatheSimScalarDown=20.0f;



const CGPoint kDefaultStart={-25, 25};

const float standbyExpiry=7.0f;

@implementation Daemon

-(id)initWithLayer:(CCLayer*)theHostLayer andRestingPostion:(CGPoint)theRestingPos andLy:(float)hostLy
{
    hostLayer=theHostLayer;
    ly=hostLy;

    [self resetToRestAtPoint:theRestingPos];
    
    maxForce=kBaseMaxForce;
    maxSpeed=kBaseMaxSpeed;
    mass=kBaseMass;
    slowingDist=kBaseSlowingDistance;
    effectiveRadius=kBaseEffectiveRadius;
    velocity=CGPointMake(0, 0);

    primaryParticle=[CCParticleSystemQuad particleWithFile:@"bm5.plist"];
    
    [primaryParticle setScale:0.5f];
    
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

-(void)playAnimation:(NSString *)theAnimKey
{
    animKey=theAnimKey;
    animPaths=[self getAnimationPathsFor:animKey];
    isAnimating=YES;
    animationIndex=0;
    animBaseTarget=[primaryParticle position];
    
    //currently there is only one head, set target to point 0 on that path
    target=[BLMath AddVector:animBaseTarget toVector:[[[animPaths objectAtIndex:0] objectAtIndex:0] CGPointValue]];
    
    DLog(@"daemon is animating %@", animKey);
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
        if(animationsEnabled)
        {
            //test animation call
            [self playAnimation:@"action"];
        }
        
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

-(void)enableAnimations
{
    animationsEnabled=YES;
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
    
    float useMaxForce=maxForce;
    float useMaxSpeed=maxSpeed;
    
    if(isAnimating)
    {
        useMaxForce*=5;
        useMaxSpeed*=5;
    }
    
    CGPoint pos=[primaryParticle position];
    
    //get the vector between pos and target and normalize
    CGPoint dv=[BLMath NormalizeVector:[BLMath SubtractVector:pos from:target]];
    
    //length of vector is currently max speed -- could be based on current speed?
    dv=[BLMath MultiplyVector:dv byScalar:useMaxSpeed];
    
    float lv=[BLMath LengthOfVector:[BLMath SubtractVector:pos from:target]];
    
    if(isAnimating)
    {
        if(lv<kMinLenthAnimThreshold)
        {
            dv=CGPointMake(0, 0);
            cancelVelocity=YES;
            
            //increment animation index and point
            animationIndex++;
            if(animationIndex>=[[animPaths objectAtIndex:0] count])
            {
                //animation is over
                isAnimating=NO;
            }
            else
            {
                //get next animation point
                target=[BLMath AddVector:animBaseTarget toVector:[[[animPaths objectAtIndex:0] objectAtIndex:animationIndex] CGPointValue]];
            }
        }        
    }
    else
    {
        //do normal seek / arrive throttling
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
    }
    
    //steering is difference between current vector velocity and desired velocity
    CGPoint steering=[BLMath SubtractVector:velocity from:dv];
    
    //unless we're to cancel it
    if(cancelVelocity)steering=dv;
    
    return steering;    
}

-(CGPoint)getNewPositionWithDesiredSteer:(CGPoint)desiredSteer andDelta:(ccTime)delta
{
    float useMaxForce=maxForce;
    float useMaxSpeed=maxSpeed;
    
    if(isAnimating)
    {
        useMaxForce*=10;
        useMaxSpeed*=10;
    }
    
    //todo: what affect of using primary pos of pquad over hosting all pquad (if more than one used) on this pos
    CGPoint pos=[primaryParticle position];
    
    //bail if desired steer is zero
    if(desiredSteer.x==0 && desiredSteer.y==0) return pos;
    
    CGPoint steerForce=[BLMath TruncateVector:desiredSteer toMaxLength:useMaxForce];
    CGPoint acc=[BLMath DivideVector:steerForce byScalar:mass];
    
    //track velocity to automate external animation -- or other actions reliant on future position
    velocity=[BLMath TruncateVector:[BLMath AddVector:velocity toVector:acc] toMaxLength:useMaxSpeed];
    
    //don't add velocity directly -- add this time step's velocity
    CGPoint tsVel=[BLMath MultiplyVector:velocity byScalar:delta];
    
    pos=[BLMath AddVector:pos toVector:tsVel];
    return pos;
}

-(NSMutableArray*)getAnimationPathsFor:(NSString *)theAnimKey
{
    //todo: consider caching this
    
    //load animation data
	NSString *XMLPath=[[[NSBundle mainBundle] resourcePath] 
					   stringByAppendingPathComponent:[NSString stringWithFormat:@"daemon-%@.svg", theAnimKey]];
	
	//use that file to populate an NSData object
	NSData *XMLData=[NSData dataWithContentsOfFile:XMLPath];
	
	//get TouchXML doc
	CXMLDocument *doc=
    [[CXMLDocument alloc] initWithData:XMLData options:0 error:nil];
    
    
	//setup a namespace mapping for the svg namespace
	NSDictionary *nsMappings=[NSDictionary 
							  dictionaryWithObject:@"http://www.w3.org/2000/svg" 
							  forKey:@"svg"];
	
    
    NSMutableArray *retPaths=[[NSMutableArray alloc] init];
    [retPaths addObject:[self getAnimationPath:0 onSVG:doc withMappings:nsMappings]];
    [retPaths addObject:[self getAnimationPath:1 onSVG:doc withMappings:nsMappings]];
    [retPaths addObject:[self getAnimationPath:2 onSVG:doc withMappings:nsMappings]];
     
    return retPaths;

}

-(NSMutableArray*)getAnimationPath:(int)pathIndex onSVG:(CXMLDocument *)doc withMappings:(NSDictionary *)nsMappings
{
    //get an array of colcircles
	NSArray *pathPoints=NULL;
    pathPoints=[doc nodesForXPath:[NSString stringWithFormat:@"//svg:g[@id='path%d']/svg:circle", pathIndex] 
                namespaceMappings:nsMappings 
                            error:nil];
    
    NSMutableArray *returnPoints=[[NSMutableArray alloc] init];
    
    for (CXMLElement *ele in pathPoints) {
        NSString *spx=[[ele attributeForName:@"cx"] stringValue];
        NSString *spy=[[ele attributeForName:@"cy"] stringValue];
        
        //all animations plotted on an inverted-y, 500x500 space -- bring relative to a 250,250 centre point
        //todo: consider scaling here (instead of at daemon's pquad level?)
        float px=[spx floatValue]-250;
        float py=(500-[spy floatValue])-250;
        
        [returnPoints addObject:[NSValue valueWithCGPoint:CGPointMake(px, py)]];
    }
    
    return returnPoints;
}


@end



