//
//  SGJmapNodeGO.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@class SGJmapNodeRender;

@interface SGJmapNodeGO : SGGameObject <Transform>

@property (retain) SGJmapNodeRender* NodeRenderComponent;

@end
