//
//  BMount.m
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BMount.h"
#import "global.h"

@implementation BMount

-(BMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BMount*)[super initWithGameObject:aGameObject withData:data];
       
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        //set the mount for the GO
        DWGameObject *go=[payload objectForKey:MOUNTED_OBJECT];
        [[gameObject store] setObject:go forKey:MOUNTED_OBJECT];
    }
    
    if(messageType==kDWunsetMountedObject)
    {
        [[gameObject store] removeObjectForKey:MOUNTED_OBJECT];
    }
}

@end
