//
//  BPlaceValueObjectSpawn.m
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueObjectSpawn.h"
#import "global.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueBlockGameObject.h"

@implementation BPlaceValueObjectSpawn
-(BPlaceValueObjectSpawn *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueObjectSpawn*)[super initWithGameObject:aGameObject withData:data];
    c=(DWPlaceValueCageGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        [self spawnObject];
    }
    if(messageType==kDWunsetMountedObject)
    {
        [self spawnObject];
    }
    
}

-(void)spawnObject
{
    if(c.MountedObject)return;
    if(c.DisableAdd && c.ObjectValue>0)return;
    if(c.DisableAddNeg && c.ObjectValue<0)return;
    
    DWPlaceValueBlockGameObject *block = [DWPlaceValueBlockGameObject alloc];
    [gameWorld populateAndAddGameObject:block withTemplateName:@"TplaceValueObject"];

    block.ObjectValue=c.ObjectValue;
    block.SpriteFilename=c.SpriteFilename;
    block.PosX=c.PosX;
    block.PosY=c.PosY+20;
    
    block.PickupSprite=c.PickupSpriteFilename;

    block.Mount=gameObject;
    c.MountedObject=block;
    
    [block handleMessage:kDWsetupStuff];

    [block release];
    
}


@end
