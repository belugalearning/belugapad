//
//  BMountable.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueMountable.h"
#import "global.h"

@implementation BPlaceValueMountable

-(BPlaceValueMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueMountable*)[super initWithGameObject:aGameObject withData:data];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMount)
    {
            //set the old mount
            DWGameObject *oldMount=[[gameObject store] objectForKey:MOUNT];
            [oldMount handleMessage:kDWunsetMountedObject];
            
            //set the new mount for the GO
            DWGameObject *newMount=[payload objectForKey:MOUNT];
            [[gameObject store] setObject:newMount forKey:MOUNT];
            
            //tell the mount that i'm there
            NSMutableDictionary *pl=[[[NSMutableDictionary alloc] init] autorelease];
            [pl setObject:gameObject forKey:MOUNTED_OBJECT];
            [newMount handleMessage:kDWsetMountedObject andPayload:pl withLogLevel:0];
            
            NSMutableDictionary *pl2 = [[[NSMutableDictionary alloc] init] autorelease];
            [pl2 setObject:[[newMount store] objectForKey:POS_X] forKey:POS_X];
            [pl2 setObject:[[newMount store] objectForKey:POS_Y] forKey:POS_Y];
            
            if([payload objectForKey:ANIMATE_ME])
            {
                [pl2 setObject:ANIMATE_ME forKey:ANIMATE_ME];
            }
            
        
            //update the sprite
            //[gameObject handleMessage:kDWupdateSprite andPayload:[newMount store] withLogLevel:0];
            [gameObject handleMessage:kDWupdateSprite andPayload:pl2 withLogLevel:0];
        
        
    }
    
    if(messageType==kDWdismantle)
    {
        DWGameObject *m=[[gameObject store] objectForKey:MOUNT];
        if(m)
        {
            [m handleMessage:kDWunsetMountedObject];
        }
        [[gameObject store] removeObjectForKey:MOUNT];
    }
}

@end
