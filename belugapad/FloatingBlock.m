//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FloatingBlock.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"
#import "LoggingService.h"
#import "AppDelegate.h"

#import "SGGameWorld.h"
#import "SGFBlockObjectProtocols.h"
#import "SGFBlockBlock.h"
#import "SGFBlockBubble.h"
#import "SGFBlockGroup.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"

@interface FloatingBlock()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
    id pickupObject;
    
}

@end

@implementation FloatingBlock

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
        loggingService = ac.loggingService;
        
        
        [self readPlist:pdef];
        [self populateGW];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

#pragma mark - loops

-(void)doUpdateOnTick:(ccTime)delta
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

    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType=[[pdef objectForKey:REJECT_TYPE] intValue];
    solutionType=[[pdef objectForKey:SOLUTION_TYPE] intValue];
    initBubbles=[[pdef objectForKey:INIT_BUBBLES]intValue];
    initObjects=[pdef objectForKey:INIT_OBJECTS];
    bubbleAutoOperate=[[pdef objectForKey:BUBBLE_AUTO_OPERATE]boolValue];
    maxObjectsInGroup=[[pdef objectForKey:MAX_GROUP_SIZE]intValue];
    expSolution=[[pdef objectForKey:SOLUTION]intValue];
    
    
}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;
    
    // create our bubbles!
    for(int i=0;i<initBubbles;i++)
    {
        float xPos=(lx/initBubbles)*(i+0.5);
        
        id<Rendered> newbubble;
        newbubble=[[SGFBlockBubble alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,300) andReplacement:NO];
        [newbubble setup];
    }
    
    // create our shapes
    for(int i=0;i<[initObjects count];i++)
    {
        NSDictionary *d=[initObjects objectAtIndex:i];
        [self createShapeWith:d];
    }
    
    
    // and our commit pipe
    commitPipe=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/pipe.png")];
    [commitPipe setPosition:ccp(lx-150,70)];
    [renderLayer addChild:commitPipe];
    
    newPipe=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/pipe.png")];
    [newPipe setRotation:45.0f];
    [newPipe setPosition:ccp(25,550)];
    [renderLayer addChild:newPipe];
    
    
}

#pragma mark - interaction
-(void)createShapeWith:(NSDictionary*)theseSettings
{
    
    int numberInShape=[[theseSettings objectForKey:NUMBER]intValue];
    id<Group> thisGroup=[[SGFBlockGroup alloc]initWithGameWorld:gw];
    thisGroup.MaxObjects=maxObjectsInGroup;
    
    float xPos=arc4random()%1000;
    float yPos=arc4random()%700;
    
    for(int i=0;i<numberInShape;i++)
    {
        id<Rendered,Moveable> newblock;
        newblock=[[SGFBlockBlock alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos+(i*52),yPos)];
        newblock.MyGroup=(id)thisGroup;
        
        [newblock setup];
        
        [thisGroup addObject:newblock];
    }
    
    
}

-(void)handleMergeShapes
{
    for(id go in gw.AllGameObjectsCopy)
    {
        if([go conformsToProtocol:@protocol(Target)])
        {
            go=(id<Target>)go;
            
            if([go containedGroups]>1)
            {
                // get the list of blocks, move to index 0 group
                // for each group we go through, remove it's game object at the end
                id<Group>targetGroup=[((id<Target>)go).GroupsInMe objectAtIndex:0];
                
                // loop through all the groups in this current bubble
                for(id<Group>thisGroup in ((id<Target>)go).GroupsInMe)
                {
                    if(thisGroup==targetGroup)continue;
                    
                    NSMutableArray *theseBlocks=[NSMutableArray arrayWithArray:thisGroup.MyBlocks];
                    // and the blocks in that group
                    for(id<Moveable,Rendered> block in theseBlocks)
                    {
                        [thisGroup removeObject:block];
                        [targetGroup addObject:block];
                        if([thisGroup.MyBlocks count]==0)
                            [thisGroup destroy];
                        
                        [block.MySprite runAction:[CCMoveBy actionWithDuration:0.5f position:ccp(0,50)]];
                        
                    }
                    
                    float xPos=((id<Rendered>)go).MySprite.position.x;
                    
                    // kill the existing bubble - create a new one
                    [go fadeAndDestroy];
                    id<Rendered> newbubble;
                    newbubble=[[SGFBlockBubble alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,-50) andReplacement:YES];
                    [newbubble setup];

                    
                }
                
                // then animate
                for(id<Rendered> block in targetGroup.MyBlocks)
                {
                    [block.MySprite runAction:[CCMoveBy actionWithDuration:0.5f position:ccp(0,250)]];
                    block.Position=ccp(block.MySprite.position.x, block.MySprite.position.y+250);
                    
                }
                [targetGroup tintBlocksTo:ccc3(255,255,255)];
            }
            
            
        }
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
    touchStartPos=location;
    
    if(CGRectContainsPoint(newPipe.boundingBox, location))
    {
        NSDictionary *d=[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:NUMBER];
        [self createShapeWith:d];
    }
    
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(Group)])
        {
            id<Group>thisGroup=go;
            
            if([thisGroup checkTouchInGroupAt:location])
                pickupObject=thisGroup;
            
        }
    }
    
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];

    // if we have these things, handle them differently
    if(pickupObject)
    {
        if([pickupObject conformsToProtocol:@protocol(Group)])
        {
            id<Group>grp=(id<Group>)pickupObject;
            [grp moveGroupPositionFrom:lastTouch To:location];
            [grp checkIfInBubbleAt:location];
        }
    }
   
    lastTouch=location;
 
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    if(bubbleAutoOperate)
        [self handleMergeShapes];
    
    if(pickupObject)
    {
        if([pickupObject isKindOfClass:[SGFBlockGroup class]])
        {
            if(CGRectContainsPoint(commitPipe.boundingBox, location))
                [self evalProblem];
        }
    }
    
    // if we were moving the marker

    pickupObject=nil;
    isTouching=NO;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{    

    pickupObject=nil;
    isTouching=NO;

    // empty selected objects
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(Group)])
        {
            id<Group>thisGroup=(id<Group>)go;
            if([thisGroup.MyBlocks count]==expSolution)
                return YES;
        }
    }
    
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
