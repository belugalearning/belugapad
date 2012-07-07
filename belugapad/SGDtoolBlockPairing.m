//
//  SGDtoolBlockPairing.m
//  belugapad
//
//  Created by David Amphlett on 06/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGDtoolBlockPairing.h"
#import "SGDtoolBlock.h"
#import "BLMath.h"

@interface SGDtoolBlockPairing()
{
    CCSprite *blockSprite;
}

@end

@implementation SGDtoolBlockPairing

-(SGDtoolBlockPairing*)initWithGameObject:(id<Pairable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)draw:(int)z
{
    if(z==0)
    {
        if([ParentGO.PairedObjects count]>0)
        {
            for(int i=0;i<[ParentGO.PairedObjects count];i++)
            {
                id<Transform, Moveable, Pairable> curObj=[ParentGO.PairedObjects objectAtIndex:i];
                ccDrawLine(curObj.Position, ParentGO.Position);
            }
        }
    }
}

-(void)pairMeWith:(id)thisObject
{
    if(!ParentGO.PairedObjects)ParentGO.PairedObjects=[[NSMutableArray alloc]init];
    
    // if the array already contains the object - don't readd it
    if(![ParentGO.PairedObjects containsObject:thisObject])[ParentGO.PairedObjects addObject:thisObject];
    [self pairPickupObjectToMe:thisObject];
}

-(void)pairPickupObjectToMe:(id)pickupObject
{
    // declare the current PickupObject as a pairable item
    id<Pairable> currentPickupObject=pickupObject;
    
    // check whether the array exists - if not, create it 
    if(!currentPickupObject.PairedObjects)currentPickupObject.PairedObjects=[[NSMutableArray alloc]init];
    // then, pair our pickupObject with our current GO
    if(![currentPickupObject.PairedObjects containsObject:ParentGO])[currentPickupObject.PairedObjects addObject:ParentGO];
}

-(void)unpairMeFrom:(id)thisObject
{
    if([ParentGO.PairedObjects containsObject:thisObject])[ParentGO.PairedObjects removeObject:thisObject];
    [self unpairPickupObjectFromMe:thisObject];
}

-(void)unpairPickupObjectFromMe:(id)pickupObject
{
    // declare the current PickupObject as a pairable item
    id<Pairable> currentPickupObject=pickupObject;
    
    // then, pair our pickupObject with our current GO
    if([currentPickupObject.PairedObjects containsObject:ParentGO])[currentPickupObject.PairedObjects removeObject:ParentGO];
}

@end
