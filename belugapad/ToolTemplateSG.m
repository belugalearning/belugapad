//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolTemplateSG.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"

#import "SGGameWorld.h"
#import "SGJmapNode.h"
#import "SGJmapMasteryNode.h"
#import "SGJmapProximityEval.h"
#import "SGJmapNodeSelect.h"
#import "SGJmapRegion.h"


@interface ToolTemplateSG()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
}

@end

@implementation ToolTemplateSG

#pragma mark - init

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    ToolTemplateSG *layer=[ToolTemplateSG node];
    [scene addChild:layer];
    return scene;
}

-(id)init
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

        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        loggingService = ac.loggingService;
        usersService = ac.usersService;
        contentService = ac.contentService;
        
        [usersService syncDeviceUsers];
        
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        [self schedule:@selector(doUpdateProximity:) interval:15.0f / 60.0f];
        
    }
    
    return self;
}

#pragma mark loops

-(void)doUpdate:(ccTime)delta
{
    [gw doUpdate:delta];
    
    //[daemon doUpdate:delta];
    
}

-(void)doUpdateProximity:(ccTime)delta
{
    //don't do proximity on general view
}

#pragma mark - draw

-(void)draw
{
    
}

#pragma mark - setup and parse

-(void)populateGW;
{
    gw=[[SGGameWorld alloc] initWithGameScene:self];
    
    gw.Blackboard.RenderLayer=renderLayer;
    
    //setup render batch for nodes
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/jmap/node-icons.plist")];
    
}

-(void)readPlist
{
    
}

#pragma mark - evaluation

-(BOOL)evalExpression
{
    return YES;
}

-(void)evalProblem
{

}

-(void)resetProblem
{

}

#pragma mark - meta question positioning

-(float)metaQuestionTitleYLocation
{
    return 700.0f;
}

-(float)metaQuestionAnswersYLocation
{
    return 150.0f;
}

#pragma mark touch handling

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
}

#pragma mark - tear down

-(void)dealloc
{
    [gw release];
    
    [super dealloc];
}

@end
