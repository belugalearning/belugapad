//
//  BlockFloating.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "chipmunk.h"
#import "DWGameWorld.h"
#import "DWGameObject.h"

@interface BlockFloating : CCLayer
{
    float cx;
    float cy;
    
    DWGameWorld *gameWorld;
    
    BOOL touching;
    
    cpSpace *space;
    
    CCLabelTTF *problemDescLabel;
    NSArray *solutionsDef;
    CCLabelTTF *problemCompleteLabel;
    
    NSArray *problemFiles;
    int currentProblemIndex;
    
    NSArray *tutorials;
    BOOL doTutorials;
    int tutorialPos;
    CCLayer *ghostLayer;
    float timeToNextTutorial;
}

+(CCScene *) scene;

-(void) setupBkgAndTitle;
-(void) setupAudio;
-(void) setupSprites;
-(void) setupGW;
-(void) populateGW;
-(void) populateGWHard;
-(void)setupChSpace;
-(void) doUpdate:(ccTime)delta;
-(void) attachBodyToGO:(DWGameObject *)attachGO atPositionPayload:(NSDictionary *)positionPayload;

-(void)spawnObjects:(NSDictionary*)objects;

-(void)createObjectWithCols:(int)cols andRows:(int)rows andTag:(NSString*)tag;
-(void)createContainerWithPos:(CGPoint)pos andData:(NSDictionary*)containerData;

-(void)listProblemFiles;
-(void) resetToNextProblem;

// both abstracted (i.e. from gw implementation) but fixed to this tool's current problem load -- hence effectively a single-problem evaluation prototype of abstracted (from gw) evaluation
-(void)evalCompletion:(ccTime)delta;
-(float)getEvaluatedValueForItemTag: (NSString *)itemContainerTag andItemValue:(NSNumber*)itemValue andValueRequiredIsSize:(BOOL)valIsSize;

-(int)evalClauses:(NSDictionary*)clauses;

-(void)clearGhost;
-(void)showGhostOf:(NSString *)ghostObjectTag to:(NSString *)ghostDestinationTag;
-(CCSprite *)ghostCopySprite:(CCSprite*)spriteSource;
-(void)updateTutorials:(ccTime)delta;

@end
