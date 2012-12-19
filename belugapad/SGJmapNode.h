//
//  SGJmapNodeGO.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"
#import "UserNodeState.h"

@class SGJmapNodeRender;
@class SGJmapMasteryNode;
@class UserNodeState;

@interface SGJmapNode : SGGameObject <Transform, ProximityResponder, Drawing, CouchDerived, Configurable, Selectable, Completable, Searchable, PinRender>

@property (retain) SGJmapNodeRender* NodeRenderComponent;
@property (retain) SGJmapMasteryNode *MasteryNode;
@property (retain) NSMutableArray *PrereqNodes;

@property (retain) UserNodeState *ustate;
@property (retain) UserNodeState *lastustate;

@property (retain) CCSprite *artefactSpriteBase;

-(SGJmapNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition;

-(void)setupArtefactRender;
-(void)flipSprite;

@end

