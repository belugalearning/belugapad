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

@synthesize RegionRenderComponent, MasteryNodes, RegionNumber, Name;

-(SGJmapRegion*) initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        //init components
        RegionRenderComponent=[[SGJmapRegionRender alloc] initWithGameObject:self];
        
        MasteryNodes=[[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    //rebroadcast to components
    [self.RegionRenderComponent handleMessage:messageType];
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
    self.RenderBatch=nil;
    self.RegionRenderComponent=nil;
    self.MasteryNodes=nil;
    self.Name=nil;
    
    [super dealloc];
}

@end
