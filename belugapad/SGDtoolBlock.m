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
@synthesize blockType;

//Transform protocol properties
@synthesize Position, Visible, RenderLayer;

@synthesize Selected, HitProximity, MyContainer;

// Pairable protocol properties
@synthesize PairedObjects, SeekingPair;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"SGDtoolBlock"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }

-(SGDtoolBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andType:(NSString*)thisType
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.Selected=NO;
        self.Visible=YES;
        self.blockType=thisType;
        self.PairedObjects=[[NSMutableArray alloc]init];
        BlockRenderComponent=[[SGDtoolBlockRender alloc] initWithGameObject:self];
        BlockPairComponent=[[SGDtoolBlockPairing alloc] initWithGameObject:self];
    }

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
    self.logPollId = nil;
    self.blockType=nil;
    if (logPollId) [logPollId release];
    logPollId = nil;
    
    [super dealloc];
}

@end
