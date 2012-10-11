//
//  RatioTool.h
//  belugapad
//
//  Created by David Amphlett on 11/10/2012.
//
//

#import "cocos2d.h"
#import "ToolConsts.h"
#import "ToolScene.h"


@interface RatioTool : ToolScene
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
    
    
    CCLayer *renderLayer;
    CCSprite *mbox;
    
    int initValueBlue;
    int initValueRed;
    int initValueGreen;
    
    int evalValueBlue;
    int evalValueRed;
    int evalValueGreen;
    
    int recipeBlue;
    int recipeRed;
    int recipeGreen;
    
    CCLabelTTF *amountRed;
    CCLabelTTF *amountGreen;
    CCLabelTTF *amountBlue;
    
    int wheelMax;
}


-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)draw;
-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

-(void)dealloc;

@end
