//
//  SGJmapNodeRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapNodeRender.h"

@interface SGJmapNodeRender()
{
    CCSprite *nodeSprite;
}

@end

@implementation SGJmapNodeRender

-(SGJmapNodeRender*)initWithGameObject:(id<Transform>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        
        [self setup];
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
    nodeSprite=[CCSprite spriteWithSpriteFrameName:@"node-incomplete.png"];
    [nodeSprite setPosition:ParentGO.Position];
    [ParentGO.RenderBatch addChild:nodeSprite];
}



@end
