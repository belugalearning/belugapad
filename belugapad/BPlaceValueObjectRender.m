//
//  BFloatRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BFloatObjectRender.h"
#import "global.h"

@implementation BFloatObjectRender

-(BFloatObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BFloatObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
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
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
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
            CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
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
    
    if(messageType==kDWsetMount)
    {
        //disable phys on this object
        if(physBody)
        {
            //be aware that other activators on the object will revert this
            cpBodySleep(physBody);
        }
    }
    if(messageType==kDWunsetMount)
    {
        if(physBody)
        {
            cpBodyActivate(physBody);
        }
    }
}

-(void)setPhysPos
{
    
}

-(void)setSprite
{
    CCSprite *mySprite=[CCSprite spriteWithFile:@"obj-float-45.png"];
    [[gameWorld GameScene] addChild:mySprite z:0];
    
    //if we're on an object > 1x1, render more sprites as children
    int r=[GOS_GET(OBJ_ROWS) intValue];
    int c=[GOS_GET(OBJ_COLS) intValue];
    
    for(int ri=0;ri<r;ri++)
    {
        for(int ci=0; ci<c;ci++)
        {
            if(ri>0 || ci>0)
            {
                CCSprite *cs=[CCSprite spriteWithFile:@"obj-float-45.png"];
                [cs setPosition:ccp((ci*UNIT_SIZE)+HALF_SIZE, (ri*UNIT_SIZE)+HALF_SIZE)];
                [mySprite addChild:cs];
            }
        }
    }
    
    //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
    [[gameObject store] setObject:mySprite forKey:MY_SPRITE];
}

-(void)setSpritePos:(NSDictionary *)position
{
    if(position != nil)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        
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
    [super dealloc];
}

@end
