//
//  DistributionTool.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DistributionTool.h"

#import "ToolTemplateSG.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"

#import "SGGameWorld.h"
#import "SGDtoolBlock.h"
#import "SGDtoolBlockRender.h"


@interface DistributionTool()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
    // and then any specifics we need for this tool
    id<Moveable,Transform> currentPickupObject;
    
}

@end

@implementation DistributionTool

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
        
        
        
        gw = [[SGGameWorld alloc] initWithGameScene:renderLayer];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        renderLayer = [[CCLayer alloc] init];
        [self.ForeLayer addChild:renderLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        
        
        [self readPlist:pdef];
        [self populateGW];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

#pragma mark - loops

-(void)doUpdate:(ccTime)delta
{
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

-(void)draw
{
    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];    
    
}

-(void)populateGW
{
    // set our renderlayer
    gw.Blackboard.RenderLayer = renderLayer;
    
    // init our array for use with the created gameobjects
    for(int i=0;i<3;i++)
    {
        id<Configurable, Selectable> newblock;
        newblock=[[[SGDtoolBlock alloc] initWithGameWorld:gw andRenderLayer:renderLayer andPosition:ccp(cx+(100*i),cy)] autorelease];
        
        [newblock setup];
        
    }
    
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
    
    
    // loop over 
    for(id thisObj in gw.AllGameObjects)
    {
        if([thisObj conformsToProtocol:@protocol(Moveable)])
        {
            id <Moveable, Transform> cObj=thisObj;
            
            if(CGRectContainsPoint(cObj.mySprite.boundingBox, location))
            {
                currentPickupObject=thisObj;
                break;
            }
        }
        
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;
    
    if(currentPickupObject)
    {

        // check that the shape is being moved within bounds of the screen
        if((location.x>=35.0f&&location.x<=lx-35.0f) && (location.y>=35.0f&&location.y<=ly-35.0f))
        {
            // set it's position and move it!
            currentPickupObject.Position=location;
            [currentPickupObject move];
        }
        
        // then for each other moveable thing, check if we're proximate
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                [go amIProximateTo:location];
            }
        }
    }
    
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //    UITouch *touch=[touches anyObject];
    //    CGPoint location=[touch locationInView: [touch view]];
    //    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
    if(currentPickupObject)
    {
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                [go resetTint];
            }
        }
    }
    currentPickupObject=nil;
    
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    currentPickupObject=nil;
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

#pragma mark - dealloc
-(void) dealloc
{
    //write log on problem switch
    
    //tear down
    [gw release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    
    [super dealloc];
}
@end