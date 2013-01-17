//
//  BDotGridTileObjectRender.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWDotGridTileGameObject;

@interface BDotGridTileObjectRender : DWBehaviour
{
    DWDotGridTileGameObject *tile;
}

-(BDotGridTileObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(BOOL) withAnimation;


@end
