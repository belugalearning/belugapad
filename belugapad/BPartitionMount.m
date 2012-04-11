//
//  BMount.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPartitionMount.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "PlaceValue.h"
#import "DWPartitionRowGameObject.h"
#import "DWPartitionObjectGameObject.h"

@implementation BPartitionMount

-(BPartitionMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPartitionMount*)[super initWithGameObject:aGameObject withData:data];
    
    prgo=(DWPartitionRowGameObject*)gameObject;
    
    return self;
}
-(void)doUpdate:(ccTime)delta
{
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        DWGameObject *addO=[payload objectForKey:MOUNTED_OBJECT];
        
        [prgo.MountedObjects addObject:addO];
        
        for(CCSprite *s in prgo.BaseNode.children)
        {
            [s setColor:ccc3(255,255,255)];
        }

    }
    
    if(messageType==kDWunsetMountedObject)
    {
        DWGameObject *removeO=[payload objectForKey:MOUNTED_OBJECT];
        
        [prgo.MountedObjects removeObject:removeO];
    }

    
    if(messageType==kDWresetPositionEval)
    {
        float myHeldValue=0.0f;
        for(int i=0;i<prgo.MountedObjects.count;i++)
        {
            DWPartitionObjectGameObject *mo = [prgo.MountedObjects objectAtIndex:i];
            mo.MovePosition=ccp(prgo.Position.x+(50*myHeldValue), prgo.Position.y);
            NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:ANIMATE_ME];
            [mo handleMessage:kDWmoveSpriteToPosition andPayload:pl withLogLevel:-1];
            
            myHeldValue=myHeldValue+mo.Length;
        }

    }
}

@end
