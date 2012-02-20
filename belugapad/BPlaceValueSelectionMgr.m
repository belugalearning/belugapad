//
//  BPlaceValueSelectionMgr.m
//  belugapad
//
//  Created by David Amphlett on 13/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueSelectionMgr.h"
#import "global.h"
#import "PlaceValue.h"

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
    if(messageType==kDWdeselectAll)
    {
        [self deselect];
    }
    if(messageType==kDWswitchBaseSelection)
    {
        //[self switchBaseSelection];
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
        [gameWorld.Blackboard.SelectedObjects removeObject:gameObject];
    }
    else
    {
        [[gameObject store] setObject:[NSNumber numberWithBool:YES] forKey:SELECTED]; 
        gameWorld.Blackboard.LastSelectedObject = gameObject;
        [gameWorld.Blackboard.SelectedObjects addObject:gameObject];
    }
    
    [gameObject handleMessage:kDWupdateSprite];
    [[gameWorld GameScene] problemStateChanged];
}

-(void)deselect
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
        [gameWorld.Blackboard.SelectedObjects removeObject:gameObject];

    }
    [gameObject handleMessage:kDWupdateSprite];
    
    [[gameWorld GameScene] problemStateChanged];
}
@end
