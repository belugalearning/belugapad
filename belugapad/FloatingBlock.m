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
#import "LogPoller.h"
#import "AppDelegate.h"

#import "NumberLayout.h"

#import "SGGameWorld.h"
#import "SGFBlockObjectProtocols.h"
#import "SGFBlockBlock.h"
#import "SGFBlockBubble.h"
#import "SGFBlockOpBubble.h"
#import "SGFBlockGroup.h"

#import "SimpleAudioEngine.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"

#import "SimpleAudioEngine.h"

//CCPickerView
#define kComponentWidth 54
#define kComponentHeight 32
#define kComponentSpacing 0

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

@synthesize pickerView;

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
    
    if(setupNumberWheel)
    {
        timeToSetupNumberWheel-=delta;
        if(timeToSetupNumberWheel<0)
        {
            setupNumberWheel=NO;
            [self setupNumberWheel];
            [pickerView spinComponent:0 speed:25 easeRate:5 repeat:3 stopRow:defaultBlocksFromPipe];
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_wheel_slots_rotate_to_start_position.wav")];
        }
    }
    
    if(self.pickerView && !setupNumberWheel)
    {
        if([self returnPickerNumber]<minBlocksFromPipe){
            [pickerView spinComponent:0 speed:10 easeRate:4 repeat:2 stopRow:minBlocksFromPipe];
            blocksFromPipe=minBlocksFromPipe;
        }
        else if([self returnPickerNumber]>maxBlocksFromPipe){
            [pickerView spinComponent:0 speed:10 easeRate:4 repeat:2 stopRow:maxBlocksFromPipe];
            blocksFromPipe=maxBlocksFromPipe;
        }
        [pickerViewSelection replaceObjectAtIndex:0 withObject:[NSNumber numberWithInteger:blocksFromPipe]];
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
    isIntroPlist=[[pdef objectForKey:IS_INTRO_PLIST]boolValue];
    
    showSolutionOnPipe=[[pdef objectForKey:SHOW_SOLUTION_ON_PIPE]boolValue];
    showMultipleControls=[[pdef objectForKey:SHOW_MULTIPLE_CONTROLS]boolValue];
    
    if([pdef objectForKey:SHOW_INPUT_PIPE])
        showNewPipe=[[pdef objectForKey:SHOW_INPUT_PIPE]boolValue];
    else
        showNewPipe=YES;
    
    if([pdef objectForKey:SUPPORTED_OPERATORS])
        supportedOperators=[[pdef objectForKey:SUPPORTED_OPERATORS]retain];
    
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
    
    if(isIntroPlist)
        initBubbles=0;

    [usersService notifyStartingFeatureKey:@"FLOATINGBLOCK_EVALUATION"];
    [usersService notifyStartingFeatureKey:@"FLOATINGBLOCK_OPERATION"];
    
    if(showNewPipe)
        [usersService notifyStartingFeatureKey:@"FLOATINGBLOCK_SHOW_INPUT_PIPE"];
    
    if([supportedOperators count]>1)
        [usersService notifyStartingFeatureKey:@"FLOATINGBLOCK_SHOW_MULTIPLE_OPERATORS"];    
}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;
    
    // create our bubbles!
    for(int i=0;i<initBubbles;i++)
    {
        float xPos=(lx/initBubbles)*(i+0.5);
        
        id<Rendered,LogPolling> newbubble;
        newbubble=[[[SGFBlockBubble alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,300) andReplacement:NO] autorelease];
        
        [loggingService.logPoller registerPollee:newbubble];
        
        [newbubble setup];
    }
    
    // create our shapes
    for(int i=0;i<[initObjects count];i++)
    {
        NSDictionary *d=[initObjects objectAtIndex:i];
        [self createShapeWith:d andObj:i of:[initObjects count]];
    }
    
    
    // and our commit pipe
    commitPipe=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/FB_Pipe_In.png")];
    [commitPipe setPosition:ccp(cx,52)];
    [commitPipe setOpacity:0];
    [commitPipe setTag:1];
    [renderLayer addChild:commitPipe z:1000];

    if(showSolutionOnPipe)
    {
        CCLabelTTF *targetSol=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", expSolution] fontName:@"Chango" fontSize:30.0f];
        [targetSol setColor:ccc3(51,51,51)]; 
        [targetSol setPosition:ccp(cx,20)];
        [targetSol setOpacity:0];
        [targetSol setTag:3];
        [renderLayer addChild:targetSol];
    }
    
    if(showNewPipe) {
        newPipe=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/FB_Pipe_Out.png")];
        [newPipe setPosition:ccp(57,500)];
        [newPipe setOpacity:0];
        [newPipe setTag:1];
        [renderLayer addChild:newPipe];
        
        if(showMultipleControls)
        {
            timeToSetupNumberWheel=3.2f;
            setupNumberWheel=YES;

//            newPipeLabel=[CCLabelTTF labelWithString:@"" fontName:@"Chango" fontSize:50.0f];
//            [newPipeLabel setPosition:ccp(100, 550)];
//            [newPipeLabel setOpacity:0];
//            [newPipeLabel setTag:3];
//            [renderLayer addChild:newPipeLabel];
            
        }
    }

    
}

