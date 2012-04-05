//
//  BMountable.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPartitionMountable.h"
#import "global.h"
#import "DWPartitionRowGameObject.h"
#import "DWPartitionObjectGameObject.h"

@implementation BPartitionMountable

-(BPartitionMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPartitionMountable*)[super initWithGameObject:aGameObject withData:data];
    
    pogo=(DWPartitionObjectGameObject*)gameObject;
    
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
        DWPartitionRowGameObject *prgo=[payload objectForKey:MOUNT];
        
        //if we had a mount previously, tell that mount to unmount me
        if(pogo.Mount)
        {
            [pogo.Mount handleMessage:kDWunsetMountedObject];
        }
        
        //set new mount
        pogo.Mount=prgo;
        
        pogo.MovePosition=prgo.Position;
        pogo.Position=prgo.Position;
        
        //message myself to move
        [pogo handleMessage:kDWmoveSpriteToPosition];
        
    }
    
    if(messageType==kDWunsetMount)
    {
        [[gameObject store] removeObjectForKey:MOUNT];
    }
    
    if(messageType==kDWmoveSpriteToHome)
    {
        if(pogo.Mount)
        {
            [pogo.Mount handleMessage:kDWunsetMountedObject];
        }
        
        pogo.Mount=nil;
    }
}

@end
