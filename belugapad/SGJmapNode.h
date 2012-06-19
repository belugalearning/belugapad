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
@class SGJmapMasteryNode;

@interface SGJmapNode : SGGameObject <Transform, ProximityResponder, Drawing, CouchDerived, Configurable, Selectable>

@property (retain) SGJmapNodeRender* NodeRenderComponent;
@property BOOL EnabledAndComplete;
@property (retain) SGJmapMasteryNode *MasteryNode;

-(SGJmapNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition;

@end
