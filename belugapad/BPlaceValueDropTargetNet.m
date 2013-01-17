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
        CGPoint hitLoc=[gameWorld.Blackboard.ComponentRenderLayer convertToWorldSpace:gameWorld.Blackboard.TestTouchLocation];
        
        
        //if([gameObjectValue isEqualToNumber:pickupObjectValue])
        if(n.ColumnValue==addO.ObjectValue||-n.ColumnValue==addO.ObjectValue)
        {
            float dist=[BLMath DistanceBetween:myLoc and:hitLoc];
            if(!gameWorld.Blackboard.DropObject || gameWorld.Blackboard.DropObjectDistance > dist)
            {
                //NSLog(@"(#%d) obj Value %f, col Value %f, MountedObject? %@, CancellingObject? %@", [gameWorld.AllGameObjects indexOfObject:n], addO.ObjectValue, n.ColumnValue, n.MountedObject? @"YES":@"NO", n.CancellingObject? @"YES":@"NO");

                if(!n.MountedObject||(n.MountedObject && n.AllowMultipleMount && !n.CancellingObject && ((DWPlaceValueBlockGameObject*)n.MountedObject).ObjectValue==-addO.ObjectValue))
                {
                    gameWorld.Blackboard.DropObject=gameObject;
                    gameWorld.Blackboard.DropObjectDistance=dist;
                    
                    //NSLog(@"net sets droptarget dist %f val %f", dist, n.ColumnValue);
                }
            }
            if(!gameWorld.Blackboard.PriorityDropObject && n.AllowMultipleMount && n.MountedObject && !n.CancellingObject && ((DWPlaceValueBlockGameObject*)n.MountedObject).ObjectValue==-addO.ObjectValue)
            {
                gameWorld.Blackboard.PriorityDropObject=gameObject;
                gameWorld.Blackboard.DropObject=gameObject;
            }
        }
        
        
            
    
    }
}

@end
