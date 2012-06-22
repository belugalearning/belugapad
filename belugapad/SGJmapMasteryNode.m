//
//  SGJmapMNodeGO.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapMasteryNode.h"
#import "SGJmapMasteryNodeRender.h"
#import "SGJmapProximityEval.h"
#import "SGJmapNodeSelect.h"

@implementation SGJmapMasteryNode

@synthesize MNodeRenderComponent, ChildNodes;

//transform protocol properties
@synthesize Position, RenderBatch;

//proximtyResponder properties
@synthesize Visible, ProximityEvalComponent;

//CouchDerived
@synthesize _id, UserVisibleString;

//selectable
@synthesize Selected, NodeSelectComponent;

-(SGJmapMasteryNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        self.Position=aPosition;
        
        MNodeRenderComponent=[[[SGJmapMasteryNodeRender alloc] initWithGameObject:self] autorelease];
        ProximityEvalComponent=[[[SGJmapProximityEval alloc] initWithGameObject:self] autorelease];
        NodeSelectComponent=[[[SGJmapNodeSelect alloc] initWithGameObject:self] autorelease];
        
        ChildNodes=[[NSMutableArray alloc] init];
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel
{
    //broadcast to components
    [self.MNodeRenderComponent handleMessage:messageType andPayload:payload];
    [self.ProximityEvalComponent handleMessage:messageType andPayload:payload];
    [self.NodeSelectComponent handleMessage:messageType andPayload:payload];
}

-(void)doUpdate:(ccTime)delta
{
    //update components
    [self.MNodeRenderComponent doUpdate:delta];
    [self.ProximityEvalComponent doUpdate:delta];
    [self.NodeSelectComponent doUpdate:delta];
}

-(void)draw
{
    if(self.Visible)
    {
        [self.MNodeRenderComponent draw];
    }
}

-(void)setup
{
    [self.MNodeRenderComponent setup];
    
}

-(void)dealloc
{
    [MNodeRenderComponent release];
    [ProximityEvalComponent release];
    [NodeSelectComponent release];
    
    [ChildNodes release];
    
    [super dealloc];
}

@end
