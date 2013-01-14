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

@interface SGJmapMasteryNode : SGGameObject <Transform, ProximityResponder, Drawing, CouchDerived, Configurable, Selectable, Completable, Searchable, PinRender>

@property (retain) SGJmapMasteryNodeRender* MNodeRenderComponent;
@property (retain) NSMutableArray *ChildNodes;

@property (retain) NSMutableArray *ConnectToMasteryNodes;
@property (retain) NSMutableArray *ConnectFromMasteryNodes;

@property (retain) NSString *Region;
@property BOOL Disabled;

@property int PrereqCount;
@property int PrereqComplete;
@property float PrereqPercentage;

@property int CompleteCount;
@property float CompletePercentage;

@property CGPoint MasteryPinPosition;

@property int renderLayout;
@property int renderBase;

@property float PreviousPreReqPercentage;

@property (retain, readonly) NSMutableArray *EffectedPathDestinationNodes;

@property bool shouldBouncePins;
@property bool shouldShowPaperPlanes;

-(SGJmapMasteryNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition;

@end
