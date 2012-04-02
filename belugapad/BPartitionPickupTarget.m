//
//  BFloatPickupTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPartitionPickupTarget.h"
#import "BLMath.h"
#import "global.h"
#import "DWPartitionObjectGameObject.h"


@implementation BPartitionPickupTarget

-(BPartitionPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPartitionPickupTarget *)[super initWithGameObject:aGameObject withData:data];
    pogo=(DWPartitionObjectGameObject*)gameObject;
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouAPickupTarget)
    {
        //float theirV=fabsf([[payload objectForKey:OBJECT_VALUE] floatValue]);
        //float myV=fabsf([[[gameObject store] objectForKey:OBJECT_VALUE] floatValue]);

        
        //if(theirV!=myV)return;
        
        // if add from cage disabled - return at this point
        //DWGameObject *mount = [[gameObject store] objectForKey:MOUNT];
        //if([[[mount store] objectForKey:DISABLE_ADD] boolValue]) return;
        
        //get current loc

        CGPoint myLoc=pogo.Position;
        
        myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToNodeSpace:myLoc];
        
        //get coords from payload (i.e. the search target)
        float xhit=[[payload objectForKey:POS_X] floatValue];
        float yhit=[[payload objectForKey:POS_Y] floatValue];
        
        CGPoint hitLoc=ccp(xhit, yhit);
        
    
        if([BLMath DistanceBetween:myLoc and:hitLoc] <= (0.040f*[gameWorld Blackboard].hostLX))
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
