//
//  TimesTableMenu.h
//  belugapad
//
//  Created by David Amphlett on 27/02/2013.
//
//

#import "cocos2d.h"
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
    int lastZIndex;
    
    CCSprite *currentSelection;
    int currentSelectionIndex;
    
    NSMutableArray *currentSelectionButtons;
    

}
+(CCScene *) scene;
-(void)populateMenu;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;


@end
