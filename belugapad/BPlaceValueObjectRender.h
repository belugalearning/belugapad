//
//  BFloatRender.h
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPlaceValueBlockGameObject;

@interface BPlaceValueObjectRender : DWBehaviour
{
    
    DWPlaceValueBlockGameObject *b;
    BOOL amPickedUp;
    
}

-(BPlaceValueObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePosWithAnimation;
-(void)resetSpriteToMount;
-(void)resetSpriteToMountAndDestroy;
-(void)switchSelection:(BOOL)isSelected;
-(void)switchBaseSelection:(BOOL)isSelected;

@end
