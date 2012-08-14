//
//  CountingTimer.h
//  belugapad
//
//  Created by David Amphlett on 14/08/2012.
//
//

#import "cocos2d.h"
#import "ToolConsts.h"
#import "ToolScene.h"

typedef enum {
    kCountNone=0,
    kCountBeep=1,
    kCountWords=2,
    kCountNumbers=3
} CountType;

@interface CountingTimer : ToolScene
{
    // required toolhost stuff
    ToolHost *toolHost;
    
    // standard Problem Definition stuff
    ProblemEvalMode evalMode;
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    
    // default positional bits
    CGPoint winL;
    CGPoint touchStartPos;
    float cx, cy, lx, ly;
    
    // common touch interactions
    BOOL isTouching;
    CGPoint lastTouch;
    
    // standard to move between problems
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    // and a default layer
    CCLayer *renderLayer;
    
    // pdef options
    float timeElapsed;
    int countMax;
    int countMin;
    int solutionNumber;
    BOOL displayNumicon;
    BOOL showCount;
    CountType countType;
    
    // tool stuff
    CCSprite *buttonOfWin;
    CCLabelTTF *currentNumber;
    int lastNumber;
    
    
}

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef;
-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)draw;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)dealloc;

@end

