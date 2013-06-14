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
//        if(!cont.myText)[self createMyLabel];
//        if(cont.ScaledUp && cont.myText.visible==NO)[cont.myText setVisible:YES];
        if(cont.ScaledUp&&!cont.labelNode.visible)[cont.labelNode setVisible:YES];
//        if(!cont.textString)cont.textString=@"";
//        if(cont.ScaledUp)[cont.myText setString:cont.textString];
//        else [cont.myText setVisible:NO];
        if(!cont.ScaledUp) [cont.labelNode setVisible:NO];
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
        [gameWorld.Blackboard.MovementLayer addChild:cont.BaseNode z:100];
        NSLog(@"this container changed parent (movement layer)");
    }
    if(messageType==kDWdismantle)
    {
        [[cont.mySprite parent] removeChild:cont.mySprite cleanup:YES];
        [cont.BaseNode removeFromParentAndCleanup:YES];
        [cont.labelNode removeFromParentAndCleanup:YES];
//        [[cont.mySpriteMid parent] removeChild:cont.mySpriteMid cleanup:YES];
//        [[cont.mySpriteBot parent] removeChild:cont.mySpriteBot cleanup:YES];
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
    
    if(!cont.labelNode)
    {
        cont.labelNode=[[CCNode alloc]init];
        cont.fractNum=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:10.0f];
        cont.fractDenom=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:10.0f];
        cont.wholeNum=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:14.0f];
        cont.decimalNum=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:14.0f];
        cont.fractLine=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/PS_FractionLine.png")];
        
        [cont.BaseNode addChild:cont.labelNode];
        [cont.labelNode setPosition:ccp(-50,50)];
        [cont.labelNode addChild:cont.decimalNum];
        [cont.labelNode addChild:cont.fractNum];
        [cont.labelNode addChild:cont.fractDenom];
        [cont.labelNode addChild:cont.wholeNum];
        [cont.labelNode addChild:cont.fractLine];
        
        [cont.wholeNum setPosition:ccp(-20.0f,0.0f)];
        [cont.decimalNum setPosition:ccp(-20.0f,0.0f)];
        [cont.fractNum setPosition:ccp(0.0f,10.0f)];
        [cont.fractDenom setPosition:ccp(0.0f,-10.0f)];
        
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [cont.wholeNum setOpacity:0];
            [cont.decimalNum setOpacity:0];
            [cont.fractNum setOpacity:0];
            [cont.fractDenom setOpacity:0];
            [cont.fractLine setOpacity:0];
            
            [cont.wholeNum setTag:3];
            [cont.decimalNum setTag:3];
            [cont.fractNum setTag:3];
            [cont.fractDenom setTag:3];
            [cont.fractLine setTag:3];
        }
        
    }

    
    
//    spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/container.png"];
    
    NSString *spriteFileNameTop=@"/images/piesplitter/big_bubble.png";

    cont.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileNameTop]))];

    if(!cont.ScaledUp)[cont.BaseNode setScale:0.5f];
    else [cont.BaseNode setScale:1.0f];

    
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [cont.mySprite setTag:1];

            [cont.mySprite setOpacity:0];

        }
    
    

    [cont.BaseNode addChild:cont.mySprite];

    
//    if(!cont.myText)
//    {
//        cont.myText=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:20.0f];
//        [cont.myText setPosition:ccp(50,cont.mySprite.contentSize.height+15)];
//        [cont.mySprite addChild:cont.myText];
//        if(gameWorld.Blackboard.inProblemSetup)
//        {
//            [cont.myText setTag:1];
//            [cont.myText setOpacity:0];
//        }
//        if(!cont.ScaledUp)
//        {
//            [cont.myText setVisible:NO];
//        }
//    }
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
    CCCallBlock *destroy=[CCCallBlock actionWithBlock:^{if(cont.BaseNode)[cont.BaseNode removeFromParentAndCleanup:YES]; [gameWorld delayRemoveGameObject:cont];}];
    CCMoveTo *move=[CCMoveTo actionWithDuration:0.5f position:cont.MountPosition];
    CCSequence *seq=[CCSequence actionOne:move two:destroy];
    [cont.BaseNode runAction:move];
}
-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end
