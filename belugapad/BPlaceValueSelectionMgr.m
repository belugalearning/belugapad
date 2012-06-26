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
#import "ToolScene.h"
#import "UsersService.h"
#import "AppDelegate.h"
#import "DWPlaceValueBlockGameObject.h"

@interface BPlaceValueSelectionMgr()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPlaceValueSelectionMgr
-(BPlaceValueSelectionMgr*)initWithGameObject:(DWGameObject *)aGameObject withData:(NSDictionary *)data
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
    self=(BPlaceValueSelectionMgr *)[super initWithGameObject:aGameObject withData:data];
    
    b=(DWPlaceValueBlockGameObject*)gameObject;
    
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
        float myV=b.ObjectValue;
        float theirV=[[payload objectForKey:OBJECT_VALUE] floatValue];
        if(myV!=theirV)
        {
            [self deselect];
        }
    }
    
}

-(void)switchSelection
{
    if(b.Selected)
    {
        [usersService logProblemAttemptEvent:kProblemAttemptPlaceValueTouchBeginDeselectObject withOptionalNote:nil];
        b.Selected=NO;
        [gameWorld.Blackboard.SelectedObjects removeObject:gameObject];
        [[gameWorld GameScene] problemStateChanged];
    }
    else
    {
       [usersService logProblemAttemptEvent:kProblemAttemptPlaceValueTouchBeginSelectObject withOptionalNote:nil];
        b.Selected=YES;
        gameWorld.Blackboard.LastSelectedObject = gameObject;
        [gameWorld.Blackboard.SelectedObjects addObject:gameObject];
        [[gameWorld GameScene] problemStateChanged];
        
        //force deselect of other objects that don't have this value
        float myV=b.ObjectValue;
        NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:myV] forKey:OBJECT_VALUE];
        [gameWorld handleMessage:kDWdeselectIfNotThisValue andPayload:pl withLogLevel:0];
    }
    
    [gameObject handleMessage:kDWupdateSprite];
}

-(void)deselect
{    
    
    if(b.Selected)
    {
        b.Selected=NO;
        [gameWorld.Blackboard.SelectedObjects removeObject:gameObject];
        [[gameWorld GameScene] problemStateChanged];
    }
    [gameObject handleMessage:kDWupdateSprite];
}
@end
