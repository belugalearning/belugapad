//
//  BObjectRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@interface BObjectRender : DWBehaviour
{

    CCSprite *mySprite;
}

-(BObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(NSDictionary *)position;


@end
