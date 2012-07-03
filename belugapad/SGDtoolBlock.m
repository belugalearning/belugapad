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
@synthesize Position, Visible, RenderLayer;

@synthesize Selected, HitProximity;

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