#pragma mark - interaction
-(void)createShapeWith:(NSDictionary*)theseSettings
{
    [self createShapeWith:theseSettings andObj:1 of:1];
}
-(void)createShapeWith:(NSDictionary*)theseSettings andObj:(int)thisObj of:(int)thisMany
{
    
    int numberInShape=[[theseSettings objectForKey:NUMBER]intValue];
    id<Group> thisGroup=[[[SGFBlockGroup alloc]initWithGameWorld:gw] autorelease];
    thisGroup.MaxObjects=maxBlocksInGroup;
    
    int totalShapes=thisMany;
    int thisShape=thisObj;
    float sectWidth=lx/totalShapes;
    
    float xStartPos=sectWidth*(thisShape+0.5);
    float yStartPos=540;
    
    //int farLeft=100;
    //int farRight=lx-60;
    //int topMost=ly-170;
    //int botMost=130;
    
    //float xStartPos=farLeft + arc4random() % (farRight - farLeft);
    //float yStartPos=botMost + arc4random() % (topMost - botMost);
    
    NSArray *blockPos=[NumberLayout physicalLayoutUpToNumber:numberInShape withSpacing:52.0f];
    
    for(int i=0;i<numberInShape;i++)
    {
        CGPoint thisPos=[[blockPos objectAtIndex:i]CGPointValue];
        thisPos=ccp(thisPos.x+xStartPos, thisPos.y+yStartPos);
        
        id<Rendered,Moveable,LogPolling> newblock;
        newblock=[[[SGFBlockBlock alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:thisPos] autorelease];
        newblock.MyGroup=(id)thisGroup;
        
        [loggingService.logPoller registerPollee:newblock];
        
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
                    [loggingService.logPoller unregisterPollee:go];
                    [go fadeAndDestroy];
                    id<Rendered,LogPolling> newbubble;
                    newbubble=[[SGFBlockBubble alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,-50) andReplacement:YES];
                    
                    [loggingService.logPoller registerPollee:newbubble];
                    
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
                isValid=NO;
            }
        }
    }
    
    // if we're showing a bubble already and it's no longer valid - remove the operator bubble
    if(showingOperatorBubble && !isValid)
    {
        id<Operator,Rendered,LogPolling>curBubble=(id<Operator,Rendered,LogPolling>)opBubble;
        [curBubble fadeAndDestroy];
        [loggingService.logPoller unregisterPollee:curBubble];
        curBubble=nil;
        opBubble=nil;
        showingOperatorBubble=NO;
        return;
    }
    // or create it if need be
    else if(!showingOperatorBubble && isValid)
    {
        id<Operator,Rendered,LogPolling>op=[[SGFBlockOpBubble alloc] initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(cx, 375) andOperators:supportedOperators];
        [loggingService.logPoller registerPollee:op];
        [op setup];
        opBubble=op;
        showingOperatorBubble=YES;
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_operator_bubble_floating_up.wav")];
        return;
    }
    // but if we have an operator bubble, it's still valid and we have a pickupobject as such
    else if(showingOperatorBubble && isValid && [pickupObject isKindOfClass:[SGFBlockOpBubble class]])
    {
        [(SGFBlockOpBubble*)pickupObject fadeAndDestroy];
        // then if we only have 1 operator - merge the bubbles 
        if([supportedOperators count]==1)
        {
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_tapping_operator.wav")];
            NSString *s=[supportedOperators objectAtIndex:0];
            
            [loggingService logEvent:BL_PA_FBLOCK_TOUCH_END_USE_OPERATOR withAdditionalData:[NSDictionary dictionaryWithObject:s forKey:OPERATOR_MODE]];
            
            if([s isEqualToString:@"+"])
                [self mergeGroupsFromBubbles];
            else if([s isEqualToString:@"x"])
                [self multiplyGroupsInBubbles];
            else if([s isEqualToString:@"-"])
                [self subtractGroupsInBubbles];
            else if([s isEqualToString:@"%"])
                [self divideGroupsInBubbles];
            else if([s isEqualToString:@"/"])
                [self divideGroupsInBubbles];
        }
        // if we have no current childoperators and there's more than 1 supported operator, then show them
        else if([supportedOperators count]>1 && [[opBubble ChildOperators]count]==0)
        {
            [loggingService logEvent:BL_PA_FBLOCK_TOUCH_END_SHOW_MORE_OPERATORS withAdditionalData:nil];
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
                    
                    [loggingService logEvent:BL_PA_FBLOCK_TOUCH_END_USE_OPERATOR withAdditionalData:[NSDictionary dictionaryWithObject:s forKey:OPERATOR_MODE]];
                    
                    if([s isEqualToString:@"+"])
                        [self mergeGroupsFromBubbles];
                    else if([s isEqualToString:@"x"])
                            [self multiplyGroupsInBubbles];
                    else if([s isEqualToString:@"-"])
                        [self subtractGroupsInBubbles];
                    else if([s isEqualToString:@"%"])
                        [self divideGroupsInBubbles];
                    else if([s isEqualToString:@"/"])
                        [self divideGroupsInBubbles];
                }
            }
            
        }
    }
    
}

