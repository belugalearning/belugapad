//
//  MenuScene.h
//  belugapad
//
//  Created by Gareth Jenkins on 04/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class ContentService;

typedef enum
{
    kMenuStateTopic=0,
    kMenuStateModule=1
} menuState;

@interface MenuScene : CCLayer
{
    menuState MenuState;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    BOOL isTouchDown;
    BOOL isMultiTouchMove;
    
    float touchXMovement;
    float touchYMovement;
    float touchPinchMovement;
    
    int moduleCount;
    int topicCount;
    
    int topicPosition;
    NSMutableArray *modulePositions;
    
    CCLayer *topicLayerBase;
    NSMutableArray *topicLayers;
    
    CCLayer *moduleViewUI;
    
    NSMutableArray *moduleBaseLayers;
    NSMutableArray *moduleLayers;
    
    NSMutableArray *moduleObjects;
    
    NSMutableArray *elementObjects;
    
    float timeSinceTap;
    
    ContentService *contentService;
    
    CCLayer *eMenu;
    
    CCSprite *eMenuLeftOlay;
    CCSprite *eMenuLeftPlayBtn;
    CCSprite *eMenuLeftClock;
    
    CCLabelTTF *eMenuTotExp;
    CCLabelTTF *eMenuTotTime;
    CCLabelTTF *eMenuModName;
    CCLabelTTF *eMenuModDesc;
    CCLabelTTF *eMenuModStatus;
    CCLabelTTF *eMenuModTime;
    CCLabelTTF *eMenuPlayerName;
    
    
    
    CCSprite *selectedElementOverlay;
}

+(CCScene *)scene;

-(void)doUpdate:(ccTime)delta;

-(void)setupBackground;
-(void)setupUI;
-(void)rotateOrbitByLinearX:(float)moveByX;
-(void)moveTopicPositionByLinearY:(float)moveByY;
-(void)pinchMovementBy:(float)pinchBy;
-(void)buildModuleOverlay;
-(void)snapToYSwipe;
-(void)snapToXSwipe;
-(void)snapToModuleView;
-(void)snapToTopicView;
-(void)resetPinch;

-(void)setupMap;
-(void)setAllModuleOpacityTo:(float)newOpacity exceptFor:(CCLayer*)activeModule;

@end
