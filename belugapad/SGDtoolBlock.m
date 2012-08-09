//
//  SGDtoolBlock.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGDtoolBlock.h"
#import "SGDtoolBlockRender.h"
#import "SGDtoolBlockPairing.h"

@implementation SGDtoolBlock

@synthesize BlockRenderComponent;
@synthesize BlockPairComponent;
@synthesize mySprite;

//Transform protocol properties
@synthesize Position, Visible, RenderLayer;

@synthesize Selected, HitProximity, MyContainer;

// Pairable protocol properties
@synthesize PairedObjects, SeekingPair;

-(SGDtoolBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.Selected=NO;
        self.Visible=YES;
    }
    BlockRenderComponent=[[SGDtoolBlockRender alloc] initWithGameObject:self];
    BlockPairComponent=[[SGDtoolBlockPairing alloc] initWithGameObject:self];
    return self;
}


-(void)handleMessage:(SGMessageType)messageType
{
    //re-broadcast messages to components
    [self.BlockRenderComponent handleMessage:messageType];
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    [self.BlockRenderComponent doUpdate:delta];
}

-(void)draw:(int)z
{
    [self.BlockPairComponent draw:z];
}

-(void)move
{
    [self.BlockRenderComponent move];
}

-(void)animateToPosition
{
    [self.BlockRenderComponent animateToPosition];
}

-(void)setup
{
    [self.BlockRenderComponent setup];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    return [self.BlockRenderComponent amIProximateTo:location];
}

-(void)resetTint
{
    [self.BlockRenderComponent resetTint];
}

-(void)pairMeWith:(id)thisObject
{
    [self.BlockPairComponent pairMeWith:thisObject];
}

-(void)unpairMeFrom:(id)thisObject
{
    [self.BlockPairComponent unpairMeFrom:thisObject];
}

-(void)dealloc
{
    self.BlockRenderComponent=nil;
    self.BlockPairComponent=nil;
    self.mySprite=nil;
    self.RenderLayer=nil;
    self.PairedObjects=nil;
    
    [super dealloc];
}

@end
