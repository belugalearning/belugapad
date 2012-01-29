//
//  NumberLine.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NumberLine.h"
#import "global.h"
#import "BLMath.h"

#import "BlockHolder.h"

#import "SimpleAudioEngine.h"

@implementation NumberLine

+(CCScene *) scene
{
    CCScene *scene=[CCScene node];
    
    NumberLine *layer=[NumberLine node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
        cx=[[CCDirector sharedDirector] winSize].width / 2.0f;
        cy=[[CCDirector sharedDirector] winSize].height / 2.0f;
        
        dragLastX=0.0f;
        dragVel=0.0f;

        [self setupBkgAndTitle];
        
        [self setupScrollLayer];
        
        [self setupPriScaleLayer];
        
        [self schedule:@selector(doUpdate:) interval:1.0/60.0f];
        
        [self schedule:@selector(doDebugUpdate:) interval:1.0/10.0f];
    }
    
    return self;
}

-(void)setupBkgAndTitle
{
    CCSprite *bkg=[CCSprite spriteWithFile:@"bg-ipad.png"];
    [bkg setPosition:ccp(cx, cy)];
    [self addChild:bkg z:0];
    
    
    CCLabelTTF *title=[CCLabelTTF labelWithString:@"Number Line" fontName:TITLE_FONT fontSize:TITLE_SIZE];
    
    [title setColor:TITLE_COLOR3];
    [title setOpacity:TITLE_OPACITY];
        [title setPosition:ccp(cx, cy + (0.75f*cy))];
    
    [self addChild:title z:2];    
    
    
    CCSprite *btnFwd=[CCSprite spriteWithFile:@"btn-fwd.png"];
    [btnFwd setPosition:ccp(1024-18-10, 768-28-5)];
    [self addChild:btnFwd z:2];
    
    debugLabel=[CCLabelBMFont labelWithString:@"scale: position:" fntFile:NLINE_MARKER_FONT];
    [debugLabel setPosition:ccp(250, 740)];
    [self addChild:debugLabel];
}

-(void)setupScrollLayer
{
    scrollLayer=[[CCLayer alloc] init];
    [scrollLayer setPosition:ccp(0, 0)];
    [self addChild:scrollLayer];
    
//    int extent=225;
//    
//    for (int i=-extent; i<extent; i++) {
//
//        CCSprite *bar=[CCSprite spriteWithFile:@"rpg-ipad-nline.png"];
//        float x=i * 40.0f + 20.0f;
//        [bar setPosition:ccp(x, cy)];
//        [bar setScaleX:1.0f];
//        [bar setOpacity:125];
//        [scrollLayer addChild:bar];
//    }
}

-(void)setupPriScaleLayer
{
    priScaleLayer=[[CCLayer alloc] init];
    [priScaleLayer setPosition:ccp(0, 0)];
    [scrollLayer addChild:priScaleLayer];
    
    //extent of items (abs, so 2x total) -- hardcoded until moving baseline in
    int extent=70;
    
    //render 0
    zeroMarker=[CCSprite spriteWithFile:@"obj-nline-marker.png"];
    [zeroMarker setPosition:ccp(0.0f, NLINE_PRI_MARKER_YBASE)];
    
    CCLabelBMFont *lz=[CCLabelBMFont labelWithString:@"0" fntFile:NLINE_MARKER_FONT];
    [lz setPosition:ccp(0.0f, NLINE_PRI_MARKER_YBASE*2.0 + 15.0f)];
    [zeroMarker addChild:lz];

    [priScaleLayer addChild:zeroMarker];
    
    
    for (int i=1; i<extent; i++) {
        //fwd items
        CCSprite *marker=[CCSprite spriteWithFile:@"obj-nline-marker.png"];
        float x=i*NLINE_PRI_SPACEBASE;
        [marker setPosition:ccp(x, NLINE_PRI_MARKER_YBASE)];
        
        CCLabelBMFont *lf=[CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d", i] fntFile:NLINE_MARKER_FONT];
        [lf setPosition:ccp(0.0f, NLINE_PRI_MARKER_YBASE*2.0 + 15.0f)];
        [marker addChild:lf];
        
        [priScaleLayer addChild:marker];
        [priScaleFwd addObject:marker];
        
        //backward items
        CCSprite *markerBack=[CCSprite spriteWithFile:@"obj-nline-marker.png"];
        [markerBack setPosition:ccp(-x, NLINE_PRI_MARKER_YBASE)];

        CCLabelBMFont *lb=[CCLabelBMFont labelWithString:[NSString stringWithFormat:@"-%d", i] fntFile:NLINE_MARKER_FONT];
        [lb setPosition:ccp(0.0f, NLINE_PRI_MARKER_YBASE*2.0 + 15.0f)];
        [markerBack addChild:lb];
        
        [priScaleLayer addChild:markerBack];
        [priScaleBack addObject:markerBack];
    }
}

-(void) ccTouchesBegan: (NSSet *)touches withEvent: (UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
    
    if(location.x>975 & location.y>720)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.4f scene:[BlockHolder scene]]];
    }
    else
    {
        isDragging=YES;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    isDragging=NO;
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //drag handling
    UITouch *touch=[touches anyObject];
    
    CGPoint a = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView:touch.view]];
	CGPoint b = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
    
    CGPoint posNow=scrollLayer.position;
    posNow.x+=(b.x-a.x);
    scrollLayer.position=posNow;
    
    //pinch handling
    if([touches count]>1)
    {
        UITouch *t1=[[touches allObjects] objectAtIndex:0];
        UITouch *t2=[[touches allObjects] objectAtIndex:1];
        
        CGPoint t1a=[[CCDirector sharedDirector] convertToGL:[t1 previousLocationInView:t1.view]];
        CGPoint t1b=[[CCDirector sharedDirector] convertToGL:[t1 locationInView:t1.view]];
        CGPoint t2a=[[CCDirector sharedDirector] convertToGL:[t2 previousLocationInView:t2.view]];
        CGPoint t2b=[[CCDirector sharedDirector] convertToGL:[t2 locationInView:t2.view]];
        
        float da=[BLMath DistanceBetween:t1a and:t2a];
        float db=[BLMath DistanceBetween:t1b and:t2b];
        
        float scaleChange=db-da;
        
        scale+=scaleChange;
    }
}

-(void)doUpdate:(ccTime)delta
{
    //without frame rate smoothing
    float f=0.95f;
    
    //with frame rate smoothing
    //float f=0.52f;
    
    if(!isDragging)
    {
        //with smoothing
        //dragVel=(dragVel* f) * (delta/(1.0f/60.0f));
        
        //without smoothing
        dragVel=dragVel*f;
        CGPoint nowPos=scrollLayer.position;
        nowPos.x+=dragVel;
        scrollLayer.position=nowPos;
    }
    else
    {
        dragVel=(scrollLayer.position.x-dragLastX)/2;
        dragLastX=scrollLayer.position.x;
    }
}

-(void)doDebugUpdate:(ccTime)delta
{
    //update debug status
    [debugLabel setString:[NSString stringWithFormat:@"scale: %f position: %f", scale, [scrollLayer position].x]];
    
}

-(void)dealloc
{
    [super dealloc];
}

@end
