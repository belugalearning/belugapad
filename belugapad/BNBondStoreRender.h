//
//  BFloatRender.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWNBondStoreGameObject;

@interface BNBondStoreRender : DWBehaviour
{
    
    BOOL amPickedUp;
    DWNBondStoreGameObject *pogo;
    
}

-(BNBondStoreRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(BOOL) withAnimation;
-(void)resetSpriteToMount;

@end
