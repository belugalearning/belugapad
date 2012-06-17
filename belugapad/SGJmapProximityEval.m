//
//  SGJmapProximityEval.m
//  belugapad
//
//  Created by Gareth Jenkins on 18/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapProximityEval.h"

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
    if(1==2)
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
