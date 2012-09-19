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

#import "NumberLayout.h"

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
    [gw doUpdate:delta];
    
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
    
    showSolutionOnPipe=[[pdef objectForKey:SHOW_SOLUTION_ON_PIPE]boolValue];
    showMultipleControls=[[pdef objectForKey:SHOW_MULTIPLE_CONTROLS]boolValue];
    
    if([pdef objectForKey:SUPPORTED_OPERATORS])
        supportedOperators=[pdef objectForKey:SUPPORTED_OPERATORS];
    
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
    
    blocksFromPipe=defaultBlocksFromPipe;
    
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

    if(showSolutionOnPipe)
    {
        CCLabelTTF *targetSol=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", expSolution] fontName:@"Chango" fontSize:50.0f];
        [targetSol setPosition:ccp(lx-150,100)];
        [renderLayer addChild:targetSol];
    }
    newPipe=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/pipe.png")];
    [newPipe setRotation:45.0f];
    [newPipe setPosition:ccp(25,550)];
    [renderLayer addChild:newPipe];
    
    if(showMultipleControls)
    {
        newPipeLabel=[CCLabelTTF labelWithString:@"" fontName:@"Chango" fontSize:50.0f];
        [newPipeLabel setPosition:ccp(100, 550)];
        [renderLayer addChild:newPipeLabel];
        
    }
    
    if(supportedOperators)
    {
        
    }
    
}

#pragma mark - interaction
-(void)createShapeWith:(NSDictionary*)theseSettings
{
    
    int numberInShape=[[theseSettings objectForKey:NUMBER]intValue];
    id<Group> thisGroup=[[SGFBlockGroup alloc]initWithGameWorld:gw];
    thisGroup.MaxObjects=maxBlocksInGroup;
    
    float xStartPos=(arc4random()%800)+100;
    float yStartPos=(arc4random()%600)+100;
    
    NSArray *blockPos=[NumberLayout physicalLayoutUpToNumber:numberInShape withSpacing:52.0f];
    
    for(int i=0;i<numberInShape;i++)
    {
        CGPoint thisPos=[[blockPos objectAtIndex:i]CGPointValue];
        thisPos=ccp(thisPos.x+xStartPos, thisPos.y+yStartPos);
        
        id<Rendered,Moveable> newblock;
        newblock=[[SGFBlockBlock alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:thisPos];
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
                [self rearrangeBlocksInGroup:targetGroup];
                [targetGroup tintBlocksTo:ccc3(255,255,255)];
            }
            
            
        }
    }
}

-(void)showOperatorBubbleOrMerge
{
    // this only gets called from a multi-bubble problem - so we must check it's valid by seeing that there's only 1 group in each bubble - if not, it's not valid
    BOOL isValid=YES;
    
    for(id go in gw.AllGameObjectsCopy)
    {
        if([go conformsToProtocol:@protocol(Target)])
        {
            go=(id<Target>)go;
            
            if([go containedGroups]!=1)
            {
                NSLog(@"not valid");
                isValid=NO;
            }
        }
    }
    
    // if we're showing a bubble already and it's no longer valid - remove the operator bubble
    if(showingOperatorBubble && !isValid)
    {
        id<Operator,Rendered>curBubble=(id<Operator,Rendered>)opBubble;
        [curBubble fadeAndDestroy];
        curBubble=nil;
        opBubble=nil;
        showingOperatorBubble=NO;
        return;
    }
    // or create it if need be
    else if(!showingOperatorBubble && isValid)
    {
        id<Operator,Rendered>op=[[SGFBlockOpBubble alloc] initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(cx, 375) andOperators:supportedOperators];
        [op setup];
        opBubble=op;
        showingOperatorBubble=YES;
        return;
    }
    // but if we have an operator bubble, it's still valid and we have a pickupobject as such
    else if(showingOperatorBubble && isValid && [pickupObject isKindOfClass:[SGFBlockOpBubble class]])
    {
        // then if we only have 1 operator - merge the bubbles 
        if([supportedOperators count]==1)
        {
            [self mergeGroupsFromBubbles];
        }
        // if we have no current childoperators and there's more than 1 supported operator, then show them
        else if([supportedOperators count]>1 && [[opBubble ChildOperators]count]==0)
        {
            [opBubble showOtherOperators];
        }
        // but if there's more and it's already showing the childoperators, then check for a touch on one of them
        else if([supportedOperators count]>1 && [[opBubble ChildOperators]count]>1)
        {
            // by looping over the childoperator array
            for(id<Operator,Rendered>oper in [opBubble ChildOperators])
            {
                // then if we have a valid hit - check the string and run whichever operation's appropriate
                if(CGRectContainsPoint(oper.MySprite.boundingBox, touchStartPos))
                {
                    NSString *s=[oper.SupportedOperators objectAtIndex:0];
                    
                    if([s isEqualToString:@"+"])
                        [self mergeGroupsFromBubbles];
                    else if([s isEqualToString:@"x"])
                            [self multiplyGroupsInBubbles];
                    else if([s isEqualToString:@"-"])
                        [self subtractGroupsInBubbles];
                    else if([s isEqualToString:@"/"])
                        [self divideGroupsInBubbles];
                }
            }
            
        }
    }
    
}

