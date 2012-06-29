//
//  SGJmapRegionRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapRegionRender.h"
#import "SGJmapRegion.h"

@implementation SGJmapRegionRender

-(SGJmapRegionRender*)initWithGameObject:(SGJmapRegion*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kSGreadyRender)
    {
        [self readyRender];
    }
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)readyRender
{
    
}

-(void)draw:(int)z
{
    
}

-(void)dealloc
{
    
    [super dealloc];
}


@end
