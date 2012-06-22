//
//  InteractionFeedback.m
//  belugapad
//
//  Created by Gareth Jenkins on 12/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InteractionFeedback.h"
#import "cocos2d.h"

@implementation InteractionFeedback

+(CCAction*)shakeAction
{
    CCEaseInOut *ml1=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.05f position:ccp(-10, 0)] rate:2.0f];
    CCEaseInOut *mr1=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.1f position:ccp(20, 0)] rate:2.0f];
    CCEaseInOut *ml2=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.05f position:ccp(-10, 0)] rate:2.0f];
    CCSequence *s=[CCSequence actions:ml1, mr1, ml2, nil];
    CCRepeat *r=[CCRepeat actionWithAction:s times:4];
    
    CCEaseInOut *oe=[CCEaseInOut actionWithAction:r rate:2.0f];
    
    return oe;
}

+(CCAction*)enlargeTo1xAction
{
    //todo: consider expanding to a "pickup" action, would need texture swap out params and fixed scaling
    return [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.15f scale:1.0f] rate:2.0f];
}

+(CCAction*)reduceTo1xAction
{
    //todo: consider expanding to a "pickup" action, would need texture swap out params and fixed scaling
    return [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.15f scale:1.0f] rate:2.0f];
}

+(CCAction*)reduceTo0xAndHide
{
    CCEaseInOut *ease=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.15f scale:0.0f] rate:2.0f];
    CCFadeTo *fade=[CCFadeOut actionWithDuration:0.05f];
    CCSequence *seq=[CCSequence actions:ease, fade, nil];
    return seq;
}

@end