-(NSMutableArray*)returnCurrentValidGroups
{
    NSMutableArray *groups=[[NSMutableArray alloc]init];
    
    float xPos=lx;
    
    for(id go in gw.AllGameObjectsCopy)
    {
        if([go conformsToProtocol:@protocol(Target)])
        {
            id<Target,Rendered> current=(id<Target,Rendered>)go;
            if([go containedGroups]==1)
            {
                if(current.Position.x<xPos)
                {
                    xPos=current.Position.x;
                    
                    [groups insertObject:[current.GroupsInMe objectAtIndex:0] atIndex:0];
                    id<Group> grp=[current.GroupsInMe objectAtIndex:0];
                    NSLog(@"got furthest left obj %d", [grp.MyBlocks count]);
                }
                else
                {
                    id<Group> grp=[current.GroupsInMe objectAtIndex:0];
                    NSLog(@"got rightmost %d", [grp.MyBlocks count]);
                    [groups addObject:[current.GroupsInMe objectAtIndex:0]];
                }
            }
        }
    }
    
    return groups;
}

-(void)destroyBubblesAndCreateNew
{
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
}

-(void)mergeGroupsFromBubbles
{
    NSMutableArray *groups=[self returnCurrentValidGroups];
    
    id<Group> targetGroup=[groups objectAtIndex:0];
    id<Rendered,Moveable> firstBlock=[targetGroup.MyBlocks objectAtIndex:0];
    id<Rendered,Moveable> lastBlock=[targetGroup.MyBlocks objectAtIndex:[targetGroup.MyBlocks count]-1];
    float xPosOfFirstBlock=firstBlock.Position.x;
    float yPosOfFirstBlock=lastBlock.Position.y-52;
    
    
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
        

        [self rearrangeBlocksInGroup:targetGroup];
        
        [targetGroup tintBlocksTo:ccc3(255,255,255)];

        
    }
    
    [self destroyBubblesAndCreateNew];
    [self showOperatorBubbleOrMerge];
}

-(void)multiplyGroupsInBubbles
{
    // TODO: is now not running the fade ani -- sort! probably due to updated returnCurrentValidGroups
    NSMutableArray *groups=[self returnCurrentValidGroups];
    id<Group> targetGroup=[groups objectAtIndex:0];
    id<Group> operatedGroup=[groups objectAtIndex:1];
    
    int result=[targetGroup.MyBlocks count]*[operatedGroup.MyBlocks count];
    int existing=[targetGroup.MyBlocks count]+[operatedGroup.MyBlocks count];
    int needed=result-existing;
    
    NSLog(@"multiply result %d, existing %d, needed %d", result, existing, needed);

    [self mergeGroupsFromBubbles];
    

    
    for(int i=0;i<needed;i++)
    {
        int lastindex=[targetGroup.MyBlocks count]-1;
        id<Moveable>lastObj=[targetGroup.MyBlocks objectAtIndex:lastindex];
        float xPos=lastObj.Position.x+52;
        float yPos=lastObj.Position.y;
        
        NSLog(@"create existing at x %f y %f", xPos, yPos);
        
        id<Rendered,Moveable> newblock;
        newblock=[[SGFBlockBlock alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,yPos)];
        newblock.MyGroup=(id)targetGroup;
        
        [newblock setup];
        
        [targetGroup addObject:newblock];
    }
    
    [self rearrangeBlocksInGroup:targetGroup];

}

