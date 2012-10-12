//
//  FractionBuilder.h
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "ToolConsts.h"
#import "ToolScene.h"

typedef enum {
    kSolutionMatch=0,
    kSolutionEquivalents=1,
    kSolutionAddition=2
} SolutionType;

@interface MQDisplay : ToolScene
{
    // required toolhost stuff
    ToolHost *toolHost;
    
     // default positional bits
    CGPoint winL;
    CGPoint touchStartPos;
    float cx, cy, lx, ly;
    
    // and a default layer
    CCLayer *renderLayer;
    float sectionWidth;
    
    NSMutableArray *initVisuals;
    
}

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

-(void)dealloc;

@end
