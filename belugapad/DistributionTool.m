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
#import "LoggingService.h"
#import "SGGameWorld.h"
#import "SGDtoolBlock.h"
#import "SGDtoolBlockRender.h"
#import "InteractionFeedback.h"

#define DRAW_DEPTH 1
static float kTimeSinceAction=7.0f;
static float kDistanceBetweenBlocks=70.0f;

@interface DistributionTool()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
    // and then any specifics we need for this tool
    id<Moveable,Transform,Pairable> currentPickupObject;
    
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
    timeSinceInteraction+=delta;
    
    if(timeSinceInteraction>kTimeSinceAction)
    {
        BOOL isWinning=[self evalExpression];
        if(!hasMovedBlock)
        {
            for(id<Moveable> go in gw.AllGameObjects)
            {
                [go.mySprite runAction:[InteractionFeedback shakeAction]];
            }
        }
        
        if(isWinning)[toolHost shakeCommitButton];
        
        timeSinceInteraction=0.0f;
    }

}

-(void)draw
{
    for (int i=0; i<DRAW_DEPTH; i++)
    {
        for(id go in [gw AllGameObjects]) {
            if([go conformsToProtocol:@protocol(Pairable)])
                [((id<Pairable>)go) draw:i];
        }
    } 
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    evalType=[[pdef objectForKey:DISTRIBUTION_EVAL_TYPE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    if([pdef objectForKey:INIT_OBJECTS])initObjects=[pdef objectForKey:INIT_OBJECTS];
    if([pdef objectForKey:SOLUTION])solutionsDef=[pdef objectForKey:SOLUTION];
    
}

-(void)populateGW
{
    // set our renderlayer
    gw.Blackboard.RenderLayer = renderLayer;
    
    // init our array for use with the created gameobjects
    for(int i=0;i<[initObjects count];i++)
    {
        NSDictionary *d=[initObjects objectAtIndex:i];
        int blocksInShape=[[d objectForKey:QUANTITY]intValue];
        [self createShapeWith:blocksInShape andWith:d];
    }
    
}

#pragma mark - objects
-(void)createShapeWith:(int)blocks andWith:(NSDictionary*)theseSettings
{
    NSMutableArray *createdBlocksForShape;
    CCLabelTTF *labelForShape;
    id lastObj=nil;
    int posX=0;
    int posY=0;
    float avgPosX=0;
    float avgPosY=0;
    BOOL hasLabel;
    
    if([theseSettings objectForKey:LABEL]){
        createdBlocksForShape=[[NSMutableArray alloc]init];
        hasLabel=YES;
    }
    

    
    if([theseSettings objectForKey:POS_X])
        posX=[[theseSettings objectForKey:POS_X]intValue];
    else
        posX=(arc4random() % 960) + 30;

    if([theseSettings objectForKey:POS_Y])
        posY=[[theseSettings objectForKey:POS_Y]intValue];
    else
        posY=(arc4random() % 730) + 30;
    
    for(int i=0;i<blocks;i++)
    {
        id<Configurable, Selectable,Pairable> newblock;
        newblock=[[[SGDtoolBlock alloc] initWithGameWorld:gw andRenderLayer:renderLayer andPosition:ccp(posX+(kDistanceBetweenBlocks*i),posY)] autorelease];
        
        [newblock setup];
        if(lastObj){
            [newblock pairMeWith:lastObj];
            [self findMountPositionForThisShape:newblock toThisShape:lastObj];
        }
        
        if(hasLabel){
            [createdBlocksForShape addObject:newblock];
            avgPosX+=posX;
            avgPosY+=posY;
        }
        
        lastObj=newblock;
        
    }
    
    if(hasLabel)
    {
        NSLog(@"(before) avgPosX %f, avgPosY %f", avgPosX, avgPosY);
        avgPosX=avgPosX/2;
        avgPosY=avgPosY/[createdBlocksForShape count];
        NSLog(@"(after) avgPosX %f, avgPosY %f", avgPosX, avgPosY);
        labelForShape=[CCLabelTTF labelWithString:[theseSettings objectForKey:LABEL] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        [labelForShape setPosition:ccp(avgPosX,avgPosY+40)];
        [renderLayer addChild:labelForShape];
    }

}

-(CGPoint)checkWhereIShouldMount:(id<Pairable>)gameObject;
{
    NSArray *existingShapes=[self evalUniqueShapes];
    float minXPos=0.0f;
    float maxXPos=0.0f;
    float minYPos=0.0f;
    float maxYPos=0.0f;
    int shapeIndex=0;
    
    for(int i=0;i<[existingShapes count];i++)
    {
        NSArray *a=[existingShapes objectAtIndex:i];
        if([a containsObject:gameObject])
        {
            shapeIndex=i;
            break;
        }
    }
    
    NSArray *thisShape=[existingShapes objectAtIndex:shapeIndex];
    
    for(id<Pairable> go in thisShape)
    {
        if(go.Position.x>maxXPos)maxXPos=go.Position.x;
        if(go.Position.y>maxYPos)maxYPos=go.Position.y;
        
        if([thisShape indexOfObject:go]==0)
        {
            minXPos=go.Position.x;
            minYPos=go.Position.y;
        }
        else {
            if(go.Position.x<minXPos)minXPos=go.Position.x;
            if(go.Position.y<minYPos)minYPos=go.Position.y;
        }
    }
    
    CGPoint retval=ccp(maxXPos+100,maxYPos);
    return retval;
}

-(CGPoint)findMountPositionForThisShape:(id<Pairable>)pickupObject toThisShape:(id<Pairable>)mountedShape
{
    CGPoint mountedShapePos=mountedShape.Position;
    CGPoint retval=CGPointZero;

    BOOL freeSpaceNegX=YES;
    BOOL freeSpaceNegY=YES;
    BOOL freeSpacePosX=YES;
    BOOL freeSpacePosY=YES;
    
    NSMutableArray *possCoords=[[NSMutableArray alloc]init];
    

    
    for(id<Moveable,Pairable> go in mountedShape.PairedObjects)
    {
        NSLog(@"go Position %@, current retVal %@", NSStringFromCGPoint(go.Position), NSStringFromCGPoint(mountedShapePos));
        if(go==pickupObject)continue;
        
        if(mountedShapePos.x-kDistanceBetweenBlocks==go.Position.x && freeSpaceNegX)
            freeSpaceNegX=NO;
        else if(mountedShapePos.x+kDistanceBetweenBlocks==go.Position.x && freeSpacePosX)
            freeSpacePosX=NO;
        else if(mountedShapePos.y-kDistanceBetweenBlocks==go.Position.y && freeSpaceNegY)
            freeSpaceNegY=NO;
        else if(mountedShapePos.y+kDistanceBetweenBlocks==go.Position.y && freeSpacePosY)
            freeSpacePosY=NO;
           
           //NSLog(@"go Position %@, final retVal %@, found other shape? %@", NSStringFromCGPoint(go.Position), NSStringFromCGPoint(retval), foundAnotherShape? @"YES":@"NO");
    }
           
    NSLog(@"-x %@, +x %@, -y %@, +y %@", freeSpaceNegX? @"YES":@"NO", freeSpacePosX? @"YES":@"NO", freeSpaceNegY? @"YES":@"NO", freeSpacePosY? @"YES":@"NO");
    

        if(freeSpacePosX)
        {
            CGPoint retvalPX=ccp(mountedShapePos.x+kDistanceBetweenBlocks, mountedShapePos.y);
            [possCoords addObject:[NSValue valueWithCGPoint:retvalPX]];
        }
        if(freeSpaceNegX)
        {
            CGPoint retvalNX=ccp(mountedShapePos.x-kDistanceBetweenBlocks, mountedShapePos.y); 
            [possCoords addObject:[NSValue valueWithCGPoint:retvalNX]];
        }
        if(freeSpacePosY)
        {
            CGPoint retvalPY=ccp(mountedShapePos.x, mountedShapePos.y+kDistanceBetweenBlocks);
            [possCoords addObject:[NSValue valueWithCGPoint:retvalPY]];
        }
        if(freeSpaceNegY)
        {
            CGPoint retvalNY=ccp(mountedShapePos.x, mountedShapePos.y-kDistanceBetweenBlocks);
            [possCoords addObject:[NSValue valueWithCGPoint:retvalNY]];
        }
   


    if([possCoords count]>0)
    {
        int retValNum=(arc4random() % [possCoords count]);
        NSLog(@"retval posscords count is %d chosennum is %d", [possCoords count], retValNum);
        retval=[[possCoords objectAtIndex:retValNum]CGPointValue];
    }
    else
    {
        // TODO: decide what a no-mount-point scenario does - for now we just move it down
        retval=ccp(10,10);
    }
    return retval;
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
                [loggingService logEvent:BL_PA_DT_TOUCH_START_PICKUP_BLOCK withAdditionalData:nil];
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
        if(!hasMovedBlock)hasMovedBlock=YES;
        if(!hasLoggedMovedBlock)
        {
            [loggingService logEvent:BL_PA_DT_TOUCH_MOVE_MOVE_BLOCK withAdditionalData:nil];
            hasLoggedMovedBlock=YES;
        }
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
                BOOL prx=[go amIProximateTo:location];
                if(prx)hasBeenProximate=YES;
            }
        }
    }
    
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
    // check there's a pickupobject
    if(currentPickupObject)
    {
        CGPoint curPOPos=currentPickupObject.Position;
        // check all the gamobjects and search for a moveable object
        for(id go in gw.AllGameObjects)
        {
            if(go==currentPickupObject)
            {
                [go resetTint];
                continue;
            }
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                // return whether the object is proximate to our current pickuobject
                BOOL proximateToPickupObject=[go amIProximateTo:curPOPos];
                [go resetTint];
                if(proximateToPickupObject){
                    [go pairMeWith:currentPickupObject];
                    
                    [loggingService logEvent:BL_PA_DT_TOUCH_END_PAIR_BLOCK withAdditionalData:nil];
                    
                    currentPickupObject.Position=[self findMountPositionForThisShape:currentPickupObject toThisShape:go];
                    [currentPickupObject animateToPosition];
                    
                }
                else {
                    [go unpairMeFrom:currentPickupObject];
                }
                
                //TODO: add bit in here to check existing links - ie, at the minute, if a block is dragged out of the middle of the row, it doesn't seem to update all of them
                
                [self evalUniqueShapes];
                if(evalMode==kProblemEvalAuto)[self evalProblem];
                
            }
        }
    }
    
    if(hasBeenProximate)
    {
        hasBeenProximate=NO;
        [loggingService logEvent:BL_PA_DT_TOUCH_MOVE_PROXIMITY_OF_BLOCK withAdditionalData:nil];
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

-(NSArray*)evalUniqueShapes
{
    NSMutableArray *checkedObjects=[[NSMutableArray alloc]init];
    NSMutableArray *foundShapes=[[NSMutableArray alloc]init];
    
    // loop through each object in the gameworld
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(Pairable)])
        {
            // cast the go as a pairable to use properties
            id<Pairable> pairableGO=(id<Pairable>)go;
            
            //check if we're a lonesome object
            if ([pairableGO.PairedObjects count]==0) {
                NSMutableArray *shape=[[NSMutableArray alloc]init];
                [shape addObject:pairableGO];
                [foundShapes addObject:shape];       
                [shape release];
            }
            // and if not, run our normal checks
            else {
                // for each object in the pairedobjects array
                for(id<Pairable> pairedObj in pairableGO.PairedObjects)
                {
                    // we need to know if this is already in checked objects - if it's not, add it
                    if(![checkedObjects containsObject:pairedObj])
                        [checkedObjects addObject:pairedObj];
                    else
                        continue;
                    
                    //we need our arrays to contain arrays of each shape so
                    //if the count of fondshapes is <1 we must be starting so we need to add a shape
                    if([foundShapes count]<1)
                    {
                        NSMutableArray *shape=[[NSMutableArray alloc]init];
                        [shape addObject:pairedObj];
                        [foundShapes addObject:shape];
                        [shape release];
                    }
                    
                    else if([foundShapes count]>0)
                    {
                        BOOL noArrayFound;
                        
                        // but if it's greater we need to loop through the existing shape arrays
                        for (NSMutableArray *a in foundShapes)
                        {
                            // loop through each object in the current paired objects paired objects
                            for(id<Pairable> fsGO in pairedObj.PairedObjects)
                            {
                                // and if the array contains one of the paired objects - we know it already exists
                                if([a containsObject:fsGO])
                                {
                                    // so add it to the current shape and set the bool to NO and break the loop
                                    [a addObject:pairedObj];
                                    noArrayFound=NO;
                                    break;
                                }
                                else
                                {
                                    // but if after all this we find no array to stick our object in, confirm that we've not found an array
                                    noArrayFound=YES;
                                }
                            }
                        }

                        
                        // and if we haven't found a matching array, stick it into a new array that we add to found shapes
                        if(noArrayFound)
                        {
                            NSMutableArray *shape=[[NSMutableArray alloc]init];
                            [shape addObject:pairedObj];
                            [foundShapes addObject:shape];
                            [shape release];
                        }
                    }
                    
                }
            }
            
        }
    }
    
    for(int i=0;i<[foundShapes count];i++)
    {
        //NSLog(@"recurse shape %d", i);
        for(int fs=0; fs<[[foundShapes objectAtIndex:i] count];fs++)
        {
            //NSLog(@"object %d", fs);
        }
    }
    
    [checkedObjects release];
    
    return [foundShapes autorelease];
    
}

-(BOOL)evalExpression
{
    int solutionsFound=0;
    int solutionsExpected=[solutionsDef count];
    NSMutableArray *shapesMatched=[[NSMutableArray alloc]init];
    NSArray *shapesHere=[self evalUniqueShapes];

    
    for(int i=0;i<[solutionsDef count];i++)
    {
        int thisSolution=[[solutionsDef objectAtIndex:i]intValue];
        for(NSArray *a in shapesHere)
        {
            if([a count]==thisSolution&&![shapesMatched containsObject:a]){
                [shapesMatched addObject:a];
                solutionsFound++;
            }
        }
    }
    
    [shapesMatched release];
    
    if(solutionsFound==solutionsExpected)
        return YES;
    else
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

    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [renderLayer release];
    
    [gw release];
    
    [super dealloc];
}
@end