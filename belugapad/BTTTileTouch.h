//
//  BDotGridAnchorTouch.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWTTTileGameObject;

@interface BTTTileTouch : DWBehaviour
{
    
    DWTTTileGameObject *tile;
    
}

-(BTTTileTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)checkTouch:(CGPoint)hitLoc;

@end
