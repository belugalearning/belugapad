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
#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueNetGameObject.h"

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
//        DWGameObject *addO=gameWorld.Blackboard.PickupObject;
        DWPlaceValueBlockGameObject *addO=(DWPlaceValueBlockGameObject*)gameWorld.Blackboard.PickupObject;
        BOOL inactive=c.Hidden;
        if(c.DisableDel)return;

        
        
        if(inactive==NO)
        {

            if (!c.MountedObject || c.AllowMultipleMount)
            {
                //get current loc
                float x=c.PosX;
                float y=c.PosY;
                CGPoint myLoc=ccp(x,y);
                
                myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToWorldSpace:myLoc];
                
                
                //get coords from payload (i.e. the search target)
                float xhit=[[payload objectForKey:POS_X] floatValue];
                float yhit=[[payload objectForKey:POS_Y] floatValue];
                CGPoint hitLoc=ccp(xhit, yhit);
                

                    NSNumber *gameObjectValue = nil;
                    NSNumber *pickupObjectValue = nil;
                    if(c.AllowMultipleMount)
                    {
                        gameObjectValue = [NSNumber numberWithFloat:c.ObjectValue];
                        pickupObjectValue = [NSNumber numberWithFloat:addO.ObjectValue];
                    }
                    else
                    {
                        gameObjectValue = [NSNumber numberWithFloat:fabsf(c.ObjectValue)];
                        pickupObjectValue = [NSNumber numberWithFloat:fabsf(addO.ObjectValue)];
                    }
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
