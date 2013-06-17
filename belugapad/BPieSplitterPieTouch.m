//
//  BPieSplitterPieTouch.m
//  belugapad
//
//  Created by David Amphlett on 07/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//


#import "BPieSplitterPieTouch.h"
#import "DWPieSplitterPieGameObject.h"

#import "global.h"
#import "ToolConsts.h"
#import "ToolHost.h"
#import "BLMath.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BPieSplitterPieTouch()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPieSplitterPieTouch

-(BPieSplitterPieTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterPieTouch*)[super initWithGameObject:aGameObject withData:data];
    pie=(DWPieSplitterPieGameObject *)gameObject;
    
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
    if(!pie.Touchable)return;
    
    if(CGRectContainsPoint(pie.mySprite.boundingBox, hitLoc) && !pie.HasSplit)
    {
        gameWorld.Blackboard.PickupObject=gameObject;
    }
   
}

-(void) dealloc
{
    [super dealloc];
}

@end
