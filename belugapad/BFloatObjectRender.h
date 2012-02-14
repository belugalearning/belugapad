//
//  BFloatRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
#import "chipmunk.h"


@interface BFloatObjectRender : DWBehaviour
{
    
    BOOL amPickedUp;
    cpBody *physBody;
    
    BOOL physDetached;
    
}

-(BFloatObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(NSDictionary *)position;
-(CGPoint)avgPosForFloatObject:(DWGameObject *)go;
-(void)addMeTo:(DWGameObject*)targetGo;
-(void)subtractMeFrom:(DWGameObject*)targetGo;

@end
