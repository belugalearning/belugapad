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
    
    ccColor4B currentCol;
    
    CCSprite *islandSprite;
    CCSprite *islandShadowSprite;
    
    NSMutableArray *featureSprites;
    
    NSString *islandName;
    NSMutableDictionary *islandData;
}

@property (readonly) SGJmapMasteryNode *ParentGO;
@property (readonly) NSMutableArray *sortedChildren;
@property CGPoint *allPerimPoints;
@property CGPoint *scaledPerimPoints;
@property BOOL zoomedOut;

-(void)draw:(int)z;
-(void)setup;

@end


@interface MasteryDrawNode : CCLayer
{
    SGJmapMasteryNodeRender *renderParent;
}

-(MasteryDrawNode*)initWithParent:(SGJmapMasteryNodeRender*)masteryNodeRender;

@end