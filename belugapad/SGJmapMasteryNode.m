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

@synthesize MNodeRenderComponent, ChildNodes, ConnectToMasteryNodes, ConnectFromMasteryNodes, EnabledAndComplete, Region, PrereqCount, PrereqComplete, PrereqPercentage;

//transform protocol properties
@synthesize Position, RenderBatch;

//proximtyResponder properties
@synthesize Visible, ProximityEvalComponent;

//CouchDerived
@synthesize _id, UserVisibleString;

//selectable
@synthesize Selected, NodeSelectComponent, HitProximity, HitProximitySign;

-(SGJmapMasteryNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        self.Position=aPosition;
        self.Visible=NO;
        
        MNodeRenderComponent=[[[SGJmapMasteryNodeRender alloc] initWithGameObject:self] retain];
        ProximityEvalComponent=[[[SGJmapProximityEval alloc] initWithGameObject:self] retain];
        NodeSelectComponent=[[[SGJmapNodeSelect alloc] initWithGameObject:self] retain];
        
        ChildNodes=[[NSMutableArray alloc] init];
        ConnectFromMasteryNodes=[[NSMutableArray alloc] init];
        ConnectToMasteryNodes=[[NSMutableArray alloc] init];
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    //broadcast to components
    [self.MNodeRenderComponent handleMessage:messageType];
    [self.ProximityEvalComponent handleMessage:messageType];
    [self.NodeSelectComponent handleMessage:messageType];
}

-(void)doUpdate:(ccTime)delta
{
    //update components
    [self.MNodeRenderComponent doUpdate:delta];
    [self.ProximityEvalComponent doUpdate:delta];
    [self.NodeSelectComponent doUpdate:delta];
}

-(void)draw:(int)z
{
    if(self.Visible)
    {
        [self.MNodeRenderComponent draw:z];
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
    [ConnectToMasteryNodes release];
    [ConnectFromMasteryNodes release];
    
    [super dealloc];
}

@end
