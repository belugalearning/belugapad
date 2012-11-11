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
    
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(Container)])
            if([((id<Container>)go) blocksInShape]==0)
                {
                    [(id<Container>)go destroyThisObject];
                }
    }

}

-(void)draw
{
    for(id go in [gw AllGameObjects])
    {
        if([go conformsToProtocol:@protocol(Container)])
        {
            id<Container>goc=(id<Container>)go;
            
            for(int i=0; i<goc.BlocksInShape.count; i++)
            {
                SGDtoolBlock *block1=[goc.BlocksInShape objectAtIndex:i];
                if (i%2) {
                    //odd numbers
                    if(i<goc.blocksInShape-2)
                    {
                        //there is a next+1 number
                        SGDtoolBlock *block3=[goc.BlocksInShape objectAtIndex:i+2];
                        [self drawBondLineFrom:block1.mySprite.position to:block3.mySprite.position];
                    }
                }
                else
                {
                    //even numbers
                    if(i<goc.blocksInShape-1)
                    {
                        //there is a next number
                        SGDtoolBlock *block2=[goc.BlocksInShape objectAtIndex:i+1];
                        [self drawBondLineFrom:block1.mySprite.position to:block2.mySprite.position];
                    }
                    if(i<goc.blocksInShape-2)
                    {
                        //there is a next+1 number
                        SGDtoolBlock *block3=[goc.BlocksInShape objectAtIndex:i+2];
                        [self drawBondLineFrom:block1.mySprite.position to:block3.mySprite.position];
                    }
                }
            }
        }
    }
    
    if(isTouching && nearestObject && currentPickupObject)
    {
        SGDtoolBlock *b=(SGDtoolBlock*)nearestObject;
        SGDtoolBlock *c=(SGDtoolBlock*)currentPickupObject;
        
        if(!bondDifferentTypes && b.blockType!=c.blockType)
            return;

        
        if(![b.MyContainer conformsToProtocol:@protocol(Cage)])
        {
            if([BLMath DistanceBetween:b.mySprite.position and:currentPickupObject.mySprite.position] < gw.Blackboard.MaxObjectDistance+50 || nearestObject==lastNewBondObject)
            {
                [self drawBondLineFrom:currentPickupObject.mySprite.position to:((id<Moveable>)nearestObject).mySprite.position];
                lastNewBondObject=nearestObject;
            }
        }
    }
    
    
//    for (int i=0; i<DRAW_DEPTH; i++)
//    {
//        for(id go in [gw AllGameObjects]) {
//            if([go conformsToProtocol:@protocol(Pairable)])
//                [((id<Pairable>)go) draw:i];
//        }
//    } 
}

