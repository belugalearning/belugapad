//
//  BPlaceValueDropTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondStoreDropTarget.h"
#import "global.h"
#import "BLMath.h"

@implementation BNBondStoreDropTarget

-(BNBondStoreDropTarget *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNBondStoreDropTarget*)[super initWithGameObject:aGameObject withData:data];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouADropTarget)
    {
//        DWGameObject *addO=gameWorld.Blackboard.PickupObject;
        BOOL inactive=[[[gameObject store] objectForKey:HIDDEN] boolValue];
        if([[[gameObject store] objectForKey:DISABLE_DEL] boolValue])return;

        
        
        if(inactive==NO)
        {

            if (![[gameObject store] objectForKey:MOUNTED_OBJECT] || [[gameObject store] objectForKey:ALLOW_MULTIPLE_MOUNT])
            {
                //get current loc
                float x=[[[gameObject store] objectForKey:POS_X] floatValue];
                float y=[[[gameObject store] objectForKey:POS_Y] floatValue];   
                CGPoint myLoc=ccp(x,y);
                
                myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToNodeSpace:myLoc];
                
                
                //get coords from payload (i.e. the search target)
                float xhit=[[payload objectForKey:POS_X] floatValue];
                float yhit=[[payload objectForKey:POS_Y] floatValue];
                CGPoint hitLoc=ccp(xhit, yhit);
                

                    NSNumber *gameObjectValue = nil;
                    NSNumber *pickupObjectValue = nil;

                    if([gameObjectValue isEqualToNumber:pickupObjectValue])
                    {
                        float dist=[BLMath DistanceBetween:myLoc and:hitLoc];
                        if(!gameWorld.Blackboard.DropObject || gameWorld.Blackboard.DropObjectDistance > dist)
                        {
                            gameWorld.Blackboard.DropObject=gameObject;
                            gameWorld.Blackboard.DropObjectDistance=dist;
                        }
                    }
                    
            }
            
        }

    }
}

@end
