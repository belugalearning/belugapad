//
//  ClippingTest.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "ClippingTest.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "BLMath.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "UsersService.h"
#import "AppDelegate.h"

@interface ClippingTest()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation ClippingTest

#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        gw = [[DWGameWorld alloc] initWithGameScene:self];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [self readPlist:pdef];
        [self populateGW];
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    
    if(autoMoveToNextProblem)
    {
        timeToAutoMoveToNextProblem+=delta;
        if(timeToAutoMoveToNextProblem>=kTimeToAutoMove)
        {
            self.ProblemComplete=YES;
            autoMoveToNextProblem=NO;
            timeToAutoMoveToNextProblem=0.0f;
        }
    }
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    

    [self createClippingNode];
    
}

-(void)createClippingNode
{
    CCClippingNode *clipper = [CCClippingNode clippingNode];
    //clipper.tag = kTagClipperNode;
    clipper.contentSize = CGSizeMake(200, 200);
    clipper.anchorPoint = ccp(0.5, 0.5);
    clipper.position = ccp(cx,cy);
    //[clipper runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1 angle:45]]];
    [renderLayer addChild:clipper];
    
    //CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Magnify_Glass.png")];
    //[s setPosition:ccp(cx,cy)];
    //[renderLayer addChild:s];
    
    CCDrawNode *stencil = [CCDrawNode node];
//    [stencil setPosition:ccp(cx,cy-100)];
    CGPoint rectangle[] = {{0, 0}, {clipper.contentSize.width, 0}, {clipper.contentSize.width, clipper.contentSize.height}, {0, clipper.contentSize.height}};
    ccColor4F white = {1, 1, 1, 1};
    [stencil drawPolyWithVerts:rectangle count:4 fillColor:white borderWidth:1 borderColor:white];
    [clipper addChild:stencil];
    clipper.stencil = stencil;
    
    CCSprite *content = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/line.png")];
    //    content.tag = kTagContentNode;
    content.anchorPoint = ccp(0.5, 0.5);
    content.position = ccp(clipper.contentSize.width / 2, clipper.contentSize.height / 2);
    [clipper addChild:content];
    
}

-(void)populateGW
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    
}

#pragma mark - touches events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    lastTouch=location;
    
    
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;
    
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //    UITouch *touch=[touches anyObject];
    //    CGPoint location=[touch locationInView: [touch view]];
    //    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    gw.Blackboard.LastSelectedObject=nil;
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    gw.Blackboard.LastSelectedObject=nil;
    // empty selected objects
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    return NO;
}

-(void)evalProblem
{
    BOOL isWinning=[self evalExpression];
    
    if(isWinning)
    {
        autoMoveToNextProblem=YES;
        [toolHost showProblemCompleteMessage];
    }
    else {
        if(evalMode==kProblemEvalOnCommit)[self resetProblem];
    }
    
}

#pragma mark - problem state
-(void)resetProblem
{
    [toolHost showProblemIncompleteMessage];
    [toolHost resetProblem];
}

#pragma mark - meta question
-(float)metaQuestionTitleYLocation
{
    return kLabelTitleYOffsetHalfProp*cy;
}

-(float)metaQuestionAnswersYLocation
{
    return kMetaQuestionYOffsetPlaceValue*cy;
}

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    
}

#pragma mark - dealloc
-(void) dealloc
{
    [renderLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
