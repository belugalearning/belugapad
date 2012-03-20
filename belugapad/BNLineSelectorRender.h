//
//  BNLineSelectorRender.h
//  belugapad
//
//  Created by Dave Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWSelectorGameObject;

@interface BNLineSelectorRender : DWBehaviour
{
    DWSelectorGameObject *selector;
    CCSprite *mySprite;
    CCSprite *connectorSprite;
    CCSprite *selectionLabel;
}

-(BNLineSelectorRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;

@end



