//
//  SGDtoolBlock.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGDtoolBlock.h"
#import "SGDtoolBlockRender.h"

@implementation SGDtoolBlock

@synthesize BlockRenderComponent;


//Transform protocol properties
@synthesize Position, Visible, RenderBatch;

@synthesize Selected, BlockSelectComponent, HitProximity;

-(SGDtoolBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{   
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        self.Position=aPosition;
        self.Selected=NO;
        self.Visible=NO;
        
        BlockRenderComponent=[[[SGDtoolBlockRender alloc] initWithGameObject:self] retain];
    }
    return self;
}


-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel 
{
    //re-broadcast messages to components
    [self.BlockRenderComponent handleMessage:messageType andPayload:payload];
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    [self.BlockRenderComponent doUpdate:delta];
}

-(void)draw:(int)z
{
    if(self.Visible)
    {
        [self.BlockRenderComponent draw:z];
    }
}


-(void)setup
{
    [self.BlockRenderComponent setup];
}

-(void)dealloc
{
    [BlockRenderComponent release];
    
    [super dealloc];
}

@end
