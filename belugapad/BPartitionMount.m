//
//  BMount.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPartitionMount.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "PlaceValue.h"

@implementation BPartitionMount

-(BPartitionMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPartitionMount*)[super initWithGameObject:aGameObject withData:data];
    
    NSMutableArray *mo=[[NSMutableArray alloc] init];
    GOS_SET(mo, MOUNTED_OBJECTS);
    [mo release];
    
    return self;
}
-(void)doUpdate:(ccTime)delta
{
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        DWGameObject *addO=[payload objectForKey:MOUNTED_OBJECT];
        [[gameObject store] setObject:addO forKey:MOUNTED_OBJECT];
        

    }
    
    if(messageType==kDWunsetMountedObject)
    {
        [[gameObject store] removeObjectForKey:MOUNTED_OBJECT];
    }

}

@end
