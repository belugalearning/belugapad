//
//  BFloatRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BFloatRender.h"
#import "global.h"

@implementation BFloatRender

-(BFloatRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BFloatRender*)[super initWithGameObject:aGameObject withData:data];
    
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
        //[self setSprite];
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(mySprite==nil) [self setSprite];
        [self setSpritePos:payload];
        
        //set phys position
        float x=[[payload objectForKey:POS_X]floatValue];
        float y=[[payload objectForKey:POS_Y]floatValue];
        
        if(physBody)
        {
            physBody->p=ccp(x, y);
        }
    }
    
    if(messageType==kDWupdatePosFromPhys)
    {
        if(amPickedUp==NO)
        {
            if(mySprite==nil) [self setSprite];
            [self setSpritePos:payload];            
        }
    }
    
    if(messageType==kDWsetPhysBody)
    {
        physBody=[[payload objectForKey:PHYS_BODY] pointerValue];
    }
    
    if(messageType==kDWpickedUp)
    {
        amPickedUp=YES;
    }
    
    if(messageType==kDWputdown)
    {
        amPickedUp=NO;
    }
}

-(void)setPhysPos
{
    
}

-(void)setSprite
{
    mySprite=[CCSprite spriteWithFile:@"obj-float-object1x1.png"];
        
    [[gameWorld GameScene] addChild:mySprite z:0];
    
}

-(void)setSpritePos:(NSDictionary *)position
{
    if(position != nil)
    {
        float x=[[position objectForKey:POS_X] floatValue];
        float y=[[position objectForKey:POS_Y] floatValue];
        
        if ([position objectForKey:ROT]) {
            float r=[[position objectForKey:ROT]floatValue];
            [mySprite setRotation:r];
        }
        
        //also set posx/y on store
        GOS_SET([NSNumber numberWithFloat:x], POS_X);
        GOS_SET([NSNumber numberWithFloat:y], POS_Y);
        
        //set sprite position
        [mySprite setPosition:ccp(x, y)];
    }
}

-(void) dealloc
{
    [mySprite release];
    [super dealloc];
}

@end
