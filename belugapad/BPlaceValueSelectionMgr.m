//
//  BPlaceValueSelectionMgr.m
//  belugapad
//
//  Created by David Amphlett on 13/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueSelectionMgr.h"
#import "global.h"

@implementation BPlaceValueSelectionMgr
-(BPlaceValueSelectionMgr*)initWithGameObject:(DWGameObject *)aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueSelectionMgr *)[super initWithGameObject:aGameObject withData:data];
    return self;
}
-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWswitchSelection)
    {
        [self switchSelection];
    }
    
}

-(void)switchSelection
{
    NSNumber *isSelected = [[gameObject store] objectForKey:SELECTED];

    if(!isSelected)
    {
        DLog(@"no isselected value");
        isSelected = [NSNumber numberWithBool:NO]; 
    }
    
    if([isSelected boolValue])
    {
        [[gameObject store] setObject:[NSNumber numberWithBool:NO] forKey:SELECTED];
    }
    else
    {
        [[gameObject store] setObject:[NSNumber numberWithBool:YES] forKey:SELECTED];       
    }
    
    [gameObject handleMessage:kDWupdateSprite];
}

@end
