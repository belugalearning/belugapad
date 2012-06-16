//
//  SGJmapMNodeGO.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@class SGJmapMasteryNodeRender;

@interface SGJmapMasteryNode : SGGameObject <Transform>

@property (retain) SGJmapMasteryNodeRender* MNodeRenderComponent;

-(SGJmapMasteryNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition;

@end
