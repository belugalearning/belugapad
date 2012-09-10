//
//  BPlaceValueDropTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueDropTargetCage.h"
#import "global.h"
#import "BLMath.h"
#import "PlaceValueConsts.h"
#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueNetGameObject.h"

@implementation BPlaceValueDropTargetCage

-(BPlaceValueDropTargetCage *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueDropTargetCage*)[super initWithGameObject:aGameObject withData:data];
    c=(DWPlaceValueCageGameObject*)gameObject;
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
                CGPoint hitLoc=[gameWorld.Blackboard.ComponentRenderLayer convertToWorldSpace:gameWorld.Blackboard.TestTouchLocation];
                
                
                    if(c.ObjectValue==addO.ObjectValue)
                    {
                        float dist=[BLMath DistanceBetween:myLoc and:hitLoc];

                        if(!gameWorld.Blackboard.DropObject || gameWorld.Blackboard.DropObjectDistance > dist)
                        {
                            gameWorld.Blackboard.DropObject=gameObject;
                            gameWorld.Blackboard.DropObjectDistance=dist;
                            
                            //NSLog(@"cage sets droptarget dist %f val %f", dist, c.ObjectValue);
                        }
                    }
                    
            }
            
        }

    }
}

@end
