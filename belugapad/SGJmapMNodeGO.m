//
//  SGJmapMNodeGO.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapMNodeGO.h"
#import "SGJmapMNodeRender.h"

@implementation SGJmapMNodeGO

@synthesize MNodeRenderComponent;

//transform protocol properties
@synthesize Position;

-(SGJmapMNodeGO*) initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.MNodeRenderComponent=[[SGJmapMNodeRender alloc] initWithGameObject:self];
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel
{
    //broadcast to components
    [self.MNodeRenderComponent handleMessage:messageType andPayload:payload];
}

-(void)doUpdate:(ccTime)delta
{
    //update components
    [self.MNodeRenderComponent doUpdate:delta];
}

@end
