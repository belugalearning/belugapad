//
//  BPlaceValueObjectSpawn.m
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueObjectSpawn.h"
#import "global.h"
#import "DWPlaceValueBlockGameObject.h"

@implementation BPlaceValueObjectSpawn
-(BPlaceValueObjectSpawn *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueObjectSpawn*)[super initWithGameObject:aGameObject withData:data];
    b=(DWPlaceValueBlockGameObject*)gameObject;
    
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

    block.ObjectValue=b.ObjectValue;
    block.SpriteFilename=b.SpriteFilename;
    block.PickupSprite=b.PickupSprite;
    block.Mount=b.Mount;

    
    [block handleMessage:kDWsetMount andPayload:nil withLogLevel:0];
}


@end
