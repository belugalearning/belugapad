//
//  DotGrid.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"

typedef enum {
    kAnyStartAnchorValid=0,
    kSpecifiedStartAnchor=1
} DrawMode;

typedef enum {
    kNoState=0,
    kStartAnchor=1,
    kCollectAnchors=2,
    kDrawnShape=3
} GameState;

@interface DotGrid : ToolScene
{
    ToolHost *toolHost;
    DWGameWorld *gw;
    
    DrawMode drawMode;
    GameState gameState;

    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    BOOL isTouching;
    
    CCLayer *renderLayer;
    
    NSArray *initObjects;
    NSArray *solutionsDef;
    
    CGPoint lastTouch;
    
    ProblemRejectMode rejectMode;
    ProblemEvalMode evalMode;
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    int spaceBetweenAnchors;
    int startX;
    int startY;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;

@end
