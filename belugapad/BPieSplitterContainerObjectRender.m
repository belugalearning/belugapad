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
    if(messageType==kDWupdateLabels)
    {
        if(!cont.myText)
        {
            cont.myText=[CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            [cont.myText setPosition:ccp(50,-20)];
            [cont.mySprite addChild:cont.myText];
        }
        [cont.myText setString:cont.textString];
    }
    if(messageType==kDWmoveSpriteToPosition)
    {
        [self moveSprite];
    }
    if(messageType==kDWresetToMountPosition)
    {
        [self moveSpriteHome];
    }
    if(messageType==kDWdismantle)
    {
        [[cont.mySprite parent] removeChild:cont.mySprite cleanup:YES];
    } 
    
}



-(void)setSprite
{    
    
    NSString *spriteFileName=[[NSString alloc]init];
    
    
    spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/container.png"];
    
    cont.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [cont.mySprite setPosition:cont.Position];
    if(!cont.ScaledUp)[cont.mySprite setScale:0.5f];
    else [cont.mySprite setScale:1.0f];
    
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [cont.mySprite setTag:1];
            [cont.mySprite setOpacity:0];
        }
    
    
    
        [[gameWorld Blackboard].ComponentRenderLayer addChild:cont.mySprite z:2];
    
}
-(void)moveSprite
{
    if(!cont.ScaledUp){
        [cont.mySprite runAction:[CCScaleTo actionWithDuration:0.2f scale:1.0f]];
        cont.ScaledUp=YES;
    }
    [cont.mySprite setPosition:cont.Position];
}
-(void)moveSpriteHome
{
    if(cont.ScaledUp){
        [cont.mySprite runAction:[CCScaleTo actionWithDuration:0.2f scale:0.5f]];
        cont.ScaledUp=NO;
    }
    [cont.mySprite runAction:[CCMoveTo actionWithDuration:0.5f position:cont.MountPosition]];
}
-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end