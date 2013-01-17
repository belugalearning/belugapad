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

@synthesize NodeRenderComponent, EnabledAndComplete, MasteryNode, PrereqNodes, Attempted, DateLastPlayed, FreshlyCompleted;

//Transform protocol properties
@synthesize Position, RenderBatch;

//proximtyResponder properties
@synthesize Visible, ProximityEvalComponent;

//CouchDerived
@synthesize _id, UserVisibleString;

//selectable
@synthesize Selected, NodeSelectComponent, HitProximity, HitProximitySign;

//searchable
@synthesize searchMatchString;

@synthesize flip;

@synthesize ustate;
@synthesize lastustate;

-(SGJmapNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        Position=aPosition;
        self.Selected=NO;
        self.Visible=NO;
        
        PrereqNodes=[[NSMutableArray alloc] init];
        
        NodeRenderComponent=[[SGJmapNodeRender alloc] initWithGameObject:self];
        ProximityEvalComponent=[[SGJmapProximityEval alloc] initWithGameObject:self];
        NodeSelectComponent=[[SGJmapNodeSelect alloc] initWithGameObject:self];
    }
    return self;
}


-(void)handleMessage:(SGMessageType)messageType
{
    //re-broadcast messages to components
    [self.NodeRenderComponent handleMessage:messageType];
    [self.ProximityEvalComponent handleMessage:messageType];
    [self.NodeSelectComponent handleMessage:messageType];
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    [self.NodeRenderComponent doUpdate:delta];
    [self.ProximityEvalComponent doUpdate:delta];
    [self.NodeSelectComponent doUpdate:delta];
}

-(void)setPosition:(CGPoint)aPosition
{
    Position=aPosition;
    [NodeRenderComponent updatePosition:Position];
}

-(void)setupArtefactRender
{
    [NodeRenderComponent setupArtefact];
}

-(void)draw:(int)z
{
    if(self.Visible)
    {
        [self.NodeRenderComponent draw:z];
    }
}

-(void)flipSprite
{
    [self.NodeRenderComponent flipSprite];
}

-(void)setup
{
    [self.NodeRenderComponent setup];
}

-(void)dealloc
{
    self.NodeRenderComponent=nil;
    self.MasteryNode=nil;
    self.PrereqNodes=nil;
    self.RenderBatch=nil;
    self.ProximityEvalComponent=nil;
    self._id=nil;
    self.UserVisibleString=nil;
    self.NodeSelectComponent=nil;
    self.searchMatchString=nil;
    
    [super dealloc];
}

@end
