//
//  SGBlackboard.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMap.h"

@class CCLayer;
@class CCSpriteBatchNode;
@class CCDrawNode;

@interface SGBlackboard : NSObject {
 
}

@property (retain) CCLayer *RenderLayer;
@property BOOL inProblemSetup;
@property float MaxObjectDistance;
@property (retain) NSMutableArray *islandData;
@property (retain) CCSpriteBatchNode *btxeIconBatch;

@property (retain) JMap *jmapInstance;

@property (retain) CCDrawNode *debugDrawNode;
@property BOOL playFailedBondOverMax;

@property BOOL disableAllBTXEinteractions;

@end
