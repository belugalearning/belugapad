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

#import "AppDelegate.h"
#import "ContentService.h"
#import "UsersService.h"

#import "ConceptNode.h"

@interface JourneyScene()
{
    @private
    ContentService *contentService;
    NSArray *kcmNodes;
    
    float nMinX, nMinY, nMaxX, nMaxY;
}

@end

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
        
        contentService = ((AppController*)[[UIApplication sharedApplication] delegate]).contentService; 
        
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
    
    kcmNodes=[contentService allConceptNodes];
    //find bounds
    //set bounds to first element
    if(kcmNodes.count>0)
    {
        ConceptNode *n1=[kcmNodes objectAtIndex:0];
        nMinX=[n1.x floatValue];
        nMinY=[n1.y floatValue];
        nMaxX=nMinX;
        nMaxY=nMaxY;
        
        if(kcmNodes.count>1)
        {
            for (int i=1; i<[kcmNodes count]; i++) {
                ConceptNode *n=[kcmNodes objectAtIndex:i];
                if([n.x floatValue]<nMinX)nMinX=[n.x floatValue];
                if([n.y floatValue]<nMinY)nMinY=[n.y floatValue];
                if([n.x floatValue]>nMaxX)nMaxX=[n.x floatValue];
                if([n.y floatValue]>nMaxY)nMaxY=[n.y floatValue];
            }
        }
    }
    
    NSLog(@"node bounds are %f, %f -- %f, %f", nMinX, nMinY, nMaxX, nMaxY);
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
