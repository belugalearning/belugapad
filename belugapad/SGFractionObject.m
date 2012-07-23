//
//  SGFractionObject.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGFractionObject.h"
#import "SGFractionBuilderRender.h"


@implementation SGFractionObject

// configurable properties
@synthesize RenderLayer, HasSlider, CreateChunksOnInit, CreateChunks, FractionMode, Position, FractionSprite, SliderSprite, SliderMarkerSprite;

// interactive properties
@synthesize Divisions, Chunks;

@synthesize RenderComponent;

-(SGFractionObject*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;

    }
    RenderComponent=[[SGFractionBuilderRender alloc] initWithGameObject:self];
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


-(void)dealloc
{
    [RenderComponent release];
    
    [super dealloc];
}

@end
