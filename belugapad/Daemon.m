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
#import "global.h"
#import "SimpleAudioEngine.h"

const float kBaseMaxForce=6000.0f;
const float kBaseMaxSpeed=800.0f;
const float kBaseMass=5.0f;
const float kBaseEffectiveRadius=15.0f;
const float kBaseSlowingDistance=20.0f;

const float kFollowMaxSpeed=900.0f;

const float kChaseMaxSpeed=1200.0f;
const float kChaseMaxForce=6000.0f;

const float kMinLengthThreshold=1.0f;
const float kMinLenthAnimThreshold=40.0f;


const float kBreatheSimMax=200.0f;
const float kBreatheSimScalarDown=2.0f;


const CGPoint kDefaultStart={-25, 25};

const float standbyExpiry=7.0f;

static float kSubParticleOffset=10.0f;

@implementation Daemon

-(id)initWithLayer:(CCLayer*)theHostLayer andRestingPostion:(CGPoint)theRestingPos andLy:(float)hostLy
{
    self=[super init];
    
    hostLayer=theHostLayer;
    ly=hostLy;

    [self resetToRestAtPoint:theRestingPos];
    
    maxForce=kBaseMaxForce;
    maxSpeed=kBaseMaxSpeed;
    mass=kBaseMass;
    slowingDist=kBaseSlowingDistance;
    effectiveRadius=kBaseEffectiveRadius;
    velocity=CGPointMake(0, 0);

    primaryParticle=[CCParticleSystemQuad particleWithFile:@"bm11.plist"];
    
    //initial position is defaulted to offscreen;
    [primaryParticle setPosition:theRestingPos];
    
    //add secondary particles
    secondParticle=[CCParticleSystemQuad particleWithFile:@"bm11.plist"];
    [secondParticle setPosition:CGPointMake(kSubParticleOffset, kSubParticleOffset)];
    thirdParticle=[CCParticleSystemQuad particleWithFile:@"bm11.plist"];
    [thirdParticle setPosition:CGPointMake(-kSubParticleOffset, kSubParticleOffset)];
    
    [primaryParticle addChild:secondParticle];
    [primaryParticle addChild:thirdParticle];
    
    baseEmitterRate=primaryParticle.emissionRate;
    baseLife=primaryParticle.life;
    baseStartSize=primaryParticle.startSize;
    
    [hostLayer addChild:primaryParticle];

    shardsActive=[[NSMutableArray alloc] init];
    shardsExpiring=[[NSMutableArray alloc] init];
    
    return self;
}

-(void)hideZubi
{
    [primaryParticle setVisible:NO];
    [secondParticle setVisible:NO];
    [thirdParticle setVisible:NO];
    hidden=YES;
}

-(void)showZubi
{
    [primaryParticle setVisible:YES];
    [secondParticle setVisible:YES];
    [thirdParticle setVisible:YES];    
    hidden=NO;
}

-(void)createXPshards:(int)numShards fromLocation:(CGPoint)baseLocation
{
    [self createXPshards:numShards fromLocation:baseLocation withCallback:nil fromCaller:nil];
}

-(void)createXPshards:(int)numShards fromLocation:(CGPoint)baseLocation withCallback:(SEL)callback fromCaller:(NSObject*)caller
{
    if(shardsActive.count>30) return;
    
    if(callback)
    {
        shardCollectCallback=callback;
        shardCollectCaller=caller;
    }
    
    for (int i=0;i<numShards;i++)
    {
        CCSprite *shardSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/shard.png")];
        int o=50+(arc4random()%200);
        [shardSprite setOpacity:o];
        
        float d=arc4random()%200;
        float a=arc4random()%360;
        
        CGPoint destpos=[BLMath ProjectMovementWithX:d andY:d forRotation:a];
        destpos=[BLMath AddVector:destpos toVector:baseLocation];
        
        [shardSprite setPosition:baseLocation];
        [shardSprite setOpacity:0];
        
        CCFadeTo *f=[CCFadeTo actionWithDuration:0.2f opacity:o];
        CCMoveTo *mt=[CCMoveTo actionWithDuration:5.0f position:destpos];
        CCEaseIn *ea=[CCEaseIn actionWithAction:mt rate:0.1f];
        [shardSprite runAction:f];
        [shardSprite runAction:ea];
        
        [shardsActive addObject:shardSprite];
        
        [hostLayer addChild:shardSprite];
        
        retainedXP++;
    }
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_state_shards_dispersed.wav")];
}

-(void)dumpXP
{
    for (int i=0;i<retainedXP;i++)
    {
        CCSprite *shardSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/shard.png")];
        int o=50+(arc4random()%200);
        [shardSprite setOpacity:o];
        
        float d=arc4random()%1000;
        float a=arc4random()%360;
        
        CGPoint destpos=[BLMath ProjectMovementWithX:d andY:d forRotation:a];
        destpos=[BLMath AddVector:destpos toVector:[primaryParticle position]];
        
        [shardSprite setPosition:[primaryParticle position]];
        [shardSprite setOpacity:o];
        
        CCFadeTo *f=[CCFadeTo actionWithDuration:0.2f opacity:0];
        CCMoveTo *mt=[CCMoveTo actionWithDuration:5.0f position:destpos];
        CCEaseIn *ea=[CCEaseIn actionWithAction:mt rate:0.1f];
        [shardSprite runAction:f];
        [shardSprite runAction:ea];
        
        [shardsExpiring addObject:shardSprite];
        expireShardsCooldown=2.0f;
        
        [hostLayer addChild:shardSprite];
        
        retainedXP--;
    }
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_tool_scene_shards_flying_back.wav")];
}

