//
//  SGJmapRegion.h
//  belugapad
//
//  Created by Gareth Jenkins on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@class SGJmapRegionRender;

@interface SGJmapRegion : SGGameObject <Transform, Drawing>

@property (retain) SGJmapRegionRender *RegionRenderComponent;

-(SGJmapRegion*) initWithGameWorld:(SGGameWorld*)aGameWorld andPosition:(CGPoint)aPosition;

@end