-(NSMutableArray*)returnCurrentValidGroups
{
    NSMutableArray *groups=[[[NSMutableArray alloc]init] autorelease];
    
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
            
            
            id<Target,LogPolling> bubbleid=(id<Target,LogPolling>)bubble;
            [loggingService.logPoller unregisterPollee:bubbleid];
            [bubbleid fadeAndDestroy];
            id<Rendered,LogPolling> newbubble;
            newbubble=[[SGFBlockBubble alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,-50) andReplacement:YES];
            [loggingService.logPoller registerPollee:newbubble];
            [newbubble setup];
        }
    }
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_bubble_added_to_scene_and_floating_up.wav")];
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
        
        id<Rendered,Moveable,LogPolling> newblock;
        newblock=[[[SGFBlockBlock alloc]initWithGameWorld:gw andRenderLayer:gw.Blackboard.RenderLayer andPosition:ccp(xPos,yPos)] autorelease];
        newblock.MyGroup=(id)targetGroup;
        
        [loggingService.logPoller registerPollee:newblock];
        
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
            id<Rendered,Moveable,LogPolling> obj=[blocks objectAtIndex:i];
            [targetGroup removeObject:obj];
            [loggingService.logPoller unregisterPollee:obj];
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
    
    float tGc=[targetGroup.MyBlocks count];
    float oGc=[operatedGroup.MyBlocks count];
    
    float outcome=tGc/oGc;
    outcome=outcome-(int)outcome;
    
    
    if(outcome>0){
        id<Operator,Rendered,LogPolling>curBubble=(id<Operator,Rendered,LogPolling>)opBubble;
        [loggingService.logPoller unregisterPollee:curBubble];
        [curBubble fadeAndDestroy];
        opBubble=nil;
        showingOperatorBubble=NO;
        return;
    }
    
    if([targetGroup.MyBlocks count]>[operatedGroup.MyBlocks count])
    {
        int result=[targetGroup.MyBlocks count]/[operatedGroup.MyBlocks count];
        NSMutableArray *blocks=targetGroup.MyBlocks;
        
        NSLog(@"result %d, total block count %d", result, [blocks count]);
        
        [self mergeGroupsFromBubbles];
        
        for(int i=[blocks count]-1;i>=result;i--)
        {
            NSLog(@"remove block");
            id<Rendered,Moveable,LogPolling> obj=[blocks objectAtIndex:i];
            [targetGroup removeObject:obj];
            [loggingService.logPoller unregisterPollee:obj];
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


#pragma mark - CCPickerView for number wheel

-(void)setupNumberWheel
{
    if(!pickerViewSelection)pickerViewSelection=[[[NSMutableArray alloc]init]retain];
    
    if(self.pickerView) return;
    
    self.pickerView = [CCPickerView node];
    pickerView.position = ccp(21, 500);
    pickerView.dataSource = self;
    pickerView.delegate = self;

    [pickerViewSelection addObject:[NSNumber numberWithInt:defaultBlocksFromPipe]];
    
    
    [renderLayer addChild:self.pickerView z:20];
}

#pragma mark CCPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(CCPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(CCPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    NSInteger numRows = 0;
    
    switch (component) {
        case 0:
            numRows = maxBlocksFromPipe+1;
            break;
        case 1:
            numRows = 2;
            break;
        case 2:
            numRows=10;
            break;
        default:
            break;
    }
    
    return numRows;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return kComponentHeight;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView widthForComponent:(NSInteger)component {
    return kComponentWidth;
}

- (NSString *)pickerView:(CCPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"Not used";
}

- (CCNode *)pickerView:(CCPickerView *)pickerView nodeForRow:(NSInteger)row forComponent:(NSInteger)component reusingNode:(CCNode *)node {
    
    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", row]fontName:@"Chango" fontSize:24];
    return l;
    
    //    temp.color = ccYELLOW;
    //    temp.textureRect = CGRectMake(0, 0, kComponentWidth, kComponentHeight);
    //
    //    NSString *rowString = [NSString stringWithFormat:@"%d", row];
    //    CCLabelBMFont *label = [CCLabelBMFont labelWithString:rowString fntFile:@"bitmapFont.fnt"];
    //    label.position = ccp(kComponentWidth/2, kComponentHeight/2-5);
    //    [temp addChild:label];
    //    return temp;
    
}

- (void)pickerView:(CCPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    [pickerViewSelection replaceObjectAtIndex:component withObject:[NSNumber numberWithInteger:row]];
    
    NSLog(@"didSelect row = %d, component = %d, totSum = %d", row, component, [self returnPickerNumber]);

    [loggingService logEvent:BL_PA_FBLOCK_TOUCH_END_CHANGE_NUMBER_WHEEL withAdditionalData:nil];
    
    blocksFromPipe=(int)row;
}

- (CGFloat)spaceBetweenComponents:(CCPickerView *)pickerView {
    return kComponentSpacing;
}

- (CGSize)sizeOfPickerView:(CCPickerView *)pickerView {
    CGSize size = CGSizeMake(42, 100);
    
    return size;
}

- (CCNode *)overlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberwheel/FB_OutPut_Pipe__Picker_Overlay.png")];
    return sprite;
}

- (CCNode *)underlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberwheel/FB_OutPut_Pipe__Picker_Overlay.png")];
    [sprite setOpacity:0];
    return sprite;
}

