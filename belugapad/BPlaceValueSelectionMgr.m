//
//  BPlaceValueSelectionMgr.m
//  belugapad
//
//  Created by David Amphlett on 13/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueSelectionMgr.h"
#import "global.h"
#import "LoggingService.h"
#import "PlaceValue.h"
#import "ToolScene.h"
#import "UsersService.h"
#import "AppDelegate.h"

@interface BPlaceValueSelectionMgr()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPlaceValueSelectionMgr
-(BPlaceValueSelectionMgr*)initWithGameObject:(DWGameObject *)aGameObject withData:(NSDictionary *)data
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    loggingService = ac.loggingService;
    contentService = ac.contentService;
    usersService = ac.usersService;
    
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
    if(messageType==kDWdeselectIfNotThisValue)
    {
        float myV=[[[gameObject store] objectForKey:OBJECT_VALUE] floatValue];
        float theirV=[[payload objectForKey:OBJECT_VALUE] floatValue];
        if(myV!=theirV)
        {
            [self deselect];
        }
    }
    
}

-(void)switchSelection
{
    NSNumber *isSelected = [[gameObject store] objectForKey:SELECTED];
    
    if(!isSelected)
    {
        isSelected = [NSNumber numberWithBool:NO]; 
    }
    
    if([isSelected boolValue])
    {
        [loggingService logEvent:BL_PA_PV_TOUCH_BEGIN_DESELECT_OBJECT withAdditionalData:nil];
        [[gameObject store] setObject:[NSNumber numberWithBool:NO] forKey:SELECTED];
        [gameWorld.Blackboard.SelectedObjects removeObject:gameObject];
        [[gameWorld GameScene] problemStateChanged];
    }
    else
    {
        [loggingService logEvent:BL_PA_PV_TOUCH_BEGIN_SELECT_OBJECT withAdditionalData:nil];
        [[gameObject store] setObject:[NSNumber numberWithBool:YES] forKey:SELECTED]; 
        gameWorld.Blackboard.LastSelectedObject = gameObject;
        [gameWorld.Blackboard.SelectedObjects addObject:gameObject];
        [[gameWorld GameScene] problemStateChanged];
        
        //force deselect of other objects that don't have this value
        float myV=[[[gameObject store] objectForKey:OBJECT_VALUE] floatValue];
        NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:myV] forKey:OBJECT_VALUE];
        [gameWorld handleMessage:kDWdeselectIfNotThisValue andPayload:pl withLogLevel:0];
    }
    
    [gameObject handleMessage:kDWupdateSprite];
}

-(void)deselect
{
    NSNumber *isSelected = [[gameObject store] objectForKey:SELECTED];
    
    if(!isSelected)
    {
        isSelected = [NSNumber numberWithBool:NO]; 
    }
    
    if([isSelected boolValue])
    {
        [[gameObject store] setObject:[NSNumber numberWithBool:NO] forKey:SELECTED];
        [gameWorld.Blackboard.SelectedObjects removeObject:gameObject];
        [[gameWorld GameScene] problemStateChanged];
    }
    [gameObject handleMessage:kDWupdateSprite];
}
@end
