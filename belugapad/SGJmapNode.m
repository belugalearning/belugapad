//
//  SGJmapNodeGO.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapNode.h"
#import "SGJmapNodeRender.h"

@implementation SGJmapNode

@synthesize NodeRenderComponent;

//Transform protocol properties
@synthesize Position, RenderBatch;

-(SGJmapNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.NodeRenderComponent=[[SGJmapNodeRender alloc] initWithGameObject:self];
        
        self.RenderBatch=aRenderBatch;
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
