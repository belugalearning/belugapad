//
//  TimesTableMenu.h
//  belugapad
//
//  Created by David Amphlett on 27/02/2013.
//
//

#import "cocos2d.h"
#import "AppDelegate.h"
#import <Foundation/Foundation.h>

@interface TimesTableMenu : CCLayer {
    CGPoint winL;
    float cx;
    float cy;
    float lx;
    float ly;
    
    CCLayer *renderLayer;
    
    NSString *gameState;
    
    NSMutableArray *sceneButtons;
    NSMutableArray *sceneButtonPositions;
    NSMutableArray *sceneButtonMedals;
    int lastZIndex;
    
    CCSprite *currentSelection;
    CCSprite *totalTab;
    int currentSelectionIndex;
    
    NSMutableArray *currentSelectionButtons;
    AppController *ac;
    
    BOOL RandomPipeline;
    BOOL ChallengePipeline;
    BOOL CountdownToPipeline;
    float CountdownToPipelineTime;
    BOOL ChallengeReturnFromPipeline;
    BOOL IsCountingDownChallengeScore;
    BOOL ReturnChallengeOrRandom;
    float ReturnChallengeRandomCountdown;
    
    float challengeCounter;
    float challengeDecrementer;
    float challengesLeft;
    CCLabelTTF *challengeLabel;
    CCLabelTTF *totalPercentage;
    

}
+(CCScene *) scene;
-(void)populateMenu;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;


@end
