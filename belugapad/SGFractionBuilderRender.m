//
//  SGDtoolBlockRender.m
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGFractionBuilderRender.h"
#import "SGFractionObject.h"
#import "BLMath.h"

@interface SGFractionBuilderRender()
{
    CCSprite *fractionSprite;
    CCSprite *sliderSprite;
    CCSprite *sliderMarkerSprite;
}

@end

@implementation SGFractionBuilderRender

-(SGFractionBuilderRender*)initWithGameObject:(id<Configurable, Interactive>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)setup
{
    
    //blockSprite=[CCSprite spriteWithSpriteFrameName:@"node-complete.png"];
    fractionSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/distribution/block.png")];
    ParentGO.FractionSprite=fractionSprite;
    [fractionSprite setPosition:ParentGO.Position];
    [ParentGO.RenderLayer addChild:fractionSprite];
}

@end
