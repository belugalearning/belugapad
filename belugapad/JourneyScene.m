//
//  JourneyScene.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JourneyScene.h"

#import "Daemon.h"
#import "global.h"
#import "BLMath.h"

@implementation JourneyScene

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    JourneyScene *layer=[JourneyScene node];
    [scene addChild:layer];
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        [[CCDirector sharedDirector] view].multipleTouchEnabled=NO;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx = lx / 2.0f;
        cy = ly / 2.0f;
        
        [self setupMap];
        
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        daemon=[[Daemon alloc] initWithLayer:mapLayer andRestingPostion:ccp(cx, cy) andLy:ly];
        [daemon setMode:kDaemonModeFollowing];
        
    }
    
    return self;
}

-(void) setupMap
{
    //base map layer
    mapLayer=[[CCLayer alloc] init];
    [self addChild:mapLayer];
    
    //add background to the map itself
    for (int r=-2; r<3; r++) {
        for (int c=-2; c<3; c++) {
            CCSprite *btile=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/mapbase.png")];
            [btile setPosition:ccp((lx*c)+cx, (ly*r)+cy)];
            [mapLayer addChild:btile];
        }
    }
    
    //add overlay on centre tile
    CCSprite *sample=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/samplenodes.png")];
    [sample setPosition:ccp(cx, cy)];
    [mapLayer addChild:sample];
}

-(void) doUpdate:(ccTime)delta
{
    [daemon doUpdate:delta];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
 
    lastTouch=l;
    
    CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
    
    [daemon setTarget:lOnMap];
    [daemon setRestingPoint:lOnMap];
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
    lastTouch=l;
    
    CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
    
    [daemon setTarget:lOnMap];    
    [daemon setRestingPoint:lOnMap];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint tapFromC=[BLMath SubtractVector:ccp(cx, cy) from:lastTouch];
    CGPoint moveBy=ccp(-tapFromC.x, -tapFromC.y);
    
    CCMoveBy *m=[CCMoveBy actionWithDuration:2.5f position:moveBy];
    
    //CCEaseInOut *ease=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:2.0f position:moveBy] rate:0.5f];
    
    //CCEaseOut *eout=[CCEaseOut actionWithAction:m rate:0.6f];
    //CCEaseIn *ein=[CCEaseIn actionWithAction:eout rate:0.6f];
    
    CCEaseIn *eins=[CCEaseIn actionWithAction:m rate:0.5f];
    
    [mapLayer runAction:eins];
}



@end
