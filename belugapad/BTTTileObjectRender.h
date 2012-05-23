//
//  BTTTileObjectRender.h
//  belugapad
//
//  Created by Dave Amphlett on 17/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWTTTileGameObject;

@interface BTTTileObjectRender : DWBehaviour
{
    DWTTTileGameObject *tile;
}

-(BTTTileObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)handleTap;


@end
