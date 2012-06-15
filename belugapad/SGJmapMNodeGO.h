//
//  SGJmapMNodeGO.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@class SGJmapMNodeRender;

@interface SGJmapMNodeGO : SGGameObject <Transform>

@property (retain) SGJmapMNodeRender* MNodeRenderComponent;

@end