-(void)setColor:(ccColor4F)aColor
{
    [primaryParticle setStartColor:aColor];
    [primaryParticle setEndColor:aColor];
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
    
    [primaryParticle setLife:baseLife*3.5f];
    [primaryParticle setEmissionRate:baseEmitterRate*1.5f];
    
    //currently there is only one head, set target to point 0 on that path
    target=[BLMath AddVector:animBaseTarget toVector:[[[animPaths objectAtIndex:0] objectAtIndex:0] CGPointValue]];
}

-(void)animationOver
{
    [primaryParticle setEmissionRate:baseEmitterRate];
    [primaryParticle setLife:baseLife];
    
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

-(void)setRestingPoint:(CGPoint)newRestingPoint
{
    restingPos=newRestingPoint;
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
    
    
    [self tickManageShards:delta];
    
    //for the moment, completely disable movement if hidden
    if(!hidden)
    {
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
        //disabled during testing peffect perf
        [self updateBreatheVars:delta];
        
        if(standbyTime>standbyExpiry)
        {
            [self setMode:kDaemonModeResting];
        }
    }
    
}

-(CGPoint)currentPosition
{
    return primaryParticle.position;
}

-(void)tickManageShards:(ccTime)delta
{
    //shard accumulation
    for (CCSprite *shard in shardsActive) {
        int diff=(int)[BLMath DistanceBetween:[shard position] and:[primaryParticle position]];
        
        //mod down -- chance of collection
        int chanceDiff=(int)(diff / 10.f);
        
        if(diff<50 || (arc4random()%chanceDiff)==1)
        {
            //collect it
            
            //dispersing shards -- not used
            //CGPoint diffPos=[BLMath SubtractVector:ccp(512, 384) from:shard.position];
            //CGPoint dest=[BLMath MultiplyVector:diffPos byScalar:5.0f];
            //CCMoveTo *mt=[CCMoveTo actionWithDuration:0.25f position:dest];
            
            CCMoveTo *mt=[CCMoveTo actionWithDuration:0.25f position:[primaryParticle position]];
            CCEaseOut *eo=[CCEaseOut actionWithAction:mt rate:0.5f];
            CCFadeOut *fo=[CCFadeOut actionWithDuration:0.3f];
            [shard stopAllActions];
            [shard runAction:eo];
            [shard runAction:fo];
            
            //indicate to any interested caller that we collected this shard
            if(shardCollectCallback)
            {
//                [shardCollectCaller performSelectorOnMainThread:shardCollectCallback withObject:self waitUntilDone:YES];
                
                [shardCollectCaller performSelector:shardCollectCallback withObject:self afterDelay:0.25f];
            }
            
            //dispose of it in the future
            [shardsExpiring addObject:shard];
            
            //reset disposal timer
            //expireShardsCooldown=2.0f;
        }
    }
    
    //remove any disposal shards from the active shards
    [shardsActive removeObjectsInArray:shardsExpiring];
    
    //shard expiry management & layer removal
    if(expireShardsCooldown>0)
    {
        expireShardsCooldown-=delta;
    }
    else
    {
        //expire the shards
        for (CCSprite *s in shardsExpiring) {
            [hostLayer removeChild:s cleanup:YES];
        }

        [shardsExpiring removeAllObjects];
        
        //reset expiry
        expireShardsCooldown=0.2f;
    }
    
}

-(void)updateBreatheVars:(ccTime)delta
{
    incrBreathe++;
    if(incrBreathe>baseStartSize) incrBreathe=0;
    
    [primaryParticle setStartSize:baseStartSize+incrBreathe];
    
//    if (incrBreathe>kBreatheSimMax) incrBreathe=0;
//    
//    float newStartSize=(sin(incrBreathe/kBreatheSimScalarDown)) * kBreatheSimMax;
//    [primaryParticle setStartSize:newStartSize];
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
                [self animationOver];
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

-(NSMutableArray*)getAnimationPathsFor:(NSString *)theAnimKey
{
    //todo: consider caching this
    
    //load animation data
	NSString *XMLPath=BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/zubi/animatons/daemon-%@.svg", theAnimKey]));
	
	//use that file to populate an NSData object
	NSData *XMLData=[NSData dataWithContentsOfFile:XMLPath];
	
	//get TouchXML doc
	CXMLDocument *doc=
    [[[CXMLDocument alloc] initWithData:XMLData options:0 error:nil] autorelease];
    
    
	//setup a namespace mapping for the svg namespace
	NSDictionary *nsMappings=[NSDictionary 
							  dictionaryWithObject:@"http://www.w3.org/2000/svg" 
							  forKey:@"svg"];
	
    
    NSMutableArray *retPaths=[[[NSMutableArray alloc] init] autorelease];
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
    
    NSMutableArray *returnPoints=[[[NSMutableArray alloc] init] autorelease];
    
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

-(void)dealloc
{
    [shardsActive release];
    [shardsExpiring release];
    
    
    
    [super dealloc];
}

@end



