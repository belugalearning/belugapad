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

@implementation SGJmapNode

@synthesize NodeRenderComponent;

//Transform protocol properties
@synthesize Position, RenderBatch;

//proximtyResponder properties
@synthesize Visible, ProximityEvalComponent;

//CouchDerived
@synthesize _id, UserVisibleString;

-(SGJmapNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        self.Position=aPosition;
        
        self.NodeRenderComponent=[[SGJmapNodeRender alloc] initWithGameObject:self];
        self.ProximityEvalComponent=[[SGJmapProximityEval alloc] initWithGameObject:self];
    }
    return self;
}


-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel 
{
    //re-broadcast messages to components
    [self.NodeRenderComponent handleMessage:messageType andPayload:payload];
    [self.ProximityEvalComponent handleMessage:messageType andPayload:payload];
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    [self.NodeRenderComponent doUpdate:delta];
    [self.ProximityEvalComponent doUpdate:delta];
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
    
}

-(void)dealloc
{
    [self.NodeRenderComponent release];
    
    [super dealloc];
}

@end
