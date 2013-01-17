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
#import "ToolConsts.h"

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
#import "SGBtxeProtocols.h"
#import "SGBtxeObjectIcon.h"

#define DRAW_DEPTH 1
static float kTimeSinceAction=7.0f;


@interface DistributionTool()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
    // and then any specifics we need for this tool
    id<Moveable,Transform,Pairable,Configurable> currentPickupObject;
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
        
        drawNode=[[CCDrawNode alloc]init];
        [renderLayer addChild:drawNode];
        
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
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_interaction_feedback_block_shaking.wav")];
        }
        
        if(isWinning)[toolHost shakeCommitButton];
        
        timeSinceInteraction=0.0f;
    }
    
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(ShapeContainer)])
            if([((id<ShapeContainer>)go) blocksInShape]==0)
                {
                    [(id<ShapeContainer>)go destroyThisObject];
                }
    }
    
    if(showTotalValue)
    {
        if(!totalValueLabel)
        {
            totalValueLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g",[self showValueOfAllObjects]] fontName:SOURCE fontSize:20.0f];
            [totalValueLabel setPosition:ccp(lx-150,50)];
            [renderLayer addChild:totalValueLabel];
        }
        else
        {
            [totalValueLabel setString:[NSString stringWithFormat:@"%g",[self showValueOfAllObjects]]];
        }
    }
    [self drawConnections];
    //[self checkForOverlappingContainers];
}

-(void)drawConnections
{
    [drawNode clear];
    
    for(id go in [gw AllGameObjects])
    {
        if([go conformsToProtocol:@protocol(ShapeContainer)])
        {
            id<ShapeContainer>goc=(id<ShapeContainer>)go;
            
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
                if(nearestObject==nil)return;
                
                if(bondAllObjects)
                {
                    id<ShapeContainer>theRightContainer=((id<Moveable>)nearestObject).MyContainer;
                    id<Moveable>theRightBlock=[theRightContainer.BlocksInShape objectAtIndex:[theRightContainer.BlocksInShape count]-1];
                    [self drawBondLineFrom:currentPickupObject.mySprite.position to:((id<Moveable>)theRightBlock).mySprite.position];
                    lastNewBondObject=nearestObject;
                }
                else{
                    [self drawBondLineFrom:currentPickupObject.mySprite.position to:((id<Moveable>)nearestObject).mySprite.position];
                    lastNewBondObject=nearestObject;
                }
            }
        }
    }
    
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
    
