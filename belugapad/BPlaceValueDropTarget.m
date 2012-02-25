//
//  BPlaceValueDropTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueDropTarget.h"
#import "global.h"
#import "BLMath.h"
#import "PlaceValueConsts.h"

@implementation BPlaceValueDropTarget

-(BPlaceValueDropTarget *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueDropTarget*)[super initWithGameObject:aGameObject withData:data];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouADropTarget)
    {
        DWGameObject *addO=gameWorld.Blackboard.PickupObject;
        
        
        //DWGameObject *addO=[payload objectForKey:SELECTED];
        
        BOOL inactive=[[[gameObject store] objectForKey:HIDDEN] boolValue];
        if(inactive==NO)
        {

            if (![[gameObject store] objectForKey:MOUNTED_OBJECT] || [[gameObject store] objectForKey:ALLOW_MULTIPLE_MOUNT])
            {
                //get current loc
                float x=[[[gameObject store] objectForKey:POS_X] floatValue];
                float y=[[[gameObject store] objectForKey:POS_Y] floatValue];   
                CGPoint myLoc=ccp(x,y);
                
                myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToWorldSpace:myLoc];
                
                
                //get coords from payload (i.e. the search target)
                float xhit=[[payload objectForKey:POS_X] floatValue];
                float yhit=[[payload objectForKey:POS_Y] floatValue];
                CGPoint hitLoc=ccp(xhit, yhit);
                
                //look see if this is close enough
                if([BLMath DistanceBetween:myLoc and:hitLoc] <= (kPropXDropProximity*[gameWorld Blackboard].hostLX))
                {
                    NSNumber *gameObjectValue = nil;
                    NSNumber *pickupObjectValue = nil;
                    if([[gameObject store] objectForKey:ALLOW_MULTIPLE_MOUNT])
                    {
                        gameObjectValue = [[gameObject store] objectForKey:OBJECT_VALUE];
                        pickupObjectValue = [[addO store] objectForKey:OBJECT_VALUE];
                    }
                    else
                    {
                        gameObjectValue = [NSNumber numberWithFloat:fabsf([[[gameObject store] objectForKey:OBJECT_VALUE] floatValue])];
                        pickupObjectValue = [NSNumber numberWithFloat:fabsf([[[addO store] objectForKey:OBJECT_VALUE] floatValue])];
                    }
                    if([gameObjectValue isEqualToNumber:pickupObjectValue])
                    {
                        //tell gameScene we are a target for that pickup
                        [gameWorld Blackboard].DropObject=gameObject;
                    }
                    
                }
            }
            
        }

    }
}

@end
