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

-(SGJmapProximityEval*)initWithGameObject:(id<ProximityResponder, Transform, GameObject>)aGameObject
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
        if(!ParentGO.Visible)
        {
            ParentGO.Visible=YES;
            [ParentGO handleMessage:kSGvisibilityChanged];
        }
    }
    else {
        if(ParentGO.Visible)
        {
            ParentGO.Visible=NO;
            [ParentGO handleMessage:kSGvisibilityChanged];
        }
    }
}

-(void)handleMessage:(SGMessageType)messageType
{
//    if(messageType==kSGzoomOut)
//    {
//        ParentGO.Visible=YES;
//        [ParentGO handleMessage:kSGvisibilityChanged andPayload:nil withLogLevel:0];        
//    }
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

@end
