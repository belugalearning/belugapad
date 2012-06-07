//
//  BPieSplitterSliceMount.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceMount.h"
#import "global.h"
#import "SimpleAudioEngine.h"

@implementation BPieSplitterSliceMount

-(BPieSplitterSliceMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterSliceMount*)[super initWithGameObject:aGameObject withData:data];
    
    NSMutableArray *mo=[[NSMutableArray alloc] init];
    GOS_SET(mo, MOUNTED_OBJECTS);
    [mo release];
    
    return self;
}
-(void)doUpdate:(ccTime)delta
{

}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
    }
    
    if(messageType==kDWunsetMountedObject)
    {

    }
    if(messageType==kDWresetPositionEval)
    {

    }
}

@end
