//
//  BFloatRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondStoreRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWNBondStoreGameObject.h"

@implementation BNBondStoreRender

-(BNBondStoreRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNBondStoreRender*)[super initWithGameObject:aGameObject withData:data];
    pogo = (DWNBondStoreGameObject*)gameObject;
    
    //init pos x & y in case they're not set elsewhere
    
    
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    amPickedUp=NO;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(!mySprite) 
        {
            [self setSprite];
            [self setSpritePos:NO];            
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
    
    if(messageType==kDWupdateSprite)
    {

        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(!mySprite) { 
            [self setSprite];
        }

        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
        
    if(messageType==kDWpickedUp)
    {
        amPickedUp=YES;
    }
    
    if(messageType==kDWputdown)
    {
        amPickedUp=NO;
    }
    
    if(messageType==kDWresetToMountPosition)
    {
        [self resetSpriteToMount];
    }
    if(messageType==kDWdismantle)
    {
        CCSprite *s=[[gameObject store] objectForKey:MY_SPRITE];
        [[s parent] removeChild:s cleanup:YES];
    }
}



-(void)setSprite
{
    
    for(int i=0;i<pogo.Length;i++) {
        NSString *spriteFileName=@"/images/partition/store.png";
        //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

        
        CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
        [mySprite setPosition:ccp(pogo.Position.x+(i*50), pogo.Position.y)];
        
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [mySprite setTag:2];
            [mySprite setOpacity:0];
        }

        [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:2];
        
        //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
        [[gameObject store] setObject:mySprite forKey:MY_SPRITE];
    }
}

-(void)setSpritePos:(BOOL) withAnimation
{

    if(pogo.Position.x || pogo.Position.y)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        

        
          if(withAnimation == YES)
        {
            CGPoint newPos = ccp(pogo.Position.x, pogo.Position.y);

            CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:newPos];
            [mySprite runAction:anim];
        }
        else
        {
            [mySprite setPosition:pogo.Position];
        }
    }
}

-(void)resetSpriteToMount
{
    DWGameObject *mount = [[gameObject store] objectForKey:MOUNT];
    float x = [[[mount store] objectForKey:POS_X] floatValue];
    float y = [[[mount store] objectForKey:POS_Y] floatValue];
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:x] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:y] forKey:POS_Y];
    
    CCSprite *curSprite = [[gameObject store] objectForKey:MY_SPRITE];
    
    [curSprite runAction:[CCMoveTo actionWithDuration:kTimeObjectSnapBack position:ccp(x, y)]];
    
}

-(void) dealloc
{
    [super dealloc];
}

@end
