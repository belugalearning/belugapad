//
//  BFloatPickupTarget.m
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BFloatPickupTarget.h"
#import "BLMath.h"
#import "global.h"

@implementation BFloatPickupTarget

-(BFloatPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BFloatPickupTarget *)[super initWithGameObject:aGameObject withData:data];
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouAPickupTarget)
    {        
        //get current loc
        float x=[[[gameObject store] objectForKey:POS_X] floatValue];
        float y=[[[gameObject store] objectForKey:POS_Y] floatValue];   
        CGPoint myLoc=ccp(x,y);
        
        //get coords from payload (i.e. the search target)
        float xhit=[[payload objectForKey:POS_X] floatValue];
        float yhit=[[payload objectForKey:POS_Y] floatValue];
        CGPoint hitLoc=ccp(xhit, yhit);
        
        //look see if this is close enough
    
        //tofu: currently using fixed proximity -- this will need to change for non-square shapes (maybe with hit test on shape or similar)
    
        if([BLMath DistanceBetween:myLoc and:hitLoc] <= FLOAT_PICKUP_PROXIMITY)
        {
            //tell gameScene we are a target for that pickup
            [gameWorld Blackboard].PickupObject=gameObject;
        }        
    }
}

@end
