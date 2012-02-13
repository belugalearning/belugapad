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
        //tell my existing mount i'm leaving
        DWGameObject *oldMount=[[gameObject store] objectForKey:MOUNT];
        [oldMount handleMessage:kDWunsetMountedObject];
        
        //set the new mount for the GO
        DWGameObject *newMount=[payload objectForKey:MOUNT];
        [[gameObject store] setObject:newMount forKey:MOUNT];
        
        //tell the mount that i'm there
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:gameObject forKey:MOUNTED_OBJECT];
        [newMount handleMessage:kDWsetMountedObject andPayload:pl withLogLevel:0];
        
        //update the sprite
        [gameObject handleMessage:kDWupdateSprite andPayload:[newMount store] withLogLevel:0];
        
    }
}

@end
