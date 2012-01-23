//
//  IceDiv.h
//  belugapad
//
//  Created by Gareth Jenkins on 22/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "cocos2d.h"

@interface IceDiv : CCLayer
{
    float cx;
    float cy;
    
    CCParticleSystemQuad *particle;
    
    BOOL touching;
    float fireTime;
    
    CGPoint tDown;
    CGPoint tUp;
    CGPoint tMin;
    CGPoint tMax;

    CCLabelTTF *fractionLabel;
}

+(CCScene *) scene;

-(void) setupBkgAndTitle;
-(void) setupParticle;
-(void) evalSwipe;
-(void) doUpdate:(ccTime)delta;
-(void)showFractionFoundLabel:(NSString *)frac;

@end
