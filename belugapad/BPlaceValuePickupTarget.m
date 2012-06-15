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
#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueNetGameObject.h"

@implementation BPlaceValuePickupTarget

-(BPlaceValuePickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValuePickupTarget *)[super initWithGameObject:aGameObject withData:data];
    b=(DWPlaceValueBlockGameObject*)gameObject;
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouAPickupTarget)
    {
        
        // if add from cage disabled - return at this point
    
        if([b.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
        {
            DWPlaceValueCageGameObject *mountCge=(DWPlaceValueCageGameObject*)b.Mount;
            if(mountCge.DisableAdd) return;
        }
        else if([b.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
        {
            
        }
        //get current loc
        float x=b.PosX;
        float y=b.PosY;
        CGPoint myLoc=ccp(x,y);
        
        NSLog(@"x %f y %f", x,y);
        
        myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToWorldSpace:myLoc];
        
        CGPoint hitLoc=gameWorld.Blackboard.TestTouchLocation;
        

        if([BLMath DistanceBetween:myLoc and:hitLoc] <= (kPropXDropProximity*[gameWorld Blackboard].hostLX))
        {
            //tell gameScene we are a target for that pickup
            [gameWorld Blackboard].PickupObject=gameObject;
                    NSLog(@"success x %f y %f", x,y);
        }        
    }
    
    if(messageType==kDWsetMount)
    {

    }
    
    if(messageType==kDWunsetMount)
    {
        b.Mount=nil;
    }
}

@end
