//
//  SGJmapMNodeRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"
#import "SGJmapObjectProtocols.h"

//const int shadowSteps=10;

@class SGJmapMasteryNode;

@interface SGJmapMasteryNodeRender : SGComponent
{
    SGJmapMasteryNode *ParentGO;
    
    NSMutableArray *sortedChildren;
    
    CGPoint *allPerimPoints;
    CGPoint *scaledPerimPoints;
    NSMutableArray *texturePoints;
    
    ccColor4B stepColours[10];
    
    BOOL zoomedOut;
    BOOL needToTransition;
    
    ccColor4B currentCol;
    
    CCSprite *islandSprite;
    CCSprite *islandShadowSprite;
    
    CCSprite *oldNodeSprite;
    
    NSMutableArray *featureSprites;
    
    NSMutableDictionary *islandData;
}

@property (readonly) SGJmapMasteryNode *ParentGO;
@property (readonly) NSMutableArray *sortedChildren;
@property CGPoint *allPerimPoints;
@property CGPoint *scaledPerimPoints;
@property BOOL zoomedOut;
@property int islandShapeIdx;
@property int islandLayoutIdx;
@property int islandStage;
@property (retain) NSMutableArray *indexedBaseNodes;

@property int previousIslandStage;

-(void)draw:(int)z;
-(void)setup;

@end


@interface MasteryDrawNode : CCLayer
{
    SGJmapMasteryNodeRender *renderParent;
}

-(MasteryDrawNode*)initWithParent:(SGJmapMasteryNodeRender*)masteryNodeRender;

@end