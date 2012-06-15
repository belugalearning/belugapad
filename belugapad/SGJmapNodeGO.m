//
//  SGJmapNodeGO.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapNodeGO.h"
#import "SGJmapNodeRender.h"

@implementation SGJmapNodeGO

@synthesize NodeRenderComponent;

//Transform protocol properties
@synthesize Position;

-(SGJmapNodeGO*) initWithGameWorld:(SGGameWorld*)aGameWorld
{   
    if(self=[super init])
    {
        NodeRenderComponent=[[SGJmapNodeRender alloc] initWithGameObject:self];
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel 
{
    //re-broadcast messages to components
    [self.NodeRenderComponent handleMessage:messageType andPayload:payload];
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    [self.NodeRenderComponent doUpdate:delta];
}

@end
