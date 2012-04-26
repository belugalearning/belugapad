//
//  EditUser.m
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EditZubi.h"
#import "cocos2d.h"
#import "Daemon.h"
#import "ToolConsts.h"
#import "CCScreenshot.h"

@interface EditZubi ()
{
    @private
    Daemon *daemon;
    float cx, cy;
}
- (void) doUpdate:(ccTime)delta;
@end

@implementation EditZubi

+ (CCScene *) scene
{
    CCScene *scene=[CCScene node];
    [scene addChild:[EditZubi node]];    
    return scene;
}

- (id) init
{
    if(self=[super init])
    {   
        cx = [[CCDirector sharedDirector] winSize].width / 2;
        cy = [[CCDirector sharedDirector] winSize].height / 2;
        
        self.isTouchEnabled = YES;        
        [CCDirector sharedDirector].view.multipleTouchEnabled=NO;
        
        daemon = [[Daemon alloc] initWithLayer:self andRestingPostion:(CGPoint){cx,cy} andLy:0.0f];
        [daemon enableAnimations];
        
        [self schedule:@selector(doUpdate:) interval:1.0f/kScheduleUpdateLoopTFPS];
    }
    
    return self;
}

- (void) setZubiColor:(ccColor4F)aColor
{
    
    [daemon setColor:aColor];
}

- (void) removeScreenshotSprite:(CCNode*)node
{
    [node removeFromParentAndCleanup:YES];
}

- (NSString*) takeScreenshot
{   
    NSString* screenshotFile = @"screenshot.png";
    
    [CCScreenshot screenshotWithStartNode:self filename:screenshotFile];
    return [CCScreenshot screenshotPathForFile:screenshotFile];
}

- (void)doUpdate:(ccTime)delta
{    
    //daemon updates
    [daemon doUpdate:delta];
}

@end
