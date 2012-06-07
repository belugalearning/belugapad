//
//  PieSplitter.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "PieSplitter.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "BLMath.h"

#import "DWPieSplitterContainerGameObject.h"
#import "DWPieSplitterPieGameObject.h"
#import "DWPieSplitterSliceGameObject.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "UsersService.h"
#import "AppDelegate.h"

@interface PieSplitter()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation PieSplitter

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
    
    if(gameState==kGameReadyToSplit)[splitBtn setVisible:YES];
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
    
}

-(void)populateGW
{
    renderLayer = [[CCLayer alloc] init];
    activeCon=[[[NSMutableArray alloc]init]retain];
    activePie=[[[NSMutableArray alloc]init]retain];
    
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    pieBox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/dropzone.png")];
    conBox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/dropzone.png")];
    splitBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/splitter.png")];
    
    [pieBox setPosition:ccp(cx,475)];
    [conBox setPosition:ccp(cx,240)];
    [splitBtn setPosition:ccp(800, 700)];
    
    [pieBox setOpacity:50];
    [conBox setOpacity:50];
    
    [pieBox setVisible:NO];
    [conBox setVisible:NO];
    
    if(gameState!=kGameReadyToSplit)[splitBtn setVisible:NO];
    
    
    [renderLayer addChild:pieBox];
    [renderLayer addChild:conBox];
    [renderLayer addChild:splitBtn];
    
    [self createPieAtMount];
    [self createContainerAtMount];

    
    [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:-1];
    
    
}

#pragma mark - object interaction
-(void)createPieAtMount
{
    DWPieSplitterPieGameObject *pie = [DWPieSplitterPieGameObject alloc];
    [gw populateAndAddGameObject:pie withTemplateName:@"TpieSplitterPie"];
    pie.Position=ccp(35,640);
    pie.MountPosition=pie.Position;
}

-(void)createContainerAtMount
{
    DWPieSplitterContainerGameObject *cont = [DWPieSplitterContainerGameObject alloc];
    [gw populateAndAddGameObject:cont withTemplateName:@"TpieSplitterContainer"];
    cont.Position=ccp(35,700);
    cont.MountPosition=cont.Position;
}

-(void)reorderActivePies
{
    
    for(int i=0;i<[activePie count];i++)
    {
        DWPieSplitterPieGameObject *p=[activePie objectAtIndex:i];
        p.Position=ccp(60+(i*100), pieBox.position.y);
        [p.mySprite runAction:[CCMoveTo actionWithDuration:0.3 position:p.Position]];
    }
}

-(void)reorderActiveContainers
{
    for(int i=0;i<[activeCon count];i++)
    {
        DWPieSplitterContainerGameObject *p=[activeCon objectAtIndex:i];
        p.Position=ccp(60+(i*100), conBox.position.y);
        [p.mySprite runAction:[CCMoveTo actionWithDuration:0.3 position:p.Position]];
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
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    
    if(gw.Blackboard.PickupObject)
    {
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])[conBox setVisible:YES];
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]])[pieBox setVisible:YES];
    }

    
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
        
    if(gw.Blackboard.PickupObject)
    {

        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
            ((DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject).Position=location;
        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]])
            ((DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject).Position=location;
        
        [gw.Blackboard.PickupObject handleMessage:kDWmoveSpriteToPosition andPayload:nil withLogLevel:-1];
        
        // if we haven't yet created a new object, do it now
        if(!createdNewCon)
        {
            [self createContainerAtMount];
            createdNewCon=YES;
        }
        if(!createdNewPie)
        {
            [self createPieAtMount];
            createdNewPie=YES;
        }
        
        if(createdNewCon||createdNewPie)[gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:-1];

    }
    
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    
    
    
    if(gw.Blackboard.PickupObject)
    {
        
        // is a container?
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
        {
            DWPieSplitterContainerGameObject *cont=(DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject;
            // first hide the box again
            [conBox setVisible:NO];
            
            // then check whether the touch end was in the bounding box 
            if(CGRectContainsRect(conBox.boundingBox, cont.mySprite.boundingBox))
            {
                // if this object isn't in the array, add it
                if(![activeCon containsObject:cont])[activeCon addObject:cont];
                
            }
            else {
                // if we're not landing on the dropzone and were previously there, remove object from array
                if([activeCon containsObject:cont])[activeCon removeObject:cont];
                
                // and if it wasn't - eject it back to it's mount
                [gw.Blackboard.PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:-1];
            }
            
            [self reorderActiveContainers];
        }
        
        
        // is a pie?
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]])
        {
            DWPieSplitterPieGameObject *pie=(DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject;
            
            // hide the box
            [pieBox setVisible:NO];
            
            // then check whether the touch end was in the bounding box 
            if(CGRectContainsRect(pieBox.boundingBox, pie.mySprite.boundingBox))
            {
                // if this object isn't in the array, add it
                if(![activePie containsObject:pie])[activePie addObject:pie];
            }
            else {
                // if we're not landing on the dropzone and were previously there, remove object from array
                if([activePie containsObject:pie])[activePie removeObject:pie];
                
                // and if it wasn't - eject it back to it's mount
                [gw.Blackboard.PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:-1];
            }
            
            [self reorderActivePies];
        }
    }
    
    
    isTouching=NO;
    createdNewCon=NO;
    createdNewPie=NO;
    gw.Blackboard.PickupObject=nil;
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    createdNewCon=NO;
    createdNewPie=NO;
    gw.Blackboard.PickupObject=nil;
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
    [gw writeLogBufferToDiskWithKey:@"PieSplitter"];
    
    //tear down
    [gw release];
    
    if(activePie)[activePie release];
    if(activeCon)[activeCon release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    
    [super dealloc];
}
@end
