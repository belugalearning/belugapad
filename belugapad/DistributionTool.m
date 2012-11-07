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
#import "LogPoller.h"
#import "SGGameWorld.h"
#import "SGDtoolBlock.h"
#import "SGDtoolCage.h"
#import "SGDtoolContainer.h"
#import "SGDtoolBlockRender.h"
#import "InteractionFeedback.h"
#import "SimpleAudioEngine.h"

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
    id<Cage> cage;
    CGPoint pickupPos;
    
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
    
    [self tidyUpEmptyGroups];
     
    timeSinceInteraction+=delta;
    
    if(timeSinceInteraction>kTimeSinceAction)
    {
        BOOL isWinning=[self evalExpression];
        if(!hasMovedBlock)
        {
            for(id go in gw.AllGameObjects)
            {
                if([go conformsToProtocol:@protocol(Moveable)])
                    [((id<Moveable>)go).mySprite runAction:[InteractionFeedback shakeAction]];
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
    problemHasCage=[[pdef objectForKey:HAS_CAGE]boolValue];
    cageObjectCount=[[pdef objectForKey:CAGE_OBJECT_COUNT]intValue];
    hasInactiveArea=[[pdef objectForKey:HAS_INACTIVE_AREA]boolValue];
    cannotBreakBonds=[[pdef objectForKey:UNBREAKABLE_BONDS]boolValue];
    randomiseDockPositions=[[pdef objectForKey:RANDOMISE_DOCK_POSITIONS]boolValue];
    
    

    if([pdef objectForKey:DOCK_TYPE])
        dockType=[pdef objectForKey:DOCK_TYPE];
    else
        dockType=@"Infinite";
    
    if(cageObjectCount>0 && [dockType isEqualToString:@"Infinite"])
    {
        if(cageObjectCount>0 && cageObjectCount<=15)
            dockType=@"15";
        else if(cageObjectCount>15 && cageObjectCount<=30)
            dockType=@"30";
        
    }
    
    if([pdef objectForKey:INIT_OBJECTS])initObjects=[pdef objectForKey:INIT_OBJECTS];
    if([pdef objectForKey:EVAL_AREAS])initAreas=[pdef objectForKey:EVAL_AREAS];
    if([pdef objectForKey:SOLUTION])solutionsDef=[pdef objectForKey:SOLUTION];
    
    if(hasInactiveArea && cannotBreakBonds)
        cannotBreakBonds=NO;
    usedShapeTypes=[[[NSMutableArray alloc]init]retain];
}

-(void)populateGW
{
    // set our renderlayer
    gw.Blackboard.RenderLayer = renderLayer;
    
    if(hasInactiveArea)
    {
        inactiveArea=[[[NSMutableArray alloc]init]retain];
        
        int thisPos=0;
        int areaWidth=4;
        int areaSize=16;
        float startXPos=lx-(62*areaWidth);
        float startYPos=50;
        int areaOpacity=100;
        
        for(int i=0;i<areaSize;i++)
        {
            if(thisPos==areaWidth)thisPos=0;
            int thisRow=i/areaWidth;
            
            CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/distribution/DT_area_2.png")];
            [s setPosition:ccp(startXPos+(thisPos*s.contentSize.width),startYPos+(thisRow*s.contentSize.height))];
            [s setOpacity:areaOpacity];
            [self.ForeLayer addChild:s];
            [inactiveArea addObject:s];
            
            thisPos++;
        }

    }
    
    // init our array for use with the created gameobjects
    for(int i=0;i<[initObjects count];i++)
    {
        NSDictionary *d=[initObjects objectAtIndex:i];
        int blocksInShape=[[d objectForKey:QUANTITY]intValue];
        [self createShapeWith:blocksInShape andWith:d];
    }
    
    if([usedShapeTypes count]==0)
        [usedShapeTypes addObject:@"Circle"];
    
    if(problemHasCage)
    {
        if(!dockType)
            dockType=@"Infinite";
        
        if(!addedCages && [dockType isEqualToString:@"Infinite"])
            addedCages=[[[NSMutableArray alloc]init]retain];
        
        for(int i=0;i<[usedShapeTypes count];i++)
        {
            int s=fabsf([usedShapeTypes count]-5);
            float adjLX=lx-(lx*((24*s)/lx));
            
            // render buttons
            float sectionW=adjLX / [usedShapeTypes count];
            

            
            cage=[[SGDtoolCage alloc]initWithGameWorld:gw atPosition:ccp(((24*s)/2)+((i+0.5) * sectionW), 80) andRenderLayer:renderLayer andCageType:dockType];
            cage.BlockType=[usedShapeTypes objectAtIndex:i];
            cage.InitialObjects=cageObjectCount;
            cage.RandomPositions=randomiseDockPositions;
            [cage setup];
            [cage spawnNewBlock];
            
            [addedCages addObject:cage];
        }
        
        
    }
    
    [self createEvalAreas];
    
}

#pragma mark - objects
-(void)createShapeWith:(int)numBlocks andWith:(NSDictionary*)theseSettings
{
//    CCLabelTTF *labelForShape;
//    float avgPosX=0;
//    float avgPosY=0;
    NSArray *thesePositions=[NSArray arrayWithArray:[NumberLayout physicalLayoutUpToNumber:numBlocks withSpacing:kDistanceBetweenBlocks]];
    
    NSString *label = [theseSettings objectForKey:LABEL];
    NSString *blockType = [theseSettings objectForKey:BLOCK_TYPE];
    
    if(!blockType)
        blockType=@"Circle";

    
    if(![usedShapeTypes containsObject:blockType])
        [usedShapeTypes addObject:blockType];
    
    SGDtoolContainer *container = [[SGDtoolContainer alloc] initWithGameWorld:gw andLabel:label andRenderLayer:renderLayer];
    container.BlockType=blockType;
    if (label && !existingGroups) existingGroups = [[NSMutableArray arrayWithObject:label] retain];
    float startPosX=0;
    float startPosY=0;
    
    if(!hasInactiveArea)
    {
        CGPoint top=[[thesePositions objectAtIndex:0]CGPointValue];
        CGPoint bottom=[[thesePositions objectAtIndex:[thesePositions count]-1]CGPointValue];
        
        int farLeft=top.x+60;
        int farRight=lx-bottom.x-60;
        int topMost=ly-top.y-60;
        int botMost=0+-bottom.y+60;
        
        //startPosX=[theseSettings objectForKey:POS_X] ? [[theseSettings objectForKey:POS_X]intValue] : (arc4random() % 960) + 30;
        //startPosY=[theseSettings objectForKey:POS_Y] ? [[theseSettings objectForKey:POS_Y]intValue] : (arc4random() % 730) + 30;
        
        startPosX = farLeft + arc4random() % (farRight - farLeft);
        startPosY = botMost + arc4random() % (topMost - botMost);
    }
    else
    {
        inactiveRect=CGRectNull;
        
        for(CCSprite *s in inactiveArea)
            inactiveRect=CGRectUnion(inactiveRect, s.boundingBox);
        int farLeft=inactiveRect.origin.x+inactiveRect.size.width/2;
        int farRight=inactiveRect.origin.x+inactiveRect.size.width;
        int topMost=inactiveRect.origin.y+inactiveRect.size.height;
        int botMost=inactiveRect.origin.y+inactiveRect.size.height/2;
        
        startPosX = farLeft + arc4random() % (farRight - farLeft);
        startPosY = botMost + arc4random() % (topMost - botMost);

    }
    for (int i=0; i<numBlocks; i++)
    {
        CGPoint thisPoint=[[thesePositions objectAtIndex:i]CGPointValue];
        
        CGPoint p = ccp(startPosX+thisPoint.x,  startPosY+thisPoint.y);
        SGDtoolBlock *block =  [[[SGDtoolBlock alloc] initWithGameWorld:gw andRenderLayer:renderLayer andPosition:p andType:blockType] autorelease];
        [block setup];
        block.MyContainer = container;
        
        if(cannotBreakBonds)
            block.LineType=1;
            
        
        [container addBlockToMe:block];
        
        if(!hasInactiveArea||cannotBreakBonds)
        {
            if(i){
                SGDtoolBlock *prevBlock = [container.BlocksInShape objectAtIndex:i-1];
                [block pairMeWith:prevBlock];
                [self returnNextMountPointForThisShape:container];
            }
        }
        [container layoutMyBlocks];
        [loggingService.logPoller registerPollee:block];
    }
       
    thesePositions=nil;
    
//    if(hasLabel)
//    {
//
//        
//        
//        NSLog(@"(before) avgPosX %f, avgPosY %f", avgPosX, avgPosY);
//        avgPosX=avgPosX/2;
//        avgPosY=avgPosY/[createdBlocksForShape count];
//        NSLog(@"(after) avgPosX %f, avgPosY %f", avgPosX, avgPosY);
//        labelForShape=[CCLabelTTF labelWithString:[theseSettings objectForKey:LABEL] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
//        [labelForShape setPosition:ccp(avgPosX,avgPosY+40)];
//        [renderLayer addChild:labelForShape];
//    }

}

-(void)createEvalAreas
{
    if(!initAreas)return;
    
    if(!evalAreas)
        evalAreas=[[[NSMutableArray alloc]init]retain];

    for(int i=0;i<[initAreas count];i++)
    {
        NSDictionary *d=[initAreas objectAtIndex:i];
        NSString *lblText=[d objectForKey:LABEL];
        int areaSize=[[d objectForKey:AREA_SIZE]intValue];
        int areaWidth=[[d objectForKey:AREA_WIDTH]intValue];
        int areaOpacity=0;
        int distFromLX=(lx-30-(areaWidth*62));
        int distFromLY=(ly-80-(areaSize/areaWidth)*62);
        int startXPos=(arc4random() % distFromLX)+30;
        int startYPos=(arc4random() % distFromLY)+60;
        
        if([d objectForKey:AREA_OPACITY])
            areaOpacity=[[d objectForKey:AREA_OPACITY]intValue];
        else
            areaOpacity=255;
        
        NSMutableArray *thisArea=[[NSMutableArray alloc]init];
        int thisPos=0;
        
        for(int i=0;i<areaSize;i++)
        {
            if(thisPos==areaWidth)thisPos=0;
            int thisRow=i/areaWidth;
            
            CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/distribution/DT_area_2.png")];
            [s setPosition:ccp(startXPos+(thisPos*s.contentSize.width),startYPos+(thisRow*s.contentSize.height))];
            [s setOpacity:areaOpacity];
            [self.ForeLayer addChild:s];
            
            if(i==1 && lblText)
            {
                CCLabelTTF *l=[CCLabelTTF labelWithString:lblText fontName:SOURCE fontSize:35.0f];
                [l setPosition:ccp(s.contentSize.width/2, -s.contentSize.height/2)];
                [s addChild:l];
            }
            
            [thisArea addObject:s];
            thisPos++;
        }
        
        [evalAreas addObject:thisArea];
    }
}

-(void)createContainerWithOne:(id)Object
{
    id<Container> container;
    NSLog(@"create container - there are %d destroyed labelled groups", [destroyedLabelledGroups count]);
    if([destroyedLabelledGroups count]==0)
    {
        container=[[SGDtoolContainer alloc]initWithGameWorld:gw andLabel:nil andRenderLayer:nil];
    }
    else
    {
        NSLog(@"creating labelled group: %@",[destroyedLabelledGroups objectAtIndex:0]);
        container=[[SGDtoolContainer alloc]initWithGameWorld:gw andLabel:[destroyedLabelledGroups objectAtIndex:0] andRenderLayer:renderLayer];
        [destroyedLabelledGroups removeObjectAtIndex:0];
        [existingGroups addObject:[container.Label string]];
    }
    
    container.BlockType=((id<Configurable>)Object).blockType;
    
    for(id obj in [NSArray arrayWithArray:gw.AllGameObjectsCopy])
    {
        if([obj conformsToProtocol:@protocol(Moveable)]){
            id<Moveable>go=(id<Moveable>)obj;
            if([go amIProximateTo:((id<Moveable>)Object).Position] && go.MyContainer==nil)
                [container addBlockToMe:go];
        }
    }
    
    [container addBlockToMe:Object];
    [container layoutMyBlocks];
}

-(void)lookForOrphanedObjects
{
    NSArray *allGWGO=[NSArray arrayWithArray:gw.AllGameObjects];
    
    for(id go in allGWGO)
    {
        if([go conformsToProtocol:@protocol(Moveable)])
        {
            id <Moveable> cObj=go;
            if(!cObj.MyContainer)
                [self createContainerWithOne:cObj];
        }

    }
}

-(void)updateContainerForNewlyAddedBlock:(id<Moveable,Pairable>)thisBlock
{
    // if there are no paired objects - make sure i am removed from any container i may be part of
    
    NSLog(@"this block paired to %d", [thisBlock.PairedObjects count]);
    
    if([thisBlock.PairedObjects count]==0)
    {
        if(thisBlock.MyContainer)
            [thisBlock.MyContainer removeBlockFromMe:thisBlock];
            
    }
    else
    {
        // set a new container by assuming the same container as any of the paired objects (not resetting if part of this container)
        id<Moveable,Pairable>pairedObj=[thisBlock.PairedObjects objectAtIndex:0];
        if(thisBlock.MyContainer != pairedObj.MyContainer)
        {
            if(thisBlock.MyContainer)
                [thisBlock.MyContainer removeBlockFromMe:thisBlock];
            
            //TODO: this is causing a crash if dragged from a cage
            if(![pairedObj.MyContainer conformsToProtocol:@protocol(Cage)])
                [pairedObj.MyContainer addBlockToMe:thisBlock];
            
            [pairedObj.MyContainer layoutMyBlocks];
        }
    }
}

-(void)tidyUpEmptyGroups
{
    NSArray *allGWGO=gw.AllGameObjectsCopy;
    
    for(id go in allGWGO)
    {
        if([go conformsToProtocol:@protocol(Container)])
        {
            id <Container> cObj=go;
            
            if([cObj.BlocksInShape count]==0)
            {
                
                if([existingGroups containsObject:[cObj.Label string]])
                {
                    [existingGroups removeObject:[cObj.Label string]];
                    if(!destroyedLabelledGroups)destroyedLabelledGroups=[[NSMutableArray alloc]init];
                    [destroyedLabelledGroups addObject:[cObj.Label string]];
                }
            
                
                [cObj destroyThisObject];
            }
            
        }
        
        
        
        
        
    }
}

-(void)updateContainerLabels
{
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(Container)])
        {
            id<Container>c=(id<Container>)go;
            [c repositionLabel];
            
            
            for(id<Pairable>tgo in c.BlocksInShape)
            {
                NSLog(@"block position in group %@", NSStringFromCGPoint(tgo.Position));
            }
            
            NSLog(@"count of group %d", [c.BlocksInShape count]);
        }
    }
}

