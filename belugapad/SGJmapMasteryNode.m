//
//  SGJmapMNodeGO.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapMasteryNode.h"
#import "SGJmapMasteryNodeRender.h"

@implementation SGJmapMasteryNode

@synthesize MNodeRenderComponent;

//transform protocol properties
@synthesize Position, RenderBatch;

-(SGJmapMasteryNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        self.Position=aPosition;
        
        self.MNodeRenderComponent=[[SGJmapMasteryNodeRender alloc] initWithGameObject:self];
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
