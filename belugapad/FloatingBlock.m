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
#import "SGFBlockOpBubble.h"
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
    id opBubble;
    
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
    [newPipeLabel setString:[NSString stringWithFormat:@"%d", blocksFromPipe]];
    
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
    initObjects=[pdef objectForKey:INIT_OBJECTS];
    bubbleAutoOperate=[[pdef objectForKey:BUBBLE_AUTO_OPERATE]boolValue];
    maxBlocksInGroup=[[pdef objectForKey:MAX_GROUP_SIZE]intValue];
    expSolution=[[pdef objectForKey:SOLUTION]intValue];
    
    showMultipleControls=[[pdef objectForKey:SHOW_MULTIPLE_CONTROLS]boolValue];
    
    if([pdef objectForKey:MIN_BLOCKS_FROM_PIPE])
        minBlocksFromPipe=[[pdef objectForKey:MIN_BLOCKS_FROM_PIPE]intValue];
    else
        minBlocksFromPipe=1;
    
    if([pdef objectForKey:MAX_BLOCKS_FROM_PIPE])
        maxBlocksFromPipe=[[pdef objectForKey:MAX_BLOCKS_FROM_PIPE]intValue];
    else
        maxBlocksFromPipe=10;
    
    if([pdef objectForKey:DEFAULT_BLOCKS_FROM_PIPE])
        defaultBlocksFromPipe=[[pdef objectForKey:DEFAULT_BLOCKS_FROM_PIPE]intValue];
    else
        defaultBlocksFromPipe=1;
    
    if(bubbleAutoOperate)
        initBubbles=1;
    else
        initBubbles=2;
    
    
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
    
    CCLabelTTF *targetSol=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", expSolution] fontName:@"Chango" fontSize:50.0f];
    [targetSol setPosition:ccp(lx-150,100)];
    [renderLayer addChild:targetSol];
    
    newPipe=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/pipe.png")];
    [newPipe setRotation:45.0f];
    [newPipe setPosition:ccp(25,550)];
    [renderLayer addChild:newPipe];
    
    if(showMultipleControls)
    {
        newPipeLabel=[CCLabelTTF labelWithString:@"dickhead" fontName:@"Chango" fontSize:50.0f];
        [newPipeLabel setPosition:ccp(100, 550)];
        [renderLayer addChild:newPipeLabel];
        
    }
    
}

