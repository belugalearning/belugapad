//
//  BObjectRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BObjectRender.h"
#import "global.h"

@implementation BObjectRender

-(BObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];

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
    }
    
}

-(void)setSprite
{
    mySprite=[CCSprite spriteWithFile:@"obj-blockholder-object1x1.png"];
    
//    float x=[[[gameObject store] objectForKey:POS_X] floatValue];
//    float y=[GOS_GET(POS_Y) floatValue];
    
//    [mySprite setPosition:ccp(x, y)];
    
    [[gameWorld GameScene] addChild:mySprite z:1];
    
}

-(void)setSpritePos:(NSDictionary *)position
{
    //attempt to get mounting GO
    DWGameObject *go=[[gameObject store] objectForKey:MOUNT];
    
    if(position != nil)
    {
        float x=[[position objectForKey:POS_X] floatValue];
        float y=[[position objectForKey:POS_Y] floatValue];
        
        //set sprite position
        [mySprite setPosition:ccp(x, y)];
    }
    else if(go != nil)
    {
        float x=[[[go store] objectForKey:POS_X] floatValue];
        float y=[[[go store] objectForKey:POS_Y] floatValue];   
        
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