-(void)removeBlockByCage
{
    
    if(currentPickupObject)
    {
        for(id<Pairable> pairedObj in [NSArray arrayWithArray:currentPickupObject.PairedObjects])
        {
            [pairedObj unpairMeFrom:currentPickupObject];
        }
        
        SGGameObject *go=(SGGameObject*)currentPickupObject;
        CCSprite *s=currentPickupObject.mySprite;
        CCMoveTo *moveAct=[CCMoveTo actionWithDuration:0.3f position:cage.Position];
        CCFadeOut *fadeAct=[CCFadeOut actionWithDuration:0.1f];
        CCAction *cleanUp=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES]; [gw delayRemoveGameObject:go];}];
        CCSequence *sequence=[CCSequence actions:moveAct, fadeAct, cleanUp, nil];
        [s runAction:sequence];
        currentPickupObject=nil;

        
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
//        NSLog(@"go Position %@, current retVal %@", NSStringFromCGPoint(go.Position), NSStringFromCGPoint(mountedShapePos));
        if(go==pickupObject)continue;
        
        if(mountedShapePos.x-kDistanceBetweenBlocks==go.Position.x && freeSpaceNegX && mountedShapePos.x-kDistanceBetweenBlocks>50.0f)
            freeSpaceNegX=NO;
        else if(mountedShapePos.x+kDistanceBetweenBlocks==go.Position.x && freeSpacePosX && mountedShapePos.x+kDistanceBetweenBlocks<(lx-50.0f))
            freeSpacePosX=NO;
        else if(mountedShapePos.y-kDistanceBetweenBlocks==go.Position.y && freeSpaceNegY && mountedShapePos.y-kDistanceBetweenBlocks>50.0f)
            freeSpaceNegY=NO;
        else if(mountedShapePos.y+kDistanceBetweenBlocks==go.Position.y && freeSpacePosY && mountedShapePos.y+kDistanceBetweenBlocks>(lx-50.0f))
            freeSpacePosY=NO;
           
           //NSLog(@"go Position %@, final retVal %@, found other shape? %@", NSStringFromCGPoint(go.Position), NSStringFromCGPoint(retval), foundAnotherShape? @"YES":@"NO");
    }
           
