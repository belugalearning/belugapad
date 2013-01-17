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

@property (retain) NSMutableArray *MasteryNodes;

@property int RegionNumber;
@property (retain) NSString *Name;

-(SGJmapRegion*) initWithGameWorld:(SGGameWorld*)aGameWorld;

@end
