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
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!cont.mySpriteBot) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!cont.mySpriteBot) { 
            [self setSprite];
        }
        
    }
    if(messageType==kDWupdateLabels)
    {
        if(cont.ScaledUp && cont.myText.visible==NO)[cont.myText setVisible:YES];
        if(cont.ScaledUp)[cont.myText setString:cont.textString];
        else [cont.myText setVisible:NO];
    }
    if(messageType==kDWmoveSpriteToPosition)
    {
        [self moveSprite];
    }
    if(messageType==kDWresetToMountPosition)
    {
        [self moveSpriteHome];
    }
    if(messageType==kDWswitchParentToRenderLayer)
    {
        [cont.BaseNode.parent removeChild:cont.BaseNode cleanup:NO];
        [cont.BaseNode setPosition:[gameWorld.Blackboard.ComponentRenderLayer convertToNodeSpace:cont.Position]];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:cont.BaseNode];
        NSLog(@"this container changed parent (render layer)");
    }
    if(messageType==kDWswitchParentToMovementLayer)
    {
        [cont.BaseNode.parent removeChild:cont.BaseNode cleanup:NO];
        [cont.BaseNode setPosition:[gameWorld.Blackboard.MovementLayer convertToNodeSpace:cont.Position]];
        [gameWorld.Blackboard.MovementLayer addChild:cont.BaseNode];
        NSLog(@"this container changed parent (movement layer)");
    }
    if(messageType==kDWdismantle)
    {
        [[cont.mySpriteTop parent] removeChild:cont.mySpriteTop cleanup:YES];
        [[cont.mySpriteMid parent] removeChild:cont.mySpriteMid cleanup:YES];
        [[cont.mySpriteBot parent] removeChild:cont.mySpriteBot cleanup:YES];    
    } 
    
}



-(void)setSprite
{    
    
    if(!cont.BaseNode){
        cont.BaseNode=[[[CCNode alloc]init] autorelease];
        [cont.BaseNode setPosition:cont.Position];
        if(!cont.ScaledUp)[[gameWorld Blackboard].ComponentRenderLayer addChild:cont.BaseNode z:2];
        else [[gameWorld Blackboard].MovementLayer addChild:cont.BaseNode z:2];
        
    }

    
    
//    spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/container.png"];
    
    NSString *spriteFileNameTop=@"/images/piesplitter/container-t.png";
    NSString *spriteFileNameMid=@"/images/piesplitter/container-m.png";
    NSString *spriteFileNameBot=@"/images/piesplitter/container-b.png";
    
//    cont.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    cont.mySpriteTop=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileNameTop]))];
    cont.mySpriteMid=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileNameMid]))];
    cont.mySpriteBot=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileNameBot]))];
    [cont.mySpriteTop setAnchorPoint:ccp(0.5,-1)];    
    [cont.mySpriteMid setAnchorPoint:ccp(0.5,-1)];
    [cont.mySpriteBot setAnchorPoint:ccp(0.5,-1)];
    if(!cont.ScaledUp)[cont.BaseNode setScale:0.5f];
    else [cont.BaseNode setScale:1.0f];

    //[cont.mySpriteTop setPosition:ccp(0,(cont.mySpriteMid.contentSize.height)-(cont.mySpriteTop.contentSize.height/2))];
    //[cont.mySpriteBot setPosition:ccp(0,0-(cont.mySpriteMid.contentSize.height/2)-(cont.mySpriteTop.contentSize.height/2))];
    
    [cont.mySpriteMid setPosition:ccp(0,-50-(cont.mySpriteTop.contentSize.height))];
    [cont.mySpriteBot setPosition:ccp(0,-(cont.mySpriteTop.contentSize.height+(cont.mySpriteMid.contentSize.height*cont.mySpriteMid.scaleY)))];
    
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [cont.mySpriteTop setTag:1];
            [cont.mySpriteMid setTag:1];
            [cont.mySpriteBot setTag:1];
            [cont.mySpriteTop setOpacity:0];
            [cont.mySpriteMid setOpacity:0];
            [cont.mySpriteBot setOpacity:0];
        }
    
    
    [cont.BaseNode addChild:cont.mySpriteMid];
    [cont.BaseNode addChild:cont.mySpriteTop];
    [cont.BaseNode addChild:cont.mySpriteBot];
    
    if(!cont.myText && cont.ScaledUp)
    {
        cont.myText=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:PROBLEM_DESC_FONT_SIZE];
        [cont.myText setPosition:ccp(50,40)];
        [cont.mySpriteTop addChild:cont.myText];
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [cont.myText setTag:1];
            [cont.myText setOpacity:0];
        }
    }
//        [cont.BaseNode addChild:cont.mySprite];
    
}
-(void)moveSprite
{
    if(!cont.ScaledUp){
        
        [cont.BaseNode runAction:[CCScaleTo actionWithDuration:0.2f scale:1.0f]];

        cont.ScaledUp=YES;
    }
    [cont.BaseNode setPosition:cont.Position];
}
-(void)moveSpriteHome
{
    if(cont.ScaledUp){
        [cont.BaseNode runAction:[CCScaleTo actionWithDuration:0.2f scale:0.5f]];
      
        cont.ScaledUp=NO;
    }
    [cont.BaseNode runAction:[CCMoveTo actionWithDuration:0.5f position:cont.MountPosition]];
}
-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end
