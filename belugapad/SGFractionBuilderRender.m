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
    [ParentGO.BaseNode setPosition:ParentGO.Position];
    
    //blockSprite=[CCSprite spriteWithSpriteFrameName:@"node-complete.png"];
    fractionSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/fraction.png")];
    sliderSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/slider.png")];
    sliderMarkerSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/marker.png")];
    ParentGO.FractionSprite=fractionSprite;
    ParentGO.SliderSprite=sliderSprite;
    ParentGO.SliderMarkerSprite=sliderMarkerSprite;
    
    [fractionSprite setPosition:ccp(0,0)];
    [sliderSprite setPosition:ccp(0,-100)];
    [sliderMarkerSprite setPosition:ccp(0,-80)];
    
    [ParentGO.BaseNode addChild:fractionSprite];
    [ParentGO.BaseNode addChild:sliderSprite];
    [ParentGO.BaseNode addChild:sliderMarkerSprite];
    
    [ParentGO.RenderLayer addChild:ParentGO.BaseNode];
}


@end
