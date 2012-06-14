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
    DWPlaceValueBlockGameObject *block = [DWPlaceValueBlockGameObject alloc];
    [gameWorld populateAndAddGameObject:block withTemplateName:@"TplaceValueObject"];

    block.ObjectValue=c.ObjectValue;
    block.SpriteFilename=c.SpriteFilename;

    block.PickupSprite=c.PickupSpriteFilename;

    block.Mount=c;

    
    [block handleMessage:kDWsetMount andPayload:nil withLogLevel:0];
}


@end
