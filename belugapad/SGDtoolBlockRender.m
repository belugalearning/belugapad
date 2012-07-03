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

}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)setup
{

    //blockSprite=[CCSprite spriteWithSpriteFrameName:@"node-complete.png"];
    blockSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/distribution/block.png")];
    
    [blockSprite setPosition:ParentGO.Position];
    [blockSprite setVisible:ParentGO.Visible];
    [ParentGO.RenderLayer addChild:blockSprite];
}



@end
