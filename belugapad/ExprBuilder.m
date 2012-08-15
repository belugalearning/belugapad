//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExprBuilder.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"

#import "SGGameWorld.h"

#import "SGBtxeRow.h"
#import "SGBtxeText.h"
#import "SGBtxeObjectText.h"
#import "SGBtxeMissingVar.h"
#import "SGBtxeContainerMgr.h"

@interface ExprBuilder()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;

}

@end

@implementation ExprBuilder

#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] view].multipleTouchEnabled=NO;
        
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
        loggingService = ac.loggingService;
        
        
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
    gw.Blackboard.RenderLayer = renderLayer;
    
    [self populateDemo];
}

#pragma mark - dev / test content

-(void)populateDemo
{
    //create row
    id<Container, Bounding> row=[[SGBtxeRow alloc] initWithGameWorld:gw andRenderLayer:self.ForeLayer];
    row.position=ccp(cx, cy+100);
    
    //create some children
    SGBtxeText *t1=[[SGBtxeText alloc] initWithGameWorld:gw];
    t1.text=@"Tom had";
    [row.containerMgrComponent addObjectToContainer:t1];
    
    SGBtxeObjectText *t2=[[SGBtxeObjectText alloc] initWithGameWorld:gw];
    t2.text=@"5 sweets.";
    t2.tag=@"a";
    [row.containerMgrComponent addObjectToContainer:t2];
    
    SGBtxeText *t3=[[SGBtxeText alloc] initWithGameWorld:gw];
    t3.text=@"He gets";
    [row.containerMgrComponent addObjectToContainer:t3];
    
    SGBtxeObjectText *o3=[[SGBtxeObjectText alloc]initWithGameWorld:gw];
    o3.text=@"4 more.";
    o3.tag=@"b";
    [row.containerMgrComponent addObjectToContainer:o3];
    
    SGBtxeText *t4=[[SGBtxeText alloc] initWithGameWorld:gw];
    t4.text=@"How many does he have?";
    [row.containerMgrComponent addObjectToContainer:t4];

    [row setupDraw];

    //create row
    id<Container, Bounding> row2=[[SGBtxeRow alloc] initWithGameWorld:gw andRenderLayer:self.ForeLayer];
    row2.position=ccp(cx, cy-100);
    
    //create some children

    SGBtxeObjectText *tt2=[[SGBtxeObjectText alloc] initWithGameWorld:gw];
    tt2.text=@"5 sweets";
    tt2.tag=@"a";
    tt2.enabled=NO;
    [row2.containerMgrComponent addObjectToContainer:tt2];

    SGBtxeText *tt1=[[SGBtxeText alloc] initWithGameWorld:gw];
    tt1.text=@"+";
    [row2.containerMgrComponent addObjectToContainer:tt1];
    
    SGBtxeObjectText *tt3=[[SGBtxeObjectText alloc] initWithGameWorld:gw];
    tt3.text=@"4 sweets";
    tt3.enabled=NO;
    tt3.tag=@"b";
    [row2.containerMgrComponent addObjectToContainer:tt3];
    
    SGBtxeText *tt4=[[SGBtxeText alloc] initWithGameWorld:gw];
    tt4.text=@" = ";
    [row2.containerMgrComponent addObjectToContainer:tt4];
    
    SGBtxeObjectText *tt5=[[SGBtxeObjectText alloc] initWithGameWorld:gw];
    tt5.text=@"9 sweets";
    tt5.enabled=NO;
    tt5.tag=@"c";
    [row2.containerMgrComponent addObjectToContainer:tt5];
    
    
    [row2 setupDraw];
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
    
    if(isHoldingObject) return;  // no multi-touch but let's be sure

    for(id<MovingInteractive, NSObject> o in gw.AllGameObjects)
    {
        if([o conformsToProtocol:@protocol(MovingInteractive)])
        {
            if(o.enabled && [BLMath DistanceBetween:o.worldPosition and:location] <= BTXE_PICKUP_PROXIMITY)
            {
                heldObject=o;
                isHoldingObject=YES;
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

    if(isHoldingObject)
    {
        //track that object's position
        heldObject.worldPosition=location;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
    if(heldObject)
    {
        //test new location for target / drop
        for(id<Interactive, NSObject> o in gw.AllGameObjects)
        {
            if([o conformsToProtocol:@protocol(Interactive)])
            {
                if(!o.enabled
                   && [heldObject.tag isEqualToString:o.tag]
                   && [BLMath DistanceBetween:o.worldPosition and:location]<=BTXE_PICKUP_PROXIMITY)
                {
                    //this object is proximate, disabled and the same tag
                    [o activate];
                }
            }
        }
        
        [heldObject returnToBase];
        
        heldObject=nil;
        isHoldingObject=NO;
    }
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
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
    
    [renderLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
