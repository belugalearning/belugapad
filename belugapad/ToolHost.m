//
//  ToolHost.m
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolHost.h"
#import "ToolConsts.h"
#import "BlockFloating.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "BLMath.h"
#import "Daemon.h"

@implementation ToolHost

@synthesize Zubi;

+(CCScene *) scene
{
    CCScene *scene=[CCScene node];
    
    ToolHost *layer=[ToolHost node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        //setup layer sequence
        backgroundLayer=[[CCLayer alloc] init];
        [self addChild:backgroundLayer z:-2];
        perstLayer=[[CCLayer alloc] init];
        [self addChild:perstLayer z:0];
        
        //add background to background layer
        CCSprite *bkg=[CCSprite spriteWithFile:@"bg-ipad.png"];
        [bkg setPosition:ccp(cx, cy)];
        [backgroundLayer addChild:bkg z:0];

        
        [self populatePerstLayer];
        
        [self loadTestPipeline];
        
        [self gotoNewProblem];
        
        [self schedule:@selector(doUpdateOnTick:) interval:1.0f/60.0f];
        [self schedule:@selector(doUpdateOnSecond:) interval:1.0f];
        [self schedule:@selector(doUpdateOnQuarterSecond:) interval:1.0f/40.0f];
        
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
    //do internal mgmt updates
    
    
    //let tool do updates
    [currentTool doUpdateOnTick:delta];
}

-(void)doUpdateOnSecond:(ccTime)delta
{
    //do internal mgmt updates
    if(currentTool.ProblemComplete)
    {
        [self gotoNewProblem];
    }
    
    //let tool do updates
    [currentTool doUpdateOnSecond:delta];
}

-(void)doUpdateOnQuarterSecond:(ccTime)delta
{
    [currentTool doUpdateOnQuarterSecond:delta];
}

-(void) addToolBackLayer:(CCLayer *) backLayer
{
    toolBackLayer=backLayer;
    [self addChild:toolBackLayer z:-1];
}

-(void) addToolForeLayer:(CCLayer *) foreLayer
{
    toolForeLayer=foreLayer;
    [self addChild:toolForeLayer z:1];
}

-(void) populatePerstLayer
{
    Zubi=[[Daemon alloc] initWithLayer:perstLayer andRestingPostion:ccp(50,50) andLy:ly];
}

-(void) loadTool
{
    //reset multitouch
    //if tool requires multitouch, it will need to reset accordingly
    [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=NO;

    
}

-(void) gotoNewProblem
{
    NSDictionary *pdef=[self getNextProblem];
    
    NSString *toolKey=[pdef objectForKey:TOOL_KEY];
    
    if(currentTool)
    {
        [self removeChild:toolBackLayer cleanup:YES];
        [self removeChild:toolForeLayer cleanup:YES];
        [currentTool release];
    }
    
    currentTool=[NSClassFromString(toolKey) alloc];
    [currentTool initWithToolHost:self andProblemDef:pdef];
    
}

-(void)loadTestPipeline
{
    //TODO: test-specific -- pulls fixed problem list from plist
    
    NSString *broot=[[NSBundle mainBundle] bundlePath];
    NSString *pfile=[broot stringByAppendingPathComponent:@"pipeline-test.plist"];
    problemList=[NSArray arrayWithContentsOfFile:pfile];
    
    [problemList retain];
}

-(NSDictionary*)getNextProblem
{
    //TODO: effectively test specific, as it only loads data from problem file, no user context etc
    NSString *pfilename=[problemList objectAtIndex:problemIndex];
    NSString *broot=[[NSBundle mainBundle] bundlePath];
    NSString *pfilepath=[broot stringByAppendingPathComponent:pfilename];
    NSDictionary *pdef=[NSDictionary dictionaryWithContentsOfFile:pfilepath];

    //TODO: this is test-specific, just loops the problem list
    problemIndex++;
    if(problemIndex>=[problemList count])problemIndex=0;
    
    return pdef;
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if (location.x<cx && location.y > kButtonToolbarHitBaseYOffset)
        [self gotoNewProblem];
    else
        [currentTool ccTouchesBegan:touches withEvent:event];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [currentTool ccTouchesMoved:touches withEvent:event];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [currentTool ccTouchesEnded:touches withEvent:event];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [currentTool ccTouchesCancelled:touches withEvent:event];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return [currentTool ccTouchBegan:touch withEvent:event];
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    [currentTool ccTouchMoved:touch withEvent:event];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    [currentTool ccTouchEnded:touch withEvent:event];
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    [currentTool ccTouchCancelled:touch withEvent:event];
}

-(void) dealloc
{
    [problemList release];
    
    [super dealloc];
}

@end
