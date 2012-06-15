//
//  BPlaceValueDropTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueDropTargetNet.h"
#import "global.h"
#import "BLMath.h"
#import "PlaceValueConsts.h"
#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueNetGameObject.h"

@implementation BPlaceValueDropTargetNet

-(BPlaceValueDropTargetNet *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueDropTargetNet*)[super initWithGameObject:aGameObject withData:data];
    n=(DWPlaceValueNetGameObject*)gameObject;
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouADropTarget)
    {
        //        DWGameObject *addO=gameWorld.Blackboard.PickupObject;
        DWPlaceValueBlockGameObject *addO=(DWPlaceValueBlockGameObject*)gameWorld.Blackboard.PickupObject;

              

        //get current loc
        float x=n.PosX;
        float y=n.PosY;
        CGPoint myLoc=ccp(x,y);
        
        myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToWorldSpace:myLoc];
        
        
        //get coords from payload (i.e. the search target)
        CGPoint hitLoc=gameWorld.Blackboard.TestTouchLocation;
        
        
        NSNumber *gameObjectValue = nil;
        NSNumber *pickupObjectValue = nil;
        gameObjectValue=[NSNumber numberWithFloat:n.ColumnValue];
        pickupObjectValue=[NSNumber numberWithFloat:addO.ObjectValue];
        
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

@end
