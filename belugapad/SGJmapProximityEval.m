//
//  SGJmapProximityEval.m
//  belugapad
//
//  Created by Gareth Jenkins on 18/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapProximityEval.h"
#import "BLMath.h"

static float visibleProximity=1024.0f;

@implementation SGJmapProximityEval

-(SGJmapProximityEval*)initWithGameObject:(id<ProximityResponder, Transform>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)actOnProximityTo:(CGPoint)pos
{
    if([BLMath DistanceBetween:pos and:ParentGO.Position]<visibleProximity)
    {
        ParentGO.Visible=YES;
    }
    else {
        ParentGO.Visible=NO;
    }
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

@end
