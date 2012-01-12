//
//  BPickupTarget.m
//  belugapad
//
//  Created by Gareth Jenkins on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPickupTarget.h"
#import "BLMath.h"
#import "global.h"

@implementation BPickupTarget


-(BPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPickupTarget *)[super initWithGameObject:aGameObject withData:data];
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouAPickupTarget)
    {
        //attempt to get mounting GO
        DWGameObject *go=[[gameObject store] objectForKey:MOUNT];
        
        if(go != nil)
        {
            //get current loc (based on mount pos)
            float x=[[[go store] objectForKey:POS_X] floatValue];
            float y=[[[go store] objectForKey:POS_Y] floatValue];   
            CGPoint myLoc=ccp(x,y);
            
            //get coords from payload (i.e. the search target)
            float xhit=[[payload objectForKey:POS_X] floatValue];
            float yhit=[[payload objectForKey:POS_Y] floatValue];
            CGPoint hitLoc=ccp(xhit, yhit);
            
            //look see if this is close enough
            if([BLMath DistanceBetween:myLoc and:hitLoc] <= PICKUP_PROXIMITY)
            {
                //tell gameScene we are a target for that pickup
                [gameWorld Blackboard].PickupObject=gameObject;
            }
        }
        
    }
}

@end
