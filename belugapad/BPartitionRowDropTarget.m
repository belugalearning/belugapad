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
#import "DWPartitionObjectGameObject.h"

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
        

            //float dist=[BLMath DistanceBetween:myLoc and:hitLoc];
        CGRect boundingBox = CGRectZero;
        for(int i=0;i<prgo.BaseNode.children.count;i++)
        {
            CCSprite *curSprite = [prgo.BaseNode.children objectAtIndex:i];
            boundingBox=CGRectUnion(boundingBox, curSprite.boundingBox);
        }
        
        if(!gameWorld.Blackboard.DropObject && CGRectContainsPoint(boundingBox, [prgo.BaseNode convertToNodeSpace:hitLoc]) && !prgo.Locked)
            {
                float myHeldValue=0.0f;
                for(int i=0;i<prgo.MountedObjects.count;i++)
                {
                    DWPartitionObjectGameObject *mo = [prgo.MountedObjects objectAtIndex:i];
                    myHeldValue=myHeldValue+mo.Length;
                }
                DWPartitionObjectGameObject *newO = (DWPartitionObjectGameObject*)gameWorld.Blackboard.PickupObject;
                if(myHeldValue+newO.Length<=prgo.Length)
                {           
                    // change the hover-over tint colour
                    for(CCSprite *s in prgo.BaseNode.children)
                    {
                        [s setColor:ccc3(0,255,0)];
                    }
                    gameWorld.Blackboard.DropObject=gameObject;
                    //gameWorld.Blackboard.DropObjectDistance=dist;
                    
                }

            }
        else {
            // if not a valid droptarget, not in view, set all sprites back to their proper colour
            for(CCSprite *s in prgo.BaseNode.children)
            {
                [s setColor:ccc3(255,255,255)];
            }
            gameWorld.Blackboard.DropObject=nil;
        }

    }
}

@end