//    NSLog(@"-x %@, +x %@, -y %@, +y %@", freeSpaceNegX? @"YES":@"NO", freeSpacePosX? @"YES":@"NO", freeSpaceNegY? @"YES":@"NO", freeSpacePosY? @"YES":@"NO");
    

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
//        NSLog(@"retval posscords count is %d chosennum is %d", [possCoords count], retValNum);
        retval=[[possCoords objectAtIndex:retValNum]CGPointValue];
    }
    else
    {
        // TODO: decide what a no-mount-point scenario does - for now we just move it down
        retval=ccp(10,10);
    }
    return retval;
}

-(BOOL)evalNumberOfShapesInEvalAreas
{
    NSMutableArray *solutions=[NSMutableArray arrayWithArray:solutionsDef];
    
    int shapesInArea[[evalAreas count]];
    int solutionsFound=0;
    
    for(int i=0;i<[evalAreas count];i++)
    {
        shapesInArea[i]=0;
    }
    
    for(int i=0;i<[evalAreas count];i++)
    {
        CGRect thisRect=CGRectNull;
        NSArray *a=[evalAreas objectAtIndex:i];
        
        for(CCSprite *s in a)
        {
            thisRect=CGRectUnion(thisRect, s.boundingBox);
        }
        
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Pairable)])
            {
                id<Pairable>c=(id<Pairable>)go;
                
                if(CGRectContainsPoint(thisRect, c.Position))
                    shapesInArea[i]++;
                
            }
        }
        
        NSNumber *thisNo=nil;
        for(int i=0;i<[solutions count];i++)
        {
            NSNumber *n=nil;
            NSString *s=nil;

            if([[solutions objectAtIndex:i] isKindOfClass:[NSNumber class]])
                n=[solutions objectAtIndex:i];
            
            if([[solutions objectAtIndex:i] isKindOfClass:[NSString class]]){
                s=[solutions objectAtIndex:i];
                [s integerValue];
            }

            
            if([n isEqualToNumber:[NSNumber numberWithInt:shapesInArea[i]]])
            {
                thisNo=n;
                solutionsFound++;
            }
        }
        [solutions removeObject:thisNo];

    }

    if(solutionsFound==[solutionsDef count])
        return YES;
    else
        return NO;
}

