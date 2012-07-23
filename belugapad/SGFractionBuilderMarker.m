//
//  SGFractionBuilderMarker.m
//  belugapad
//
//  Created by David Amphlett on 23/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGFractionBuilderMarker.h"
#import "SGFractionObject.h"
#import "BLMath.h"

@interface SGFractionBuilderMarker()
{
    CCSprite *sliderSprite;
    CCSprite *sliderMarkerSprite;
}

@end

@implementation SGFractionBuilderMarker

-(SGFractionBuilderMarker*)initWithGameObject:(id<Configurable, Moveable>)aGameObject
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

-(BOOL)amIProximateTo:(CGPoint)location
{
    if(!sliderMarkerSprite)sliderMarkerSprite=ParentGO.SliderMarkerSprite;
    if(!sliderSprite)sliderSprite=ParentGO.SliderSprite;
    location=[ParentGO.BaseNode convertToNodeSpace:location];

    float dist=[BLMath DistanceBetween:sliderMarkerSprite.position and:location];
    
    if(dist<50)
    {
        return YES;
    }
    else {
        return NO;
    }
}

-(void)moveMarkerTo:(CGPoint)location
{
    location=[ParentGO.BaseNode convertToNodeSpace:location];
    float halfOfSlider=(sliderSprite.contentSize.width-40)/2;
    float furthestLeft=sliderSprite.position.x-halfOfSlider;
    float furthestRight=sliderSprite.position.x+halfOfSlider;
    if((location.x>=furthestLeft&&location.x<=furthestRight))
        [sliderMarkerSprite setPosition:ccp(location.x, sliderMarkerSprite.position.y)];
}


@end