//    ccDrawColor4F(1, 1, 1, op);
    
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
        
        [drawNode drawSegmentFrom:a to:b radius:1.0f color:ccc4f(1,1,1,op)];
    }
    
    for(int j=-barHalfW; j<0; j++)
    {
        CGPoint a=[BLMath AddVector:p1 toVector:[BLMath MultiplyVector:upV byScalar:j*0.75f*distScalar]];
        CGPoint b=[BLMath AddVector:p2 toVector:[BLMath MultiplyVector:upV byScalar:(j+barHalfW)*0.75f*distScalar]];
        
        [drawNode drawSegmentFrom:a to:b radius:1.0f color:ccc4f(1,1,1,op)];
    }
    
    for(int k=barHalfW; k>0; k--)
    {
        CGPoint a=[BLMath AddVector:p1 toVector:[BLMath MultiplyVector:upV byScalar:k*0.75f*distScalar]];
        CGPoint b=[BLMath AddVector:p2 toVector:[BLMath MultiplyVector:upV byScalar:(k-barHalfW)*0.75f*distScalar]];
        
        [drawNode drawSegmentFrom:a to:b radius:1.0f color:ccc4f(1,1,1,op)];
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
    bondAllObjects=[[pdef objectForKey:BOND_ALL_OBJECTS]boolValue];
    
    if([pdef objectForKey:BOND_DIFFERENT_TYPES])
        bondDifferentTypes=[[pdef objectForKey:BOND_DIFFERENT_TYPES]boolValue];
    else
        bondDifferentTypes=YES;
    
    showTotalValue=[[pdef objectForKey:SHOW_TOTAL_VALUE]boolValue];
    
    if(bondAllObjects)
        gw.Blackboard.MaxObjectDistance=2048.0f;
    else
        gw.Blackboard.MaxObjectDistance=150.0f;
    

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
    if([pdef objectForKey:SOLUTION])solutionsDef=[[pdef objectForKey:SOLUTION]retain];
    
    if(evalType==kCheckGroupTypeAndNumber)
        bondDifferentTypes=NO;
    

    usedShapeTypes=[[NSMutableArray alloc]init];
    
    if(problemHasCage)
    {
        [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_ADD_FROM_CAGE"];
        [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_REMOVE_TO_CAGE"];
    }
    
    if([initObjects count]==1 && !problemHasCage)
        [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_SPLIT_INIT_OBJECT"];
    
    if([initAreas count]>0 && evalType)
        [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_EVAL_AREAS"];
    
    if(evalType==kCheckTaggedGroups){
        [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_BTXE_LABELLING"];
    }
    else if(evalType==kCheckContainerValues||evalType==kCheckEvalAreaValues){
        [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_VALUES"];
    }
    else if(evalType==kCheckEvalAreasForTypes||evalType==kCheckGroupsForTypes){
        for(NSDictionary *d in solutionsDef)
        {
            for(NSString *key in [d allKeys])
            {
                if([key rangeOfString:@"VALUE"].location!=0)
                {
                    [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_VALUES"];
                    break;
                }
            }
        }
    }
    else if(evalType==kCheckGroupTypeAndNumber)
    {
        for(NSDictionary *d in solutionsDef)
        {
            if([d objectForKey:BLOCK_TYPE])
            {
                if([[d objectForKey:BLOCK_TYPE] rangeOfString:@"Value"].location!=0)
                {
                    [usersService notifyStartingFeatureKey:@"DISTRIBUTIONTOOL_VALUES"];
                }
            }
        }
    }
}

-(void)populateGW
{
    // set our renderlayer
    gw.Blackboard.RenderLayer = renderLayer;
    activeRects=[[[NSMutableArray alloc]init]autorelease];
    
    
    if(hasInactiveArea)
    {
        inactiveArea=[[[NSMutableArray alloc]init]autorelease];
        
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
    
    [self createEvalAreas];
    
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
        
        if(!addedCages)
            addedCages=[[NSMutableArray alloc]init];
        
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
    
}

#pragma mark - objects
-(void)createShapeWith:(int)numBlocks andWith:(NSDictionary*)theseSettings
{
    NSArray *thesePositions=[NSArray arrayWithArray:[NumberLayout physicalLayoutAcrossToNumber:numBlocks withSpacing:kDistanceBetweenBlocks]];
    
    NSString *label = [theseSettings objectForKey:LABEL];
    NSString *blockType = [theseSettings objectForKey:BLOCK_TYPE];
    NSString *thisColour = [theseSettings objectForKey:TINT_COLOUR];
    BOOL unbreakableBonds = [[theseSettings objectForKey:UNBREAKABLE_BONDS]boolValue];
    BOOL showContainerCount = [[theseSettings objectForKey:SHOW_CONTAINER_VALUE]boolValue];
    BOOL isEvalTarget = [[theseSettings objectForKey:IS_EVAL_TARGET]boolValue];

    
    if(!thisColour)
        thisColour=@"WHITE";
    
    ccColor3B blockCol = ccc3(0,0,0);
    
    if([thisColour isEqualToString:@"BLUE"])
        blockCol=ccc3(0,0,255);
    else if([thisColour isEqualToString:@"RED"])
        blockCol=ccc3(255,0,0);
    else if([thisColour isEqualToString:@"GREEN"])
        blockCol=ccc3(0,255,0);
    else if([thisColour isEqualToString:@"WHITE"])
        blockCol=ccc3(255,255,255);
    else if([thisColour isEqualToString:@"BLACK"])
        blockCol=ccc3(0,0,0);
        
    if(!blockType)
        blockType=@"Circle";
    
    if(!usedShapeTypes)
        usedShapeTypes=[[NSMutableArray alloc]init];
    
    if(![usedShapeTypes containsObject:blockType])
        [usedShapeTypes addObject:blockType];
    
    SGDtoolContainer *container = [[SGDtoolContainer alloc] initWithGameWorld:gw andLabel:label andShowCount:showContainerCount andRenderLayer:renderLayer];
    container.BlockType=blockType;
    
    if(unbreakableBonds)
        container.LineType=@"Unbreakable";
    else
        container.LineType=@"Breakable";
    
    container.AllowDifferentTypes=bondDifferentTypes;
    container.IsEvalTarget=isEvalTarget;
    
    if (label && !existingGroups) existingGroups = [NSMutableArray arrayWithObject:label];
    float startPosX=0;
    float startPosY=0;
    
    if(!hasInactiveArea)
    {
        
        int farLeft=(numBlocks/1.5)*kDistanceBetweenBlocks+30;
        int farRight=lx-kDistanceBetweenBlocks;
        int topMost=ly-200;
        int botMost=180;
        
        //startPosX=[theseSettings objectForKey:POS_X] ? [[theseSettings objectForKey:POS_X]intValue] : (arc4random() % 960) + 30;
        //startPosY=[theseSettings objectForKey:POS_Y] ? [[theseSettings objectForKey:POS_Y]intValue] : (arc4random() % 730) + 30;
        
        startPosX = farLeft + arc4random() % (farRight - farLeft);
        startPosY = botMost + arc4random() % (topMost - botMost);
    
        
        if(!bondAllObjects)
        {
            for(id go in gw.AllGameObjects)
            {
                    while([self isPointInActiveRects:ccp(startPosX,startPosY) andThisManyOthers:numBlocks])
                    {
                        startPosX = farLeft + arc4random() % (farRight - farLeft);
                        startPosY = botMost + arc4random() % (topMost - botMost);

                    }
            }
        }
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
    
    CGRect thisShapeRect=CGRectNull;
    
    for (int i=0; i<numBlocks; i++)
    {
        CGPoint thisPoint=[[thesePositions objectAtIndex:i]CGPointValue];
        
        CGPoint p = ccp(startPosX+thisPoint.x,  startPosY+thisPoint.y);
        
        NSLog(@"create block %d/%d at position %@", i+1, numBlocks, NSStringFromCGPoint(p));
        
        SGDtoolBlock *block =  [[[SGDtoolBlock alloc] initWithGameWorld:gw andRenderLayer:renderLayer andPosition:p andType:blockType] autorelease];
        [block setup];
        block.MyContainer = container;
        [block.mySprite setColor:blockCol];
        [block.mySprite setZOrder:10];
        
        thisShapeRect=CGRectUnion(thisShapeRect,block.mySprite.boundingBox);
        
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
    
    [activeRects addObject:[NSValue valueWithCGRect:thisShapeRect]];
    [container release];
    thesePositions=nil;

}

-(BOOL)isPointInActiveRects:(CGPoint)thisPosition andThisManyOthers:(int)thisMany
{
    NSArray *thesePositions=[NumberLayout physicalLayoutAcrossToNumber:thisMany withSpacing:kDistanceBetweenBlocks];
    
    CGRect thisRect=CGRectNull;
    
    for(int i=0;i<thisMany;i++)
    {
        CGPoint point=[[thesePositions objectAtIndex:i]CGPointValue];
        CGRect rect=CGRectMake((thisPosition.x+point.x)-(kDistanceBetweenBlocks/2),(thisPosition.y+point.y)-(kDistanceBetweenBlocks/2),kDistanceBetweenBlocks,kDistanceBetweenBlocks);
        thisRect=CGRectUnion(thisRect, rect);
    }
    
    for(int i=0;i<[activeRects count];i++)
    {
        CGRect r=[[activeRects objectAtIndex:i]CGRectValue];
        
        //NSLog(@"this rect: %@, this position %@", NSStringFromCGRect(r), NSStringFromCGPoint(thisPosition));

            if(CGRectIntersectsRect(thisRect, r))
            {
                return YES;
            }
//        for(int p=0;p<thisMany;p++)
//        {
//            CGPoint curPos=[[thesePositions objectAtIndex:p]CGPointValue];
//            curPos=ccp(curPos.x+thisPosition.x, curPos.y+thisPosition.y);
//            
//            if(CGRectContainsPoint(r, curPos))
//            {
//                return YES;
//            }
//        }
    }

    return NO;
}

-(void)createEvalAreas
{
    if(!initAreas)return;
    
    if(!evalAreas)
        evalAreas=[[NSMutableArray alloc]init];

    float sectionWidth=lx/[initAreas count];
    
    for(int i=0;i<[initAreas count];i++)
    {
        NSDictionary *d=[initAreas objectAtIndex:i];
        NSString *lblText=[d objectForKey:LABEL];
        int areaSize=[[d objectForKey:AREA_SIZE]intValue];
        int areaWidth=[[d objectForKey:AREA_WIDTH]intValue];
        int areaOpacity=0;
        int distFromLY=(ly-150-(areaSize/areaWidth)*62);
        float startXPos=((i+0.5)*sectionWidth)-((areaWidth/2)*60);
        int startYPos = 100 + arc4random() % (distFromLY - 100);
        CGRect thisEvalArea=CGRectNull;
        
        
        if([d objectForKey:AREA_OPACITY])
            areaOpacity=[[d objectForKey:AREA_OPACITY]intValue];
        else
            areaOpacity=255;
        
        NSMutableArray *thisArea=[[[NSMutableArray alloc]init]autorelease];
        int thisPos=0;
        
        for(int i=0;i<areaSize;i++)
        {
            if(thisPos==areaWidth)thisPos=0;
            int thisRow=i/areaWidth;
            
            CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/distribution/DT_area.png")];
            [s setPosition:ccp(startXPos+(thisPos*s.contentSize.width),startYPos+(thisRow*s.contentSize.height))];
            [s setOpacity:areaOpacity];
            [self.BkgLayer addChild:s z:0];
            
            thisEvalArea=CGRectUnion(thisEvalArea, s.boundingBox);
            
            if(i==1 && lblText)
            {
                CCLabelTTF *l=[CCLabelTTF labelWithString:lblText fontName:SOURCE fontSize:35.0f];
                [l setPosition:ccp(s.contentSize.width/2, -s.contentSize.height/2)];
                [s addChild:l];
            }
            
            [thisArea addObject:s];
            thisPos++;
        }
        
        [activeRects addObject:[NSValue valueWithCGRect:thisEvalArea]];
        [evalAreas addObject:thisArea];
    }
}

-(void)addDestroyedLabel:(NSString*)thisGroup
{
    [destroyedLabelledGroups addObject:thisGroup];
}

-(void)createContainerWithOne:(id)Object
{
    id<ShapeContainer> container;
    //NSLog(@"create container - there are %d destroyed labelled groups", [destroyedLabelledGroups count]);
    if([destroyedLabelledGroups count]==0)
    {
        container=[[[SGDtoolContainer alloc]initWithGameWorld:gw andLabel:nil andShowCount:NO andRenderLayer:nil]autorelease];
//        container.Label=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",(int)container] fontName:SOURCE fontSize:15.0f];
//        [container.Label setPosition:ccp(cx,cy)];
//        [renderLayer addChild:container.Label];
    }
    else
    {
        NSLog(@"creating labelled group: %@",[destroyedLabelledGroups objectAtIndex:0]);
        container=[[[SGDtoolContainer alloc]initWithGameWorld:gw andLabel:[destroyedLabelledGroups objectAtIndex:0] andShowCount:NO andRenderLayer:renderLayer]autorelease];
        [destroyedLabelledGroups removeObjectAtIndex:0];
        [existingGroups addObject:[container.Label string]];
    }
    
    container.AllowDifferentTypes=YES;
    container.BlockType=((id<Configurable>)Object).blockType;
    [container addBlockToMe:Object];
    [container layoutMyBlocks];
    [container repositionLabel];
}

-(float)showValueOfAllObjects
{
    float totalValue=0.0f;
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(Configurable) ])
        {
            SGDtoolBlock *b=(SGDtoolBlock*)go;
            
            if([b.MyContainer isKindOfClass:[SGDtoolCage class]])continue;
            
            if([b.blockType isEqualToString:@"Value_001"])
                totalValue+=kShapeValue001;
            else if([b.blockType isEqualToString:@"Value_01"])
                totalValue+=kShapeValue01;
            else if([b.blockType isEqualToString:@"Value_1"])
                totalValue+=kShapeValue1;
            else if([b.blockType isEqualToString:@"Value_10"])
                totalValue+=kShapeValue10;
            else if([b.blockType isEqualToString:@"Value_100"])
                totalValue+=kShapeValue100;
            
        }
    }
    return totalValue;
}

-(float)valueOf:(SGDtoolContainer*)thisContainer
{
    float totalValue=0.0f;
    
    for(SGDtoolBlock *b in thisContainer.BlocksInShape)
    {
        if([b.blockType isEqualToString:@"Value_001"])
            totalValue+=kShapeValue001;
        else if([b.blockType isEqualToString:@"Value_01"])
            totalValue+=kShapeValue01;
        else if([b.blockType isEqualToString:@"Value_1"])
            totalValue+=kShapeValue1;
        else if([b.blockType isEqualToString:@"Value_10"])
            totalValue+=kShapeValue10;
        else if([b.blockType isEqualToString:@"Value_100"])
            totalValue+=kShapeValue100;
    }
    return totalValue;
}

-(void)removePickupFromContainer
{
    if(currentPickupObject.MyContainer)
        [(id<ShapeContainer>)currentPickupObject.MyContainer removeBlockFromMe:currentPickupObject];
}

-(void)removeBlockByCage
{
    if([dockType isEqualToString:@"15"])return;
    if([dockType isEqualToString:@"30"])return;
    if(currentPickupObject)
    {
        for(id<Cage>cge in addedCages)
        {
            if(cge.CurrentObject==currentPickupObject)
                cge.CurrentObject=nil;
                
            if([cge.BlockType isEqualToString:currentPickupObject.blockType])
                cage=cge;
        }
        
        if([dockType isEqualToString:@"Infinite-Random"])
            cage=[addedCages objectAtIndex:0];
        
        id<Pairable>thisGO=currentPickupObject;
        CCSprite *s=currentPickupObject.mySprite;
        [s setZOrder:100];
        
        CCMoveTo *moveAct=[CCMoveTo actionWithDuration:0.3f position:ccp(cage.MySprite.position.x,cage.MySprite.position.y+10)];
        CCFadeOut *fadeAct=[CCFadeOut actionWithDuration:0.1f];
        CCAction *cleanUp=[CCCallBlock actionWithBlock:^{[thisGO destroyThisObject];}];
        CCSequence *sequence=[CCSequence actions:moveAct, fadeAct, cleanUp, nil];
        [s runAction:sequence];
        currentPickupObject=nil;
//        if(!spawnedNewObj)
//            [cage spawnNewBlock];
    }
}

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    id<MovingInteractive,Text>iBTXE=(id<MovingInteractive,Text>)thisObject;
    
    for(id go in gw.AllGameObjectsCopy)
    {
        if([go isKindOfClass:[SGDtoolBlock class]])
        {
            id<Moveable>thisBlock=(id<Moveable>)go;

            if([thisBlock amIProximateTo:thisLocation]&&thisBlock.MyContainer)
            {
                id<ShapeContainer>thisCont=(SGDtoolContainer*)thisBlock.MyContainer;
                //if(!thisCont.BTXERow)
                //{
                    [thisCont setGroupBTXELabel:[iBTXE createADuplicateIntoGameWorld:gw]];
                    break;
                //}
            }
        }
    }

}

-(BOOL)evalNumberOfShapesInEvalAreas
{
    NSMutableArray *solutions=[NSMutableArray arrayWithArray:solutionsDef];
    
    int arraySize=[evalAreas count];
    
    int shapesInArea[arraySize];
    int solutionsFound=0;
    
    for(int i=0;i<arraySize;i++)
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
        // analyser throws this up as an issue - but we know it works, so ignore
#ifndef __clang_analyzer__
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
#endif
    
    if(solutionsFound==[solutionsDef count])
        return YES;
    else
        return NO;
}

-(BOOL)evalNumberOfShapesAndTypesInEvalAreas
{
    int solutionsFound=0;
    NSMutableArray *matchedEvalAreas=[[[NSMutableArray alloc]init] autorelease];
//    NSMutableArray *matchedSolutions=[[NSMutableArray alloc]init];
    NSMutableArray *solutionsLeft=[NSMutableArray arrayWithArray:solutionsDef];
    

    for(int i=0;i<[evalAreas count];i++)
    {
        for(NSDictionary *solutions in solutionsDef)
        {
            if(![solutionsLeft containsObject:solutions])continue;
            
            int circlesReq=[[solutions objectForKey:EVAL_CIRCLES_REQUIRED]intValue];
            int diamondsReq=[[solutions objectForKey:EVAL_DIAMONDS_REQUIRED]intValue];
            int ellipsesReq=[[solutions objectForKey:EVAL_ELLIPSES_REQUIRED]intValue];
            int housesReq=[[solutions objectForKey:EVAL_HOUSES_REQUIRED]intValue];
            int roundedSquaresReq=[[solutions objectForKey:EVAL_ROUNDEDSQUARES_REQUIRED]intValue];
            int squaresReq=[[solutions objectForKey:EVAL_SQUARES_REQUIRED]intValue];
            int val001Req=[[solutions objectForKey:EVAL_VALUE_001_REQUIRED]intValue];
            int val01Req=[[solutions objectForKey:EVAL_VALUE_01_REQUIRED]intValue];
            int val1Req=[[solutions objectForKey:EVAL_VALUE_1_REQUIRED]intValue];
            int val10Req=[[solutions objectForKey:EVAL_VALUE_10_REQUIRED]intValue];
            int val100Req=[[solutions objectForKey:EVAL_VALUE_100_REQUIRED]intValue];
            
            int circlesFound=0;
            int diamondsFound=0;
            int ellipsesFound=0;
            int housesFound=0;
            int roundedSquaresFound=0;
            int squaresFound=0;
            int val001Found=0;
            int val01Found=0;
            int val1Found=0;
            int val10Found=0;
            int val100Found=0;
            
            BOOL circlesMatch=NO;
            BOOL diamondsMatch=NO;
            BOOL ellipsesMatch=NO;
            BOOL housesMatch=NO;
            BOOL roundedSquaresMatch=NO;
            BOOL squaresMatch=NO;
            BOOL val001Match=NO;
            BOOL val01Match=NO;
            BOOL val1Match=NO;
            BOOL val10Match=NO;
            BOOL val100Match=NO;
            
            BOOL shouldContinueEval=YES;
            
            
            
            CGRect thisRect=CGRectNull;
            NSArray *a=[evalAreas objectAtIndex:i];
            
            if([matchedEvalAreas containsObject:a])continue;
            
            for(CCSprite *s in a)
            {
                thisRect=CGRectUnion(thisRect, s.boundingBox);
            }
            
            for(id go in gw.AllGameObjects)
            {
                if([go conformsToProtocol:@protocol(Configurable)])
                {
                    id<Configurable,Moveable>c=(id<Configurable,Moveable>)go;
                    
                    if(!CGRectContainsPoint(thisRect, c.Position))continue;
                    
                    if([c.blockType isEqualToString:@"Circle"])
                        circlesFound++;
                    if([c.blockType isEqualToString:@"Diamond"])
                        diamondsFound++;
                    if([c.blockType isEqualToString:@"Ellipse"])
                        ellipsesFound++;
                    if([c.blockType isEqualToString:@"House"])
                        housesFound++;
                    if([c.blockType isEqualToString:@"RoundedSquare"])
                        roundedSquaresFound++;
                    if([c.blockType isEqualToString:@"Square"])
                        squaresFound++;
                    if([c.blockType isEqualToString:@"Value_001"])
                        val001Found++;
                    if([c.blockType isEqualToString:@"Value_01"])
                        val01Found++;
                    if([c.blockType isEqualToString:@"Value_1"])
                        val1Found++;
                    if([c.blockType isEqualToString:@"Value_10"])
                        val10Found++;
                    if([c.blockType isEqualToString:@"Value_100"])
                        val100Found++;
                    
                }
            }
        
            
            NSLog(@"(%d) Circles f:%d r:%d, Houses f:%d r:%d", [evalAreas indexOfObject:a], circlesFound, circlesReq, housesFound, housesReq);
            
            if(circlesFound==circlesReq && shouldContinueEval)
                circlesMatch=YES;
            else
                shouldContinueEval=NO;

            if(diamondsFound==diamondsReq && shouldContinueEval)
                diamondsMatch=YES;
            else
                shouldContinueEval=NO;
            
            if(ellipsesFound==ellipsesReq && shouldContinueEval)
                ellipsesMatch=YES;
            else
                shouldContinueEval=NO;
            
            if(housesFound==housesReq && shouldContinueEval)
                housesMatch=YES;
            else
                shouldContinueEval=NO;
            
            if(roundedSquaresFound==roundedSquaresReq && shouldContinueEval)
                roundedSquaresMatch=YES;
            else
                shouldContinueEval=NO;
            
            if(squaresFound==squaresReq && shouldContinueEval)
                squaresMatch=YES;
            else
                shouldContinueEval=NO;
            
            if(val001Found==val001Req && shouldContinueEval)
                val001Match=YES;
            else
                shouldContinueEval=NO;
            
            if(val01Found==val01Req && shouldContinueEval)
                val01Match=YES;
            else
                shouldContinueEval=NO;
            
            if(val1Found==val1Req && shouldContinueEval)
                val1Match=YES;
            else
                shouldContinueEval=NO;
            
            if(val10Found==val10Req && shouldContinueEval)
                val10Match=YES;
            else
                shouldContinueEval=NO;
        
            if(val100Found==val100Req && shouldContinueEval)
                val100Match=YES;
            else
                shouldContinueEval=NO;
            
            if(shouldContinueEval && circlesMatch && diamondsMatch && ellipsesMatch && housesMatch && roundedSquaresMatch && squaresMatch && val001Match && val01Match && val1Match && val10Match && val100Match){
                solutionsFound++;

                [matchedEvalAreas addObject:a];
                [solutionsLeft removeObjectIdenticalTo:solutions];
                break;
            }

            
        }
    }
 
    //NSLog(@"solutions found %d req %d", solutionsFound, [solutionsDef count]);
    if(solutionsFound==[solutionsDef count])
        return YES;
    else
        return NO;
}

-(BOOL)evalGroupTypesAndShapes
{
    NSMutableArray *shapesFound=[[[NSMutableArray alloc]init]autorelease];
    NSMutableArray *solFound=[[[NSMutableArray alloc]init]autorelease];
    int solutionsExpected=[solutionsDef count];
    int solutionsFound=0;
    
    
    for(NSDictionary *d in solutionsDef)
    {
        if([solFound containsObject:d])continue;
        
        for (id cont in gw.AllGameObjects)
        {
            if([shapesFound containsObject:cont])continue;
            
            if([cont conformsToProtocol:@protocol(ShapeContainer)])
            {
                id<ShapeContainer>thisCont=cont;
                
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

-(BOOL)evalValueOfEvalAreas
{
    int solutionsFound=0;
    NSMutableArray *matchedEvalAreas=[[[NSMutableArray alloc]init]autorelease];
    NSMutableArray *solutionsLeft=[NSMutableArray arrayWithArray:solutionsDef];
    
    for(int i=0;i<[evalAreas count];i++)
    {
        for(NSDictionary *solutions in solutionsDef)
        {
            if(![solutionsLeft containsObject:solutions])continue;
            
            float valRequired=[[solutions objectForKey:VALUE]floatValue];
            
            float evalAreaVal=0.0f;
            
            
            
            CGRect thisRect=CGRectNull;
            NSArray *a=[evalAreas objectAtIndex:i];
            
            if([matchedEvalAreas containsObject:a])continue;
            
            for(CCSprite *s in a)
            {
                thisRect=CGRectUnion(thisRect, s.boundingBox);
            }
            
            for(id go in gw.AllGameObjects)
            {
                if([go conformsToProtocol:@protocol(Configurable)])
                {
                    id<Configurable,Moveable>c=(id<Configurable,Moveable>)go;
                    
                    if(!CGRectContainsPoint(thisRect, c.Position))continue;
                    
                    if([c.blockType isEqualToString:@"Value_001"])
                        evalAreaVal+=kShapeValue001;
                    if([c.blockType isEqualToString:@"Value_01"])
                        evalAreaVal+=kShapeValue01;
                    if([c.blockType isEqualToString:@"Value_1"])
                        evalAreaVal+=kShapeValue1;
                    if([c.blockType isEqualToString:@"Value_10"])
                        evalAreaVal+=kShapeValue10;
                    if([c.blockType isEqualToString:@"Value_100"])
                        evalAreaVal+=kShapeValue100;
                    
                }
            }
            
            NSNumber *evalarea=[NSNumber numberWithFloat:evalAreaVal];
            NSNumber *solution=[NSNumber numberWithFloat:valRequired];
            
            NSLog(@"evalarea val %g, expected val %g, is equal? %@", evalAreaVal, [[solutions objectForKey:VALUE]floatValue],[evalarea isEqualToNumber:solution]?@"YES":@"NO");
            
            
            if([evalarea isEqualToNumber:solution]){
                solutionsFound++;
                [matchedEvalAreas addObject:a];
                [solutionsLeft removeObjectIdenticalTo:solutions];
                break;
            }
            
            
        }
    }
    
    NSLog(@"solutions found %d req %d", solutionsFound, [solutionsDef count]);
    if(solutionsFound==[solutionsDef count])
        return YES;
    else
        return NO;
}


-(BOOL)evalValueOfShapesInContainers
{
    int solutionsFound=0;
    NSMutableArray *matchedContainers=[[[NSMutableArray alloc]init]autorelease];
    NSMutableArray *matchedSolutions=[[[NSMutableArray alloc]init]autorelease];
    
    
    for(id thisC in gw.AllGameObjectsCopy)
    {
        if([thisC isKindOfClass:[SGDtoolContainer class]])
        {
            SGDtoolContainer *c=(SGDtoolContainer*)thisC;
            for(NSDictionary *solutions in solutionsDef)
            {
                if([matchedSolutions containsObject:solutions])continue;
                
                float valRequired=[[solutions objectForKey:VALUE]floatValue];
                
                float containerVal=0.0f;
                
                
                
                if([matchedContainers containsObject:c])continue;
                
                for(SGDtoolBlock *b in c.BlocksInShape)
                {
                
                    if([b.blockType isEqualToString:@"Value_001"])
                        containerVal+=kShapeValue001;
                    if([b.blockType isEqualToString:@"Value_01"])
                        containerVal+=kShapeValue01;
                    if([b.blockType isEqualToString:@"Value_1"])
                        containerVal+=kShapeValue1;
                    if([b.blockType isEqualToString:@"Value_10"])
                        containerVal+=kShapeValue10;
                    if([b.blockType isEqualToString:@"Value_100"])
                        containerVal+=kShapeValue100;
                    
                    
                }
                
                NSNumber *container=[NSNumber numberWithFloat:containerVal];
                NSNumber *solution=[NSNumber numberWithFloat:valRequired];
                
                NSLog(@"container val %g, expected val %g, is equal? %@", containerVal, [[solutions objectForKey:VALUE]floatValue],[container isEqualToNumber:solution]?@"YES":@"NO");
                
                if([container isEqualToNumber:solution]){
                    solutionsFound++;
                    [matchedContainers addObject:c];
                    [matchedSolutions addObject:solutions];
                    break;
                }
                
                
            }
        }
    }
    
    NSLog(@"solutions found %d req %d", solutionsFound, [solutionsDef count]);
    if(solutionsFound==[solutionsDef count])
        return YES;
    else
        return NO;
}

-(BOOL)evalNumberOfShapesAndTypesInContainers
{
    int solutionsFound=0;
    NSMutableArray *matchedContainers=[[[NSMutableArray alloc]init]autorelease];
    NSMutableArray *matchedSolutions=[[[NSMutableArray alloc]init]autorelease];
    
    
    for(id thisC in gw.AllGameObjectsCopy)
    {
        if([thisC isKindOfClass:[SGDtoolContainer class]])
        {
            SGDtoolContainer *c=(SGDtoolContainer*)thisC;
            for(NSDictionary *solutions in solutionsDef)
            {
                if([matchedSolutions containsObject:solutions])continue;
                
                int circlesReq=[[solutions objectForKey:EVAL_CIRCLES_REQUIRED]intValue];
                int diamondsReq=[[solutions objectForKey:EVAL_DIAMONDS_REQUIRED]intValue];
                int ellipsesReq=[[solutions objectForKey:EVAL_ELLIPSES_REQUIRED]intValue];
                int housesReq=[[solutions objectForKey:EVAL_HOUSES_REQUIRED]intValue];
                int roundedSquaresReq=[[solutions objectForKey:EVAL_ROUNDEDSQUARES_REQUIRED]intValue];
                int squaresReq=[[solutions objectForKey:EVAL_SQUARES_REQUIRED]intValue];
                int val001Req=[[solutions objectForKey:EVAL_VALUE_001_REQUIRED]intValue];
                int val01Req=[[solutions objectForKey:EVAL_VALUE_01_REQUIRED]intValue];
                int val1Req=[[solutions objectForKey:EVAL_VALUE_1_REQUIRED]intValue];
                int val10Req=[[solutions objectForKey:EVAL_VALUE_10_REQUIRED]intValue];
                int val100Req=[[solutions objectForKey:EVAL_VALUE_100_REQUIRED]intValue];
                
                int circlesFound=0;
                int diamondsFound=0;
                int ellipsesFound=0;
                int housesFound=0;
                int roundedSquaresFound=0;
                int squaresFound=0;
                int val001Found=0;
                int val01Found=0;
                int val1Found=0;
                int val10Found=0;
                int val100Found=0;
                
                BOOL circlesMatch=NO;
                BOOL diamondsMatch=NO;
                BOOL ellipsesMatch=NO;
                BOOL housesMatch=NO;
                BOOL roundedSquaresMatch=NO;
                BOOL squaresMatch=NO;
                BOOL val001Match=NO;
                BOOL val01Match=NO;
                BOOL val1Match=NO;
                BOOL val10Match=NO;
                BOOL val100Match=NO;
                
                BOOL shouldContinueEval=YES;
                
                
                if([matchedContainers containsObject:c])continue;
                
                for(SGDtoolBlock *b in c.BlocksInShape)
                {
                    
                    if([b.blockType isEqualToString:@"Circle"])
                        circlesFound++;
                    if([b.blockType isEqualToString:@"Diamond"])
                        diamondsFound++;
                    if([b.blockType isEqualToString:@"Ellipse"])
                        ellipsesFound++;
                    if([b.blockType isEqualToString:@"House"])
                        housesFound++;
                    if([b.blockType isEqualToString:@"RoundedSquare"])
                        roundedSquaresFound++;
                    if([b.blockType isEqualToString:@"Square"])
                        squaresFound++;
                    if([b.blockType isEqualToString:@"Value_001"])
                        val001Found++;
                    if([b.blockType isEqualToString:@"Value_01"])
                        val01Found++;
                    if([b.blockType isEqualToString:@"Value_1"])
                        val1Found++;
                    if([b.blockType isEqualToString:@"Value_10"])
                        val10Found++;
                    if([b.blockType isEqualToString:@"Value_100"])
                        val100Found++;
                    

                }
                
                if(circlesFound==circlesReq && shouldContinueEval)
                    circlesMatch=YES;
                else
                    shouldContinueEval=NO;
                
                if(diamondsFound==diamondsReq && shouldContinueEval)
                    diamondsMatch=YES;
                else
                    shouldContinueEval=NO;
                
                if(ellipsesFound==ellipsesReq && shouldContinueEval)
                    ellipsesMatch=YES;
                else
                    shouldContinueEval=NO;
                
                if(housesFound==housesReq && shouldContinueEval)
                    housesMatch=YES;
                else
                    shouldContinueEval=NO;
                
                if(roundedSquaresFound==roundedSquaresReq && shouldContinueEval)
                    roundedSquaresMatch=YES;
                else
                    shouldContinueEval=NO;
                
                if(squaresFound==squaresReq && shouldContinueEval)
                    squaresMatch=YES;
                else
                    shouldContinueEval=NO;
                
                if(val001Found==val001Req && shouldContinueEval)
                    val001Match=YES;
                else
                    shouldContinueEval=NO;
                
                if(val01Found==val01Req && shouldContinueEval)
                    val01Match=YES;
                else
                    shouldContinueEval=NO;
                
                if(val1Found==val1Req && shouldContinueEval)
                    val1Match=YES;
                else
                    shouldContinueEval=NO;
                
                if(val10Found==val10Req && shouldContinueEval)
                    val10Match=YES;
                else
                    shouldContinueEval=NO;
                
                if(val100Found==val100Req && shouldContinueEval)
                    val100Match=YES;
                else
                    shouldContinueEval=NO;
                
                if(shouldContinueEval && circlesMatch && diamondsMatch && ellipsesMatch && housesMatch && roundedSquaresMatch && squaresMatch && val001Match && val01Match && val1Match && val10Match && val100Match){
                    solutionsFound++;
                    [matchedContainers addObject:c];
                    [matchedSolutions addObject:solutions];
                    break;
                }
                
                
            }
        }
    }
    
    NSLog(@"solutions found %d req %d", solutionsFound, [solutionsDef count]);
    if(solutionsFound==[solutionsDef count])
        return YES;
    else
        return NO;
}


-(CGPoint)returnNextMountPointForThisShape:(id<ShapeContainer>)thisShape
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
    touchStart=location;
    
    
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
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_block_picked_up.wav")];
                
                if([currentPickupObject.MyContainer isKindOfClass:[SGDtoolCage class]]){
                    
                    if([dockType isEqualToString:@"Infinite"] || [dockType isEqualToString:@"Infinite-Random"] || [dockType isEqualToString:@"Infinite-Value"] || [dockType isEqualToString:@"Infinite-RandomValue"])
                        spawnedNewObj=NO;
                    else
                        spawnedNewObj=YES;
                    
                    hasMovedCagedBlock=YES;
                    ((id<Cage>)currentPickupObject.MyContainer).CurrentObject=nil;

                    if([currentPickupObject.MyContainer isKindOfClass:[SGDtoolCage class]])
                        cage=currentPickupObject.MyContainer;
                    
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
            [thisCage spawnNewBlock];
            spawnedNewObj=YES;
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
        if((location.x>=80.0f&&location.x<=lx-80.0f) && (location.y>=60.0f&&location.y<=ly-200.0f) && [BLMath DistanceBetween:touchStart and:location]>8.0f)
        {
            // set it's position and move it!
            currentPickupObject.Position=location;
            [currentPickupObject move];
        }
        if([((id<ShapeContainer>)currentPickupObject.MyContainer).LineType isEqualToString:@"Unbreakable"])
            return;

        BOOL prx=NO;
        
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
                
                    
                prx=[go amIProximateTo:location];
                if(prx && !hasBeenProximate){
                    hasBeenProximate=YES;
                }
                if(prx){
                    if(lastContainer!=((id<Moveable>)go).MyContainer||lastContainer==nil)
                        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_bond_possible.wav")];
                    lastContainer=((id<Moveable>)go).MyContainer;
                    lastProxPos=location;
                }
                
            }
        }
        
        if([BLMath DistanceBetween:location and:lastProxPos]>100&&!bondAllObjects)
            lastContainer=nil;


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
    
    if(location.y<cage.MySprite.contentSize.height && problemHasCage)
    {
        [self removePickupFromContainer];
        [self removeBlockByCage];
        
        [self setTouchVarsToOff];
        
        return;
    }

    
    if(currentPickupObject)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_block_dropped.wav")];
        
        // check all the gamobjects and search for a moveable object
        
        if(CGRectContainsPoint(inactiveRect, location))
        {
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_blocks_added_to_evaluation_area.wav")];
        }
        
        if([BLMath DistanceBetween:touchStart and:location]<=8.0f)
        {
            id<ShapeContainer>blockContainer=currentPickupObject.MyContainer;
            if([blockContainer.LineType isEqualToString:@"Unbreakable"])
            {
                [self deselectAll];
                [blockContainer selectMyBlocks];
            }
            else
            {
                [(id<Moveable>)currentPickupObject selectMe];
            }
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
                    [loggingService logEvent:BL_PA_DT_TOUCH_END_PAIR_BLOCK withAdditionalData:nil];
                    NSLog(@"moved pickup object close to this GO. add pickupObject to cObj container");
                    hasBeenProximate=YES;
                    
                    // if the 2 containers are different, check for unbreakable blocks, if so, just layout the containers blocks
                    if(cObj.MyContainer!=currentPickupObject.MyContainer){
                        if([((id<ShapeContainer>)cObj.MyContainer).LineType isEqualToString:@"Unbreakable"]){
                            [((id<ShapeContainer>)currentPickupObject.MyContainer) layoutMyBlocks];
                            [self setTouchVarsToOff];
                            return;
                        }
                        // if the current pickup has a container - layout the old container's blocks it's blocks after removing from it
                        if(currentPickupObject.MyContainer){
                            id<ShapeContainer>oldCont=(id<ShapeContainer>)currentPickupObject.MyContainer;
                            [((id<ShapeContainer>)currentPickupObject.MyContainer) removeBlockFromMe:currentPickupObject];
                            [oldCont layoutMyBlocks];
                        }
                        
                        
                        // then add it to a new container and layout those blocks
                        [((id<ShapeContainer>)cObj.MyContainer) addBlockToMe:currentPickupObject];
                        [((id<ShapeContainer>)currentPickupObject.MyContainer) layoutMyBlocks];
                    }
                    // but if the 2 containers are equal
                    if(cObj.MyContainer==currentPickupObject.MyContainer)
                    {
                        // check if the block at index 0 is this one - if it is, don't layout the blocks
                        if([((id<ShapeContainer>)currentPickupObject.MyContainer).BlocksInShape objectAtIndex:0]!=currentPickupObject)
                            [((id<ShapeContainer>)currentPickupObject.MyContainer) layoutMyBlocks];
                    }
                    
                    gotTarget=YES;
                    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_bond_made.wav")];
                    break;
                    
                }
                // if it's unbreakabe, basically relayout the blocks and do nothing more 
                if([((id<ShapeContainer>)currentPickupObject.MyContainer).LineType isEqualToString:@"Unbreakable"]){
                    [((id<ShapeContainer>)currentPickupObject.MyContainer) layoutMyBlocks];
                    [self setTouchVarsToOff];
                    return;
                }

            }

        }
        if(!gotTarget)
        {
            // if it doesn't have a new targetl and the blocks in it's current shape are over 1 or the container's nil (ie if it's dragged from a cage) create a new group
            if([(id<NSObject>)currentPickupObject.MyContainer isKindOfClass:[SGDtoolCage class]])return;
            
            if([((id<ShapeContainer>)currentPickupObject.MyContainer).BlocksInShape count]>1||currentPickupObject.MyContainer==nil)
            {
                id<ShapeContainer>LayoutCont=currentPickupObject.MyContainer;
                
                if(currentPickupObject==[LayoutCont.BlocksInShape objectAtIndex:0] && [LayoutCont.BlocksInShape count]>2)
                {
                    id<Moveable>object1=[LayoutCont.BlocksInShape objectAtIndex:1];
                    object1.Position=ccp(object1.Position.x, object1.Position.y+52);
                }
                [LayoutCont removeBlockFromMe:currentPickupObject];
                [LayoutCont layoutMyBlocks];
                [self createContainerWithOne:currentPickupObject];
            }
            
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_distribution_general_bond_broken_snapped.wav")];
        }

        //[self evalUniqueShapes];
        if(evalMode==kProblemEvalAuto)[self evalProblem];
    }
    
    // if it has a container
    if(currentPickupObject.MyContainer)
    {
        [currentPickupObject.MyContainer repositionLabel];
        // check whether any of the blocks are outside of the screen bounds - then set the position and move it back into the screen bounds
        float diffX=0.0f;
        float diffY=0.0f;

        SGDtoolContainer *c=(SGDtoolContainer*)currentPickupObject.MyContainer;
        
        if([c.BlocksInShape count]>=1){
            for(SGDtoolBlock *b in c.BlocksInShape)
            {
                    if(b.Position.x<60)
                        diffX+=60;
                
                    if(b.Position.y<100)
                        diffY+=60;
            }
            
            SGDtoolBlock *b=[c.BlocksInShape objectAtIndex:0];
        
            CGPoint newPoint=ccp(b.Position.x+diffX, b.Position.y+diffY);
            [b setPosition:newPoint];
            if([((id<ShapeContainer>)currentPickupObject.MyContainer).BlocksInShape objectAtIndex:0]!=currentPickupObject){
                    [b.MyContainer layoutMyBlocks];
            }
            else
            {
                if([((id<ShapeContainer>)currentPickupObject.MyContainer).BlocksInShape count]>1){
                    SGDtoolBlock *b2=[((id<ShapeContainer>)currentPickupObject.MyContainer).BlocksInShape objectAtIndex:1];
                    b.Position=ccp(b2.Position.x,b2.Position.y+52);
                    [b.MyContainer layoutMyBlocks];
                }
            }
        }
    }
    
    if(hasBeenProximate)
    {
        hasBeenProximate=NO;
        [loggingService logEvent:BL_PA_DT_TOUCH_MOVE_PROXIMITY_OF_BLOCK withAdditionalData:nil];
    }
    
    [self setTouchVarsToOff];
    //[self checkForOverlappingContainers];
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // empty selected objects
    [self setTouchVarsToOff];
}

-(void)deselectAll
{
    for (id<Selectable,Moveable,NSObject>go in gw.AllGameObjectsCopy) {
        
        if([go conformsToProtocol:@protocol(Moveable)])
        {
            id<ShapeContainer,NSObject>goCont=go.MyContainer;
            
            if([goCont isKindOfClass:[SGDtoolContainer class]])
                goCont.Selected=NO;
            go.Selected=YES;
            [go selectMe];
        }
    }
}

-(CGRect)rectForThisShape:(id<ShapeContainer>)thisShape
{
    CGRect thisShapeRect=CGRectNull;
    for(id<Moveable> block in thisShape.BlocksInShape)
    {
        CCSprite *s=block.mySprite;
        thisShapeRect=CGRectUnion(thisShapeRect, s.boundingBox);
    }

    
    return thisShapeRect;
}

-(void)checkForOverlappingContainers
{
    NSMutableArray *shapeRects=[[[NSMutableArray alloc]init]autorelease];
    NSMutableArray *shapeObjects=[[[NSMutableArray alloc]init]autorelease];
    
    for(id<NSObject,ShapeContainer> go in gw.AllGameObjectsCopy)
    {
        if([go conformsToProtocol:@protocol(ShapeContainer)])
        {
            CGRect thisShapeRect=CGRectNull;
            for(id<Moveable> block in go.BlocksInShape)
            {
                CCSprite *s=block.mySprite;
                thisShapeRect=CGRectUnion(thisShapeRect, s.boundingBox);
            }
            [shapeRects addObject:[NSValue valueWithCGRect:thisShapeRect]];
            [shapeObjects addObject:go];
        }
    }
    
    
    for(int o=0;o<[shapeRects count];o++)
    {
        CGRect contRect=[[shapeRects objectAtIndex:o]CGRectValue];
        
        for(int i=0;i<[shapeRects count];i++)
        {
            if(o==i)continue;
            CGRect otherRect=[[shapeRects objectAtIndex:i]CGRectValue];
            
            if(CGRectIntersectsRect(contRect, otherRect))
            {
                SGDtoolContainer *co=nil;
                SGDtoolBlock *bo=nil;
                // contrect is further left than otherrect
                if(contRect.origin.x<otherRect.origin.x)
                {
                    co=[shapeObjects objectAtIndex:i];
                
                    bo=[co.BlocksInShape objectAtIndex:0];
                    
                    bo.Position=ccp(bo.Position.x+otherRect.size.width-(contRect.size.width), bo.Position.y);


                }
                else
                {
                    co=[shapeObjects objectAtIndex:o];
                    bo=[co.BlocksInShape objectAtIndex:0];
                    
                    bo.Position=ccp(bo.Position.x+contRect.size.width-(otherRect.size.width), bo.Position.y);
                    
                }
                
                [co layoutMyBlocks];
                break;
            }
        }
    }
    
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
            if(![pairableGO.MyContainer conformsToProtocol:@protocol(ShapeContainer)])
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
                        BOOL noArrayFound=NO;
                        
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
        NSMutableArray *shapesFound=[[[NSMutableArray alloc]init]autorelease];
        NSMutableArray *solFound=[[[NSMutableArray alloc]init]autorelease];
        NSMutableArray *containers=[[[NSMutableArray alloc]init]autorelease];
        int solutionsExpected=[solutionsDef count];
        int solutionsFound=0;
        
        
        
        for(NSNumber *n in solutionsDef)
        {
            if([solFound containsObject:n])continue;
            
            for (id cont in gw.AllGameObjects)
            {
                if([shapesFound containsObject:cont])continue;
                
                if([cont conformsToProtocol:@protocol(ShapeContainer)])
                {
                    id<ShapeContainer>thisCont=cont;
                    
                    if(![containers containsObject:cont])
                        [containers addObject:cont];
                    
                    NSLog(@"blocksinshape %d is %d", (int)thisCont, [thisCont.BlocksInShape count]);
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
        
        
        
        NSLog(@"solutions found %d required %d containers %d", solutionsFound, solutionsExpected, [containers count]);
        if (solutionsFound==solutionsExpected && [containers count]==solutionsExpected)
            return YES;
        else
            return NO;
        
    }
    if(evalType==kIncludeShapeSizes)
    {
        NSMutableArray *shapesFound=[[[NSMutableArray alloc]init]autorelease];
        NSMutableArray *solFound=[[[NSMutableArray alloc]init]autorelease];
        NSMutableArray *containers=[[[NSMutableArray alloc]init]autorelease];
        int solutionsExpected=[solutionsDef count];
        int solutionsFound=0;
        
        
        
        for(NSNumber *n in solutionsDef)
        {
            if([solFound containsObject:n])continue;
            
            for (id cont in gw.AllGameObjects)
            {
                if([shapesFound containsObject:cont])continue;
                
                if([cont conformsToProtocol:@protocol(ShapeContainer)])
                {
                    id<ShapeContainer>thisCont=cont;
                    
                    if(![containers containsObject:cont])
                        [containers addObject:cont];
                    
                    NSLog(@"blocksinshape %d is %d", (int)thisCont, [thisCont.BlocksInShape count]);
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
        
        
        if (solutionsFound==solutionsExpected)
            return YES;
        else
            return NO;
        
    }
    
    else if(evalType==kCheckTaggedGroups)
    {
        NSMutableDictionary *d=[NSMutableDictionary dictionaryWithDictionary:[solutionsDef objectAtIndex:0]];
        int solutionsExpected=[d count];
        int solutionsFound=0;
        int totalShapes=0;
        
        
        for(id cont in gw.AllGameObjects)
        {
            
            if([cont conformsToProtocol:@protocol(ShapeContainer)])
            {
                id <ShapeContainer> thisCont=cont;
                totalShapes++;
                
                NSLog(@"BTXE Label tag %@ has %d objects", ((id<Interactive>)thisCont.BTXELabel).tag, [thisCont.BlocksInShape count]);
                
                if([d objectForKey:((SGBtxeObjectIcon*)thisCont.BTXELabel).tag])
                {
                    int thisVal=[[d objectForKey:((SGBtxeObjectIcon*)thisCont.BTXELabel).tag] intValue];
                    if([thisCont.BlocksInShape count]==thisVal)
                        solutionsFound++;
                 
                    [d removeObjectForKey:((SGBtxeObjectIcon*)thisCont.BTXELabel).tag];
                    
                }
            
            }
        }
        
        NSLog(@"solutions found %d, expected %d, total shapes %d", solutionsFound, solutionsExpected, totalShapes);
        
//        for(id cont in gw.AllGameObjects)
//        {
//            if([cont conformsToProtocol:@protocol(ShapeContainer)])
//            {
//                id <ShapeContainer> thisCont=cont;
//                NSString *thisKey=[thisCont.Label string];
//                if([d objectForKey:thisKey])
//                {
//                    
//                    int thisVal=[[d objectForKey:thisKey] intValue];
//                    NSLog(@"this group %d, required for key %d", [thisCont.BlocksInShape count], thisVal);
//                    if([thisCont.BlocksInShape count]==thisVal)
//                        solutionsFound++;
//                }
//            }
//        }
        
        if (solutionsFound==solutionsExpected && solutionsFound==totalShapes)
            return YES;
        else
            return NO;
    }
    
    else if(evalType==kCheckEvalAreas)
    {
        return [self evalNumberOfShapesInEvalAreas];
    }
    
    else if(evalType==kCheckEvalAreasForTypes)
    {
        return [self evalNumberOfShapesAndTypesInEvalAreas];
    }

    else if(evalType==kCheckGroupsForTypes)
    {
        return [self evalNumberOfShapesAndTypesInContainers];
    }
    
    else if(evalType==kCheckGroupTypeAndNumber)
    {
        return [self evalGroupTypesAndShapes];
    }
    
    else if(evalType==kCheckContainerValues)
    {
        return [self evalValueOfShapesInContainers];
    }
    
    else if(evalType==kCheckEvalAreaValues)
    {
        return [self evalValueOfEvalAreas];
    }
    
    else if(evalType==kCheckSelectedGroupEvalTarget)
    {
        int selectCount=0;
        int reqCount=0;
        int selectEval=0;
        BOOL gotTarget=NO;
        
        for(NSDictionary *d in initObjects)
            if([[d objectForKey:IS_EVAL_TARGET]boolValue])reqCount++;
        
        for(id<NSObject,ShapeContainer> cont in gw.AllGameObjects)
        {
            if([cont conformsToProtocol:@protocol(ShapeContainer)])
            {
                if(cont.Selected)
                {
                    selectCount++;
                }
                if(cont.IsEvalTarget && cont.Selected)
                {
                    selectEval++;
                    gotTarget=YES;
                }
            }
        }
        
        if(selectCount==reqCount && selectEval==reqCount && gotTarget)
            return YES;
        else
            return NO;
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
        if(evalMode==kProblemEvalOnCommit)[toolHost doIncomplete];
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
    activeRects=nil;
    initAreas=nil;
    usedShapeTypes=nil;
    addedCages=nil;
    evalAreas=nil;
    inactiveArea=nil;
    activeRects=nil;
    
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [renderLayer release];
    
    [gw release];
    
    [super dealloc];
}
@end