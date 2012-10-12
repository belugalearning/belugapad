//
//  SGFractionChunk.m
//  belugapad
//
//  Created by David Amphlett on 25/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGFbuilderChunk.h"
#import "SGFractionBuilderChunkManager.h"
#import "SGFractionBuilderChunkRender.h"


@implementation SGFbuilderChunk

// configurable properties
@synthesize RenderLayer, MyParent, CurrentHost, Position, MySprite, Value, ScaleX, Selected;

@synthesize ChunkManagerComponent;
@synthesize ChunkRenderComponent;

-(SGFbuilderChunk*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        ChunkManagerComponent=[[SGFractionBuilderChunkManager alloc]initWithGameObject:self];
        ChunkRenderComponent=[[SGFractionBuilderChunkRender alloc]initWithGameObject:self];
        
    }
    
    return self;
}


-(void)handleMessage:(SGMessageType)messageType
{
    //re-broadcast messages to components
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
}

-(void)draw:(int)z
{
    
}

-(void)setup
{
    [self.ChunkRenderComponent setup];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    return [self.ChunkRenderComponent amIProximateTo:(CGPoint)location];
}

-(void)moveChunk
{
    [self.ChunkRenderComponent moveChunk];
}

-(void)changeChunkSelection
{
    [self.ChunkRenderComponent changeChunkSelection];
}

-(BOOL)checkForChunkDropIn:(id<Configurable>)thisObject
{
    return [self.ChunkRenderComponent checkForChunkDropIn:thisObject];
}

-(void)changeChunk:(id<ConfigurableChunk>)thisChunk toBelongTo:(id<Interactive>)newFraction
{
    [self.ChunkManagerComponent changeChunk:thisChunk toBelongTo:newFraction];
}

-(void)returnToParentSlice
{
    [self.ChunkRenderComponent returnToParentSlice];
}

-(void)dealloc
{
    self.RenderLayer=nil;
    self.MyParent=nil;
    self.CurrentHost=nil;
    self.MySprite=nil;
    self.ChunkManagerComponent=nil;
    self.ChunkRenderComponent=nil;
    
    [super dealloc];
}

@end
