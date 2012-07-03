//
//  SGDtoolBlockRender.m
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGDtoolBlockRender.h"
#import "SGDtoolBlock.h"

@interface SGDtoolBlockRender()
{
    CCSprite *blockSprite;
}

@end

@implementation SGDtoolBlockRender

-(SGDtoolBlockRender*)initWithGameObject:(id<Transform>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kSGvisibilityChanged)
    {
        blockSprite.visible=ParentGO.Visible;
    }
    
    if(messageType==kSGzoomOut)
    {
        [blockSprite setVisible:YES];
        [blockSprite setOpacity:50];
    }
    if(messageType==kSGzoomIn)
    {
        [blockSprite setOpacity:255];
    }
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)draw:(int)z
{
    //    CGPoint lp=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
    //    
    //    //glLineWidth(6.0f);
    //    ccDrawColor4B(255, 255, 255, 50);
    //    ccDrawLine(lp, ccpAdd(lp, ccp(100,100)));
    
}

-(void)setup
{

    //blockSprite=[CCSprite spriteWithSpriteFrameName:@"node-complete.png"];
    blockSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/distribution/block.png")];
    
    [blockSprite setPosition:ParentGO.Position];
    [blockSprite setVisible:ParentGO.Visible];
    [ParentGO.RenderBatch addChild:blockSprite];
}



@end
