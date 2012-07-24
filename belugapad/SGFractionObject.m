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


@implementation SGFractionObject

// configurable properties
@synthesize RenderLayer, HasSlider, CreateChunksOnInit, CreateChunks, FractionMode, Position, FractionSprite, SliderSprite, SliderMarkerSprite, BaseNode, MarkerStartPosition;

// interactive properties
@synthesize Divisions, Chunks, MarkerPosition;

@synthesize RenderComponent;
@synthesize MarkerComponent;

-(SGFractionObject*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.BaseNode=[[CCNode alloc]init];

    }
    RenderComponent=[[SGFractionBuilderRender alloc] initWithGameObject:self];
    MarkerComponent=[[SGFractionBuilderMarker alloc] initWithGameObject:self];
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

-(void)snapToNearestPos
{
    [self.MarkerComponent snapToNearestPos];
}

-(void)dealloc
{
    [RenderComponent release];
    
    [super dealloc];
}

@end
