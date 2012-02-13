//
//  BMount.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueMount.h"
#import "global.h"
#import "SimpleAudioEngine.h"

@implementation BPlaceValueMount

-(BPlaceValueMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueMount*)[super initWithGameObject:aGameObject withData:data];
    
    NSMutableArray *mo=[[NSMutableArray alloc] init];
    GOS_SET(mo, MOUNTED_OBJECTS);
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        //set the mount for the GO
        
        DWGameObject *addO=[payload objectForKey:MOUNTED_OBJECT];
        [[gameObject store] setObject:addO forKey:MOUNTED_OBJECT];
        
    }
    
    if(messageType==kDWunsetMountedObject)
    {
        [[gameObject store] removeObjectForKey:MOUNTED_OBJECT];
    }
    
}

@end
