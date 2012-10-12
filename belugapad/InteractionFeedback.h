//
//  InteractionFeedback.h
//  belugapad
//
//  Created by Gareth Jenkins on 12/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCAction;

@interface InteractionFeedback : NSObject

+(CCAction*)shakeAction;
+(CCAction*)dropAndBounceAction;
+(CCAction*)stampAction;
+(CCAction*)fadeInOutHoldFor:(float)hold to:(float)to;
+(CCAction*)delaySpinFast;
+(CCAction*)delayMoveOutAndDown;
+(CCAction*)enlargeTo1xAction;
+(CCAction*)reduceTo1xAction;
+(CCAction*)reduceTo0xAndHide;
+(CCAction*)highlightIncreaseAction;
+(CCAction*)fallAndReturn;
+(CCAction*)fadeOutIn;
+(CCAction*)fadeOutInTo:(GLubyte)opacity;
+(CCAction*)scaleOutReturn;

@end