-(void)drawBondLineFrom:(CGPoint)p1 to:(CGPoint)p2
{
    int barHalfW=30;
    
    float llen=[BLMath LengthOfVector:[BLMath SubtractVector:p2 from:p1]];
    
    if(llen>gw.Blackboard.MaxObjectDistance)return;
    
    float op=1.0f;
    if(llen>300)
    {
        barHalfW=1;
    }
    if(llen>70.0f)
    {
        float diff=gw.Blackboard.MaxObjectDistance-llen;
        barHalfW=1 + (30 * (diff / (gw.Blackboard.MaxObjectDistance-70.0f)));
    }
    
    ccDrawColor4F(1, 1, 1, op);
    
    CGPoint line=[BLMath SubtractVector:p1 from:p2];
    CGPoint lineN=[BLMath NormalizeVector:line];
    CGPoint upV=[BLMath PerpendicularLeftVectorTo:lineN];
    
    float distScalar=1.0f;
    float distScaleBase=0.25f;
    float distScaleFrom=50.0f;
    float lOfLine=[BLMath LengthOfVector:line];
    if(lOfLine<distScaleFrom)
    {
        distScalar=distScaleBase + (1-(lOfLine / distScaleFrom));
    }
    else
    {
        distScalar=distScaleBase;
    }
    
    for(int i=0; i<1; i++)
    {
        CGPoint a=[BLMath AddVector:p1 toVector:[BLMath MultiplyVector:upV byScalar:i*0.75f]];
        CGPoint b=[BLMath AddVector:p2 toVector:[BLMath MultiplyVector:upV byScalar:i*0.75f]];
        
        ccDrawLine(a, b);
    }
    
    for(int j=-barHalfW; j<0; j++)
    {
        CGPoint a=[BLMath AddVector:p1 toVector:[BLMath MultiplyVector:upV byScalar:j*0.75f*distScalar]];
        CGPoint b=[BLMath AddVector:p2 toVector:[BLMath MultiplyVector:upV byScalar:(j+barHalfW)*0.75f*distScalar]];
        
        ccDrawLine(a, b);
    }
    
    for(int k=barHalfW; k>0; k--)
    {
        CGPoint a=[BLMath AddVector:p1 toVector:[BLMath MultiplyVector:upV byScalar:k*0.75f*distScalar]];
        CGPoint b=[BLMath AddVector:p2 toVector:[BLMath MultiplyVector:upV byScalar:(k-barHalfW)*0.75f*distScalar]];
        
        ccDrawLine(a, b);
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
    randomiseDockPositions=[[pdef objectForKey:RANDOMISE_DOCK_POSITIONS]boolValue];
    bondDifferentTypes=[[pdef objectForKey:BOND_DIFFERENT_TYPES]boolValue];
    bondAllObjects=[[pdef objectForKey:BOND_ALL_OBJECTS]boolValue];
    
    if(bondAllObjects)
        gw.Blackboard.MaxObjectDistance=1024.0f;
    else
        gw.Blackboard.MaxObjectDistance=100.0f;
    

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
    
    if(evalType==kCheckGroupTypeAndNumber)
        bondDifferentTypes=NO;
    

    usedShapeTypes=[[NSMutableArray alloc]init];
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
    
    if(problemHasCage)
    {
        if(!dockType)
            dockType=@"Infinite";
        
        if(!addedCages && [dockType isEqualToString:@"Infinite"])
            addedCages=[[[NSMutableArray alloc]init]retain];
        
        if([usedShapeTypes count]==0)
            [usedShapeTypes addObject:@"Circle"];
        
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
    NSArray *thesePositions=[NSArray arrayWithArray:[NumberLayout physicalLayoutAcrossToNumber:numBlocks withSpacing:kDistanceBetweenBlocks]];
    
    NSString *label = [theseSettings objectForKey:LABEL];
    NSString *blockType = [theseSettings objectForKey:BLOCK_TYPE];
    BOOL unbreakableBonds = [[theseSettings objectForKey:UNBREAKABLE_BONDS]boolValue];
    
    if(!blockType)
        blockType=@"Circle";
    
    if(!usedShapeTypes)
        usedShapeTypes=[[[NSMutableArray alloc]init]retain];
    
    if(![usedShapeTypes containsObject:blockType])
        [usedShapeTypes addObject:blockType];
    
    SGDtoolContainer *container = [[SGDtoolContainer alloc] initWithGameWorld:gw andLabel:label andRenderLayer:renderLayer];
    container.BlockType=blockType;
    
    if(unbreakableBonds)
        container.LineType=@"Unbreakable";
    else
        container.LineType=@"Breakable";
    
    container.AllowDifferentTypes=bondDifferentTypes;
    if (label && !existingGroups) existingGroups = [[NSMutableArray arrayWithObject:label] retain];
    float startPosX=0;
    float startPosY=0;
    
    if(!hasInactiveArea)
    {
        
        int farLeft=(numBlocks/2)*60;
        int farRight=lx-30;
        int topMost=ly-120;
        int botMost=100;
        
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
        
            
        
        [container addBlockToMe:block];
        
        if(!hasInactiveArea)
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
    //NSLog(@"create container - there are %d destroyed labelled groups", [destroyedLabelledGroups count]);
    if([destroyedLabelledGroups count]==0)
    {
        container=[[SGDtoolContainer alloc]initWithGameWorld:gw andLabel:nil andRenderLayer:nil];
//        container.Label=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",(int)container] fontName:SOURCE fontSize:15.0f];
//        [container.Label setPosition:ccp(cx,cy)];
//        [renderLayer addChild:container.Label];
    }
    else
    {
        NSLog(@"creating labelled group: %@",[destroyedLabelledGroups objectAtIndex:0]);
        container=[[SGDtoolContainer alloc]initWithGameWorld:gw andLabel:[destroyedLabelledGroups objectAtIndex:0] andRenderLayer:renderLayer];
        [destroyedLabelledGroups removeObjectAtIndex:0];
        [existingGroups addObject:[container.Label string]];
    }
    
    container.AllowDifferentTypes=YES;
    container.BlockType=((id<Configurable>)Object).blockType;
    [container addBlockToMe:Object];
    [container layoutMyBlocks];
}



-(void)removeBlockByCage
{
    
    if(currentPickupObject)
    {
        id<Pairable>thisGO=currentPickupObject;
        CCSprite *s=currentPickupObject.mySprite;
        
        if(currentPickupObject.MyContainer)
            [(id<Container>)currentPickupObject.MyContainer removeBlockFromMe:currentPickupObject];
        
        CCMoveTo *moveAct=[CCMoveTo actionWithDuration:0.3f position:cage.Position];
        CCFadeOut *fadeAct=[CCFadeOut actionWithDuration:0.1f];
        CCAction *cleanUp=[CCCallBlock actionWithBlock:^{[thisGO destroyThisObject];}];
        CCSequence *sequence=[CCSequence actions:moveAct, fadeAct, cleanUp, nil];
        [s runAction:sequence];
        currentPickupObject=nil;
//        if(!spawnedNewObj)
//            [cage spawnNewBlock];
    }
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
        for(NSNumber *n in solutions)
        {
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
                
                //NSLog(@"thisCont type=%@, thisCont BlocksInShape=%d", thisCont.BlockType, [thisCont.BlocksInShape count]);
                
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
    
    
    
    //NSLog(@"solutions found %d required %d", solutionsFound, solutionsExpected);
    if (solutionsFound==solutionsExpected)
        return YES;
    else
        return NO;

}

-(CGPoint)returnNextMountPointForThisShape:(id<Container>)thisShape
{
    id<Moveable>firstShape=[thisShape.BlocksInShape objectAtIndex:0];
    
    NSArray *newObjects=[NumberLayout physicalLayoutAcrossToNumber:[thisShape.BlocksInShape count] withSpacing:kDistanceBetweenBlocks];
    
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
                
                if([currentPickupObject.MyContainer isKindOfClass:[SGDtoolCage class]]){
                    spawnedNewObj=NO;
                    hasMovedCagedBlock=YES;
                    ((id<Cage>)currentPickupObject.MyContainer).CurrentObject=nil;
                    currentPickupObject.MyContainer=nil;
                }
                
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
    if(problemHasCage && hasMovedCagedBlock && !spawnedNewObj)
    {
        for(id<Cage>thisCage in addedCages)
        {
            if([BLMath DistanceBetween:thisCage.Position and:pickupPos]<=60.0f)
            {
                [thisCage spawnNewBlock];
                spawnedNewObj=YES;
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
        if((location.x>=80.0f&&location.x<=lx-80.0f) && (location.y>=80.0f&&location.y<=ly-80.0f))
        {
            // set it's position and move it!
            currentPickupObject.Position=location;
            [currentPickupObject move];
        }
        if([((id<Container>)currentPickupObject.MyContainer).LineType isEqualToString:@"Unbreakable"])
            return;

        
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                if(go==currentPickupObject)continue;
                
                float dist=[BLMath DistanceBetween:currentPickupObject.Position and:((id<Moveable>)go).Position];
                
                if(nearestObjectDistance==0){
                    nearestObjectDistance=dist;
                    nearestObject=go;
                }
                else if(dist<nearestObjectDistance){
                    nearestObjectDistance=dist;
                    nearestObject=go;
                }
                
                    
                BOOL prx=[go amIProximateTo:location];
                if(prx && !hasBeenProximate){
                    hasBeenProximate=YES;
                    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_bond_possible.wav")];
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
    
    if(!spawnedNewObj && hasMovedCagedBlock)
        [cage spawnNewBlock];
    
    if(currentPickupObject)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_block_dropped.wav")];
        CGPoint curPOPos=currentPickupObject.Position;
        // check all the gamobjects and search for a moveable object
        
        if([BLMath DistanceBetween:curPOPos and:cage.Position]<90.0f && problemHasCage)
        {
            [self removeBlockByCage];
            return;
        }
        
        if(CGRectContainsPoint(inactiveRect, location))
        {
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_blocks_added_to_evaluation_area.wav")];
        }
        
        BOOL gotTarget=NO;
        for(id go in allGWCopy)
        {
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                if(go==currentPickupObject)
                    continue;
                
                // return whether the object is proximate to our current pickuobject


                    
                id<Moveable,Pairable>cObj=(id<Moveable,Pairable>)go;
                
                if([cObj amIProximateTo:location]){
                    
                    NSLog(@"moved pickup object close to this GO. add pickupObject to cObj container");
                    hasBeenProximate=YES;
                    
                    if(cObj.MyContainer!=currentPickupObject.MyContainer){
                        if([((id<Container>)cObj.MyContainer).LineType isEqualToString:@"Unbreakable"]){
                            [((id<Container>)currentPickupObject.MyContainer) layoutMyBlocks];
                            return;
                        }
                        if(currentPickupObject.MyContainer){
                            [((id<Container>)currentPickupObject.MyContainer) layoutMyBlocks];
                            [((id<Container>)currentPickupObject.MyContainer) removeBlockFromMe:currentPickupObject];
                        }
                        [((id<Container>)cObj.MyContainer) addBlockToMe:currentPickupObject];
                        [((id<Container>)cObj.MyContainer) layoutMyBlocks];
                    }
                    
                    if(cObj.MyContainer==currentPickupObject.MyContainer)
                    {
                            [((id<Container>)currentPickupObject.MyContainer) layoutMyBlocks];
                    }
                    
                    gotTarget=YES;
                    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_bond_made.wav")];
                    break;
                    
                }
                if([((id<Container>)currentPickupObject.MyContainer).LineType isEqualToString:@"Unbreakable"]){
                    gotTarget=YES;
                    [((id<Container>)currentPickupObject.MyContainer) layoutMyBlocks];
                    [self setTouchVarsToOff];
                    return;
                }

            }

        }
        if(!gotTarget)
        {
            if([(id<NSObject>)currentPickupObject.MyContainer isKindOfClass:[SGDtoolCage class]])return;
            
            if([((id<Container>)currentPickupObject.MyContainer).BlocksInShape count]>1||currentPickupObject.MyContainer==nil)
            {
                id<Container>LayoutCont=currentPickupObject.MyContainer;
                [((id<Container>)currentPickupObject.MyContainer) removeBlockFromMe:currentPickupObject];
                [LayoutCont layoutMyBlocks];
                [self createContainerWithOne:currentPickupObject];
            }
            
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_bond_broken_snapped.wav")];
        }

        //[self evalUniqueShapes];
        if(evalMode==kProblemEvalAuto)[self evalProblem];
    }
    
    
    if(hasBeenProximate)
    {
        hasBeenProximate=NO;
        [loggingService logEvent:BL_PA_DT_TOUCH_MOVE_PROXIMITY_OF_BLOCK withAdditionalData:nil];
    }
    
    [self setTouchVarsToOff];
    
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // empty selected objects
    [self setTouchVarsToOff];
}

-(void)setTouchVarsToOff
{
    isTouching=NO;
    currentPickupObject=nil;
    nearestObjectDistance=0.0f;
    nearestObject=nil;
    spawnedNewObj=YES;
    hasMovedCagedBlock=NO;

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
    if(evalType==kCheckShapeSizes)
    {
        NSMutableArray *shapesFound=[[NSMutableArray alloc]init];
        NSMutableArray *solFound=[[NSMutableArray alloc]init];
        NSMutableArray *containers=[[NSMutableArray alloc]init];
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
                    
                    if(![containers containsObject:cont])
                        [containers addObject:cont];
                    
                    NSLog(@"blocksinshape %d is %d", (int)thisCont, [thisCont.BlocksInShape count]);
                    if([thisCont.BlocksInShape count]==[n intValue])
                    {
                        NSLog(@"found solution nigguh");
                        solutionsFound++;
                        [shapesFound addObject:cont];
                        [solFound addObject:n];
                        continue;
                    }
                }
            }
        }
        
        
          
        NSLog(@"solutions found %d required %d containers %d", solutionsFound, solutionsExpected, [containers count]);
        if (solutionsFound==solutionsExpected && [containers count]==solutionsExpected)
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