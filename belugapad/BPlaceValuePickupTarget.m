//
//  BFloatPickupTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValuePickupTarget.h"
#import "BLMath.h"
#import "global.h"
#import "PlaceValueConsts.h"

@implementation BPlaceValuePickupTarget

-(BPlaceValuePickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValuePickupTarget *)[super initWithGameObject:aGameObject withData:data];
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouAPickupTarget)
    {
        float theirV=[[payload objectForKey:OBJECT_VALUE] floatValue];
        float myV=[[[gameObject store] objectForKey:OBJECT_VALUE] floatValue];
        
        if(theirV!=myV)return;
        
        //get current loc
        float x=[[[gameObject store] objectForKey:POS_X] floatValue];
        float y=[[[gameObject store] objectForKey:POS_Y] floatValue];   
        CGPoint myLoc=ccp(x,y);
        
        myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToWorldSpace:myLoc];
        
        //get coords from payload (i.e. the search target)
        float xhit=[[payload objectForKey:POS_X] floatValue];
        float yhit=[[payload objectForKey:POS_Y] floatValue];
        CGPoint hitLoc=ccp(xhit, yhit);
        
        
        if([BLMath DistanceBetween:myLoc and:hitLoc] <= (kPropXDropProximity*[gameWorld Blackboard].hostLX))
        {
            //tell gameScene we are a target for that pickup
            [gameWorld Blackboard].PickupObject=gameObject;
        }        
    }
    
    if(messageType==kDWsetMount)
    {
        GOS_SET([payload objectForKey:MOUNT], MOUNT);
    }
    
    if(messageType==kDWunsetMount)
    {
        [[gameObject store] removeObjectForKey:MOUNT];
    }
}

@end
