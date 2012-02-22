//
//  BMount.m
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BMount.h"
#import "global.h"
#import "SimpleAudioEngine.h"

@implementation BMount

-(BMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BMount*)[super initWithGameObject:aGameObject withData:data];
    
    NSMutableArray *mo=[[NSMutableArray alloc] init];
    GOS_SET(mo, MOUNTED_OBJECTS);
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        //set the mount for the GO
        NSMutableArray *mo=GOS_GET(MOUNTED_OBJECTS);
        
        DWGameObject *addO=[payload objectForKey:MOUNTED_OBJECT];
        [mo addObject:addO];
        
    }
    
    if(messageType==kDWunsetMountedObject)
    {
        NSMutableArray *mo=GOS_GET(MOUNTED_OBJECTS);
        
        [mo removeObject:[payload objectForKey:MOUNTED_OBJECT]];
    }
    
    if(messageType==kDWpurgeMatchSolutions)
    {
        [[gameObject store] removeObjectForKey:MATCHES_IN_SOLUTIONS];
    }
    
    if(messageType==kDWejectContents)
    {
        NSMutableArray *mo=[[gameObject store] objectForKey:MOUNTED_OBJECTS];
        for (DWGameObject *m in mo) {
            //audio cue (generic)
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/thats_not_quite_it.wav")];
                        
            [m handleMessage:kDWunsetMount andPayload:nil withLogLevel:0];
        }
        
        [mo removeAllObjects];
    }
}

@end
