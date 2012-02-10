//
//  BPlaceValueObjectSpawn.m
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueObjectSpawn.h"
#import "global.h"

@implementation BPlaceValueObjectSpawn
-(BPlaceValueObjectSpawn *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueObjectSpawn*)[super initWithGameObject:aGameObject withData:data];
    
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
    DWGameObject *block = [gameWorld addGameObjectWithTemplate:@"TplaceValueObject"];

    NSDictionary *pl = [NSDictionary dictionaryWithObject:gameObject forKey:MOUNT];
    
    [block handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
}


@end
