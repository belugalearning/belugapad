//
//  BPlaceValueDropTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPartitionRowDropTarget.h"
#import "DWPartitionRowGameObject.h"
#import "global.h"
#import "BLMath.h"

@implementation BPartitionRowDropTarget

-(BPartitionRowDropTarget *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPartitionRowDropTarget*)[super initWithGameObject:aGameObject withData:data];
    prgo = (DWPartitionRowGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouADropTarget)
    {

        //get current loc
        CGPoint myLoc=prgo.Position;
            
        myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToNodeSpace:myLoc];
        
        
        //get coords from payload (i.e. the search target)
        float xhit=[[payload objectForKey:POS_X] floatValue];
        float yhit=[[payload objectForKey:POS_Y] floatValue];
        CGPoint hitLoc=ccp(xhit, yhit);
        

            float dist=[BLMath DistanceBetween:myLoc and:hitLoc];
            if(!gameWorld.Blackboard.DropObject && dist<80.0f)
            {
                gameWorld.Blackboard.DropObject=gameObject;
                //gameWorld.Blackboard.DropObjectDistance=dist;
                NSLog(@"hover over row drop target");
            }

    }
}

@end