-(void)subtractGroupsInBubbles
{
    NSMutableArray *groups=[self returnCurrentValidGroups];
    id<Group> targetGroup=[groups objectAtIndex:0];
    id<Group> operatedGroup=[groups objectAtIndex:1];
    

    NSLog(@"target group count %d, oper group count %d", [targetGroup.MyBlocks count], [operatedGroup.MyBlocks count]);
    
    if([targetGroup.MyBlocks count]>=[operatedGroup.MyBlocks count])
    {

        NSMutableArray *blocks=targetGroup.MyBlocks;
        int result=[targetGroup.MyBlocks count]-[operatedGroup.MyBlocks count];
        
        NSLog(@"(subtract) result %d", result);
        
        [self mergeGroupsFromBubbles];

        NSLog(@"total objects in target now are %d", [targetGroup.MyBlocks count]);
        
        for(int i=[blocks count]-1;i>=result;i--)
        {
            NSLog(@"remove block");
            id<Rendered,Moveable> obj=[blocks objectAtIndex:i];
            [targetGroup removeObject:obj];
            [obj fadeAndDestroy];
        }
        
        [self rearrangeBlocksInGroup:targetGroup];

    }
    
}

-(void)divideGroupsInBubbles
{
    NSMutableArray *groups=[self returnCurrentValidGroups];
    id<Group> targetGroup=[groups objectAtIndex:0];
    id<Group> operatedGroup=[groups objectAtIndex:1];
    
    if([targetGroup.MyBlocks count]>[operatedGroup.MyBlocks count])
    {
        int result=[targetGroup.MyBlocks count]/[operatedGroup.MyBlocks count];
        NSMutableArray *blocks=targetGroup.MyBlocks;
        
        NSLog(@"result %d, total block count %d", result, [blocks count]);
        
        [self mergeGroupsFromBubbles];
        
        for(int i=[blocks count]-1;i>=result;i--)
        {
            NSLog(@"remove block");
            id<Rendered,Moveable> obj=[blocks objectAtIndex:i];
            [targetGroup removeObject:obj];
            [obj fadeAndDestroy];
        }
        
    }
    
    [self rearrangeBlocksInGroup:targetGroup];
}

-(void)rearrangeBlocksInGroup:(id<Group>)targetGroup
{
    NSArray *blockPos=[NumberLayout physicalLayoutUpToNumber:[targetGroup.MyBlocks count] withSpacing:52.0f];
    int xOffsetPos=([targetGroup.MyBlocks count]/10)*52.0f;
    int yOffsetPos=([targetGroup.MyBlocks count]/2)*52.0f;
    float xStartPos=cx+xOffsetPos;
    float yStartPos=cy+yOffsetPos;
    
    // then animate
    for(id<Rendered> block in targetGroup.MyBlocks)
    {
        CGPoint thisPos=[[blockPos objectAtIndex:[targetGroup.MyBlocks indexOfObject:block]]CGPointValue];
        thisPos=ccp(thisPos.x+xStartPos, thisPos.y+yStartPos);
        
        [block.MySprite runAction:[CCMoveTo actionWithDuration:0.5f position:thisPos]];
        block.Position=thisPos;
        
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
            {
                pickupObject=thisGroup;
                [thisGroup inflateZIndexOfMyObjects];
            }
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
        [self showOperatorBubbleOrMerge];
    
    if(pickupObject)
    {
        if([pickupObject isKindOfClass:[SGFBlockGroup class]])
        {
            id<Group> pickupGroup=(id<Group>)pickupObject;
            
            [pickupGroup resetZIndexOfMyObjects];
            
            if(CGRectContainsPoint(commitPipe.boundingBox, location) && evalMode==kProblemEvalAuto)
                [self evalProblem];
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
