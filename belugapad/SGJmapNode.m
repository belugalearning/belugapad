//
//  SGJmapNodeGO.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapNode.h"
#import "SGJmapNodeRender.h"
#import "SGJmapProximityEval.h"
#import "SGJmapNodeSelect.h"

@implementation SGJmapNode

@synthesize NodeRenderComponent, EnabledAndComplete, MasteryNode;

//Transform protocol properties
@synthesize Position, RenderBatch;

//proximtyResponder properties
@synthesize Visible, ProximityEvalComponent;

//CouchDerived
@synthesize _id, UserVisibleString;

//selectable
@synthesize Selected, NodeSelectComponent;

-(SGJmapNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        self.Position=aPosition;
        self.Selected=NO;
        
        self.NodeRenderComponent=[[SGJmapNodeRender alloc] initWithGameObject:self];
        self.ProximityEvalComponent=[[SGJmapProximityEval alloc] initWithGameObject:self];
        self.NodeSelectComponent=[[SGJmapNodeSelect alloc] initWithGameObject:self];
    }
    return self;
}


-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel 
{
    //re-broadcast messages to components
    [self.NodeRenderComponent handleMessage:messageType andPayload:payload];
    [self.ProximityEvalComponent handleMessage:messageType andPayload:payload];
    [self.NodeSelectComponent handleMessage:messageType andPayload:payload];
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    [self.NodeRenderComponent doUpdate:delta];
    [self.ProximityEvalComponent doUpdate:delta];
    [self.NodeSelectComponent doUpdate:delta];
}

-(void)draw
{
    if(self.Visible)
    {
        [self.NodeRenderComponent draw];
    }
}


-(void)setup
{
    [self.NodeRenderComponent setup];
}

-(void)dealloc
{
    [self.NodeRenderComponent release];
    
    [super dealloc];
}

@end