-(BOOL)evalGroupTypesAndShapes
{
    NSMutableArray *shapesFound=[[NSMutableArray alloc]init];
    NSMutableArray *solFound=[[NSMutableArray alloc]init];
    int solutionsExpected=[solutionsDef count];
    int solutionsFound=0;
    
    
    for(NSDictionary *d in solutionsDef)
    {
        if([solFound containsObject:d])continue;
        
        for (id cont in gw.AllGameObjects)
        {
            if([shapesFound containsObject:cont])continue;
            
            if([cont conformsToProtocol:@protocol(Container)])
            {
                id<Container>thisCont=cont;
                
                NSLog(@"thisCont type=%@, thisCont BlocksInShape=%d", thisCont.BlockType, [thisCont.BlocksInShape count]);
                
                if([thisCont.BlocksInShape count]==[[d objectForKey:NUMBER]intValue] && [thisCont.BlockType isEqualToString:[d objectForKey:BLOCK_TYPE]])
                {
                    solutionsFound++;
                    [shapesFound addObject:cont];
                    [solFound addObject:d];
                    continue;
                }
            }
        }
    }
    
    
    
    NSLog(@"solutions found %d required %d", solutionsFound, solutionsExpected);
    if (solutionsFound==solutionsExpected)
        return YES;
    else
        return NO;

}

