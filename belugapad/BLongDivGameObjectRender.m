//
//  BLongDivGameObject.m
//  belugapad
//
//  Created by David Amphlett on 28/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "DWLongDivGameObject.h"
#import "BLongDivGameObjectRender.h"

@implementation BLongDivGameObjectRender
-(BLongDivGameObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BLongDivGameObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    
    obj=(DWLongDivGameObject*)gameObject;
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];

    return self;
}
-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!obj.mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!obj.mySprite) { 
            [self setSprite];
        }
        
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
    }
    if(messageType==kDWdismantle)
    {
        [[obj.mySprite parent] removeChild:obj.mySprite cleanup:YES];
    }
    
    if(messageType==kDWswitchSelection)
    {
        //[self switchSelection];
    }
}

-(void)setSprite
{
    
}
-(void)switchSelection
{
    
}
@end
