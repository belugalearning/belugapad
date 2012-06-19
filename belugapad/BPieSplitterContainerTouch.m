//
//  BPieSplitterContainerTouch.m
//  belugapad
//
//  Created by David Amphlett on 07/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//


#import "BPieSplitterContainerTouch.h"
#import "DWPieSplitterContainerGameObject.h"

#import "global.h"
#import "ToolConsts.h"
#import "ToolHost.h"
#import "BLMath.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BPieSplitterContainerTouch()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPieSplitterContainerTouch

-(BPieSplitterContainerTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterContainerTouch*)[super initWithGameObject:aGameObject withData:data];
    cont=(DWPieSplitterContainerGameObject *)gameObject;
    //init pos x & y in case they're not set elsewhere
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWrenderSelection)
    {
        
    }
    
    if(messageType==kDWcanITouchYou)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self checkTouch:loc];
    }
    
    if(messageType==kDWaddMeToSelection)
    {
        
    }
    
}

-(void)checkTouch:(CGPoint)hitLoc
{
    if(CGRectContainsPoint(cont.mySprite.boundingBox, [cont.BaseNode convertToNodeSpace:hitLoc]) && [cont.mySlices count]==0)
    {
        gameWorld.Blackboard.PickupObject=gameObject;
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
