//
//  SGFractionObject.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGFbuilderFraction.h"
#import "SGFractionBuilderRender.h"
#import "SGFractionBuilderMarker.h"
#import "SGFractionBuilderChunkManager.h"


@implementation SGFbuilderFraction

// configurable properties
@synthesize RenderLayer, HasSlider, CreateChunksOnInit, CreateChunks, FractionMode, Position, FractionSprite, SliderSprite, SliderMarkerSprite, BaseNode, MarkerStartPosition, AutoShadeNewChunks, ShowEquivalentFractions, ShowCurrentFraction, CurrentFraction;

// interactive properties
@synthesize Chunks, Divisions, GhostChunks, MarkerPosition, Value, Tag;

@synthesize RenderComponent;
@synthesize MarkerComponent;
@synthesize ChunkComponent;

-(SGFbuilderFraction*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.BaseNode=[[[CCNode alloc]init]autorelease];
        self.Chunks=[[[NSMutableArray alloc]init]autorelease];
        self.GhostChunks=[[[NSMutableArray alloc]init]autorelease];

    }
    self.RenderComponent=[[[SGFractionBuilderRender alloc] initWithGameObject:self] autorelease];
    self.MarkerComponent=[[[SGFractionBuilderMarker alloc] initWithGameObject:self] autorelease];
    self.ChunkComponent=[[[SGFractionBuilderChunkManager alloc] initWithGameObject:self] autorelease];
    return self;
}


-(int)Divisions
{
    return MarkerPosition+1;
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

-(void)showFraction
{
    [self.RenderComponent showFraction];
}

-(void)hideFraction
{
    [self.RenderComponent hideFraction];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    return [self.MarkerComponent amIProximateTo:location];
}

-(void)moveMarkerTo:(CGPoint)location
{
    [self.MarkerComponent moveMarkerTo:location];
}

-(id)createChunk
{
    return [self.ChunkComponent createChunk];
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
    self.RenderLayer=nil;
    self.FractionSprite=nil;
    self.SliderSprite=nil;
    self.SliderMarkerSprite=nil;
    self.BaseNode=nil;
    self.Chunks=nil;
    self.GhostChunks=nil;
    self.RenderComponent=nil;
    self.MarkerComponent=nil;
    self.ChunkComponent=nil;
    self.CurrentFraction=nil;
    
    [super dealloc];
}

@end
