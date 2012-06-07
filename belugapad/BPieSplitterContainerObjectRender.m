//
//  BPieSplitterContainerObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterContainerObjectRender.h"
#import "DWPieSplitterContainerGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BPieSplitterContainerObjectRender()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPieSplitterContainerObjectRender

-(BPieSplitterContainerObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterContainerObjectRender*)[super initWithGameObject:aGameObject withData:data];
    cont=(DWPieSplitterContainerGameObject*)gameObject;
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
    //init pos x & y in case they're not set elsewhere
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!cont.mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!cont.mySprite) { 
            [self setSprite];
        }
        
    }
    if(messageType==kDWdismantle)
    {
        [[cont.mySprite parent] removeChild:cont.mySprite cleanup:YES];
    } 
    
}



-(void)setSprite
{    
    
    NSString *spriteFileName=[[NSString alloc]init];
    
    
    spriteFileName=[NSString stringWithFormat:@"/images/timestables/container.png"];
    
    cont.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [cont.mySprite setPosition:cont.Position];
    
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [cont.mySprite setTag:1];
            [cont.mySprite setOpacity:0];
        }
    
    
    
        [[gameWorld Blackboard].ComponentRenderLayer addChild:cont.mySprite z:2];
    
}

-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end
