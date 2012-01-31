//
//  IceDiv.m
//  belugapad
//
//  Created by Gareth Jenkins on 22/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IceDiv.h"
#import "global.h"
#import "NumberLine.h"
#import "SimpleAudioEngine.h"
#import "Daemon.h"

#define ICE_BOTTOM 200.0f
#define ICE_TOP 568.0f

#define SWIPE_YVAR_MAX 100.0f
#define SWIPE_FRACTION_PROX 50.0f

const CGPoint kDaemonPos={50,50};

@implementation IceDiv

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    
    IceDiv *layer=[IceDiv node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=NO;
        
        cx=[[CCDirector sharedDirector] winSize].width / 2.0f;
        cy=[[CCDirector sharedDirector] winSize].height / 2.0f;
        
        [self setupBkgAndTitle];
        
        daemon=[[Daemon alloc] initWithLayer:self andRestingPostion:kDaemonPos];
        
        [self setupParticle];
        
        [self schedule:@selector(doUpdate:) interval:0.0f/60.0f];
        
        touching=NO;
        fireTime=0.0f;
        
    }
    
    return self;
}



-(void) setupBkgAndTitle
{
    CCSprite *bkg=[CCSprite spriteWithFile:@"bg-ipad.png"];
    [bkg setPosition:ccp(cx, cy)];
    [self addChild:bkg z:0];
    
    CCSprite *ice=[CCSprite spriteWithFile:@"icediv-ice.png"];
    [ice setPosition:ccp(cx, cy)];
    [ice setOpacity:150];
    [self addChild:ice z:0];
    
    
    CCLabelTTF *title=[CCLabelTTF labelWithString:@"Cut the ice into quarters" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [title setPosition:ccp(cx, cy + (0.85f*cy))];
    
    [self addChild:title z:2];    
    
    fractionLabel=[CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [fractionLabel setPosition:ccp(cx, 0.25*cy)];
    [fractionLabel setOpacity:0];
    [self addChild:fractionLabel];
    
    CCSprite *btnFwd=[CCSprite spriteWithFile:@"btn-fwd.png"];
    [btnFwd setPosition:ccp(1024-18-10, 768-28-5)];
    [self addChild:btnFwd z:2];
    
}

-(void) setupParticle
{
    particle=[CCParticleSystemQuad particleWithFile:@"fire3.plist"];
    [self addChild:particle];
    [particle setEmissionRate:0.0f];
    
    [particle setPosition:ccp(cx, cy)];
}

-(void) ccTouchesBegan: (NSSet *)touches withEvent: (UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
    
    if(location.x>975 & location.y>720)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.4f scene:[NumberLine scene]]];
    }
    else
    {
        [daemon setMode:kDaemonModeChasing];
        [daemon setTarget:location];
        
        [particle setPosition:location];
        [particle setEmissionRate:20000.0f];
        
        tDown=location;
        
        tMin=location;
        tMax=location;
        
        touching=YES;
        
        [[SimpleAudioEngine sharedEngine] playEffect:@"icediv-fire.wav"];
    }
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
    
    //[daemon setMode:kDaemonModeResting];
    
    [particle setEmissionRate:0.0f];
    
    tUp=location;
    
    [self evalSwipe];
    
    touching=NO;
    fireTime=0.0f;
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"icediv-fireball.wav"];
}

-(void) evalSwipe
{
    if(!((tDown.y<ICE_BOTTOM && tUp.y>ICE_TOP) || (tDown.y>ICE_TOP && tUp.y<ICE_BOTTOM)))
    {
        DLog(@"swipe wasn't through bottom and top");
        return;
    }
    
    float xMin=0;
    float xMax=0;
    
    if(tDown.x<tUp.x)
    {
        xMin=tDown.x;
        xMax=tUp.x;
    }
    else
    {
        xMin=tUp.x;
        xMax=tDown.x;
    }
    
    if(fabsf(tMax.x-tMin.x) > SWIPE_YVAR_MAX)
    {
        DLog(@"yvariance too great %f", (tMax.x-tMin.x));
        return;
    }
    
    float xMean=xMin + ((xMax - xMin) / 2.0f);
    
    CCSprite *crack=[CCSprite spriteWithFile:@"icediv-crack.png"];
    [crack setPosition:ccp(xMean, cy)];
    [self addChild:crack];
    
    CCDelayTime *s1=[CCDelayTime actionWithDuration:2.0f];
    CCFadeTo *s2=[CCFadeTo actionWithDuration:0.5f opacity:0];
    CCSequence *seq=[CCSequence actions:s1, s2, nil];
    [crack runAction:seq];
    
    
    //force set crack opacity, so we can up it if it strikes a fraction
    [crack setOpacity:50];
    
    //look for a valid fraction
    float xBase=40.0f;
    float xSpan=(cx*2)-(xBase*2);

    //look at some manual fractions
    if(fabsf((xMean-xBase) - 0.25*xSpan) < SWIPE_FRACTION_PROX)
    {
        [crack setOpacity:255];
        [crack runAction:[CCMoveTo actionWithDuration:0.1f position:ccp(0.25f*xSpan+xBase, cy)]];
        
        [self showFractionFoundLabel:@"1/4"];
        
        [[SimpleAudioEngine sharedEngine] playEffect:@"icediv-crack.wav"];
    }
    
    if(fabsf((xMean-xBase) - 0.5*xSpan) < SWIPE_FRACTION_PROX)
    {
        [crack setOpacity:255];
        [crack runAction:[CCMoveTo actionWithDuration:0.1f position:ccp(0.5f*xSpan+xBase, cy)]];
        
        [self showFractionFoundLabel:@"1/2"];
        
        [[SimpleAudioEngine sharedEngine] playEffect:@"icediv-crack.wav"];
    }
    
    if(fabsf((xMean-xBase) - 0.75*xSpan) < SWIPE_FRACTION_PROX)
    {
        [crack setOpacity:255];
        [crack runAction:[CCMoveTo actionWithDuration:0.1f position:ccp(0.75f*xSpan+xBase, cy)]];
        
        [self showFractionFoundLabel:@"3/4"];
    
        [[SimpleAudioEngine sharedEngine] playEffect:@"icediv-crack.wav"];
    }
    
}

-(void)showFractionFoundLabel:(NSString *)frac
{
    [fractionLabel stopAllActions];
    
    [fractionLabel setString:frac];
    
    [fractionLabel setOpacity:255];
    
    CCDelayTime *s1=[CCDelayTime actionWithDuration:2.0f];
    CCFadeOut *s2=[CCFadeOut actionWithDuration:0.5f];
    CCSequence *seq=[CCSequence actions:s1, s2, nil];
    [fractionLabel runAction:seq];
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
	CGPoint location=[touch locationInView: [touch view]];
	location=[[CCDirector sharedDirector] convertToGL:location];
    
    [daemon setTarget:location];
    
    [particle setPosition:location];
    
    if(location.x < tMin.x) tMin=location;
    if(location.y > tMax.y) tMax=location;
}

-(void) doUpdate:(ccTime)delta
{
    if(touching)
    {
        fireTime+=delta;
        if(fireTime>0.25f)
        {
            [[SimpleAudioEngine sharedEngine] playEffect:@"icediv-fire.wav"];
            fireTime=0.0f;
        }
    }
    
    [daemon doUpdate:delta];
}

-(void)dealloc
{
    [super dealloc];
}

@end
