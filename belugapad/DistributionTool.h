//
//  DistributionTool.h
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "ToolConsts.h"
#import "ToolScene.h"
#import "SGDtoolObjectProtocols.h"
#import "NumberLayout.h"

typedef enum 
{
    kCheckShapeSizes=0,
    kCheckTaggedGroups=1,
    kCheckEvalAreas=2,
    kCheckGroupTypeAndNumber=3,
    kIncludeShapeSizes=4,
    kCheckEvalAreasForTypes=5,
    kCheckGroupsForTypes=6,
    kCheckContainerValues=7,
    kCheckEvalAreaValues=8,
    kCheckSelectedGroupEvalTarget=9
}DistributionEvalType;

@interface DistributionTool : ToolScene
{
    // required toolhost stuff
    ToolHost *toolHost;
    
    // standard Problem Definition stuff
    ProblemEvalMode evalMode;
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    DistributionEvalType evalType;
    float timeSinceInteraction;
    
    // default positional bits
    CGPoint winL;
    float cx, cy, lx, ly;
    
    // common touch interactions
    BOOL isTouching;
    CGPoint lastTouch;
    CGPoint touchStart;
    
    // standard to move between problems
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    BOOL hasMovedBlock;
    BOOL hasLoggedMovedBlock;
    BOOL hasBeenProximate;
    BOOL problemHasCage;
    BOOL hasInactiveArea;
    BOOL spawnedNewObj;
    BOOL randomiseDockPositions;
    BOOL bondDifferentTypes;
    BOOL hasMovedCagedBlock;
    BOOL bondAllObjects;
    BOOL showTotalValue;
    BOOL hasPlayedAudioCantBondOverMax;
    BOOL foundFirstNearestObject;
    int cageObjectCount;
    
    BOOL problemHasMQ;
    
    id lastContainer;
    CGPoint lastProxPos;
    id nearestObject;
    float nearestObjectDistance;
    id lastNewBondObject;
    
    NSString *dockType;
    
    CCLabelTTF *totalValueLabel;
    
    // and a default layer
    CCLayer *renderLayer;
    
    // and stuff we want to add!
    NSArray *initObjects;
    NSArray *initAreas;
    NSArray *solutionsDef;
    NSMutableArray *existingGroups;
    NSMutableArray *destroyedLabelledGroups;
    NSMutableArray *usedShapeTypes;
    NSMutableArray *addedCages;
    NSMutableArray *evalAreas;
    NSMutableArray *inactiveArea;
    NSMutableArray *activeRects;
    CGRect inactiveRect;
    CCDrawNode *drawNode;
}

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef;
-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)drawConnections;
-(void)createEvalAreas;
-(NSArray*)evalUniqueShapes;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;
-(void)createShapeWith:(int)blocks andWith:(NSDictionary*)theseSettings;
-(void)addDestroyedLabel:(NSString*)thisGroup;
-(void)createContainerWithOne:(id)Object;
-(void)removeBlockByCage;
-(BOOL)evalGroupTypesAndShapes;
-(BOOL)evalNumberOfShapesInEvalAreas;
-(CGPoint)returnNextMountPointForThisShape:(id<ShapeContainer>)thisShape;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)dealloc;

@end
