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
    
    //NSDictionary *pl = [NSDictionary dictionaryWithObject:gameObject forKey:MOUNT];

    [[block store] setObject:[[gameObject store] objectForKey:OBJECT_VALUE] forKey:OBJECT_VALUE];
    [[block store] setObject:[[gameObject store] objectForKey:SPRITE_FILENAME] forKey:SPRITE_FILENAME];
    
    NSMutableDictionary *pl = [[NSMutableDictionary alloc] init];
    [pl setObject:gameObject forKey:MOUNT];
    
    DLog(@"do we have object value %@", [[gameObject store] objectForKey:OBJECT_VALUE]);
    DLog(@"do we have sprite fname %@", [[gameObject store] objectForKey:SPRITE_FILENAME]);
    
//    if([[gameObject store] objectForKey:SPRITE_FILENAME])
//    {
//        
//    }
    
    [block handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
}


@end
