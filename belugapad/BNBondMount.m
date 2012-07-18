;//
//  BMount.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondMount.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "PlaceValue.h"
#import "DWNBondRowGameObject.h"
#import "DWNBondObjectGameObject.h"

@implementation BNBondMount

-(BNBondMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNBondMount*)[super initWithGameObject:aGameObject withData:data];
    
    prgo=(DWNBondRowGameObject*)gameObject;
    
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
        DWNBondObjectGameObject *removeO=[payload objectForKey:MOUNTED_OBJECT];
        removeO.Mount=nil;
        
        [prgo.MountedObjects removeObject:removeO];
    }

    
    if(messageType==kDWresetPositionEval)
    {
        float myHeldValue=0.0f;
        for(int i=0;i<prgo.MountedObjects.count;i++)
        {
            DWNBondObjectGameObject *mo = [prgo.MountedObjects objectAtIndex:i];
            mo.MovePosition=ccp(prgo.Position.x+(50*myHeldValue), prgo.Position.y);
            mo.Position=mo.MovePosition;
            NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:ANIMATE_ME];
            [mo handleMessage:kDWmoveSpriteToPosition andPayload:pl withLogLevel:-1];
            
            myHeldValue=myHeldValue+mo.Length;
        }

    }
}

@end