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

typedef enum 
{
    kCheckShapeSizes=0,
    kCheckNamedGroups=1
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
    
    // standard to move between problems
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    BOOL hasMovedBlock;
    BOOL hasLoggedMovedBlock;
    BOOL hasBeenProximate;
    
    // and a default layer
    CCLayer *renderLayer;
    
    // and stuff we want to add!
    NSArray *initObjects;
    NSArray *solutionsDef;
}

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef;
-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)draw;
-(NSArray*)evalUniqueShapes;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;
-(void)createShapeWith:(int)blocks andWith:(NSDictionary*)theseSettings;
-(void)createContainerWithOne:(id)Object;
-(void)lookForOrphanedObjects;
-(void)updateContainerForNewlyAddedBlock:(id<Moveable,Pairable>)thisBlock;
-(void)tidyUpEmptyGroups;
-(CGPoint)checkWhereIShouldMount:(id<Pairable>)gameObject;
-(CGPoint)findMountPositionForThisShape:(id<Pairable>)pickupObject toThisShape:(id<Pairable>)mountedShape;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)dealloc;

@end
