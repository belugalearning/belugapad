//
//  SGDtoolBlockRender.m
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGFractionBuilderRender.h"
#import "SGFbuilderFraction.h"
#import "BLMath.h"
#import "ToolConsts.h"


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
    
    ParentGO.FractionSprite=fractionSprite;
    [fractionSprite setPosition:ccp(0,0)];
    [ParentGO.BaseNode addChild:fractionSprite];
    
    
    //if(ParentGO.HasSlider || ParentGO.FractionMode==0){
        
        float markerZeroPosition=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
        float markerStartPosition=markerZeroPosition+((fractionSprite.contentSize.width/kNumbersAlongFractionSlider)*(ParentGO.MarkerStartPosition-1));
        ParentGO.MarkerPosition=ParentGO.MarkerStartPosition-1;
        
        sliderSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/slider.png")];
        sliderMarkerSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/marker.png")];
        ParentGO.SliderSprite=sliderSprite;
        ParentGO.SliderMarkerSprite=sliderMarkerSprite;
        [sliderSprite setPosition:ccp(0,-100)];
        [sliderMarkerSprite setPosition:ccp(markerStartPosition,-80)];    
        [ParentGO.BaseNode addChild:sliderSprite];
        [ParentGO.BaseNode addChild:sliderMarkerSprite];
    //}
    
    [ParentGO.RenderLayer addChild:ParentGO.BaseNode];
}

-(void)showFraction
{
    if(!ParentGO.BaseNode.visible)
    {
        [ParentGO.BaseNode setVisible:YES];
    }
}

-(void)hideFraction
{
    if(ParentGO.BaseNode.visible)
    {
        [ParentGO.BaseNode setVisible:NO];
    }
}


@end
