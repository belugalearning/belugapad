//
//  BFloatRender.h
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"


@interface BPlaceValueObjectRender : DWBehaviour
{
    
    BOOL amPickedUp;
    
}

-(BPlaceValueObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(NSDictionary *)position withAnimation:(BOOL) animate;
-(void)resetSpriteToMount;
-(void)switchSelection:(BOOL)isSelected;
-(void)switchBaseSelection:(BOOL)isSelected;

@end
