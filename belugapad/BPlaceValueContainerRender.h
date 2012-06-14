//
//  BContainerRender.h
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPlaceValueNetGameObject;

@interface BPlaceValueContainerRender : DWBehaviour
{
    DWPlaceValueNetGameObject *n;
    CCSprite *mySprite;
}

-(BPlaceValueContainerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;

@end
