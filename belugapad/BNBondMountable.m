//
//  BMountable.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondMountable.h"
#import "global.h"
#import "DWNBondRowGameObject.h"
#import "DWNBondObjectGameObject.h"

@implementation BNBondMountable

-(BNBondMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNBondMountable*)[super initWithGameObject:aGameObject withData:data];
    
    pogo=(DWNBondObjectGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWdismantle)
    {
        DWGameObject *m=[[gameObject store] objectForKey:MOUNT];
        if(m)
        {
            [m handleMessage:kDWunsetMountedObject];
        }
        [[gameObject store] removeObjectForKey:MOUNT];
    }
    
    if(messageType==kDWsetMount)
    {
        DWNBondRowGameObject *prgo=[payload objectForKey:MOUNT];
        
        //if we had a mount previously, tell that mount to unmount me
        if(pogo.Mount)
        {
            [pogo.Mount handleMessage:kDWunsetMountedObject];
        }
        
        //set new mount
        pogo.Mount=prgo;
        
        float myHeldValue=0.0f;
        for(int i=0;i<prgo.MountedObjects.count;i++)
        {
            DWNBondObjectGameObject *mo = [prgo.MountedObjects objectAtIndex:i];
            myHeldValue=myHeldValue+mo.Length;
        }
        
        pogo.MovePosition=ccp(prgo.Position.x+(50*myHeldValue), prgo.Position.y);
        pogo.Position=prgo.Position;
        
        //message myself to move
        [pogo handleMessage:kDWmoveSpriteToPosition];
        
        // and set a new mounted object
        NSDictionary *pl=[NSDictionary dictionaryWithObject:pogo forKey:MOUNTED_OBJECT];
        [prgo handleMessage:kDWsetMountedObject andPayload:pl withLogLevel:-1];   
        
    }
    
    if(messageType==kDWunsetMount)
    {
        if(pogo.Mount)
        {
            NSDictionary *pl=[NSDictionary dictionaryWithObject:pogo forKey:MOUNTED_OBJECT];
            [pogo.Mount handleMessage:kDWunsetMountedObject andPayload:pl withLogLevel:-1];
        }
    }
    
    if(messageType==kDWmoveSpriteToHome)
    {
        if(pogo.Mount)
        {
            NSDictionary *pl=[NSDictionary dictionaryWithObject:pogo forKey:MOUNTED_OBJECT];
            [pogo.Mount handleMessage:kDWunsetMountedObject andPayload:pl withLogLevel:-1];
            [pogo.Mount handleMessage:kDWresetPositionEval];
        }
        
        pogo.Mount=nil;
    }
}

@end