-(CGPoint)returnNextMountPointForThisShape:(id<Container>)thisShape
{
    id<Moveable>firstShape=[thisShape.BlocksInShape objectAtIndex:0];
    
    NSArray *newObjects=[NumberLayout physicalLayoutUpToNumber:[thisShape.BlocksInShape count] withSpacing:kDistanceBetweenBlocks];
    
    CGPoint newVal=[[newObjects objectAtIndex:[newObjects count]-1] CGPointValue];
    
    newVal=[BLMath AddVector:newVal toVector:firstShape.Position];
    
    return newVal;
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
                pickupPos=((id<Moveable>)currentPickupObject).Position;
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
    
    // check the pickup start position against a cage position. if they matched, then spawn a new block
    if(problemHasCage && !spawnedNewObj)
    {
        for(id<Cage>thisCage in addedCages)
        {
            if([BLMath DistanceBetween:thisCage.Position and:pickupPos]<=60.0f)
            {
                cage=thisCage;
            }
        }
        
        pickupPos=CGPointZero;
    }
    
    if(currentPickupObject)
    {
        if(!hasMovedBlock)hasMovedBlock=YES;
        if(!hasLoggedMovedBlock)
        {
            [loggingService logEvent:BL_PA_DT_TOUCH_MOVE_MOVE_BLOCK withAdditionalData:nil];
            hasLoggedMovedBlock=YES;
        }

        // check that the shape is being moved within bounds of the screen
        if((location.x>=60.0f&&location.x<=lx-60.0f) && (location.y>=60.0f&&location.y<=ly-60.0f))
        {
            // set it's position and move it!
            currentPickupObject.Position=location;
            [currentPickupObject move];
        }
        
        // then for each other moveable thing, check if we're proximate
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Moveable)] && [go conformsToProtocol:@protocol(Pairable)])
            {
                BOOL prx=[go amIProximateTo:location];
                if(prx)
                {
                    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_interation_feedback_block_trying_to_bond.wav")];
                    hasBeenProximate=YES;
                }
                [go resetTint];

                [go unpairMeFrom:go];
                if(((id<Moveable>)go).MyContainer==currentPickupObject.MyContainer)
                   [((id<Container>)((id<Moveable>)go).MyContainer) removeBlockFromMe:go];
                
                for(id<Moveable,Pairable>gop in ((id<Moveable,Pairable>)go).PairedObjects)
                {
                    
                    NSLog(@"count of pairedobjects for go %d is %d", (int)go, [((id<Moveable,Pairable>)go).PairedObjects count]);
                    if([gop amIProximateTo:((id<Moveable>)go).Position])
                    {
                        if(gop.MyContainer)
                            [((id<Container>)((id<Moveable>)gop).MyContainer) removeBlockFromMe:gop];
                        
                        gop.MyContainer=((id<Moveable>)go).MyContainer;
                        [gop pairMeWith:go];
                        [((id<Container>)((id<Moveable>)go).MyContainer) addBlockToMe:gop];
                    }
                    
                }
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
    NSArray *allGWCopy=[NSArray arrayWithArray:gw.AllGameObjects];
    
    [cage spawnNewBlock];
    
    if(currentPickupObject)
    {
        CGPoint curPOPos=currentPickupObject.Position;
        // check all the gamobjects and search for a moveable object
        
        if([BLMath DistanceBetween:curPOPos and:cage.Position]<90.0f && problemHasCage)
        {
            [self removeBlockByCage];
            return;
        }
        
        id previousObjectContainer=nil;
        
        for(id go in allGWCopy)
        {
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                if(go==currentPickupObject)
                {
                    [go resetTint];
                    continue;
                }
                // return whether the object is proximate to our current pickuobject
                BOOL proximateToPickupObject=[go amIProximateTo:curPOPos];
                [go resetTint];
                if(!proximateToPickupObject&&!cannotBreakBonds){
                    [go unpairMeFrom:currentPickupObject];
                }
                else {
                    
                    id<Moveable,Pairable>cObj=(id<Moveable,Pairable>)go;
                    
                    // we only want to be pairable with a container with objects of the same group - so check that here
                    
                    if(!previousObjectContainer || previousObjectContainer==cObj.MyContainer)
                    {
                        if(!CGRectContainsPoint(inactiveRect, location)){
                            
                            if([cObj.PairedObjects count]>0 && cannotBreakBonds)return;
                            
                            if(evalAreas){
                                for(NSArray *a in evalAreas)
                                {
                                    CGRect evalAreaBox=CGRectNull;
                                    for(CCSprite *s in a)
                                    {
                                        evalAreaBox=CGRectUnion(evalAreaBox, s.boundingBox);
                                    }
                                    
                                    if(CGRectContainsPoint(evalAreaBox, cObj.Position))
                                    {
                                        currentPickupObject=nil;
                                        isTouching=NO;
                                        spawnedNewObj=NO;
                                        return;
                                    }
                                }
                            }
                            [go pairMeWith:currentPickupObject];
                        
                            previousObjectContainer=cObj.MyContainer;
                            
                            
                            [loggingService logEvent:BL_PA_DT_TOUCH_END_PAIR_BLOCK withAdditionalData:nil];
                            
                            //currentPickupObject.Position=[self returnNextMountPointForThisShape:cObj.MyContainer];
                            [cObj.MyContainer layoutMyBlocks];
                            //[currentPickupObject animateToPosition];
                        }
                    }
                }
                
                //TODO: add bit in here to check existing links - ie, at the minute, if a block is dragged out of the middle of the row, it doesn't seem to update all of them
                
                
            }

        }
        [self updateContainerForNewlyAddedBlock:currentPickupObject];
        [self lookForOrphanedObjects];
        [self tidyUpEmptyGroups];
        [self updateContainerLabels];
        [currentPickupObject resetTint];
        
        //[self evalUniqueShapes];
        if(evalMode==kProblemEvalAuto)[self evalProblem];
    }
    
    
    if(hasBeenProximate)
    {
        hasBeenProximate=NO;
        [loggingService logEvent:BL_PA_DT_TOUCH_MOVE_PROXIMITY_OF_BLOCK withAdditionalData:nil];
    }
    
    currentPickupObject=nil;
    isTouching=NO;
    spawnedNewObj=NO;
    audioHasPlayedBonding=NO;
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    currentPickupObject=nil;
    spawnedNewObj=NO;
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
            id<Pairable,Moveable> pairableGO=(id<Pairable,Moveable>)go;
            if(![pairableGO.MyContainer conformsToProtocol:@protocol(Container)])
                continue;
                
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
//    if(evalType==kCheckShapeSizes)
//    {
//        int solutionsFound=0;
//        int solutionsExpected=[solutionsDef count];
//        NSMutableArray *shapesMatched=[[NSMutableArray alloc]init];
//        NSArray *shapesHere=[self evalUniqueShapes];
//
//        
//        for(int i=0;i<[solutionsDef count];i++)
//        {
//            int thisSolution=[[solutionsDef objectAtIndex:i]intValue];
//            for(NSArray *a in shapesHere)
//            {
//                if([a count]==thisSolution&&![shapesMatched containsObject:a]){
//                    [shapesMatched addObject:a];
//                    solutionsFound++;
//                }
//            }
//        }
//        
//        [shapesMatched release];
//        
//        if(solutionsFound==solutionsExpected)
//            return YES;
//        else
//            return NO;
//    }
    if(evalType==kCheckShapeSizes)
    {
        NSMutableArray *shapesFound=[[NSMutableArray alloc]init];
        NSMutableArray *solFound=[[NSMutableArray alloc]init];
        int solutionsExpected=[solutionsDef count];
        int solutionsFound=0;
        
        
        for(NSNumber *n in solutionsDef)
        {
            if([solFound containsObject:n])continue;
            
            for (id cont in gw.AllGameObjects)
            {
                if([shapesFound containsObject:cont])continue;
                
                if([cont conformsToProtocol:@protocol(Container)])
                {
                    id<Container>thisCont=cont;
                    
                    if([thisCont.BlocksInShape count]==[n intValue])
                    {
                        solutionsFound++;
                        [shapesFound addObject:cont];
                        [solFound addObject:n];
                        continue;
                    }
                }
            }
        }
        
        
          
        NSLog(@"solutions found %d required %d", solutionsFound, solutionsExpected);
        if (solutionsFound==solutionsExpected)
            return YES;
        else
            return NO;

    }
    
    else if(evalType==kCheckNamedGroups)
    {
        NSDictionary *d=[solutionsDef objectAtIndex:0];
        int solutionsExpected=[d count];
        int solutionsFound=0;
        
        for(id cont in gw.AllGameObjects)
        {
                if([cont conformsToProtocol:@protocol(Container)])
                {
                    id <Container> thisCont=cont;
                    NSString *thisKey=[thisCont.Label string];
                    if([d objectForKey:thisKey])
                    {

                        int thisVal=[[d objectForKey:thisKey] intValue];
                         NSLog(@"this group %d, required for key %d", [thisCont.BlocksInShape count], thisVal);
                        if([thisCont.BlocksInShape count]==thisVal)
                            solutionsFound++;
                    }
                }
        }
        
        if (solutionsFound==solutionsExpected)
            return YES;
        else
            return NO;
    }
    
    else if(evalType==kCheckEvalAreas)
    {
        return [self evalNumberOfShapesInEvalAreas];
    }
    
    else if(evalType==kCheckGroupTypeAndNumber)
    {
        return [self evalGroupTypesAndShapes];
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

#pragma mark - dealloc
-(void) dealloc
{

    initObjects=nil;
    solutionsDef=nil;
    existingGroups=nil;
    destroyedLabelledGroups=nil;
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [renderLayer release];
    
    [gw release];
    
    [super dealloc];
}
@end