//
//  NumberLine.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface NumberLine : CCLayer
{
    float cx;
    float cy;
    
    CCLayer *scrollLayer;
    CCLayer *priScaleLayer;
    CCLayer *bkgScaleLayer;
    CCLayer *foreScaleLayer;
    
    BOOL isDragging;
    float dragVel;
    float dragLastX;
    
    NSMutableArray *priScaleFwd;
    NSMutableArray *priScaleBack;
    
    CCSprite *zeroMarker;
    
    CCLabelBMFont *debugLabel;
    
    float scale;
    
    float posUpdate;
    
}

+(CCScene *) scene;

-(void)setupBkgAndTitle;
-(void)setupScrollLayer;
-(void)setupPriScaleLayer;


@end
