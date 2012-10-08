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

+(CCAction*)dropAndBounceAction
{
    //pick it up
    CCEaseInOut *ml1=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.25f] rate:2.0f];
    
    //drop it    
    CCEaseInOut *ml2=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:0.95f] rate:2.0f];

    //pick it up
    CCEaseInOut *ml3=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.15f] rate:2.0f];
    
    //drop it    
    CCEaseInOut *ml4=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:0.97f] rate:2.0f];
    
    //pick it up
    CCEaseInOut *ml5=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.05f] rate:2.0f];
    
    //drop it    
    CCEaseInOut *ml6=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:1.0f] rate:2.0f];
    
    CCSequence *s=[CCSequence actions:ml1, ml2, ml3, ml4, ml5, ml6, nil];
    
    CCEaseInOut *oe=[CCEaseInOut actionWithAction:s rate:2.0f];
    
    return oe;
}

+(CCAction*)stampAction
{
    CCScaleTo *s1=[CCScaleTo actionWithDuration:0.0f scale:5.0f];

    CCFadeIn *f1=[CCFadeIn actionWithDuration:0.0f];
    
    //stamp it
    CCEaseInOut *ml2=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:0.75f] rate:2.0f];
    
    //pick it up
    CCEaseInOut *ml3=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.75f] rate:2.0f];
    
    //drop it
    CCEaseInOut *ml4=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:0.87f] rate:2.0f];
    
    //pick it up
    CCEaseInOut *ml5=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.35f] rate:2.0f];
    
    //drop it
    CCEaseInOut *ml6=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:1.0f] rate:2.0f];
    
    //fade
    CCFadeOut *f2=[CCFadeTo actionWithDuration:0.25f opacity:0];
    
    CCSequence *s=[CCSequence actions:f1, s1, ml2, ml3, ml4, ml5, ml6, f2, nil];
    
    CCEaseInOut *oe=[CCEaseInOut actionWithAction:s rate:2.0f];
    
    return oe;
}

+(CCAction*)fadeInOutHoldFor:(float)hold to:(float)to
{
    CCFadeTo *f1=[CCFadeTo actionWithDuration:0.0f opacity:0];

    CCFadeTo *f2=[CCFadeTo actionWithDuration:0.25f opacity:to];
    
    CCDelayTime *d1=[CCDelayTime actionWithDuration:hold];
    
    CCFadeTo *f3=[CCFadeTo actionWithDuration:0.25f opacity:0];
    
    CCSequence *s=[CCSequence actions:f1, f2, d1, f3, nil];
    
    return s;
}

+(CCAction*)delayMoveOutAndDown
{
    ccBezierConfig bc;
    bc.controlPoint_1=ccp(20, 20);
    bc.controlPoint_2=ccp(100, -200);
    bc.endPosition=ccp(150, -1024);
    
    CCDelayTime *d1=[CCDelayTime actionWithDuration:1.0f];
    
    CCBezierBy *b1=[CCBezierBy actionWithDuration:1.0f bezier:bc];
    
    CCSequence *s=[CCSequence actions: d1, b1, nil];
    
    return s;
}

+(CCAction*)delaySpinFast
{
    CCDelayTime *d1=[CCDelayTime actionWithDuration:1.0f];
    
    CCRotateBy *r1=[CCRotateBy actionWithDuration:1.0f angle:360.0f];
    
    CCSequence *s=[CCSequence actions: d1, r1, nil];
    
    return s;
}

+(CCAction*)highlightIncreaseAction
{
    //short cut this to drop and bouce for now
    return [self dropAndBounceAction];
}

+(CCAction*)fallAndReturn
{
    CCMoveBy *mv=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.5f position:ccp(0, -100)] rate:2.0f];
    CCMoveBy *mup=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.1f position:ccp(0, 100)] rate:2.0f];
    CCSequence *smove=[CCSequence actions:mv, mup, nil];
    return smove;
}

+(CCAction*)scaleOutReturn
{
    CCMoveBy *mv=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.5f scale:0.0f] rate:2.0f];
    CCMoveBy *mup=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.0f] rate:2.0f];
    CCSequence *smove=[CCSequence actions:mv, mup, nil];
    return smove;
}

+(CCAction*)fadeOutIn;
{
    CCFadeOut *fo=[CCFadeOut actionWithDuration:0.5f];
    CCFadeIn *fi=[CCFadeIn actionWithDuration:0.1f];
    CCSequence *sfade=[CCSequence actions:fo, fi, nil];
    return sfade;
}

+(CCAction*)fadeOutInTo:(GLubyte)opacity
{
    CCFadeTo *fo=[CCFadeTo actionWithDuration:0.5f opacity:0];
    CCFadeTo *fi=[CCFadeTo actionWithDuration:0.1f opacity:opacity];
    CCSequence *sfade=[CCSequence actions:fo, fi, nil];
    return sfade;    
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
