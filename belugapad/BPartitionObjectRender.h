//
//  BFloatRender.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPartitionRowGameObject;
@class DWPartitionStoreGameObject;
@class DWPartitionObjectGameObject;

@interface BPartitionObjectRender : DWBehaviour
{
    
    BOOL amPickedUp;
    DWPartitionObjectGameObject *pogo;
    
}

-(BPartitionObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(BOOL) withAnimation;
-(void)moveSpriteHome;
-(void)resetSpriteToMount;
-(void)resetHalfScale;

@end
