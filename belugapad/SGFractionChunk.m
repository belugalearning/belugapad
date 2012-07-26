//
//  SGFractionChunk.m
//  belugapad
//
//  Created by David Amphlett on 25/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGFractionChunk.h"
#import "SGFractionBuilderChunk.h"
#import "SGFractionBuilderChunkRender.h"


@implementation SGFractionChunk

// configurable properties
@synthesize RenderLayer, MyParent, CurrentHost, Position, MySprite, Value;

@synthesize ChunkComponent;
@synthesize ChunkRenderComponent;

-(SGFractionChunk*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        ChunkComponent=[[SGFractionBuilderChunk alloc]initWithGameObject:self];
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
    [self.ChunkRenderComponent amIProximateTo:(CGPoint)location];    
}

-(void)moveMarkerTo:(CGPoint)location
{
    
}

-(void)dealloc
{
    [super dealloc];
}

@end
