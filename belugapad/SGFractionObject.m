//
//  SGFractionObject.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGFractionObject.h"
#import "SGFractionBuilderRender.h"
#import "SGFractionBuilderMarker.h"
#import "SGFractionBuilderChunk.h"


@implementation SGFractionObject

// configurable properties
@synthesize RenderLayer, HasSlider, CreateChunksOnInit, CreateChunks, FractionMode, Position, FractionSprite, SliderSprite, SliderMarkerSprite, BaseNode, MarkerStartPosition;

// interactive properties
@synthesize Divisions, Chunks, GhostChunks, MarkerPosition, Value, Tag;

@synthesize RenderComponent;
@synthesize MarkerComponent;
@synthesize ChunkComponent;

-(SGFractionObject*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.BaseNode=[[CCNode alloc]init];
        self.Chunks=[[NSMutableArray alloc]init];
        self.GhostChunks=[[NSMutableArray alloc]init];

    }
    RenderComponent=[[SGFractionBuilderRender alloc] initWithGameObject:self];
    MarkerComponent=[[SGFractionBuilderMarker alloc] initWithGameObject:self];
    ChunkComponent=[[SGFractionBuilderChunk alloc] initWithGameObject:self];
    return self;
}


-(void)handleMessage:(SGMessageType)messageType
{
    //re-broadcast messages to components
    [self.RenderComponent handleMessage:messageType];
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    [self.RenderComponent doUpdate:delta];
}

-(void)draw:(int)z
{

}

-(void)setup
{
    [self.RenderComponent setup];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    return [self.MarkerComponent amIProximateTo:location];
}

-(void)moveMarkerTo:(CGPoint)location
{
    [self.MarkerComponent moveMarkerTo:location];
}

-(void)createChunk
{
    [self.ChunkComponent createChunk];
}

-(void)removeChunks
{
    [self.ChunkComponent removeChunks];
}

-(void)ghostChunk
{
    [self.ChunkComponent ghostChunk];
}

-(void)snapToNearestPos
{
    [self.MarkerComponent snapToNearestPos];
}

-(void)changeChunk:(id<ConfigurableChunk>)thisChunk toBelongTo:(id<Interactive>)newFraction
{
    [self.ChunkComponent changeChunk:thisChunk toBelongTo:newFraction];
}

-(void)dealloc
{
    [RenderComponent release];
    [MarkerComponent release];
    if(self.BaseNode)[self.BaseNode release];
    if(self.Chunks)[self.Chunks release];
    if(self.GhostChunks)[self.GhostChunks release];
    
    [super dealloc];
}

@end
