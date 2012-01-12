//
//  BFloatRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
#import "chipmunk.h"


@interface BFloatRender : DWBehaviour
{
    CCSprite *mySprite;
    
    BOOL amPickedUp;
    cpBody *physBody;
    
}

-(BFloatRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(NSDictionary *)position;

@end
