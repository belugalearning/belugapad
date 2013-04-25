//
//  TTAppUState.h
//  belugapad
//
//  Created by gareth on 03/04/2013.
//
//

#import "AppUState.h"

@class AppController;

@interface TTAppUState : AppUState {
    
    int logRollover;
    BOOL persistSaves;
    BOOL overwriteOnLoad;
    
    NSString *persistPath;
    NSMutableDictionary *udata;
    NSDictionary *prevUdata;
    
    AppController *ac;

    int incorrectBeforePipelinePurge;
}

-(NSString*) getMedalForX:(int)x andY:(int)y;
-(NSString*) getPreviousMedalForX:(int)x andY:(int)y;
-(float) getScoreForX:(int)x andY:(int)y;
-(float) getScoreForX:(int)x;

-(void)setupPipelineFor:(int)pforIndex;

-(int)countOfChallengingQuestions;
-(int)prevCountOfChallengingQuestions;
-(void) fireMedalAchivements;

@end