#pragma mark - interaction
-(void)createShapeWith:(NSDictionary*)theseSettings
{
    
    int numberInShape=[[theseSettings objectForKey:NUMBER]intValue];
    id<Group> thisGroup=[[SGFBlockGroup alloc]initWithGameWorld:gw];
    thisGroup.MaxObjects=maxBlocksInGroup;
    
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

-(void)showOperatorBubble
{
    BOOL isValid=YES;
    
    for(id go in gw.AllGameObjectsCopy)
    {
        if([go conformsToProtocol:@protocol(Target)])
        {
            go=(id<Target>)go;
            
            if([go containedGroups]!=1)
            {
                isValid=NO;
            }
        }
    }
    
    if(showingOperatorBubble && !isValid)
    {
        id<Operator,Rendered>curBubble=(id<Operator,Rendered>)opBubble;
        [curBubble fadeAndDestroy];
        curBubble=nil;
        showingOperatorBubble=NO;
    }
    
    if(!showingOperatorBubble && isValid)
    {
        id<Operator,Rendered>op=[[SGFBlockOpBubble alloc] initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(cx, 375)];
        op.OperatorType=1;
        [op setup];
        opBubble=op;
        showingOperatorBubble=YES;
    }
}

-(void)mergeGroupsFromBubbles
{
    NSMutableArray *groups=[[NSMutableArray alloc]init];
    
    for(id go in gw.AllGameObjectsCopy)
    {
        if([go conformsToProtocol:@protocol(Target)])
        {
            id<Target> current=(id<Target>)go;
            if([go containedGroups]==1)
            {
                [groups addObject:[current.GroupsInMe objectAtIndex:0]];
                
            }
        }
    }
    
    id<Group> targetGroup=[groups objectAtIndex:0];
    id<Rendered,Moveable> firstBlock=[targetGroup.MyBlocks objectAtIndex:0];
    float xPosOfFirstBlock=firstBlock.Position.x;
    float yPosOfFirstBlock=firstBlock.Position.y-52;
    
    
    for(id<Group> grp in groups)
    {
        if(grp==targetGroup)continue;
        
        int blocksMoved=0;
        
        NSMutableArray *theseBlocks=[NSMutableArray arrayWithArray:grp.MyBlocks];
        // and the blocks in that group
        for(id<Moveable,Rendered> block in theseBlocks)
        {
            float thisXPos=xPosOfFirstBlock+blocksMoved*52;
            [grp removeObject:block];
            [targetGroup addObject:block];
            if([grp.MyBlocks count]==0)
                [grp destroy];
            
            blocksMoved++;
            
            block.Position=ccp(thisXPos,yPosOfFirstBlock);
            
        }
        
        
        // kill the existing bubble - create a new one
            
            
//        float avgPosX=0;
//        float avgPosY=0;
//        
//        for(id<Rendered> block in targetGroup.MyBlocks)
//        {
//            avgPosX+=block.Position.x;
//            avgPosY+=block.Position.y;
//        }
//        
//        avgPosX=avgPosX/[targetGroup.MyBlocks count];
//        avgPosY=avgPosY/[targetGroup.MyBlocks count];
    
        
        // then animate

        //[grp moveGroupPositionFrom:ccp(avgPosX,avgPosY) To:ccp(cx,cy)];
        
        for(id<Rendered> block in targetGroup.MyBlocks)
        {
//            CGPoint diffBetweenFirstAndThis=[BLMath SubtractVector:firstBlock.Position from:block.Position];
//            CGPoint diffBetweenThisAndCX=[BLMath SubtractVector:diffBetweenFirstAndThis from:ccp(cx,cy)];
            CGPoint newPos=ccp(block.Position.x,block.Position.y+200);
            
            [block.MySprite runAction:[CCMoveTo actionWithDuration:0.5f position:newPos]];
            block.Position=newPos;
            
        }
        [targetGroup tintBlocksTo:ccc3(255,255,255)];

        
    }
    
    for(id bubble in gw.AllGameObjectsCopy)
    {
        if([bubble conformsToProtocol:@protocol(Target)])
        {
            float xPos=((id<Rendered>)bubble).MySprite.position.x;
            
            // kill the existing bubble - create a new one
            
            
            id<Target> bubbleid=(id<Target>)bubble;
            [bubbleid fadeAndDestroy];
            id<Rendered> newbubble;
            newbubble=[[SGFBlockBubble alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,-50) andReplacement:YES];
            [newbubble setup];
        }
    }
    
    [self showOperatorBubble];
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
    
    if(CGRectContainsPoint(newPipeLabel.boundingBox, location))
    {
        touchingNewPipeLabel=YES;
        return;
    }
    
    if(CGRectContainsPoint(newPipe.boundingBox, location))
    {
        NSDictionary *d=[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:blocksFromPipe] forKey:NUMBER];
        [self createShapeWith:d];
    }
    
    // check whether we have a pickupobject or not
    for(id go in gw.AllGameObjects)
    {
        // check for an object in a group
        if([go conformsToProtocol:@protocol(Group)])
        {
            id<Group>thisGroup=go;
            
            if([thisGroup checkTouchInGroupAt:location])
                pickupObject=thisGroup;
            
        }
        
        // check for an operator tap
        else if([go conformsToProtocol:@protocol(Operator)])
        {
            id<Operator>thisOperator=go;
            if([thisOperator amIProximateTo:location])
                pickupObject=thisOperator;

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
    
    if(touchingNewPipeLabel)
    {
        CGPoint touchStart=ccp(0, touchStartPos.y);
        CGPoint thisTouch=ccp(0, location.y);
        
        int differenceMoved=[BLMath DistanceBetween:touchStart and:thisTouch];
        
        NSLog(@"differenced Moved %d / with div %d", differenceMoved, (int)differenceMoved/20);
        
//        if(touchStartPos.y>location.y)
//            differenceMoved=-differenceMoved;
            
        blocksFromPipe=(differenceMoved/20);
        
        if(blocksFromPipe>maxBlocksFromPipe)
            blocksFromPipe=maxBlocksFromPipe;
        else if (blocksFromPipe<minBlocksFromPipe)
            blocksFromPipe=minBlocksFromPipe;
        
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
    else
        [self showOperatorBubble];
    
    if(pickupObject)
    {
        if([pickupObject isKindOfClass:[SGFBlockGroup class]])
        {
            if(CGRectContainsPoint(commitPipe.boundingBox, location))
                [self evalProblem];
        }
        if([pickupObject isKindOfClass:[SGFBlockOpBubble class]])
        {
            [self mergeGroupsFromBubbles];
        }
    }
    
    // if we were moving the marker

    pickupObject=nil;
    isTouching=NO;
    touchingNewPipeLabel=NO;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{    

    pickupObject=nil;
    isTouching=NO;
    touchingNewPipeLabel=NO;
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
