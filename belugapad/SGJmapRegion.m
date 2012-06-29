//
//  SGJmapRegion.m
//  belugapad
//
//  Created by Gareth Jenkins on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapRegion.h"
#import "SGJmapRegionRender.h"

@implementation SGJmapRegion

@synthesize Position, RenderBatch;
@synthesize Visible;

@synthesize RegionRenderComponent;

-(SGJmapRegion*) initWithGameWorld:(SGGameWorld*)aGameWorld andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.Position=aPosition;
        
        //init components
        RegionRenderComponent=[[SGJmapRegionRender alloc] initWithGameObject:self];
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload
{
    //rebroadcast to components
    [self.RegionRenderComponent handleMessage:messageType andPayload:payload];
}

-(void)doUpdate:(ccTime)delta
{
    //doupdate components
    [self.RegionRenderComponent doUpdate:delta];
}

-(void)draw:(int)z
{
    //draw components
    [self.RegionRenderComponent draw:z];
}

-(void)setup
{
    //setup any components needing it
}

-(void)dealloc
{
    
    [super dealloc];
}

@end