- (void)onDoneSpinning:(CCPickerView *)pickerView component:(NSInteger)component {

    NSLog(@"Component %d stopped spinning.", component);
}

-(int)returnPickerNumber
{
    int retNum=0;
    int power=0;
    
    for(int i=[pickerViewSelection count]-1;i>=0;i--)
    {
        NSNumber *n=[pickerViewSelection objectAtIndex:i];
        int thisNum=[n intValue];
        thisNum=thisNum*(pow((double)10,power));
        retNum+=thisNum;
        power++;
    }
    
    return retNum;
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
    

    if(CGRectContainsPoint(CGRectMake(54,510,20,175), location))
    {
        NSDictionary *d=[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:blocksFromPipe] forKey:NUMBER];
        [loggingService logEvent:BL_PA_FBLOCK_TOUCH_START_CREATE_NEW_GROUP withAdditionalData:nil];
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_pipe_adding_blocks_to_scene.wav")];
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
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_picking_up_blocks.wav")];
                [loggingService logEvent:BL_PA_FBLOCK_TOUCH_START_PICKUP_GROUP withAdditionalData:[(NSObject*)thisGroup isKindOfClass:[SGFBlockGroup class]]?[NSNumber numberWithInt:[(SGFBlockGroup*)thisGroup blocksInGroup]]:nil];
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
            if(location.y>ly-200||location.y<50)return;
            if(location.x>lx-60||location.x<60)return;
            id<Group>grp=(id<Group>)pickupObject;
            [grp moveGroupPositionFrom:lastTouch To:location];
            isInBubble=[grp checkIfInBubbleAt:location];
            if(!hasLoggedMove){
                hasLoggedMove=YES;
                [loggingService logEvent:BL_PA_FBLOCK_TOUCH_MOVE_MOVE_GROUP withAdditionalData:[(NSObject*)grp isKindOfClass:[SGFBlockGroup class]]?[NSNumber numberWithInt:[(SGFBlockGroup*)grp blocksInGroup]]:nil];
            }
        }
    }
    
    if(isInBubble && !audioHasPlayedBubbleProx)
    {
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_block_ready_to_mount_to_bubble.wav")];
        audioHasPlayedBubbleProx=YES;
    }
    
   
    lastTouch=location;
 
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    if(isInBubble && [BLMath DistanceBetween:location and:lastTouch]<15.0f){
       [loggingService logEvent:BL_PA_FBLOCK_TOUCH_MOVE_PLACE_GROUP_IN_BUBBLE withAdditionalData:[(NSObject*)pickupObject isKindOfClass:[SGFBlockGroup class]]?[NSNumber numberWithInt:[(SGFBlockGroup*)pickupObject blocksInGroup]]:nil];
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_adding_blocks_to_bubble.wav")];
    }else{
       [loggingService logEvent:BL_PA_FBLOCK_TOUCH_MOVE_PLACE_GROUP_IN_FREE_SPACE withAdditionalData:[(NSObject*)pickupObject isKindOfClass:[SGFBlockGroup class]]?[NSNumber numberWithInt:[(SGFBlockGroup*)pickupObject blocksInGroup]]:nil];
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_block_outside_of_mountable_area.wav")];
    }
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
            {
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_adding_blocks_to_pipe.wav")];
                
                [loggingService logEvent:BL_PA_FBLOCK_TOUCH_END_DROP_OBJECT_PIPE withAdditionalData:[(NSObject*)pickupObject isKindOfClass:[SGFBlockGroup class]]?[NSNumber numberWithInt:[(SGFBlockGroup*)pickupObject blocksInGroup]]:nil];
                [self evalProblem];
                [self setTouchVarsToOff];
                return;
            }
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_releasing_blocks.wav")];
        }
    }
    
    // if we were moving the marker

    [self setTouchVarsToOff];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{    
    [self setTouchVarsToOff];
}

