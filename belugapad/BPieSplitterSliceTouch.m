//
//  BPieSplitterSliceTouch.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceTouch.h"
#import "DWPieSplitterSliceGameObject.h"
#import "DWPieSplitterPieGameObject.h"
#import "global.h"
#import "LoggingService.h"
#import "ToolConsts.h"
#import "ToolHost.h"
#import "BLMath.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BPieSplitterSliceTouch()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPieSplitterSliceTouch

-(BPieSplitterSliceTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterSliceTouch*)[super initWithGameObject:aGameObject withData:data];
    slice=(DWPieSplitterSliceGameObject *)gameObject;
    //init pos x & y in case they're not set elsewhere
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
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
    // if the slice doesn't have a container it can respond to this message
    if(CGRectContainsPoint(slice.mySprite.boundingBox, [slice.mySprite.parent convertToNodeSpace:hitLoc]) && !slice.myCont)
    {
        gameWorld.Blackboard.PickupObject=slice;
    
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
