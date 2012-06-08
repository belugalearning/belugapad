//
//  BPieSplitterContainerMountable.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "BPieSplitterContainerMountable.h"

@implementation BPieSplitterContainerMountable


-(BPieSplitterContainerMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
self=(BPieSplitterContainerMountable *)[super initWithGameObject:aGameObject withData:data];

return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMount)
    {
        
        
    }
    
    if(messageType==kDWdismantle)
    {

    }
}

@end