-(void)setTouchVarsToOff
{
    pickupObject=nil;
    isTouching=NO;
    hasLoggedMove=NO;
    isInBubble=NO;
    audioHasPlayedBubbleProx=NO;
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
//    for(id go in gw.AllGameObjects)
//    {
//        if([go conformsToProtocol:@protocol(Group)])
//        {
//            id<Group>thisGroup=(id<Group>)go;
//            if([thisGroup.MyBlocks count]==expSolution)
//                return YES;
//        }
//    }

    for(id go in gw.AllGameObjects)
    {
        if(evalMode==kProblemEvalAuto && go==pickupObject)
        {
            id<Group>thisGroup=(id<Group>)pickupObject;
            if([thisGroup.MyBlocks count]==expSolution)
                return YES;
        }
        if(evalMode==kProblemEvalOnCommit)
        {
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                id<Moveable>thisObj=(id<Moveable>)go;
                if(CGRectContainsPoint(commitPipe.boundingBox, thisObj.Position))
                {
                    id<Group>thisObjGroup=(id<Group>)thisObj.MyGroup;
                    if([thisObjGroup.MyBlocks count]==expSolution)
                        return YES;
                }
            }
        }
    }
    return NO;
}


-(void)evalProblem
{
    BOOL isWinning=[self evalExpression];
    
    if(isWinning)
    {
        [toolHost doWinning];
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
    
    pickerViewSelection=nil;
    supportedOperators=nil;
    initObjects=nil;
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
