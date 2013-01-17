//
//  ToolScene.h
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class ToolHost;
@class CCLayer;

@interface ToolScene : NSObject

@property BOOL ProblemComplete;
@property (retain) CCLayer *BkgLayer;
@property (retain) CCLayer *NoScaleLayer;
@property (retain) CCLayer *ForeLayer;
@property float ScaleMin;
@property float ScaleMax;
@property BOOL PassThruScaling;

-(id)initWithToolHost:(ToolHost*)host andProblemDef:(NSDictionary*)pdef;
-(void)problemStateChanged;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)doUpdateOnSecond:(ccTime)delta;
-(void)doUpdateOnQuarterSecond:(ccTime)delta;
-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)evalProblem;
-(float)metaQuestionTitleXLocation;
-(float)metaQuestionAnswersXLocation;
-(void)handlePassThruScaling:(float)scale;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

-(void)draw;

@end
