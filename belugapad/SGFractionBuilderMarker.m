//
//  SGFractionBuilderMarker.m
//  belugapad
//
//  Created by David Amphlett on 23/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGFractionBuilderMarker.h"
#import "SGFbuilderFraction.h"
#import "BLMath.h"
#import "ToolConsts.h"

@interface SGFractionBuilderMarker()
{
    CCSprite *sliderSprite;
    CCSprite *sliderMarkerSprite;
    CCSprite *fractionSprite;
    int markerPosition;
}

@end

@implementation SGFractionBuilderMarker

-(SGFractionBuilderMarker*)initWithGameObject:(id<Configurable, Moveable, Interactive>)aGameObject
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
    if(!fractionSprite)fractionSprite=ParentGO.FractionSprite;
    
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
    float halfOfSlider=(fractionSprite.contentSize.width)/2;
    
    // set out the bounds of the marker 
    float furthestLeft=sliderSprite.position.x-halfOfSlider;
    float furthestRight=sliderSprite.position.x+halfOfSlider;
    
    // if the marker's still in the bounds - move it
    if((location.x>=furthestLeft&&location.x<=furthestRight))
    {
        [sliderMarkerSprite setPosition:ccp(location.x, sliderMarkerSprite.position.y)];
        
        // the 0 number position
        float markerZeroPosition=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
        
        // the size of each section on the slider
        float eachSection=fractionSprite.contentSize.width/kNumbersAlongFractionSlider;
        
        // work out how far we are along the line
        float distAlongLine=[BLMath DistanceBetween:ccp(markerZeroPosition,0) and:ccp(sliderMarkerSprite.position.x,0)];
        
        // find out the exact position and work out our remainder
        float exactPos=distAlongLine/eachSection;
        float remainder=exactPos-(int)exactPos;
        
        // then either round up or down
        if(remainder>=0.5f)
            markerPosition=(int)exactPos+1;
        else
            markerPosition=(int)exactPos;
        
        // and flip the values (ie - right to left 0-20)
        //markerPosition=fabsf(markerPosition-kNumbersAlongFractionSlider);
        
        NSLog(@"marker position %d", markerPosition);
        
        ParentGO.MarkerPosition=markerPosition;
        
        if(ParentGO.ShowCurrentFraction)
        {
            if(ParentGO.MarkerPosition>1)
                [ParentGO.CurrentFraction setString:[NSString stringWithFormat:@"/%d", markerPosition+1]];
            else
                [ParentGO.CurrentFraction setString:@""];
        }
    }
}

-(void)snapToNearestPos
{
    float markerZeroPosition=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
    float markerCurPosition=markerZeroPosition+((fractionSprite.contentSize.width/kNumbersAlongFractionSlider)*ParentGO.MarkerPosition);
    
    [sliderMarkerSprite runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(markerCurPosition,sliderMarkerSprite.position.y)]];
    
    //[sliderMarkerSprite setPosition:ccp(markerStartPosition,-80)];
}


@end
