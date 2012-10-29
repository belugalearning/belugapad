//
//  PlaceValue.m
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PlaceValue.h"
#import "global.h"
#import "LoggingService.h"
#import "BLMath.h"
#import "SimpleAudioEngine.h"
#import "ToolConsts.h"
#import "PlaceValueConsts.h"
#import "DWGameWorld.h"
#import "Daemon.h"
#import "ToolHost.h"
#import "UsersService.h"
#import "AppDelegate.h"
#import "InteractionFeedback.h"
#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueNetGameObject.h"
#import "NumberLayout.h"

@interface PlaceValue()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

static float kPropXNetSpace=0.087890625f;
static float kPropYColumnOrigin=0.75f;
static float kCageYOrigin=0.08f;
static float kPropYColumnHeader=0.85f;
static float kPropYColumnTotalCount=0.15f;
static NSString *kDefaultSprite=@"/images/placevalue/obj-placevalue-unit.png";
static float kTimeToCageShake=7.0f;


@implementation PlaceValue

#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    problemDef=pdef;
    
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
        self.NoScaleLayer=[[CCLayer alloc]init];
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        [toolHost addToolNoScaleLayer:self.NoScaleLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        loggingService = ac.loggingService;
        
        [self setupBkgAndTitle];

        [self readPlist:pdef];
        
        [self populateGW];

        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
    
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        lastCount = gw.Blackboard.SelectedObjects.count; 
        
        gw.Blackboard.inProblemSetup = NO;
        
        debugLogging=NO;
        
        for (int i=0;i<numberOfColumns;i++)
        {
            [self setGridOpacity:i toOpacity:127];
        }
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    

    timeSinceInteractionOrShake+=delta;

    // check the problem type
    if(timeSinceInteractionOrShake>7.0f)
    {
        [self isProblemComplete];
        
        if([solutionType isEqualToString:TOTAL_COUNT_AND_COUNT_SEQUENCE] || [solutionType isEqualToString:TOTAL_COUNT])
        {
            // not enough items on - shake cage
            if(lastTotalCount<expectedCount && timeSinceInteractionOrShake>kTimeToCageShake && !touching)
            {
                [gw handleMessage:kDWcheckMyMountIsCage andPayload:nil withLogLevel:-1];
            }
            // too many items - shake netted items
            else if(lastTotalCount>expectedCount && timeSinceInteractionOrShake>kTimeToCageShake && !touching)
            {
                [gw handleMessage:kDWcheckMyMountIsNet andPayload:nil withLogLevel:-1];
            }
            
            if(multipleLabels && !touching && lastTotalCount<expectedCount)
            {
                for(CCLabelTTF *l in multipleLabels)
                {
                    [l runAction:[InteractionFeedback shakeAction]];
                }
            }
            
            hasRunInteractionFeedback=YES;
        }
        if(isProblemComplete && evalMode==kProblemEvalOnCommit)
        {
            [toolHost shakeCommitButton];
        }
        
        timeSinceInteractionOrShake=0.0f;
    }
    
    // update our labels for thinging
    if(showMultipleControls||multipleBlockPickup)
    {
        [self checkAndChangeCageSpritesForMultiple];
        for(int i=0;i<[multipleLabels count];i++)
        {
            CCLabelTTF *l=[multipleLabels objectAtIndex:i];
            [l setString:[NSString stringWithFormat:@"%d", [[blocksToCreate objectAtIndex:i]intValue]]];
        }
    }
    
    if(isNegativeProblem)
    {
        [self checkAndChangeCageSpritesForNegative];
        for(int i=0;i<[blockLabels count];i++)
        {
            CCLabelTTF *l=[blockLabels objectAtIndex:i];
            [l setString:[NSString stringWithFormat:@"%d", [[currentBlockValues objectAtIndex:i]intValue]]];
        }
    }
    

    if(showCount)
    {
        for(int i=0;i<numberOfColumns;i++)
        {
            CCLabelTTF *l=[[[totalCountSprites objectAtIndex:i] children] objectAtIndex:0];
            
            int initedOnGrid=[[initBlocksForColumn objectAtIndex:i]intValue];
            float colValue=[[[columnInfo objectAtIndex:i] objectForKey:COL_VALUE] floatValue];
            
            if([self usedSpacesOnGrid:i]>initedOnGrid)
                [l setString:[NSString stringWithFormat:@"%g+%g", ([[initBlocksForColumn objectAtIndex:i]intValue]*colValue), ([self usedSpacesOnGrid:i]-initedOnGrid)*colValue]];
            else if([self usedSpacesOnGrid:currentColumnIndex]<=initedOnGrid)
                [l setString:[NSString stringWithFormat:@"%g", ([[initBlocksForColumn objectAtIndex:i]intValue]*colValue)-(([[initBlocksForColumn objectAtIndex:i]intValue]-[self usedSpacesOnGrid:i])*colValue)]];
        }
    }
    
    if(showValue)
        [countLabel setString:[NSString stringWithFormat:@"%g", totalObjectValue]];
    
    if(showMoreOrLess && [solutionType isEqualToString:TOTAL_COUNT])
    {

        NSString *expNo=[[NSNumber numberWithFloat:expectedCount]stringValue];
        for(int i=0;i<numberOfColumns;i++)
        {
            
            CCSprite *s=[arrowsForColumn objectAtIndex:i];
            
            NSString *thisNo=[NSString stringWithFormat:@"%c",[expNo characterAtIndex:i]];
            
            int blocksNeeded=[thisNo intValue];
            
            //float blocksNeeded=trackValue/colValue;
            int usedSpaces=[self usedSpacesOnGrid:i];
            
            if((int)blocksNeeded==usedSpaces)
            {
                [s setVisible:NO];
            }
            else if((int)blocksNeeded!=usedSpaces)
            {
                if(blocksNeeded>usedSpaces)
                {
                    [s setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/pv_notification_more.png")]];
                    [s setVisible:YES];
                    CCLabelTTF *l=[s.children objectAtIndex:0];
                    [l setPosition:ccp(l.position.x, (s.contentSize.height/2)-2)];
                    [l setString:[NSString stringWithFormat:@"%d more", (int)blocksNeeded-usedSpaces]];
                    
                }
                else if(blocksNeeded<usedSpaces)
                {
                    [s setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/pv_notification_less.png")]];
                    [s setVisible:YES];
                    CCLabelTTF *l=[s.children objectAtIndex:0];
                    [l setPosition:ccp(l.position.x, (s.contentSize.height/2)+5)];
                    [l setString:[NSString stringWithFormat:@"%d less", usedSpaces-(int)blocksNeeded]];
                }
            }
            
        }
    }
    
    
    
    // if we've run interaction feedback, loop through a bunch of objects - check they're running nothing and reset their position if need be
    if(hasRunInteractionFeedback)
    {
        BOOL finished=NO;
        
        finished=[self resetObjectPositions];
        
        if(finished)
            hasRunInteractionFeedback=NO;
    }
    
    if([gw.Blackboard SelectedObjects].count==columnBaseValue && showBaseSelection && (allowCondensing || autoBaseSelection))
        isBasePickup=YES;
    else
        isBasePickup=NO;
    
    [self flipToBaseSelection];
    //[self checkMountPositionsForBlocks];
}

#pragma mark gameworld setup and population
-(void)setupProblem
{
    touching = NO;
}

-(void)populateGW
{
    thisLog=0;
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    int currentColumnRows = 0;
    int currentColumnRopes = 0;
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    float ropeWidth = kPropXNetSpace*lx;

    columnInfo = [[NSMutableArray alloc] init];
    
    float currentColumnValue = firstColumnValue;
    
    for (int i=0; i<numberOfColumns; i++)
    {

        BOOL showMultipleDragging=NO;
        NSMutableDictionary *currentColumnInfo = [[[NSMutableDictionary alloc] init] autorelease];
        if(!multipleLabels)multipleLabels=[[NSMutableArray alloc]init];
        if(!multipleMinusSprites)multipleMinusSprites=[[NSMutableArray alloc]init];
        if(!multiplePlusSprites)multiplePlusSprites=[[NSMutableArray alloc]init];
        if(!pickupObjects)pickupObjects=[[NSMutableArray alloc]init];
        
        [currentColumnInfo setObject:[NSNumber numberWithFloat:currentColumnValue] forKey:COL_VALUE];
        [currentColumnInfo setObject:[NSString stringWithFormat:@"%gs", currentColumnValue] forKey:COL_LABEL];
        
        [columnInfo addObject:currentColumnInfo];
        
        
        // if column headers should be shown
        if(showColumnHeader)
        {
            CCLabelTTF *columnHeader;
            
            // check if a custom header exists or use a generic one
            if([showCustomColumnHeader objectForKey:[NSString stringWithFormat:@"%g", currentColumnValue]])
            {
                NSString *columnHeaderText = [showCustomColumnHeader objectForKey:[NSString stringWithFormat:@"%g", currentColumnValue]];
                columnHeader = [CCLabelTTF labelWithString:columnHeaderText fontName:TITLE_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            }
            else
            {
                columnHeader = [CCLabelTTF labelWithString:[currentColumnInfo objectForKey:COL_LABEL] fontName:TITLE_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            }
            if(gw.Blackboard.inProblemSetup)
            {
                [columnHeader setTag:3];
                [columnHeader setOpacity:0];
                [columnHeader setPosition:ccp(i*(kPropXColumnSpacing*lx), ly*kPropYColumnHeader)];
                [renderLayer addChild:columnHeader z:5];
            }
        }
        
        
        NSString *currentColumnValueKey = [NSString stringWithFormat:@"%g", [[currentColumnInfo objectForKey:COL_VALUE] floatValue]];
        
        DLog(@"Reset current column value to %f", currentColumnValue);
        
        NSMutableArray *newCol = [[NSMutableArray alloc] init];
        
        [gw.Blackboard.AllStores addObject:newCol];
        
        // set the layer position
        
        float layerPositionX = (cx-(defaultColumn*(kPropXColumnSpacing*lx))+(xStartOffset*lx));
        [renderLayer setPosition:ccp(layerPositionX, 0)];
        
        if(currentColumnValue == defaultColumn)
        {   
            gw.Blackboard.CurrentStore = newCol;
            currentColumnIndex = i;
        }

        // check for definitions of current colum ropes/rows
        if([columnRopes objectForKey:currentColumnValueKey]) currentColumnRopes = [[columnRopes objectForKey:currentColumnValueKey] intValue];
        else currentColumnRopes = ropesforColumn;
        if([columnRows objectForKey:currentColumnValueKey]) currentColumnRows = [[columnRows objectForKey:currentColumnValueKey] intValue];
        else currentColumnRows = rows;
        
        // check whether this row is showing multiple block facilities
        if([[multipleBlockPickup objectForKey:currentColumnValueKey]boolValue] || showMultipleControls) {
            showMultipleDragging=YES;
            posCageSprite=BUNDLE_FULL_PATH(@"/images/placevalue/cage-variable.png");
        }
        
        else if(isNegativeProblem)
        {
            posCageSprite=BUNDLE_FULL_PATH(@"/images/placevalue/cage-variable.png");            
        }
        else
        {
            showMultipleDragging=NO;
            posCageSprite=BUNDLE_FULL_PATH(@"/images/placevalue/cage-single.png");
        }

        CGPoint thisColumnOrigin = ccp(-((ropeWidth*ropesforColumn)/2.0f)+(ropeWidth/2.0f)+(i*(kPropXColumnSpacing*lx)), ly*kPropYColumnOrigin);
        // create this column
        for (int iRow=0; iRow<currentColumnRows; iRow++)
        {
            NSMutableArray *RowArray = [[NSMutableArray alloc] init];        
            [newCol addObject:RowArray];
            
            CGPoint rowOrigin=ccp(thisColumnOrigin.x, thisColumnOrigin.y-(iRow*ropeWidth)); 
            // if the default ropes are different, adjust the X position of this column
            if(currentColumnRopes != ropesforColumn)
            {
                float adjustAmount = (((ropesforColumn-currentColumnRopes) / 2.0f) * ropeWidth);
                rowOrigin=ccp(rowOrigin.x+adjustAmount, rowOrigin.y);
            }
            
            for(int iRope=0; iRope<currentColumnRopes; iRope++)
            {
                CGPoint containerOrigin=ccp(rowOrigin.x+(iRope*ropeWidth), rowOrigin.y);
                DWPlaceValueNetGameObject *c=[DWPlaceValueNetGameObject alloc];
                [gw populateAndAddGameObject:c withTemplateName:@"TplaceValueContainer"];
                
                c.PosX=containerOrigin.x;
                c.PosY=containerOrigin.y;
                c.myRow=iRow;
                c.myCol=i;
                c.myRope=iRope;
                
                // if we want to be able to have items cancel each other out -- we need explode mode to be on
                if(isNegativeProblem && explodeMode)
                    c.AllowMultipleMount=YES;
                
                if(c.myRow==0)
                    c.renderType=1;
                else if(c.myRow==currentColumnRopes-1)
                    c.renderType=2;
                

                c.ColumnValue=[[currentColumnInfo objectForKey:COL_VALUE] floatValue];

                
                [RowArray addObject:c];                
                
                //[c release];
            }
            
            [RowArray release];
        }
        
        
        if(showColumnTotalCount||showCount)
        {
            if(!totalCountSprites)
                totalCountSprites=[[[NSMutableArray alloc]init]retain];
            
            CCSprite *totalCountSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/placevalue/total_count_bg.png")];
            [totalCountSprite setPosition:ccp(i*(kPropXColumnSpacing*lx), (ly*kPropYColumnOrigin)-(currentColumnRows*(lx*kPropXNetSpace)))];
            [totalCountSprite setOpacity:0];
            [totalCountSprite setTag:2];
            [renderLayer addChild:totalCountSprite];
            [totalCountSprites addObject:totalCountSprite];
        
            if(showColumnTotalCount)
            {
                CCLabelTTF *totalCountLabel=[CCLabelTTF labelWithString:@"0" fontName:CHANGO fontSize:30.0f];
                [totalCountLabel setPosition:ccp(totalCountSprite.contentSize.width/2,(totalCountSprite.contentSize.height/2)-3)];
                [totalCountLabel setOpacity:0];
                [totalCountLabel setTag:2];
                [totalCountSprite addChild:totalCountLabel];
            }
            
            if(showCount)
            {
                CCLabelTTF *thisCountLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",[[initBlocksForColumn objectAtIndex:i]intValue]] fontName:CHANGO fontSize:25.0f];
                [thisCountLabel setPosition:ccp(totalCountSprite.contentSize.width/2,(totalCountSprite.contentSize.height/2)-3)];
                [thisCountLabel setOpacity:0];
                [thisCountLabel setTag:2];
                [totalCountSprite addChild:thisCountLabel];
            }
        }
        
        
        
        if(showColumnUserCount)
        {
            NSMutableArray *a=[[NSMutableArray alloc]init];
            [userAddedBlocks addObject:a];
            
            if(!userAddedBlocksLastCount)
                userAddedBlocksLastCount=[[[NSMutableArray alloc]init]retain];
            
            [userAddedBlocksLastCount addObject:[NSNumber numberWithInt:0]];
        }
        
        if(showMoreOrLess)
        {
            CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/placevalue/pv_notification_more.png")];
            [s setPosition:ccp(i*(kPropXColumnSpacing*lx), (ly*kPropYColumnOrigin)-(currentColumnRows*(lx*kPropXNetSpace)))];
            [s setVisible:NO];
            [renderLayer addChild:s];
            [arrowsForColumn addObject:s];
            
            CCLabelTTF *l=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:20.0f];
            [l setPosition:ccp(s.contentSize.width/2, s.contentSize.height/2)];
            [s addChild:l];
        }
        
        if(!([columnCages objectForKey:currentColumnValueKey]) || ([[columnCages objectForKey:currentColumnValueKey] boolValue]==YES))
        {
            CCSprite *cageContainer = [CCSprite spriteWithFile:posCageSprite];
            [cageContainer setPosition:ccp(i*(kPropXColumnSpacing*lx), ly*kCageYOrigin)];
            [cageContainer setOpacity:0];
            [cageContainer setTag:2];
            [renderLayer addChild:cageContainer z:10];
            
            
            // create cage
            DWPlaceValueCageGameObject *cge=[DWPlaceValueCageGameObject alloc];
            [gw populateAndAddGameObject:cge withTemplateName:@"TplaceValueCage"];
            cge.AllowMultipleMount=YES;
            cge.PosX=i*(kPropXColumnSpacing*lx);
            cge.PosY=ly*kCageYOrigin;
            
            cge.mySprite=cageContainer;
            
            if(isNegativeProblem)
                cge.ObjectValue=cageDefaultValue*currentColumnValue;
            else
                cge.ObjectValue=[[currentColumnInfo objectForKey:COL_VALUE]floatValue];
            
            // set our column specific options on the store
            
            if([columnCagePosDisableAdd objectForKey:currentColumnValueKey])
                cge.DisableAdd=[[columnCagePosDisableAdd objectForKey:currentColumnValueKey] boolValue];
            
            
            if([columnCagePosDisableDel objectForKey:currentColumnValueKey])
                cge.DisableDel=[[columnCagePosDisableDel objectForKey:currentColumnValueKey] boolValue];
            
            if([columnCageNegDisableAdd objectForKey:currentColumnValueKey])
                cge.DisableAddNeg=[[columnCageNegDisableAdd objectForKey:currentColumnValueKey] boolValue];
            
            
            if([columnCageNegDisableDel objectForKey:currentColumnValueKey])
                cge.DisableDelNeg=[[columnCageNegDisableDel objectForKey:currentColumnValueKey] boolValue];
            
            
            if([columnSprites objectForKey:currentColumnValueKey])
                cge.SpriteFilename=[columnSprites objectForKey:currentColumnValueKey];

            else
                cge.SpriteFilename=kDefaultSprite;
            
            
            
            if(pickupSprite)
                cge.PickupSpriteFilename=pickupSprite;
            
            
                
            if(!allCages) allCages=[[[NSMutableArray alloc] init]retain];
            [allCages addObject:cge];
            [cge release];
            
        }
        else
        {
            if(!allCages) allCages=[[[NSMutableArray alloc] init]retain];
            [allCages addObject:[NSNull null]];
        }
        
        if(showMultipleDragging && (!([columnCages objectForKey:currentColumnValueKey]) || ([[columnCages objectForKey:currentColumnValueKey] boolValue]==YES)))
        {
            int defaultBlocksToMake=1;
            
            if([multipleBlockPickupDefaults objectForKey:currentColumnValueKey])
                defaultBlocksToMake=[[multipleBlockPickupDefaults objectForKey:currentColumnValueKey]intValue];
            else
                defaultBlocksToMake=1;
            
            [blocksToCreate addObject:[NSNumber numberWithInt:defaultBlocksToMake]];
            
            //CCSprite *minusSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/placevalue/minus40.png")];
            //CCSprite *posiSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/placevalue/plus40.png")];
            CCLabelTTF *label=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", defaultBlocksToMake] fontName:@"Chango" fontSize:PROBLEM_DESC_FONT_SIZE];
            
            float PosX=i*(kPropXColumnSpacing*lx)-120;
            float PosY=(ly*kCageYOrigin)-41;
            
            CGRect minus=CGRectMake(PosX, PosY, 70, 82);
            CGRect plus=CGRectMake(PosX+170, PosY, 70, 82);
            
            //[minusSprite setPosition:ccp(PosX,PosY-25)];
            //[posiSprite setPosition:ccp(PosX,PosY+25)];
            [label setPosition:ccp(PosX+120,PosY+61)];
            
            [multipleMinusSprites addObject:[NSValue valueWithCGRect:minus]];
            [multiplePlusSprites addObject:[NSValue valueWithCGRect:plus]];
            [multipleLabels addObject:label];
            [label setTag:3];
            [label setOpacity:0];
            [label setColor:ccc3(0,0,0)];
            
            //[renderLayer addChild:minusSprite];
            //[renderLayer addChild:posiSprite];
            [renderLayer addChild:label z:99999];
            
        }
        else if(isNegativeProblem && (!([columnCages objectForKey:currentColumnValueKey]) || ([[columnCages objectForKey:currentColumnValueKey] boolValue]==YES)))
        {
            [currentBlockValues addObject:[NSNumber numberWithInt:cageDefaultValue]];
            
            CCLabelTTF *label=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", cageDefaultValue] fontName:@"Chango" fontSize:PROBLEM_DESC_FONT_SIZE];
            
            float PosX=i*(kPropXColumnSpacing*lx)-120;
            float PosY=(ly*kCageYOrigin)-41;
            
            CGRect minus=CGRectMake(PosX, PosY, 70, 82);
            CGRect plus=CGRectMake(PosX+170, PosY, 70, 82);
            
            //[minusSprite setPosition:ccp(PosX,PosY-25)];
            //[posiSprite setPosition:ccp(PosX,PosY+25)];
            [label setPosition:ccp(PosX+120,PosY+61)];
            
            [multipleMinusSprites addObject:[NSValue valueWithCGRect:minus]];
            [multiplePlusSprites addObject:[NSValue valueWithCGRect:plus]];
            [blockLabels addObject:label];
            
            if(debugLogging)
                NSLog(@"currentBlockValues count %d, minusSprites count %d, plusSprites count %d, blockLabels count %d", [currentBlockValues count], [multipleMinusSprites count], [multiplePlusSprites count], [blockLabels count]);

        
            [label setTag:3];
            [label setOpacity:0];
            [label setColor:ccc3(0,0,0)];
            
            //[renderLayer addChild:minusSprite];
            //[renderLayer addChild:posiSprite];
            [renderLayer addChild:label z:99999];

        }
        else {
            if(multipleBlockPickup)
            {
                int defaultBlocksToMake=1;
                [blocksToCreate addObject:[NSNumber numberWithInt:defaultBlocksToMake]];

                CGRect minus=CGRectZero;
                CGRect plus=CGRectZero;

                CCLabelTTF *label=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", defaultBlocksToMake] fontName:CHANGO fontSize:PROBLEM_DESC_FONT_SIZE];
                
                [multipleMinusSprites addObject:[NSValue valueWithCGRect:minus]];
                [multiplePlusSprites addObject:[NSValue valueWithCGRect:plus]];
                
                [multipleLabels addObject:label];
            }
        }
         
        [newCol release];

        //decrement for next column
        currentColumnValue = (currentColumnValue/columnBaseValue);
    }
    

    int numberPrecountedForRow=0;
    
    
    for(int i=0; i<(initObjects.count); i++)
    {
        NSDictionary *curDict = [initObjects objectAtIndex:i];
        int insCol = [[curDict objectForKey:PUT_IN_COL] intValue];
        int insRow = [[curDict objectForKey:PUT_IN_ROW] intValue];
        int count = [[curDict objectForKey:NUMBER] intValue];
        int countneg = [[curDict objectForKey:NUMBER_NEGATIVE]intValue];
        int numberToPrecount = [[curDict objectForKey:NUMBER_PRE_COUNTED] intValue];
        
        //check if there is a max setting on objects to populate -- acts as bounds for dvar problems
        NSArray *maxO=[problemDef objectForKey:@"MAX_OBJECTS_IN_COLS"];
        BOOL boundCol=NO;
        int boundCounter=0;
        int boundMax=0;
        
        if(maxO)
        {
            for (NSDictionary *maxODef in maxO) {
                NSNumber *coldef=[maxODef objectForKey:@"COL"];
                NSNumber *maxdef=[maxODef objectForKey:@"NUMBER"];
                
                if ([coldef intValue]==insCol && maxdef) {
                    if([maxdef intValue])
                    {
                        if(!boundCounts) boundCounts=[[NSMutableDictionary alloc] init];
                        
                        boundCol=YES;
                        //see if there a dict item for this
                        NSNumber *boundPre=[boundCounts objectForKey:[NSNumber numberWithInt:insCol]];
                        if(boundPre) boundCounter=[boundPre intValue];
                        boundMax=[maxdef intValue];
                    }
                }
            }
        }
        
        int blocksAddedToThisRow=0;
        int ropesHere=[[[gw.Blackboard.AllStores objectAtIndex:insCol] objectAtIndex:insRow] count]-1;
        
        for(int i=0; i<count+countneg; i++)
        {
            
            if(boundCol)
            {
                //incr the total count in this bound col
                boundCounter++;
                
                //if past max, stop adding objects
                if(boundCounter>boundMax) break;
                
                //update total count in this col
                [boundCounts setObject:[NSNumber numberWithInt:boundCounter] forKey:[NSNumber numberWithInt:insCol]];
            }
            
            
            DWPlaceValueBlockGameObject *block=[DWPlaceValueBlockGameObject alloc];
            [gw populateAndAddGameObject:block withTemplateName:@"TplaceValueObject"];
            
            if([curDict objectForKey:PUT_IN_ROW])
                block.Mount=[[[gw.Blackboard.AllStores objectAtIndex:insCol] objectAtIndex:insRow] objectAtIndex:i];
            else
                block.Mount=[[[gw.Blackboard.AllStores objectAtIndex:insCol] objectAtIndex:(int)i/(ropesHere+1)] objectAtIndex:blocksAddedToThisRow];
                
            if(i<count)
                block.ObjectValue=[[[columnInfo objectAtIndex:insCol] objectForKey:COL_VALUE] floatValue];
            else
                block.ObjectValue=-[[[columnInfo objectAtIndex:insCol] objectForKey:COL_VALUE] floatValue];
            
            // check whether a custom sprite has been set for this column, and if so, set it.
            NSString *currentColumnValueKey = [NSString stringWithFormat:@"%g", [[[columnInfo objectAtIndex:insCol] objectForKey:COL_VALUE] floatValue]];
            
            if([columnSprites objectForKey:currentColumnValueKey])
                block.SpriteFilename=[columnSprites objectForKey:currentColumnValueKey];
            
            
            if(pickupSprite)
                block.PickupSprite=pickupSprite;
            
            
            
            if(numberPrecountedForRow<numberToPrecount)
                [block handleMessage:kDWswitchSelection andPayload:nil withLogLevel:-1];
                numberPrecountedForRow++;
            
            [block handleMessage:kDWsetMount andPayload:nil withLogLevel:-1];
            if(blocksAddedToThisRow==ropesHere)
                blocksAddedToThisRow=0;
            else
                blocksAddedToThisRow++;
            
            [block release];
            
        }
        numberPrecountedForRow=0;
        DLog(@"col %d, rows %d, count %d", insCol, insRow, count);
        
        
        if(showColumnTotalCount)
        {
            float v=[[[columnInfo objectAtIndex:insCol] objectForKey:COL_VALUE] floatValue];
            CCSprite *s=[totalCountSprites objectAtIndex:insCol];
            CCLabelTTF *l=[s.children objectAtIndex:0];
            
            [l setString:[NSString stringWithFormat:@"%g", [self usedSpacesOnGrid:insCol]*v]];
        }

    }
    
    if(showCount)
    {
        if(!initBlocksForColumn){
            initBlocksForColumn=[[NSMutableArray alloc]init];
            [initBlocksForColumn retain];
        }
        
        for(int i=0;i<numberOfColumns;i++)
        {
            int blocksHere=[self usedSpacesOnGrid:i];
            [initBlocksForColumn addObject:[NSNumber numberWithInt:blocksHere]];
        }
    }

    [renderLayer setPosition:ccp(cx-(currentColumnIndex*(kPropXColumnSpacing*lx)+(xStartOffset*lx)), 0)];
    
    // send a problemstatechanged so that any total count eval, etc is done
    [self problemStateChanged];
    
    int objectsOnGrid=[self usedSpacesOnGrid:currentColumnIndex];
    
    if(objectsOnGrid==columnBaseValue && currentColumnIndex!=0)
    {
        [self selectBaseObjectsOnGrid:defaultColumn];
    }
    
    // define our rects for no-drag areas
    noDragAreaBottom=CGRectMake(0,0,lx,120);
    noDragAreaTop=CGRectMake(0, ly-120, lx, 120);
    

}

-(void)setupBkgAndTitle
{
    condensePanel=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/placevalue/cmpanel.png")];
    [condensePanel setPosition:ccp(100, cy)];
    [condensePanel setVisible:NO];
    [self.NoScaleLayer addChild:condensePanel z:1];
    
    mulchPanel=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/placevalue/cmpanel.png")];
    [mulchPanel setPosition:ccp(lx-100, cy)];
    [mulchPanel setVisible:NO];
    [self.NoScaleLayer addChild:mulchPanel z:1];
    
}

-(void)readPlist:(NSDictionary*)pdef
{	
    [gw logInfo:[NSString stringWithFormat:@"started problem"] withData:0];
    

    isNegativeProblem=[[pdef objectForKey:IS_NEGATIVE_PROBLEM]boolValue];
    
    if([[pdef objectForKey:DEFAULT_COL] intValue])
        defaultColumn = [[pdef objectForKey:DEFAULT_COL] intValue]; 
    else
        defaultColumn = 0; 
    
    if([pdef objectForKey:X_OFFSET])
        xStartOffset = [[pdef objectForKey:X_OFFSET]floatValue];
    else
        xStartOffset=0.0f;
    
    if([pdef objectForKey:COLUMN_SPACING])
        kPropXColumnSpacing = [[pdef objectForKey:COLUMN_SPACING]floatValue];
    else
        kPropXColumnSpacing=0.5f;
    
    columnBaseValue = [[pdef objectForKey:COL_BASE_VALUE] floatValue];
    firstColumnValue = [[pdef objectForKey:FIRST_COL_VALUE] floatValue];
    numberOfColumns = [[pdef objectForKey:NUMBER_COLS] floatValue];
    
    ropesforColumn = [[pdef objectForKey:ROPES_PER_COL] intValue];
    rows = [[pdef objectForKey:ROWS_PER_COL] intValue];
    showCount=[[pdef objectForKey:SHOW_COUNT]boolValue];
    showValue = [[pdef objectForKey:SHOW_VALUE] boolValue];
    showReset=[[pdef objectForKey:SHOW_RESET] boolValue];
    showColumnHeader = [[pdef objectForKey:SHOW_COL_HEADER] boolValue];
    showBaseSelection = [[pdef objectForKey:SHOW_BASE_SELECTION] boolValue];
    cageDefaultValue = [[pdef objectForKey:CAGE_DEFAULT_VALUE] intValue];
    explodeMode = [[pdef objectForKey:EXPLODE_MODE]boolValue];
    
    if([pdef objectForKey:SHOW_COLUMN_TOTAL_COUNT])
        showColumnTotalCount = [[pdef objectForKey:SHOW_COLUMN_TOTAL_COUNT]boolValue];
    else
        showColumnTotalCount = YES;
    
    if([pdef objectForKey:SHOW_COLUMN_USER_COUNT])
        showColumnUserCount = [[pdef objectForKey:SHOW_COLUMN_USER_COUNT]boolValue];
    else
        showColumnUserCount = YES;
    
    if(showColumnUserCount)
        userAddedBlocks=[[[NSMutableArray alloc]init]retain];
    
    if([pdef objectForKey:DISABLE_AUDIO_COUNTING])
        disableAudioCounting = [[pdef objectForKey:DISABLE_AUDIO_COUNTING] boolValue];
    else
        disableAudioCounting=NO;
    
    if([pdef objectForKey:SHOW_MULTIPLE_BLOCKS_FROM_CAGE])
        showMultipleControls = [[pdef objectForKey:SHOW_MULTIPLE_BLOCKS_FROM_CAGE]boolValue];
    else
        showMultipleControls = NO;
    

    
    // look at what positive columns are allowed to add/del
    
    if([pdef objectForKey:CAGE_POS_DISABLE_ADD]) 
        columnCagePosDisableAdd = [pdef objectForKey:CAGE_POS_DISABLE_ADD];
    
    [columnCagePosDisableAdd retain];
    
        
    if([pdef objectForKey:CAGE_POS_DISABLE_DELETE]) 
        columnCagePosDisableDel = [pdef objectForKey:CAGE_POS_DISABLE_DELETE];
    
    [columnCagePosDisableDel retain];
    
    // look at which negative column cages can add/del
    if([pdef objectForKey:CAGE_NEG_DISABLE_ADD]) 
        columnCageNegDisableAdd = [pdef objectForKey:CAGE_NEG_DISABLE_ADD];
    
    [columnCageNegDisableAdd retain];
    
    
    if([pdef objectForKey:CAGE_NEG_DISABLE_DELETE]) 
        columnCageNegDisableDel = [pdef objectForKey:CAGE_NEG_DISABLE_DELETE];
    
    [columnCageNegDisableDel retain];
    
    // are there any custom cage sprites defined?
    if([[pdef objectForKey:CAGE_SPRITES] objectForKey:POS_CAGE])
        posCageSprite = [NSString stringWithFormat:@"%@", BUNDLE_FULL_PATH([[pdef objectForKey:CAGE_SPRITES] objectForKey:POS_CAGE])];
    else posCageSprite=BUNDLE_FULL_PATH(@"/images/placevalue/cage-single.png");
            
    [posCageSprite retain];
    
    // are there any custom negative cage sprites?
    if([[pdef objectForKey:CAGE_SPRITES] objectForKey:NEG_CAGE]) 
        negCageSprite = [NSString stringWithFormat:@"%@", BUNDLE_FULL_PATH([[pdef objectForKey:CAGE_SPRITES] objectForKey:NEG_CAGE])];
    else negCageSprite=BUNDLE_FULL_PATH(@"/images/placevalue/cage-neg.png");
    
    [negCageSprite retain];
        
    // and do we have a separate pickup sprite?
    if([pdef objectForKey:PICKUP_SPRITE_FILENAME]) 
        pickupSprite = [pdef objectForKey:PICKUP_SPRITE_FILENAME];
    
    [pickupSprite retain];
    

    // check for custom column ropes/rows
    if([pdef objectForKey:COLUMN_ROPES]) 
        columnRopes = [pdef objectForKey:COLUMN_ROPES];
    
    [columnRopes retain];
    
        
    if([pdef objectForKey:COLUMN_ROWS]) 
        columnRows = [pdef objectForKey:COLUMN_ROWS];
    
    [columnRows retain];
    
    if([pdef objectForKey:MULTIPLE_BLOCK_PICKUP])
        multipleBlockPickup = [pdef objectForKey:MULTIPLE_BLOCK_PICKUP];
    
    [multipleBlockPickup retain];

    if([pdef objectForKey:MULTIPLE_BLOCK_PICKUP_DEFAULTS])
        multipleBlockPickupDefaults = [pdef objectForKey:MULTIPLE_BLOCK_PICKUP_DEFAULTS];
    
    [multipleBlockPickupDefaults retain];


    // can we deselect objects?
    if([pdef objectForKey:ALLOW_DESELECTION]) 
        allowDeselect = [[pdef objectForKey:ALLOW_DESELECTION] boolValue];
    else 
        allowDeselect=YES;
    
    // are we allowing the layer to be moved?
    if([pdef objectForKey:ALLOW_PANNING]) 
        allowPanning=[[pdef objectForKey:ALLOW_PANNING]boolValue];
    else 
        allowPanning=YES;
    
    // can we condense?
    if([pdef objectForKey:ALLOW_CONDENSING]) 
        allowCondensing=[[pdef objectForKey:ALLOW_CONDENSING]boolValue];
    else 
        allowCondensing=YES;
    
    // can we mulch?
    if([pdef objectForKey:ALLOW_MULCHING])
        allowMulching=[[pdef objectForKey:ALLOW_MULCHING]boolValue];
    else
        allowMulching=YES;
    
    if([pdef objectForKey:SHOW_MORE_LESS_ARROWS])
        showMoreOrLess=[[pdef objectForKey:SHOW_MORE_LESS_ARROWS]boolValue];
    
    else
        showMoreOrLess=NO;
    
    if(showMoreOrLess) arrowsForColumn=[[[NSMutableArray alloc]init]retain];
    
    if([pdef objectForKey:AUTO_SELECT_BASE_VALUE])
    {
        autoBaseSelection=[[pdef objectForKey:AUTO_SELECT_BASE_VALUE]boolValue];
        if(autoBaseSelection)
            showBaseSelection=YES;
    }
    else
    {
        if(numberOfColumns>1)
        {
            showBaseSelection=YES;
            autoBaseSelection=YES;
        }
    }
    if(autoBaseSelection)allowDeselect=NO;
    
    if(showColumnTotalCount)showValue=NO;
    
    //objects
    NSArray *objects=[pdef objectForKey:INIT_OBJECTS];
    initObjects = objects;
    
    // what's our reject mode on this problem?
    NSNumber *rMode=[pdef objectForKey:REJECT_MODE];
    if (rMode) rejectMode=[rMode intValue];
    
    // is a reject type defined?
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    
    // what eval mode is set?
    NSNumber *eMode=[pdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    
    // and define our solutions
    solutionsDef=[pdef objectForKey:SOLUTION];
    
    if(solutionsDef)
    {
        //only do solution & commit related stuff if there's a defined solution
        [solutionsDef retain];
        
        // set the display text of the solution
        solutionDisplayText = [solutionsDef objectForKey:SOLUTION_DISPLAY_TEXT];
        incompleteDisplayText = [solutionsDef objectForKey:INCOMPLETE_DISPLAY_TEXT];
        
        // and if it doesn't exist, use a generic one
        if(!solutionDisplayText) solutionDisplayText=[NSString stringWithFormat:@"problem complete! well done"];
        if(!incompleteDisplayText) incompleteDisplayText=[NSString stringWithFormat:@"problem incomplete, try again!"];
        [solutionDisplayText retain];
        [incompleteDisplayText retain];
        
        // set the expected count for a TOTAL_COUNT problem if there
        expectedCount = [[solutionsDef objectForKey:SOLUTION_VALUE] floatValue];

        solutionType = [solutionsDef objectForKey:SOLUTION_TYPE];

        if([solutionType isEqualToString:@"TOTAL_COUNT_AND_COUNT_SEQUENCE"])
            solutionType=@"TOTAL_COUNT";
        
    }
    else
    {
        //this is probably a meta question -- we're okay to proceed without a solution
        
    }
    
    // if the problem should be showing a reset button
    if(showReset)
    {
        CCSprite *resetBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/reset.png")];
        [resetBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), ly-(kPropXCommitButtonPadding*lx))];
        [resetBtn setTag:3];
        [resetBtn setOpacity:0];
        [self.ForeLayer addChild:resetBtn z:2];        
    }
    
    //look for custom column headers
    if([pdef objectForKey:CUSTOM_COLUMN_HEADERS]) {
        showCustomColumnHeader = [pdef objectForKey:CUSTOM_COLUMN_HEADERS];
        [showCustomColumnHeader retain];
    }
    
    if([pdef objectForKey:COLUMN_SPRITES]) {
        //look for column specific sprites
        columnSprites = [pdef objectForKey:COLUMN_SPRITES];
        [columnSprites retain];
    }
    
    if([pdef objectForKey:COLUMN_CAGES]) {
        //look for column cages
        columnCages = [pdef objectForKey:COLUMN_CAGES];
        [columnCages retain];
    }
    
    
    // define how we show our count/sum labels if applicable
    if(showCount||showValue)
    {
        if(showCount)
        {

            
//            countLabel=[CCLabelTTF labelWithString:@"s" fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
//            [countLabel setTag:3];
//            [countLabel setOpacity:0];
//            [countLabel setPosition:ccp(lx-60,ly-88)];
//            //[countLabel setPosition:ccp(lx-(kPropXCountLabelPadding*lx), kPropYCountLabelPadding*ly)];
//            [self.NoScaleLayer addChild:countLabel z:10];
        }
            
        if(showValue)
        {
            CCSprite *countBg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/placevalue/pv_counter_total.png")];
            [countBg setPosition:ccp(lx-60,ly-85)];
            [countBg setTag:3];
            [countBg setOpacity:0];
            [self.NoScaleLayer addChild:countBg z:9];
            sumLabel=[CCLabelTTF labelWithString:@"c" fontName:CHANGO fontSize:PROBLEM_DESC_FONT_SIZE];
            [sumLabel setTag:3];
            [sumLabel setOpacity:0];
            //[countLabel setPosition:ccp(lx-(kPropXCountLabelPadding*lx), kPropYCountLabelPadding*ly)];

            [self.NoScaleLayer addChild:sumLabel z:10];
        }
        

    }

    if(showColumnTotalCount && showCount)
        showColumnTotalCount=NO;
    
    if(showMultipleControls||multipleBlockPickup)blocksToCreate=[[NSMutableArray alloc]init];
    if(isNegativeProblem)
    {
        currentBlockValues=[[NSMutableArray alloc]init];
        blockLabels=[[NSMutableArray alloc]init];
    }
}

#pragma mark - status messages
-(void)doWinning
{
    // this method creates shards and displays the complete message
//    CGPoint pos=ccp(cx,cy);
//    autoMoveToNextProblem=YES; 
//    [toolHost showProblemCompleteMessage];
//    [toolHost.Zubi createXPshards:20 fromLocation:pos];

    [toolHost doWinning];
}
-(void)doIncorrect
{
    if(evalMode==kProblemEvalOnCommit)
    {
    // this method shows the incomplete message and deselects all selected objects
//        [toolHost showProblemIncompleteMessage];
        [toolHost doIncomplete];
        [gw handleMessage:kDWdeselectAll andPayload:nil withLogLevel:-1];
    }
}

#pragma mark - calculation and evaluation
-(void)problemStateChanged
{
    // contained here are just actions that are run for different kinds of problems on a state change.
    // generally they are just to calculate before evaluation.
    
    totalObjectValue=0;
    
    // check the total object value over all the grids and keep a reference to it
    // c = column
    // i = row(?)
    // o = rope(?)
    for(int c=0; c<gw.Blackboard.AllStores.count; c++)
    {
        for (int i=0; i<[[gw.Blackboard.AllStores objectAtIndex:c]count]; i++)
        {
            for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:i]count]; o++)
            {
                DWPlaceValueNetGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:(i)] objectAtIndex:o];
                DWPlaceValueBlockGameObject *goO = (DWPlaceValueBlockGameObject*)goC.MountedObject;
                if(goO)
                {
                    float objectValue=goO.ObjectValue;
                    totalObjectValue = totalObjectValue+objectValue;
                }   
            }
        }
    }
    
    // define our solution type to check against
    
    if([solutionType isEqualToString:COUNT_SEQUENCE])
    {
        
        [self calcProblemCountSequence];
        
        DLog(@"(COUNT_SEQUENCE) Selected %d lastCount %d", gw.Blackboard.SelectedObjects.count, lastCount);
        
    }
    
    else if([solutionType isEqualToString:TOTAL_COUNT])
    {
        [self calcProblemTotalCount];
        if((totalCount>maxSumReachedByUser) && !gw.Blackboard.inProblemSetup)
        {
            if (maxSumReachedByUser<=expectedCount)[toolHost.Zubi createXPshards:20 fromLocation:ccp(cx,cy)];
            maxSumReachedByUser=totalCount;
        }
        
    }
    
    else if([solutionType isEqualToString:TOTAL_COUNT_AND_COUNT_SEQUENCE])
    {
        [self calcProblemCountSequence];
        [self calcProblemTotalCount];
    }
    

    
    if(evalMode == kProblemEvalAuto)
    {
        [self evalProblem];
        //[self isProblemComplete];

    }
}

-(void)evalProblem
{
    [self isProblemComplete];
    
    if(isProblemComplete)
        [self doWinning];
    else
        [self doIncorrect];
    
    
}

-(void)isProblemComplete
{
    if([solutionType isEqualToString:COUNT_SEQUENCE]){
        isProblemComplete=[self evalProblemCountSeq];
    }
    else if([solutionType isEqualToString:TOTAL_COUNT]){
        isProblemComplete=[self evalProblemTotalCount];
    }    
    
    else if([solutionType isEqualToString:TOTAL_COUNT_AND_COUNT_SEQUENCE]) {
        BOOL seqIsOk = [self evalProblemCountSeq];
        BOOL countIsOk = [self evalProblemTotalCount];
        
        if(seqIsOk && countIsOk)
            isProblemComplete=YES;
    }
    else if([solutionType isEqualToString:MATRIX_MATCH]){
        isProblemComplete=[self evalProblemMatrixMatch];
    }  
}

-(BOOL)evalProblemCountSeq
{
//    if([problemType isEqualToString:COUNT_SEQUENCE])
//    {
        if(gw.Blackboard.SelectedObjects.count == [[solutionsDef objectForKey:SOLUTION_VALUE] intValue])
        {
            return YES;
        }
        else if(gw.Blackboard.SelectedObjects.count != [[solutionsDef objectForKey:SOLUTION_VALUE] intValue] && evalMode==kProblemEvalOnCommit)
        {
            return NO;
        }
//    }
    
//    if([problemType isEqualToString:TOTAL_COUNT_AND_COUNT_SEQUENCE])
//    {
//        if(gw.Blackboard.SelectedObjects.count == [[solutionsDef objectForKey:SOLUTION_VALUE] intValue])
//            return YES;
//
//        else if(gw.Blackboard.SelectedObjects.count != [[solutionsDef objectForKey:SOLUTION_VALUE] intValue] && evalMode==kProblemEvalOnCommit)
//            return NO;
//
//    }
    // if we get to the end we've not met all our conditions anywya so return no
    return NO;
}
-(void)calcProblemCountSequence
{
    if(gw.Blackboard.SelectedObjects.count > totalCountedInProblem)
    {
        totalCountedInProblem=gw.Blackboard.SelectedObjects.count;
        if(!(totalCountedInProblem > [[solutionsDef objectForKey:SOLUTION_VALUE] intValue]) && !gw.Blackboard.inProblemSetup)
            [toolHost.Zubi createXPshards:20 fromLocation:ccp(cx,cy)];
    }
    
    lastCount = gw.Blackboard.SelectedObjects.count;

}
-(void)calcProblemTotalCount
{
    totalCount=0;
    
    if(showColumnTotalCount)
    {
        for(int i=0;i<numberOfColumns;i++)
        {
            float v=[[[columnInfo objectAtIndex:i] objectForKey:COL_VALUE] floatValue];
            CCSprite *s=[totalCountSprites objectAtIndex:i];
            CCLabelTTF *l=[s.children objectAtIndex:0];
            
            [l setString:[NSString stringWithFormat:@"%g", [self usedSpacesOnGrid:i]*v]];
        }
        
    }
    
    if(showColumnUserCount){
        int lastNumber=[[userAddedBlocksLastCount objectAtIndex:currentColumnIndex]intValue];
        int thisNumber=[[userAddedBlocks objectAtIndex:currentColumnIndex]count];
        float fval=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE] floatValue];
        
        if(thisNumber>lastNumber)
        {
            //CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%g", thisNumber*fval] fontName:CHANGO fontSize:150.0f];
            CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%g", fval] fontName:CHANGO fontSize:150.0f];
            [l setPosition:ccp(currentColumnIndex*(kPropXColumnSpacing*lx), (ly*kPropYColumnOrigin)-(([[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex]count]/2)*(lx*kPropXNetSpace)))];
            [l setColor:ccc3(234,137,31)];
            [renderLayer addChild:l z:10000];
            [l runAction:[CCFadeOut actionWithDuration:1.0]];
        }
        else if(thisNumber<lastNumber)
        {
            CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"-%g", fval] fontName:CHANGO fontSize:150.0f];
            [l setPosition:ccp(currentColumnIndex*(kPropXColumnSpacing*lx), (ly*kPropYColumnOrigin)-(([[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex]count]/2)*(lx*kPropXNetSpace)))];
            [l setColor:ccc3(234,137,31)];
            [renderLayer addChild:l z:10000];
            [l runAction:[CCFadeOut actionWithDuration:1.0]];
        }
        
        [userAddedBlocksLastCount replaceObjectAtIndex:currentColumnIndex withObject:[NSNumber numberWithInt:thisNumber]];
        
    }
    
    
    for(int c=0; c<gw.Blackboard.AllStores.count; c++)
    {
        for (int i=0; i<[[gw.Blackboard.AllStores objectAtIndex:c]count]; i++)
        {
            for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:i]count]; o++)
            {
                DWPlaceValueNetGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:(i)] objectAtIndex:o];
                DWPlaceValueBlockGameObject *goO = (DWPlaceValueBlockGameObject*)goC.MountedObject;
                if(goO)
                {
                    float objectValue=goO.ObjectValue;
                    
                    totalCount = totalCount+objectValue;
                    lastTotalCount=totalCount;
                }   
            }
        }
    }
}
-(BOOL)evalProblemTotalCount
{
    [self calcProblemTotalCount];
//    if([problemType isEqualToString:TOTAL_COUNT])
//    {
    
    if(debugLogging)
        NSLog(@"total count %g, expected count %g", totalCount, expectedCount);
    
    NSString *totCount=[NSString stringWithFormat:@"%g", totalCount];
    NSString *expCount=[NSString stringWithFormat:@"%g", expectedCount];
    
    if([totCount isEqualToString:expCount] && !gw.Blackboard.inProblemSetup)
    {
        return YES;
    }
    else if(![totCount isEqualToString:expCount] && evalMode==kProblemEvalOnCommit)
    {
        return NO;
    }
    else {
        return NO;
    }
    
    
//    if(totalCount == expectedCount && !gw.Blackboard.inProblemSetup)
//    {
//        return YES;
//    }
//    else if(totalCount != expectedCount && evalMode==kProblemEvalOnCommit)
//    {
//        return NO;
//    }
//    else {
//        return NO;
//    }
    
//    }

}

-(BOOL)evalProblemMatrixMatch
{
    float solutionsFound = 0;
    int thisCol = 0;
    BOOL canEval=NO;
    NSArray *solutionMatrix = [solutionsDef objectForKey:SOLUTION_MATRIX];
    
    // for each column
    for(int c=0; c<gw.Blackboard.AllStores.count; c++)
    {
        thisCol=c;
        int countAtRow[[[gw.Blackboard.AllStores objectAtIndex:c]count]];
        
        
        // create a count at row for each column
        for (int car=0; car<[[gw.Blackboard.AllStores objectAtIndex:c]count]; car++)
        {
            countAtRow[car] = 0;
        }
        
        // look through each column
        for (int i=0; i<[[gw.Blackboard.AllStores objectAtIndex:c]count]; i++)
        {
            // and check each row
            for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:i]count]; o++)
            {
                DWPlaceValueNetGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:(i)] objectAtIndex:o];
                

                if(goC.MountedObject)
                    countAtRow[i] ++;
                   
            }
        }
        
        for(int o=0; o<solutionMatrix.count; o++)
        {
            NSDictionary *solDict = [solutionMatrix objectAtIndex:o];
            int curRow = [[solDict objectForKey:PUT_IN_ROW] intValue];
            
            if(countAtRow[curRow] == [[solDict objectForKey:NUMBER] intValue] && thisCol== [[solDict objectForKey:PUT_IN_COL]intValue])
                solutionsFound++;
            

                // Attach XP/partial progress here
                //[toolHost.Zubi createXPshards:20 fromLocation:pos];
        
            // TODO: this is where an else would go for partial failure
            
            canEval=YES;
            
        }
    }
    
    if(solutionsFound == solutionMatrix.count && canEval)
        return YES;

    else if(solutionsFound != solutionMatrix.count && evalMode==kProblemEvalOnCommit && canEval)
        return NO;
    else 
        return NO;

    
}

-(int)freeSpacesOnGrid:(int)thisGrid
{
    int freeSpace=0;
    
    for (int r=[[gw.Blackboard.AllStores objectAtIndex:thisGrid] count]-1; r>=0; r--) {
        NSMutableArray *row=[[gw.Blackboard.AllStores objectAtIndex:thisGrid] objectAtIndex:r];
        for (int c=[row count]-1; c>=0; c--)
        {
            DWPlaceValueNetGameObject *co=[row objectAtIndex:c];
            if(!co.MountedObject && !explodeMode)
            {
                freeSpace++;
            }
            else if(co.MountedObject && !co.CancellingObject && explodeMode)
            {
                freeSpace++;
            }
        }
    }
    return freeSpace;
}

-(int)usedSpacesOnGrid:(int)thisGrid
{
    int usedSpace=0;
    
    for (int r=[[gw.Blackboard.AllStores objectAtIndex:thisGrid] count]-1; r>=0; r--) {
        NSMutableArray *row=[[gw.Blackboard.AllStores objectAtIndex:thisGrid] objectAtIndex:r];
        for (int c=[row count]-1; c>=0; c--)
        {
            DWPlaceValueNetGameObject *co=[row objectAtIndex:c];
            if(co.MountedObject)
            {
                usedSpace++;
            }
        }
    }
    return usedSpace;
}

-(void)selectBaseObjectsOnGrid:(int)thisGrid
{
    if(!autoBaseSelection)return;
    
    //deselect anything currently selected
    
    
    for (DWPlaceValueBlockGameObject *block in [NSArray arrayWithArray:gw.Blackboard.SelectedObjects]) {
        
        float colVal=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE] floatValue];
        if(colVal==block.ObjectValue) return;
        
//        [block handleMessage:kDWdeselectMe];
        
        [gw.Blackboard.SelectedObjects removeObject:block];
    }
    
    
    
    
//    NSMutableArray *SelectedObjects=gw.Blackboard.SelectedObjects;
//    if([SelectedObjects count]>0){
//        
//        DWPlaceValueBlockGameObject *thisB=[SelectedObjects objectAtIndex:0];
//        float colVal=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE] floatValue];
//        if(thisB.ObjectValue==colVal)return;
//        
//        for(int i=0;i<[SelectedObjects count];i++)
//        {
//            DWPlaceValueBlockGameObject *b=[SelectedObjects objectAtIndex:i];
//            b.Selected=YES;
//            [b handleMessage:kDWswitchSelection];
//            //if([SelectedObjects count]==10)[b handleMessage:kDWswitchBaseSelectionBack];
//        }
//        [gw.Blackboard.SelectedObjects removeAllObjects];
//    }
    
    
    
    for (int r=[[gw.Blackboard.AllStores objectAtIndex:thisGrid] count]-1; r>=0; r--) {
        NSMutableArray *row=[[gw.Blackboard.AllStores objectAtIndex:thisGrid] objectAtIndex:r];
        for (int c=[row count]-1; c>=0; c--)
        {
            DWPlaceValueNetGameObject *co=[row objectAtIndex:c];
            if(co.MountedObject)
            {
                //[co.MountedObject handleMessage:kDWselectMe];
                
                //[pickupObjects addObject:co.MountedObject];
                
                if(![gw.Blackboard.SelectedObjects containsObject:co.MountedObject])
                {
                    [gw.Blackboard.SelectedObjects addObject:co.MountedObject];
                }
            }
        }
    }
    
    if([gw.Blackboard.SelectedObjects count]==10)
        isBasePickup=YES;

}

-(void)logOutGameObjectsPositions:(int)thisGrid
{
 
    int goNumber=0;
    
    for(DWGameObject *go in gw.AllGameObjects)
    {
        if([go isKindOfClass:[DWPlaceValueBlockGameObject class]])
        {
            DWPlaceValueBlockGameObject *block=(DWPlaceValueBlockGameObject*)go;
            if([block.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
            {
                DWPlaceValueNetGameObject *net=(DWPlaceValueNetGameObject*)block.Mount;

                if(net.myCol==thisGrid)
                {
                    NSLog(@"(%d-%d) block mounted at x %d y %d", thisLog, goNumber, net.myRow, net.myRope);
                    
                    goNumber++;
                }
            }
            
        }
         
    }
    thisLog++;
    
}

#pragma mark - environment interaction
-(void)checkForMultipleControlTouchesAt:(CGPoint)thisLocation
{
    for(int i=0;i<[multiplePlusSprites count];i++)
    {
        CGRect boundingBox=[[multiplePlusSprites objectAtIndex:i]CGRectValue];
        //CCSprite *s=[multiplePlusSprites objectAtIndex:i];
        if(CGRectContainsPoint(boundingBox, [renderLayer convertToNodeSpace:thisLocation]))
        {
            
            DWPlaceValueCageGameObject *c=[allCages objectAtIndex:i];
            
            int curNum=[[blocksToCreate objectAtIndex:i]intValue];
            curNum++;
            
            if(curNum>=10)
            {
                curNum=10;
                [c.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage_variable_down_only.png")]];
            }
            else
            {
                [c.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage-variable.png")]];                
            }
            
            [loggingService logEvent:BL_PA_PV_TOUCH_END_BLOCKSTOCREATE_UP withAdditionalData:[NSNumber numberWithInt:curNum]];
            
            [blocksToCreate replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:curNum]];
            
            changedBlockCountOrValue=YES;
            
            return;
        }
    }
    
    for(int i=0;i<[multipleMinusSprites count];i++)
    {
        CGRect boundingBox=[[multipleMinusSprites objectAtIndex:i]CGRectValue];
        //CCSprite *s=[multipleMinusSprites objectAtIndex:i];
        if(CGRectContainsPoint(boundingBox, [renderLayer convertToNodeSpace:thisLocation]))
        {
            DWPlaceValueCageGameObject *c=[allCages objectAtIndex:i];
            int curNum=[[blocksToCreate objectAtIndex:i]intValue];
            curNum--;
            if(curNum<=1)
            {
                curNum=1;
                [c.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage_variable_up_only.png")]];
            }
            else
            {
                [c.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage-variable.png")]];
            }
            
            [loggingService logEvent:BL_PA_PV_TOUCH_END_BLOCKSTOCREATE_DOWN withAdditionalData:[NSNumber numberWithInt:curNum]];
            [blocksToCreate replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:curNum]];
            
            changedBlockCountOrValue=YES;
            
            return;
        }
    }
    
}

-(void)checkForBlockValueTouchesAt:(CGPoint)thisLocation
{
    for(int i=0;i<[multiplePlusSprites count];i++)
    {
        CGRect boundingBox=[[multiplePlusSprites objectAtIndex:i]CGRectValue];
        //CCSprite *s=[multiplePlusSprites objectAtIndex:i];
        if(CGRectContainsPoint(boundingBox, [renderLayer convertToNodeSpace:thisLocation]))
        {
            DWPlaceValueCageGameObject *cge=[allCages objectAtIndex:i];
            [cge.MountedObject handleMessage:kDWdestroy];
            
            int curNum=[[currentBlockValues objectAtIndex:i]intValue];
            float colVal=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE]floatValue];
            curNum+=1*colVal;
            if(curNum>10*colVal)
                curNum=10*colVal;
            
            if(curNum>0)
                cge.ObjectValue=colVal;
            else if(curNum==0)
                cge.ObjectValue=0;
            else
                cge.ObjectValue=-colVal;
            
            [cge handleMessage:kDWsetupStuff];
            
            //TODO: Change this logging event
            [loggingService logEvent:BL_PA_PV_TOUCH_END_BLOCKSTOCREATE_UP withAdditionalData:[NSNumber numberWithInt:curNum]];
            
            [currentBlockValues replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:curNum]];
            
            changedBlockCountOrValue=YES;
            
            return;
        }
    }
    
    for(int i=0;i<[multipleMinusSprites count];i++)
    {
        CGRect boundingBox=[[multipleMinusSprites objectAtIndex:i]CGRectValue];
        //CCSprite *s=[multipleMinusSprites objectAtIndex:i];
        if(CGRectContainsPoint(boundingBox, [renderLayer convertToNodeSpace:thisLocation]))
        {
            DWPlaceValueCageGameObject *cge=[allCages objectAtIndex:i];
            [cge.MountedObject handleMessage:kDWdestroy];
            
            int curNum=[[currentBlockValues objectAtIndex:i]intValue];
            float colVal=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE]floatValue];
            curNum-=1*colVal;
            if(curNum<-10*colVal)
                curNum=-10*colVal;
            
            
            if(curNum>0)
                cge.ObjectValue=colVal;
            else if(curNum==0)
                cge.ObjectValue=0;
            else
                cge.ObjectValue=-colVal;
            
            [cge handleMessage:kDWsetupStuff];
            
            [loggingService logEvent:BL_PA_PV_TOUCH_END_BLOCKSTOCREATE_DOWN withAdditionalData:[NSNumber numberWithInt:curNum]];
            [currentBlockValues replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:curNum]];
            
            changedBlockCountOrValue=YES;
            
            return;
        }
    }
    
}

-(void)checkAndChangeCageSpritesForMultiple
{
    
    for(int i=0;i<[allCages count];i++)
    {
        if(![[allCages objectAtIndex:i] isKindOfClass:[NSNull class]])
        {
            DWPlaceValueCageGameObject *cge=[allCages objectAtIndex:i];
            
            int curNum=[[blocksToCreate objectAtIndex:i]intValue];
            
            if(curNum==10)
                [cge.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage_variable_down_only.png")]];
            else if(curNum==1)
                [cge.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage_variable_up_only.png")]];
            else
                [cge.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage-variable.png")]];
        }
    }
    
}

-(void)checkAndChangeCageSpritesForNegative
{
    
    for(int i=0;i<[allCages count];i++)
    {
        if(![[allCages objectAtIndex:i] isKindOfClass:[NSNull class]])
        {
            DWPlaceValueCageGameObject *cge=[allCages objectAtIndex:i];
            
            int curNum=[[currentBlockValues objectAtIndex:i]intValue];
            float colVal=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE]floatValue];
            
            if(curNum==10*colVal)
                [cge.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage_variable_down_only.png")]];
            else if(curNum==-10*colVal)
                [cge.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage_variable_up_only.png")]];
            else
                [cge.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/placevalue/cage-variable.png")]];
        }
    }
    
    
    
}


-(void)switchSpritesBack
{
    if(!pickupSprite)return;
    
    for(DWGameObject *go in gw.AllGameObjects)
    {
        if([go isKindOfClass:[DWPlaceValueBlockGameObject class]])
        {
            DWPlaceValueBlockGameObject *b=(DWPlaceValueBlockGameObject*)go;
            
            CCSprite *mySprite=b.mySprite;
            [mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(((DWPlaceValueBlockGameObject*)go).SpriteFilename)]];
        }
    }
}

-(void)snapLayerToPosition
{
    // code for changing the layer position to the current column
    float layerPositionX = (cx-(currentColumnIndex*(kPropXColumnSpacing*lx)));
    CCMoveTo *moveLayer = [CCMoveTo actionWithDuration:kLayerSnapAnimationTime position:ccp(layerPositionX, 0)];
    CCEaseIn *moveLayerGently = [CCEaseIn actionWithAction:moveLayer rate:kLayerSnapAnimationTime];
    [renderLayer runAction:moveLayerGently]; 
}

-(void)checkMountPositionsForBlocks
{
    if(!touching) {
        for(DWGameObject *go in gw.AllGameObjects)
        {
            if([go isKindOfClass:[DWPlaceValueBlockGameObject class]])
            {
                DWPlaceValueBlockGameObject *block=(DWPlaceValueBlockGameObject*)go;
                if([block.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
                {
                    DWPlaceValueNetGameObject *net=(DWPlaceValueNetGameObject*)block.Mount;
                    if(!net.MountedObject)
                    {
                        net.MountedObject=block;
                        block.AnimateMe=NO;
                        [block handleMessage:kDWresetToMountPosition];
                    }
                }
                
            }
            if([go isKindOfClass:[DWPlaceValueNetGameObject class]])
            {
                DWPlaceValueNetGameObject *net=(DWPlaceValueNetGameObject*)go;
                if(net.MountedObject)
                {
                    DWPlaceValueBlockGameObject *block=(DWPlaceValueBlockGameObject*)net.MountedObject;
                    if(!block.Mount)
                    {
                    block.Mount=net;
                    block.AnimateMe=NO;
                    [block handleMessage:kDWresetToMountPosition];
                    }
                }
                
            }

        }
    }
}

-(BOOL)doTransitionWithIncrement:(int)incr
{
    BOOL isNegativeNumber=NO;
    int tranCount=1;
    if(incr>0) tranCount=10;
    currentColumnIndex+=incr;
    int space=[self freeSpacesOnGrid:currentColumnIndex];

    if(debugLogging)
        NSLog(@"incr: %d trancount %d", incr, tranCount);
    
    
    // bail if not possible
    if(space<tranCount) return NO;
    
    DWPlaceValueBlockGameObject *cGO=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
    

    if(cGO.ObjectValue<0)
    {
        isNegativeNumber=YES;
    }
    
    if (incr>0) {
        [gw.Blackboard.PickupObject handleMessage:kDWdismantle andPayload:nil withLogLevel:0];
        [gw delayRemoveGameObject:gw.Blackboard.PickupObject];
        gw.Blackboard.PickupObject=nil;
    }
    else
    {
        for (int i=0; i<[gw.Blackboard.SelectedObjects count]; i++) {
            [[gw.Blackboard.SelectedObjects objectAtIndex:i] handleMessage:kDWdismantle andPayload:nil withLogLevel:0];
            [gw delayRemoveGameObject:[gw.Blackboard.SelectedObjects objectAtIndex:i]];
        }
        [gw.Blackboard.SelectedObjects removeAllObjects];
        
    }

    gw.Blackboard.CurrentStore=[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex];
    
    //[self snapLayerToPosition];
        
    for (int itran=0; itran<tranCount; itran++) {
        
        NSNumber *currentColumnValueKey;
        //create a new object
        if(!isNegativeNumber)
        {
           currentColumnValueKey=[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE];
        }
        else
        {
            
            float fval=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE] floatValue];
            fval = -fval;
            currentColumnValueKey=[NSNumber numberWithFloat:fval];
        }
        
        DWPlaceValueBlockGameObject *go=[DWPlaceValueBlockGameObject alloc];
        [gw populateAndAddGameObject:go withTemplateName:@"TplaceValueObject"];
        
        CGPoint locationToAnimateFrom=[renderLayer convertToNodeSpace:gw.Blackboard.TestTouchLocation];
        
        go.PosX=locationToAnimateFrom.x;
        go.PosY=locationToAnimateFrom.y;
        
        //drop target

        go.ObjectValue=[currentColumnValueKey floatValue];
        
        NSString *currentColumnValueString = [NSString stringWithFormat:@"%g", [currentColumnValueKey floatValue]];
        
        if(debugLogging)
            NSLog(@"currentColumnValueKey %f, currentColumnIndex %d", [currentColumnValueKey floatValue], currentColumnIndex);
        
        if([columnSprites objectForKey:currentColumnValueString])
            go.SpriteFilename=[columnSprites objectForKey:currentColumnValueString];

        if(pickupSprite)
            go.PickupSprite=pickupSprite;
        
        [go handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        
        BOOL stop=NO;
        
        //find a mount for this object
//        for (int r=[gw.Blackboard.CurrentStore count]-1; r>=0; r--) {
//            if(stop)break;
//            
//            
//            NSMutableArray *row=[gw.Blackboard.CurrentStore objectAtIndex:r];
//            for (int c=[row count]-1; c>=0; c--)
//            {
//                if(stop)break;
//                
//                DWPlaceValueNetGameObject *co=[row objectAtIndex:c];
//                
//                if(!co.MountedObject)
//                {
//                    //use this as a mount
//                    NSLog(@"set mount colindex %d to row %d col %d", currentColumnIndex, r,c);
//                    go.Mount=co;
//                    go.AnimateMe=YES;
//                    co.MountedObject=go;
//                    go.PosX=co.PosX;
//                    go.PosY=co.PosY;
//                    //                    [go handleMessage:kDWsetMount];
//                    [co handleMessage:kDWsetMountedObject];
//                    [go handleMessage:kDWupdateSprite];
//                    stop=YES;
//                }
//            }
//        }

        for (int r=0; r<[gw.Blackboard.CurrentStore count]; r++) {
            if(stop)break;
            
            
            NSMutableArray *row=[gw.Blackboard.CurrentStore objectAtIndex:r];
            for (int c=0; c<[row count]; c++)
            {
                if(stop)break;
                
                DWPlaceValueNetGameObject *co=[row objectAtIndex:c];
                
                if(!co.MountedObject)
                {
                    //use this as a mount
                    if(debugLogging)
                        NSLog(@"set mount colindex %d to row %d col %d", currentColumnIndex, r,c);
                    go.Mount=co;
                    go.AnimateMe=YES;
                    co.MountedObject=go;
                    go.PosX=co.PosX;
                    go.PosY=co.PosY;
                    //                    [go handleMessage:kDWsetMount];
                    [co handleMessage:kDWsetMountedObject];
                    [go handleMessage:kDWupdateSprite];
                    stop=YES;
                }
            }
        }

        
        [go release];
    }
    return YES;
}

-(BOOL)doCondenseFromLocation:(CGPoint)location
{
    [loggingService logEvent:BL_PA_PV_TOUCH_END_CONDENSE_OBJECT withAdditionalData:nil];
    
    return [self doTransitionWithIncrement:-1];
}

-(BOOL)doMulchFromLocation:(CGPoint)location
{
    [loggingService logEvent:BL_PA_PV_TOUCH_END_MULCH_OBJECTS withAdditionalData:nil];
    justMulched=[self doTransitionWithIncrement:1];
    return justMulched;
}

-(void)setGridOpacity:(GLbyte)toThisOpacity
{
    [self setGridOpacity:currentColumnIndex toOpacity:toThisOpacity];
}

-(void)setGridOpacity:(int)thisGrid toOpacity:(GLbyte)toThisOpacity
{
    for (int i=0; i<[[gw.Blackboard.AllStores objectAtIndex:thisGrid]count]; i++)
    {
        for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:thisGrid] objectAtIndex:i]count]; o++)
        {
            
            DWPlaceValueBlockGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:thisGrid] objectAtIndex:(i)] objectAtIndex:o];
            CCSprite *mySprite=goC.mySprite;
            [mySprite setOpacity:toThisOpacity];
        }
    }
    
}

-(void)flipToBaseSelection
{
    // switch colour if the base value is selected
    if(isBasePickup && showBaseSelection)
    {
        for(int go=0; go<gw.Blackboard.SelectedObjects.count; go++)
        {
            DWGameObject *goO = [[[gw Blackboard] SelectedObjects] objectAtIndex:go];
            
            [goO handleMessage:kDWswitchBaseSelection andPayload:nil withLogLevel:0];
        }
        
    }
    // or switch back if it's not
    else
    {
        for(int go=0; go<gw.Blackboard.SelectedObjects.count; go++)
        {
            DWGameObject *goO = [[[gw Blackboard] SelectedObjects] objectAtIndex:go];
            [goO handleMessage:kDWswitchBaseSelectionBack andPayload:nil withLogLevel:0];
        }
    }
}

-(void)tintGridColour:(ccColor3B)toThisColour
{
    [self tintGridColour:currentColumnIndex toColour:toThisColour];
}

-(void)tintGridColour:(int)thisGrid toColour:(ccColor3B)toThisColour
{
    for (int i=0; i<[[gw.Blackboard.AllStores objectAtIndex:thisGrid]count]; i++)
    {
        for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:thisGrid] objectAtIndex:i]count]; o++)
        {

            DWPlaceValueBlockGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:thisGrid] objectAtIndex:(i)] objectAtIndex:o];
            CCSprite *mySprite=goC.mySprite;
            [mySprite setColor:toThisColour]; 
        }
    }
}

-(void)resetPickupObjectPos
{
    if(isBasePickup)
    {
        for(int goC=0; goC<gw.Blackboard.SelectedObjects.count; goC++)
        {
            DWGameObject *go = [gw.Blackboard.SelectedObjects objectAtIndex:goC];
            [go handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:0];
        }
    }
    [[gw Blackboard].PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:0];    
}

-(void)resetObjectStates
{
    if(thisCageWontTakeMe)
    {
        
        DWPlaceValueCageGameObject *c=nil;
        DWPlaceValueBlockGameObject *cM=nil;
        if([[allCages objectAtIndex:currentColumnIndex]isKindOfClass:[DWPlaceValueCageGameObject class]])
            c=[allCages objectAtIndex:currentColumnIndex];
        
        if(c.MountedObject)
            cM=(DWPlaceValueBlockGameObject*)c.MountedObject;
        
        [c.mySprite stopAllActions];
        [cM.mySprite stopAllActions];
        
        [c.mySprite setPosition:ccp(c.PosX, c.PosY)];
        [cM.mySprite setPosition:ccp(c.PosX, c.PosY+20)];
        
        [c.mySprite setOpacity:255];
        [cM.mySprite setOpacity:255];

//        [c.mySprite runAction:[CCFadeOut actionWithDuration:0.5f]];
//        [cM.mySprite runAction:[CCFadeOut actionWithDuration:0.5f]];
        
    }
    // switch all opacities back to default
    for(int i=0;i<numberOfColumns;i++)
    {
        
        [self setGridOpacity:i toOpacity:127];
    }
    
}

-(BOOL)resetObjectPositions
{
    BOOL finished=NO;
    
//    for(int i=0;i<[allCages count];i++)
//    {
//        DWPlaceValueCageGameObject *c=[allCages objectAtIndex:i];
//        
//        CGPoint cagePos=ccp(c.PosX, c.PosY);
//        if(!CGPointEqualToPoint(cagePos, c.mySprite.position))
//        {
//            [c.mySprite setPosition:cagePos];
//            [c.mySprite setOpacity:255];
//            
//            if(c.MountedObject)
//            {
//                DWPlaceValueBlockGameObject *cM=(DWPlaceValueBlockGameObject*)c.MountedObject;
//                [cM.mySprite setPosition:ccp(c.PosX,c.PosY+20)];
//                [cM.mySprite setOpacity:255];
//            }
//            
//            finished=YES;
//        }
//    }
    
    for(int i=0;i<[blockLabels count];i++)
    {
        CCLabelTTF *l=[blockLabels objectAtIndex:i];
        DWPlaceValueCageGameObject *c=[allCages objectAtIndex:i];
        
        CGPoint cagePos=ccp(c.PosX, c.PosY+20);
        if(!CGPointEqualToPoint(cagePos, l.position) && [l numberOfRunningActions]==0)
        {
            [l setPosition:cagePos];
            finished=YES;
        }
    }
    for(int i=0;i<[multipleLabels count];i++)
    {
        CCLabelTTF *l=[blockLabels objectAtIndex:i];
        DWPlaceValueCageGameObject *c=nil;
        
        if([[allCages objectAtIndex:i]isKindOfClass:[DWPlaceValueCageGameObject class]])
            c=[allCages objectAtIndex:i];
        
        
        CGPoint cagePos=ccp(c.PosX, c.PosY+20);
        if(!CGPointEqualToPoint(cagePos, l.position) && [l numberOfRunningActions]==0)
        {
            [l setPosition:cagePos];
            finished=YES;
        }
    }
    
    for(int i=0;i<[gw.AllGameObjects count];i++)
    {
        if([[gw.AllGameObjects objectAtIndex:i] isKindOfClass:[DWPlaceValueBlockGameObject class]])
        {
            DWPlaceValueBlockGameObject *b=[gw.AllGameObjects objectAtIndex:i];
            
            CGPoint reqPos=ccp(b.PosX,b.PosY);
            
            if(!CGPointEqualToPoint(reqPos, b.mySprite.position) && [b.mySprite numberOfRunningActions]==0)
            {
                [b.mySprite setPosition:reqPos];
                finished=YES;
            }
        }
    }
    return finished;
}

-(void)createCondenseAndMulchBoxes
{
    // create the 2 bounding boxes for condensing and mulching on a touchbegan - these are the amalgamation of all of the net sprites for column +/-1
    
    boundingBoxCondense=CGRectNull;
    if(currentColumnIndex>0)
    {
        
        for(int i=0;i<[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex-1]count];i++)
        {
            for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex-1] objectAtIndex:i]count]; o++)
            {
                DWPlaceValueBlockGameObject *go=[[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex-1] objectAtIndex:i]objectAtIndex:o];
                CCSprite *mySprite = go.mySprite;
                boundingBoxCondense=CGRectUnion(boundingBoxCondense, mySprite.boundingBox);
            }
        }
        
    }
    
    boundingBoxMulch=CGRectNull;
    if(currentColumnIndex<numberOfColumns-1)
    {
        for(int i=0;i<[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex+1]count];i++)
        {
            for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex+1] objectAtIndex:i]count]; o++)
            {
                DWPlaceValueNetGameObject *go=[[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex+1] objectAtIndex:i]objectAtIndex:o];
                CCSprite *mySprite = go.mySprite;
                boundingBoxMulch=CGRectUnion(boundingBoxMulch, mySprite.boundingBox);
            }
        }
    }
}

#pragma mark - meta question alignment
-(float)metaQuestionTitleYLocation
{
    return kLabelTitleYOffsetHalfProp*cy;
}

-(float)metaQuestionAnswersYLocation
{
    return kMetaQuestionYOffsetPlaceValue*cy;
}

#pragma mark - touches events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    potentialTap=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    timeSinceInteractionOrShake=0.0f;
    
    // set the touch start pos for evaluation
    touchStartPos = location;
    gw.Blackboard.TestTouchLocation=location;
    float baseSelectionColumnValue=0;
    DWPlaceValueBlockGameObject *firstSelectedObject=nil;
    
    // if we have controls showing - check for touches upon them using an alternate method
    if(multipleBlockPickup||showMultipleControls)
        [self checkForMultipleControlTouchesAt:location];
    
    if(isNegativeProblem)
        [self checkForBlockValueTouchesAt:location];
    
    if(changedBlockCountOrValue)return;
    
    [gw Blackboard].PickupObject=nil;
    
    if(debugLogging)
        NSLog(@"THIS TOUCH BEGAN CONSISTS (%d touches)", [touches count]);
    
        
    //the touch location in the node space of the render layer
    CGPoint locationInNS=[renderLayer convertToNodeSpace:location];
    
    //width of a column
    float colW=lx*kPropXColumnSpacing;
    
    //offset the touch location by half the column width to allow for hitting a column in -0.5x -- +0.5x space
    CGPoint shiftedLocationInNS=ccp(locationInNS.x + (0.5f * colW), locationInNS.y);
    
    //rounded down value of touch location over col width gives us column index (e.g. anything from 0 to colw is first col (0), next is second (1) etc)
    int lastColumnIndex=currentColumnIndex;
    currentColumnIndex = (int)(shiftedLocationInNS.x / colW);
    if(currentColumnIndex>numberOfColumns-1)currentColumnIndex=numberOfColumns-1;
    if(currentColumnIndex<0)currentColumnIndex=0;
    
    if(lastColumnIndex!=currentColumnIndex)
    {
        for (DWPlaceValueBlockGameObject *block in [NSArray arrayWithArray:gw.Blackboard.SelectedObjects]) {
            [block handleMessage:kDWswitchBaseSelectionBack];
            [gw.Blackboard.SelectedObjects removeObject:block];
        }
        
        int objectsOnGrid=[self usedSpacesOnGrid:currentColumnIndex];
        
        if(objectsOnGrid==columnBaseValue && currentColumnIndex!=0)
        {
            isBasePickup=YES;
            //        [gw.Blackboard.SelectedObjects removeAllObjects];
            [self selectBaseObjectsOnGrid:currentColumnIndex];
        }

    }
    
    if(isBasePickup && [gw.Blackboard.SelectedObjects count]>0)
    {
        firstSelectedObject=[gw.Blackboard.SelectedObjects objectAtIndex:0];
        baseSelectionColumnValue=firstSelectedObject.ObjectValue;
    }
    
    if(debugLogging)
        NSLog(@"currentColIndex: %d, colW %f, locationInNS X %f, shiftedLocationInNS X %f", currentColumnIndex, colW, locationInNS.x, shiftedLocationInNS.x);
    
    if(debugLogging)
        NSLog(@"(touchbegan) free spaces on grid %d", [self freeSpacesOnGrid:currentColumnIndex]);
    
    // create our bounding boxes for condensing and mulching
    [self createCondenseAndMulchBoxes];

    
    [toolHost.Zubi setMode:kDaemonModeFollowing];
    [toolHost.Zubi setTarget:location];    
    
    // check for a reset button and touch on it
    if (CGRectContainsPoint(kRectButtonReset, location) && showReset)
        [toolHost resetProblem];
    
    gw.Blackboard.CurrentColumnValue=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE]floatValue];
    
    
    //broadcast search for pickup object gw§
    [gw handleMessage:kDWareYouAPickupTarget andPayload:nil withLogLevel:-1];
    
    // then if we get a response, do stuff
    if([gw Blackboard].PickupObject!=nil)
    {
        BOOL isCage;
        DWPlaceValueBlockGameObject *pickupObject=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
        DWPlaceValueNetGameObject *netMount=nil;
        
        // will the cage here accept the pickup block to be dropped on it?
        if([[allCages objectAtIndex:currentColumnIndex] isKindOfClass:[DWPlaceValueCageGameObject class]])
        {
            DWPlaceValueCageGameObject *c=[allCages objectAtIndex:currentColumnIndex];
            if(c.DisableDel && pickupObject.ObjectValue>0 && pickupObject.Mount!=c)
                thisCageWontTakeMe=YES;
            if(c.DisableDelNeg && pickupObject.ObjectValue<0 && pickupObject.Mount!=c)
                thisCageWontTakeMe=YES;
        }
        
        // bring our pickupobject to the front so it doesn't disappear when we drag it around
        pickupObject.lastZIndex=pickupObject.mySprite.zOrder;
        [pickupObject.mySprite setZOrder:10000];
        
        // check if the object we've picked up is off a cage or not
        if([pickupObject.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])isCage=YES;
        else isCage=NO;
        

        // but if we have a base pickup - we need to loop over every object that we have selected
        
        if(isBasePickup && !hasMovedBasePickup && baseSelectionColumnValue==gw.Blackboard.CurrentColumnValue && [gw.Blackboard.SelectedObjects containsObject:pickupObject])
        {
            for(DWPlaceValueBlockGameObject *b in gw.Blackboard.SelectedObjects)
            {
                if(b==pickupObject)
                {
                    b.LastMount=b.Mount;
                    continue;
                }
                DWPlaceValueNetGameObject *n=nil;
                if([b.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
                {
                    n=(DWPlaceValueNetGameObject*)b.Mount;
                    b.LastMount=b.Mount;
                    
                    n.MountedObject=nil;
                    n.CancellingObject=nil;
                }
            }
            return;
        }
        
        // if we have a pickupobject whose mount is a net or cage
        if([pickupObject.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
        {
            netMount=(DWPlaceValueNetGameObject*)pickupObject.Mount;
            netMount.MountedObject=nil;
            netMount.CancellingObject=nil;
            pickupObject.LastMount=pickupObject.Mount;
            
        }
        else if([pickupObject.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
        {
            [pickupObject.Mount handleMessage:kDWsetupStuff];
            pickupObject.LastMount=pickupObject.Mount;
        }
        
        // search for a new dropobject
        gw.Blackboard.DropObject=nil;
        [gw handleMessage:kDWareYouADropTarget andPayload:nil withLogLevel:-1];
        
        
        // if we're showing the multi-block controls on any column and we're picking up from the cage - and if we have more than one, loop through and create each block using the cage spawner - then add the new block to a pickupobjects array - but if we don't, add the single pickupobject
        if((multipleBlockPickup||showMultipleControls) && isCage)
        {
            int blocks=[[blocksToCreate objectAtIndex:currentColumnIndex] intValue];
            if(blocks>1)
            {
                DWPlaceValueBlockGameObject *pgo=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
                DWPlaceValueCageGameObject *cge=(DWPlaceValueCageGameObject*)pgo.Mount;
                
                for(int i=0;i<blocks;i++)
                {
                    if(i==0){
                        [pickupObjects addObject:pickupObject];
                        pickupObject.LastMount=pickupObject.Mount;
                    }
                    else{
                        [cge handleMessage:kDWsetupStuff];
                        [pickupObjects addObject:cge.MountedObject];
                        
                        DWPlaceValueBlockGameObject *newBlock=(DWPlaceValueBlockGameObject*)cge.MountedObject;
                        newBlock.LastMount=cge;
                        
                        //this is just a signal for the GO to us, pickup object is retained on the blackboard
                        [cge.MountedObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
                    }
                }
            }
            else
            {
                [pickupObjects addObject:pickupObject];
                [[gw Blackboard].PickupObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
            }
        }
        
        else if(isNegativeProblem && isCage)
        {
            int blocks=fabsf([[currentBlockValues objectAtIndex:currentColumnIndex] intValue]);
            if(blocks>1)
            {
                DWPlaceValueBlockGameObject *pgo=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
                DWPlaceValueCageGameObject *cge=(DWPlaceValueCageGameObject*)pgo.Mount;
                
                for(int i=0;i<blocks;i++)
                {
                    if(i==0){[pickupObjects addObject:pickupObject];}
                    else{
                        [cge handleMessage:kDWsetupStuff];
                        [pickupObjects addObject:cge.MountedObject];
                        
                        DWPlaceValueBlockGameObject *newBlock=(DWPlaceValueBlockGameObject*)cge.MountedObject;
                        newBlock.LastMount=cge;
                        
                        //this is just a signal for the GO to us, pickup object is retained on the blackboard
                        [cge.MountedObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
                        cge.MountedObject=nil;
                    }
                }
            }
            else
            {
                [pickupObjects addObject:pickupObject];
                [[gw Blackboard].PickupObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
            }
        }
        // if we're not - just add the pickupobject to the array
        else
        {
            [pickupObjects addObject:pickupObject];
            pickupObject.LastMount=pickupObject.Mount;
            [[gw Blackboard].PickupObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
        }
        
        // keep a ref to our current object's value
        float objValue=pickupObject.ObjectValue;
        
        // log whether the user hit a cage or grid item
        [loggingService logEvent:(isCage ? BL_PA_PV_TOUCH_BEGIN_PICKUP_CAGE_OBJECT : BL_PA_PV_TOUCH_BEGIN_PICKUP_GRID_OBJECT)
            withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:objValue] forKey:@"objValue"]];
        
        // nill the current pickupobject mount
        pickupObject.Mount=nil;
        
        gw.Blackboard.PickupOffset = location;
        // At this point we can still cancel the tap
        potentialTap = YES;
        
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
        
        [[gw Blackboard].PickupObject logInfo:@"this object was picked up" withData:0];
        
        if(debugLogging)
            NSLog(@"(touchbegan-end) free spaces on grid %d", [self freeSpacesOnGrid:currentColumnIndex]);
    }
    

    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[renderLayer convertToNodeSpace:location];
    CGPoint prevLoc = [touch previousLocationInView:[touch view]];
    prevLoc = [[CCDirector sharedDirector] convertToGL: prevLoc];
    prevLoc=[renderLayer convertToNodeSpace:prevLoc];
    
    [toolHost.Zubi setTarget:location];
    
    if(debugLogging)
        NSLog(@"THIS TOUCH MOVED CONSISTS (%d touches)", [touches count]);

    // if the distance is greater than the 'slipped tap' threshold, it's no longer a tap and is definitely moving
    if([BLMath DistanceBetween:[renderLayer convertToNodeSpace:touchStartPos] and:location] >= fabs(kTapSlipResetThreshold) && potentialTap)
    {
        touchStartPos = ccp(0, 0);
        touchEndPos = ccp(0, 0);
        potentialTap = NO;
    }
    
    // moving the layer
    else if(touching && ([gw Blackboard].PickupObject==nil) && numberOfColumns>1 && allowPanning && !CGRectContainsPoint(noDragAreaTop, location) && !CGRectContainsPoint(noDragAreaBottom, location))
    {
        hasMovedLayer=YES;
        CGPoint diff = ccpSub(location, prevLoc);
        diff = ccp(diff.x, 0);
        [renderLayer setPosition:ccpAdd(renderLayer.position, diff)];
    }
    
    // if we have a pickupobject, do stuff
    if([gw Blackboard].PickupObject!=nil)
    {
        DWPlaceValueBlockGameObject *block=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
        float distMoved=[BLMath DistanceBetween:touchStartPos and:[renderLayer convertToWorldSpace:location]];
        
        // if the block moves over the tap-slip - then change it's pickup sprite - if it has one
        if(block.PickupSprite && !gw.Blackboard.inProblemSetup && distMoved>kTapSlipThreshold)
        {
            CCSprite *mySprite=block.mySprite;
            [mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(block.PickupSprite)]];
        }
        
        // if the cage for this column won't accept this block, check the distance and fade as nesc
        if(thisCageWontTakeMe)
        {
            DWPlaceValueNetGameObject *n=[[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex] objectAtIndex:[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex]count]-1] objectAtIndex:0];
            
            DWPlaceValueCageGameObject *c=nil;
            DWPlaceValueBlockGameObject *cM=nil;
            if([[allCages objectAtIndex:currentColumnIndex]isKindOfClass:[DWPlaceValueCageGameObject class]])
                c=[allCages objectAtIndex:currentColumnIndex];
            
            if(c.MountedObject)
                cM=(DWPlaceValueBlockGameObject*)c.MountedObject;
            
            float distFromNetBottomToCage=[BLMath DistanceBetween:ccp(0, n.PosY) and:ccp(0, c.PosY)];
            float distFromBlockToCage=[BLMath DistanceBetween:location and:ccp(c.PosX, c.PosY)];
            
                

//            if(distFromBlockToCage<distFromNetBottomToCage)
//            {
//                float cageOpacity=(distFromBlockToCage/distFromNetBottomToCage)*255;
//                [c.mySprite setOpacity:cageOpacity];
//                [cM.mySprite setOpacity:cageOpacity];
//            }
            
            if(distFromBlockToCage<(distFromNetBottomToCage/2) && !cageHasDropped)
            {
                [c.mySprite runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:ccp(c.PosX, c.PosY-200)] rate:2.0f]];
                [c.mySprite runAction:[CCFadeOut actionWithDuration:0.5f]];
                [cM.mySprite runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:ccp(c.PosX, c.PosY-220)] rate:2.0f]];
                [cM.mySprite runAction:[CCFadeOut actionWithDuration:0.5f]];
                
//                [c.mySprite setPosition:ccp(c.PosX, c.PosY)];
//                [cM.mySprite setPosition:ccp(c.PosX, c.PosY+20)];
                cageHasDropped=YES;
                [loggingService logEvent:BL_PA_PV_TOUCH_MOVE_MOVED_TO_DISABLED_CAGE withAdditionalData:nil];
            }
        }
        
        // first check for a valid place to drop
        GLbyte currentOpacity=127;
        
        // update the testtouchloc
        gw.Blackboard.TestTouchLocation=location;
        
        gw.Blackboard.DropObject=nil;
        [gw handleMessage:kDWareYouADropTarget andPayload:nil withLogLevel:-1];
        
        // keep a ref to pickup mysprite
        CCSprite *mySprite = ((DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject).mySprite;
        if([gw Blackboard].DropObject != nil)
        { 
            // if a proximity sprite is set, change he pickupobject sprite now
            if(pickupSprite)
                [mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(((DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject).PickupSprite)]];
            
            // and set the opacity for use in tinting our grid later
            if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueNetGameObject class]])
                currentOpacity=255;
            
            else if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueCageGameObject class]])
                currentOpacity=127;
            
        }
        else {
            // but if we have no droptarget - set the net colour to half

            currentOpacity=127;
        }
        

        // set our grid opacity dependent on what was done above
        [self setGridOpacity:currentOpacity];
        

        CGPoint diff=[BLMath SubtractVector:prevLoc from:location];
        
        //mod location by pickup offset
        float posX = block.PosX;
        float posY = block.PosY;
        
        posX = posX + diff.x;
        posY = posY + diff.y;
        
        
        if(isBasePickup && [gw.Blackboard.SelectedObjects containsObject:gw.Blackboard.PickupObject] && allowCondensing)
        {
            //flag we're in inBlockTransition
            inBlockTransition=YES;
            hasMovedBasePickup=YES;
            
            if(CGRectContainsPoint(boundingBoxCondense, location) && currentColumnIndex>0)
                //if([BLMath rectContainsPoint:location x:0 y:0 w:200 h:ly] && currentColumnIndex>0)
            {
                inCondenseArea=YES;
                currentOpacity=255;
            }
            else
            {
                inCondenseArea=NO;
                currentOpacity=127;
            }
            if(currentColumnIndex-1>=0)
                [self setGridOpacity:currentColumnIndex-1 toOpacity:currentOpacity];
            
            // when we're moving several blocks at once
            for(int go=0;go<gw.Blackboard.SelectedObjects.count;go++)
            {
                DWPlaceValueBlockGameObject *thisObject=[[[gw Blackboard] SelectedObjects] objectAtIndex:go];
                
                thisObject.PosX=thisObject.PosX+diff.x;
                thisObject.PosY=thisObject.PosY+diff.y;
                
                [thisObject handleMessage:kDWmoveSpriteToPositionWithoutAnimation andPayload:nil withLogLevel:-1];
                hasMovedBlock=YES;
            }
        }
        
        
        else
        {
            
            // if we're hovering over a mulch location - either say we are and make it evvident we can move there, or tint it back to how it 'should' be
            if(CGRectContainsPoint(boundingBoxMulch, location) && currentColumnIndex<([gw.Blackboard.AllStores count]-1) && allowMulching && [self freeSpacesOnGrid:currentColumnIndex+1]>=columnBaseValue)
            {
                inMulchArea=YES;
                currentOpacity=255;
            }
            else
            {
                inMulchArea=NO;
                currentOpacity=127;
            }
            
            // if we can - tint the mulch location
            if(currentColumnIndex+1<numberOfColumns)
                [self setGridOpacity:currentColumnIndex+1 toOpacity:currentOpacity];
            
            // if their finger moved too much, we know we can update the sprite position
            if(!potentialTap)
            {
                // if we have multiple controls and we have a count of more than one picked up - move them all - one on top of the other
                if(multipleBlockPickup||showMultipleControls)
                {
                    if([pickupObjects count]>0)
                    {
                        NSArray *thesePositions=[NumberLayout physicalLayoutUpToNumber:[pickupObjects count] withSpacing:85.0f];
                        for(DWPlaceValueBlockGameObject *go in pickupObjects)
                        {
                            CGPoint thisPos=[[thesePositions objectAtIndex:[pickupObjects indexOfObject:go]] CGPointValue];
                            
                            go.PosX=posX+thisPos.x+diff.x;
                            go.PosY=posY+thisPos.y+diff.y;
                            [go handleMessage:kDWmoveSpriteToPositionWithoutAnimation andPayload:nil withLogLevel:-1];
                        }
                    }
                }
                if(isNegativeProblem)
                {
                    if([pickupObjects count]>0)
                    {
                        for(DWPlaceValueBlockGameObject *go in pickupObjects)
                        {
                            go.PosX=posX;
                            go.PosY=posY+85 *[pickupObjects indexOfObject:go];
                            [go handleMessage:kDWupdateSprite andPayload:nil withLogLevel:-1];
                        }
                    }
                }
                
                // otherwise set just the block to the posx/y positions and update the position
                block.PosX=posX;
                block.PosY=posY;
                [[gw Blackboard].PickupObject handleMessage:kDWmoveSpriteToPositionWithoutAnimation andPayload:nil withLogLevel:-1];
                hasMovedBlock=YES;
            }
        }
        
    }
    
}
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    BOOL aTransitionHappened=NO;
    
    if(debugLogging)
        NSLog(@"THIS TOUCH END CONSISTS (%d touches)", [touches count]);
    
    // set the touch end position for evaluation
    touchEndPos = location;
    gw.Blackboard.TestTouchLocation=[renderLayer convertToNodeSpace:location];

    
    [toolHost.Zubi setTarget:location];
    
    inBlockTransition=NO;
    
    // log out if blocks are moved
    if(hasMovedBlock)
    {
        float objValue = ((DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject).ObjectValue;
        
        [loggingService logEvent:([gw.Blackboard.SelectedObjects count] > 1 ? BL_PA_PV_TOUCH_MOVE_MOVE_OBJECTS : BL_PA_PV_TOUCH_MOVE_MOVE_OBJECT)
              withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:objValue] forKey:@"objectValue"]];
    }
    
    // if we've moved the layer - log that too
    if(hasMovedLayer)
        [loggingService logEvent:BL_PA_PV_TOUCH_MOVE_MOVE_GRID withAdditionalData:nil];
    
    //do mulching / condensing
    if (inMulchArea) {
        
        aTransitionHappened = [self doMulchFromLocation:location];
        inMulchArea=NO;
        [mulchPanel setVisible:NO];
        
    }
    if(inCondenseArea && isBasePickup)
    {
        aTransitionHappened = [self doCondenseFromLocation:location];
        inCondenseArea=NO;
        [condensePanel setVisible:NO];
        
    }
    // if a transition hasn't happened
    if(!aTransitionHappened)
    {
        
        // evaluate the distance between start/end pos.
        // if we've not moved over our tap slip threshold
        if([gw Blackboard].PickupObject!=nil && [BLMath DistanceBetween:touchStartPos and:touchEndPos] < fabs(kTapSlipThreshold) && potentialTap)
        {
            // check whether it's selected and we can deselect - or that it's deselected
            DWPlaceValueBlockGameObject *block=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
            BOOL isCage;
            
            // check whether this mount is a cage
            if([block.LastMount isKindOfClass:[DWPlaceValueCageGameObject class]])
                isCage=YES;
            else
                isCage=NO;
            
            // if we're selected and not in a cage or if we are and we're allowed to deselect, AND are not in a cage, switch selection
            
            if(debugLogging)
                NSLog(@"block selected? %@, isCage? %@", block.Selected? @"YES":@"NO", isCage? @"YES":@"NO");
            
//            if((!block.Selected && !isCage && allowDeselect) || (block.Selected && allowDeselect && !isCage))
//            {
//                [[gw Blackboard].PickupObject handleMessage:kDWswitchSelection andPayload:nil withLogLevel:0];
//                hasMovedBasePickup=NO;
//                
//                if(!disableAudioCounting&&!gw.Blackboard.inProblemSetup&&gw.Blackboard.SelectedObjects.count<=20)
//                {
//                    NSString *path=[NSString stringWithFormat:@"/sfx/numbers/%d.wav", gw.Blackboard.SelectedObjects.count];
//                    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(path)];
//                }
//            }
            
            
            // if we have a base pickup -- then set all their mounts back to what they should be - update their positions and tell them to animate to their rightful place - otherwise just do it for the current block
            if(isBasePickup)
            {
                for(int igo=0; igo<gw.Blackboard.SelectedObjects.count; igo++)
                {
                    DWPlaceValueBlockGameObject *go = [[[gw Blackboard] SelectedObjects] objectAtIndex:igo];
                    
                    go.Mount=go.LastMount;
                    
                    ((DWPlaceValueNetGameObject*)go.Mount).MountedObject=go;
                    
//                    go.AnimateMe=YES;
//
//                    go.PosX=((DWPlaceValueNetGameObject*)go.Mount).PosX;
//                    go.PosY=((DWPlaceValueNetGameObject*)go.Mount).PosY;
                    
                    [go handleMessage:kDWresetToMountPosition];
                    [go handleMessage:kDWputdown andPayload:nil withLogLevel:0];
                    
                }
                
                [self setTouchVarsToOff];
                return;
            }

            if([block.LastMount isKindOfClass:[DWPlaceValueNetGameObject class]])
            {
                block.Mount=block.LastMount;
                ((DWPlaceValueNetGameObject*)block.Mount).MountedObject=block;
                [block handleMessage:kDWresetToMountPosition];
            }
            
            // but if our lastmount was a cage - return it there and destroy it
            if([block.LastMount isKindOfClass:[DWPlaceValueCageGameObject class]])
            {
                [block handleMessage:kDWresetToMountPositionAndDestroy];
            }
            
            if(debugLogging)
                NSLog(@"(touchend-notransition) free spaces on grid %d", [self freeSpacesOnGrid:currentColumnIndex]);
            
            // switch our sprites back to the main sprite - and set our touchvars to off
            [self problemStateChanged];
            [self switchSpritesBack];
            [self setTouchVarsToOff];
            return;
        }
        // if we've moved more than our 'tap slip' threshold
        if([gw Blackboard].PickupObject!=nil && ([BLMath DistanceBetween:touchStartPos and:touchEndPos] > fabs(kTapSlipThreshold)))
        {
            // if there's a base pickup and our current pickup object isn't selected (usually a caged object) search for a droptarget
            if(isBasePickup)
            {
                DWGameObject *go = gw.Blackboard.PickupObject;
                if(![gw.Blackboard.SelectedObjects containsObject:go])
                {
                    [gw Blackboard].DropObject=nil;
                    [gw handleMessage:kDWareYouADropTarget andPayload:nil withLogLevel:-1];                
                }
            }
            
            
            if([gw Blackboard].DropObject != nil)
            {
                if(debugLogging)
                    NSLog(@"(touchend-gotdroptarget) free spaces on grid %d", [self freeSpacesOnGrid:currentColumnIndex]);
                DWPlaceValueBlockGameObject *b=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
                DWPlaceValueNetGameObject *n=nil;

                
                if([gw.Blackboard.PriorityDropObject isKindOfClass:[DWPlaceValueNetGameObject class]])
                    n=(DWPlaceValueNetGameObject*)gw.Blackboard.PriorityDropObject;
                else if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueNetGameObject class]])
                    n=(DWPlaceValueNetGameObject*)gw.Blackboard.DropObject;
                
                // set the pickup object's mount to the dropobject
                if(gw.Blackboard.PriorityDropObject && explodeMode)
                    b.Mount=gw.Blackboard.PriorityDropObject;
                else
                    b.Mount=gw.Blackboard.DropObject;
                
                // set the zindex back to what it was
                [b.mySprite setZOrder:b.lastZIndex];
                
                
                // set a bool saying whether our dropobject is a cage or not
                BOOL isCage;
                BOOL doNotSwitchSelection=NO;
                BOOL hasModifiedTestLocation=NO;
                
                if([[gw Blackboard].DropObject isKindOfClass:[DWPlaceValueCageGameObject class]])isCage=YES;
                else isCage=NO;
            
                NSMutableArray *blocksToDestroy=nil;
                NSMutableArray *mountsToNil=nil;
                
                if(isBasePickup && [gw.Blackboard.SelectedObjects containsObject:gw.Blackboard.PickupObject] && [gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueNetGameObject class]])
                {
                    for(int igo=0; igo<gw.Blackboard.SelectedObjects.count; igo++)
                    {
                        DWPlaceValueBlockGameObject *go = [[[gw Blackboard] SelectedObjects] objectAtIndex:igo];
                        go.Mount=go.LastMount;
                        
                        ((DWPlaceValueNetGameObject*)go.Mount).MountedObject=go;
                        
                        go.AnimateMe=YES;
                        
                        go.PosX=((DWPlaceValueNetGameObject*)go.Mount).PosX;
                        go.PosY=((DWPlaceValueNetGameObject*)go.Mount).PosY;
                        
                        [go handleMessage:kDWmoveSpriteToPosition];
                        [go handleMessage:kDWputdown andPayload:nil withLogLevel:0];
                        
                        [go handleMessage:kDWputdown];
                    }
                    doNotSwitchSelection=YES;
                    [loggingService logEvent:BL_PA_PV_TOUCH_END_DROPPED_BASE_PICKUP_ON_NET withAdditionalData:nil];
                    [self setTouchVarsToOff];
                    return;
                }
                else if(isBasePickup && [gw.Blackboard.SelectedObjects containsObject:gw.Blackboard.PickupObject] && [gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueCageGameObject class]])
                {
                    NSMutableArray *SelectedObjects=[NSMutableArray arrayWithArray:gw.Blackboard.SelectedObjects];
                    for(int igo=0; igo<SelectedObjects.count; igo++)
                    {
                        DWPlaceValueBlockGameObject *go = [SelectedObjects objectAtIndex:igo];
                        ((DWPlaceValueNetGameObject*)go.Mount).MountedObject=nil;
                        go.Mount=gw.Blackboard.DropObject;
                        
                        
                        go.AnimateMe=YES;
                        
                        go.PosX=((DWPlaceValueNetGameObject*)go.Mount).PosX;
                        go.PosY=((DWPlaceValueNetGameObject*)go.Mount).PosY;
                        go.Selected=NO;
                        if([gw.Blackboard.SelectedObjects containsObject:go])
                            [gw.Blackboard.SelectedObjects removeObject:go];
                        
                        [go handleMessage:kDWresetToMountPositionAndDestroy];
                        [go handleMessage:kDWputdown andPayload:nil withLogLevel:0];
                        
                        //[go handleMessage:kDWputdown];
                    }
                    doNotSwitchSelection=YES;
                    [self setTouchVarsToOff];
                    [loggingService logEvent:BL_PA_PV_TOUCH_END_DROPPED_BASE_PICKUP_ON_CAGE withAdditionalData:nil];
                    return;
                    
                }
                
                
                if((multipleBlockPickup||showMultipleControls||isNegativeProblem) && !isBasePickup)
                {
                    if([self freeSpacesOnGrid:currentColumnIndex]>=[pickupObjects count])
                    {
                        
                        gw.Blackboard.DropObject=nil;
                        [gw handleMessage:kDWareYouADropTarget andPayload:nil withLogLevel:0];
                        [loggingService logEvent:BL_PA_PV_TOUCH_END_MULTIPLE_BLOCKS_DROPPED withAdditionalData:nil];
                        if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueNetGameObject class]] && !hasModifiedTestLocation && [pickupObjects count]>1)
                        {
                            gw.Blackboard.TestTouchLocation=ccp(n.PosX,n.PosY+200);
                            hasModifiedTestLocation=YES;
                        }
                        
                    }
                    else if([self freeSpacesOnGrid:currentColumnIndex]<[pickupObjects count])
                    {
//                        for(DWPlaceValueBlockGameObject *go in pickupObjects){
//                            
//                            if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueCageGameObject class]])
//                            {
//                                [b handleMessage:kDWsetMount andPayload:nil withLogLevel:0];
//                                [b handleMessage:kDWputdown andPayload:nil withLogLevel:0];
//                            }
//                            else if(![gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueCageGameObject class]])
//                            {
//                                [b handleMessage:kDWresetToMountPositionAndDestroy];
//                            }
//                        }
                        
                        for(DWPlaceValueBlockGameObject *go in pickupObjects){
                            [go handleMessage:kDWresetToMountPositionAndDestroy];
                        }
                        [loggingService logEvent:BL_PA_PV_TOUCH_END_MULTIPLE_BLOCKS_NOT_ENOUGH_SPACE withAdditionalData:nil];
                        [self setTouchVarsToOff];
                        return;
                    }
                    
                }

                
                
                for(DWPlaceValueBlockGameObject *b in pickupObjects)
                {
                    gw.Blackboard.DropObject=nil;
                    gw.Blackboard.PriorityDropObject=nil;
                    [gw handleMessage:kDWareYouADropTarget andPayload:nil withLogLevel:0];

                    if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueNetGameObject class]])
                    {
                        if(![[userAddedBlocks objectAtIndex:currentColumnIndex] containsObject:b])
                           [[userAddedBlocks objectAtIndex:currentColumnIndex] addObject:b];
                    }
                    else if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueCageGameObject class]])
                    {
                        if([[userAddedBlocks objectAtIndex:currentColumnIndex] containsObject:b])
                            [[userAddedBlocks objectAtIndex:currentColumnIndex] removeObject:b];
                    }
                    
                    if(b.ObjectValue==0)
                    {
                        [b handleMessage:kDWfadeAndDestroy];
                        [loggingService logEvent:BL_PA_PV_TOUCH_END_DROP_ZERO withAdditionalData:nil];
                        [self setTouchVarsToOff];
                        return;
                    }
                    else if(explodeMode && isNegativeProblem)
                    {
                        
                        if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueNetGameObject class]])
                        {
                            DWPlaceValueNetGameObject *n=nil;
                            
                            if(gw.Blackboard.PriorityDropObject)
                                n=(DWPlaceValueNetGameObject*)gw.Blackboard.PriorityDropObject;
                            else
                                n=(DWPlaceValueNetGameObject*)gw.Blackboard.DropObject;
                                
                            if(!blocksToDestroy)
                                blocksToDestroy=[[[NSMutableArray alloc]init]autorelease];
                            if(!mountsToNil)
                                mountsToNil=[[[NSMutableArray alloc]init]autorelease];
                            
                            if(!n.MountedObject)
                                n.MountedObject=b;
                            else if(n.MountedObject && !n.CancellingObject)
                                n.CancellingObject=b;
                            else
                                n.MountedObject=b;
                            
                            
                            b.Mount=n;
                            [b handleMessage:kDWresetToMountPosition];
                            
                            if(n.MountedObject && n.CancellingObject){
                                [blocksToDestroy addObject:b];
                                [blocksToDestroy addObject:n.MountedObject];
                                [mountsToNil addObject:n];

                            }
                            
                        }
                        else
                        {
                            [b handleMessage:kDWresetToMountPositionAndDestroy];
                        }
//                        [b handleMessage:kDWresetToMountPosition];
//                        [n.MountedObject handleMessage:kDWfadeAndDestroy];
//                        [b handleMessage:kDWfadeAndDestroy];
//                        n.MountedObject=nil;
                    }
                    // ===== return a selection (a base selection) back to where they came from by resetting mounts etc ===

                    else if(isBasePickup && ![gw.Blackboard.SelectedObjects containsObject:gw.Blackboard.PickupObject] && [self freeSpacesOnGrid:currentColumnIndex]==0)
                    {
                        b.Mount=b.LastMount;
                        [b handleMessage:kDWresetToMountPositionAndDestroy andPayload:nil withLogLevel:0];
                    }
                    // if there's no mount, there's a dropobject that's a cage, and the last mount was a cage - return and destroy
                    else if(b.Mount==nil && [gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueCageGameObject class]] && [b.LastMount isKindOfClass:[DWPlaceValueCageGameObject class]])
                    {
                        //NSLog(@"mount nil, droptarget class %@ lastmount class %@", NSStringFromClass([gw.Blackboard.DropObject class]), NSStringFromClass([b.LastMount class]));
                        [b handleMessage:kDWresetToMountPositionAndDestroy];
                    }
                    
                    else {
                        // otherwise the pickupobject should be remounted and
                        
                        if([b.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
                            [b.Mount handleMessage:kDWunsetMountedObject];
                        
                        b.Mount=gw.Blackboard.DropObject;
                    
//                        if([gw.Blackboard.DropObject isKindOfClass:[DWPlaceValueNetGameObject class]])
//                        {
//                        
//                            if(!((DWPlaceValueNetGameObject*)gw.Blackboard.DropObject).MountedObject)
//                                ((DWPlaceValueNetGameObject*)gw.Blackboard.DropObject).MountedObject=b;
//                            else
//                                ((DWPlaceValueNetGameObject*)gw.Blackboard.DropObject).CancellingObject=b;
//                            [b handleMessage:kDWresetToMountPosition];
//                        }
//                        else
//                        {
                          [b handleMessage:kDWsetMount andPayload:nil withLogLevel:0];
//                        }
                        
                        
                        //
                        [b handleMessage:kDWputdown andPayload:nil withLogLevel:0];
                        [b logInfo:@"this object was mounted" withData:0];
                        [[gw Blackboard].DropObject logInfo:@"mounted object on this go" withData:0];
                        
                    }
                    
//                    gw.Blackboard.DropObject=nil;
//                    gw.Blackboard.PriorityDropObject=nil;
//                    [gw handleMessage:kDWareYouADropTarget andPayload:nil withLogLevel:-1];
                }
                
                // then log stuff
                [loggingService logEvent:(isCage ? BL_PA_PV_TOUCH_END_DROP_OBJECT_ON_CAGE : BL_PA_PV_TOUCH_END_DROP_OBJECT_ON_GRID)
                    withAdditionalData:nil];
                

                if(pickupSprite){
                    
                    if(isCage && doNotSwitchSelection)
                    {
                        //deselect the object if selected
                        // check whether it's selected and we can deselect - or that it's deselected
//                        if(b.Selected)
//                            [[gw Blackboard].PickupObject handleMessage:kDWswitchSelection andPayload:nil withLogLevel:0];
                    }
                }
                if(blocksToDestroy)
                {
                    
                    for(DWPlaceValueBlockGameObject *thisBlock in blocksToDestroy)
                    {
                        [thisBlock handleMessage:kDWresetToMountPosition];
//                        [thisNet.MountedObject handleMessage:kDWfadeAndDestroy];
                        [thisBlock handleMessage:kDWfadeAndDestroy];
                    }
                    
                    for(DWPlaceValueNetGameObject *thisNet in mountsToNil)
                    {
                        thisNet.MountedObject=nil;
                        thisNet.CancellingObject=nil;
                    }
                    
                    blocksToDestroy=nil;
                }
                [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/putdown.wav")];
                [loggingService logEvent:BL_PA_PV_TOUCH_END_EXPLODE_BLOCKS withAdditionalData:nil];
                // tell the tool that the problem state changed - so an auto eval will run now
                [self problemStateChanged];
                
            }
            else
            {
                // but if we're not showing multiple controls, check our last mount and reset or reset and destroy
                DWPlaceValueBlockGameObject *b=(DWPlaceValueBlockGameObject*)gw.Blackboard.PickupObject;
                
                if([b.LastMount isKindOfClass:[DWPlaceValueCageGameObject class]])
                    [b handleMessage:kDWresetToMountPositionAndDestroy];
                else
                    [self resetPickupObjectPos];
            }
            
        }
        
        else {
            [self resetPickupObjectPos];
        }
        
    }
    
    int objectsOnGrid=[self usedSpacesOnGrid:currentColumnIndex];
    
    if(objectsOnGrid==columnBaseValue && currentColumnIndex!=0 && !justMulched)
    {
        [self selectBaseObjectsOnGrid:currentColumnIndex];
    }
    else
    {
        for(DWPlaceValueBlockGameObject *b in [NSArray arrayWithArray:gw.Blackboard.SelectedObjects])
        {
            [b handleMessage:kDWswitchBaseSelectionBack];
            if([gw.Blackboard.SelectedObjects containsObject:b])
                [gw.Blackboard.SelectedObjects removeObject:b];
        }
        isBasePickup=NO;
            
    }
    
    //get any auto reset / repositions to re-evaluate
    [gw handleMessage:kDWstartRespositionSeek andPayload:nil withLogLevel:0];
    
    if(debugLogging)
        [self logOutGameObjectsPositions:currentColumnIndex];
    
    [self switchSpritesBack];
    [self setTouchVarsToOff];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setTouchVarsToOff];
}

-(void)setTouchVarsToOff
{
    [self resetObjectStates];
    //remove all condense/mulch/transition state
    [gw Blackboard].PickupObject = nil;
    [gw Blackboard].PriorityDropObject = nil;
    //gw.Blackboard.DropObject=nil;
    inBlockTransition=NO;
    inCondenseArea=NO;
    inMulchArea=NO;
    [mulchPanel setVisible:NO];
    [condensePanel setVisible:NO];
    boundingBoxCondense=CGRectNull;
    boundingBoxMulch=CGRectNull;
    hasMovedBlock=NO;
    hasMovedLayer=NO;
//    isBasePickup=NO;
    hasMovedBasePickup=NO;
    changedBlockCountOrValue=NO;
    [pickupObjects removeAllObjects];
    justMulched=NO;
    thisCageWontTakeMe=NO;
    cageHasDropped=NO;
    
    touching=NO;
}

#pragma mark - dealloc
-(void) dealloc
{
    [renderLayer release];
    [self.NoScaleLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    if(solutionsDef) [solutionsDef release];
    if(columnInfo) [columnInfo release];
    if(solutionDisplayText) [solutionDisplayText release];
    if(incompleteDisplayText) [incompleteDisplayText release];
    if(showCustomColumnHeader) [showCustomColumnHeader release];
    if(columnCagePosDisableAdd) [columnCagePosDisableAdd release];
    if(columnCagePosDisableDel) [columnCagePosDisableDel release];
    if(columnCageNegDisableAdd) [columnCageNegDisableAdd release];
    if(columnCageNegDisableDel) [columnCageNegDisableDel release];
    if(multipleBlockPickup) [multipleBlockPickup release];
    if(columnSprites) [columnSprites release];
    if(columnCages) [columnCages release];
    if(columnRows) [columnRows release];
    if(columnRopes) [columnRopes release];
    if(currentBlockValues)[currentBlockValues release];
    if(blockLabels)[blockLabels release];
    posCageSprite=nil;
    negCageSprite=nil;
    if(pickupSprite) [pickupSprite release];
    if(proximitySprite) [proximitySprite release];
    if(blocksToCreate) [blocksToCreate release];
    if(multiplePlusSprites) [multiplePlusSprites release];
    if(multipleMinusSprites) [multipleMinusSprites release];
    if(multipleLabels) [multipleLabels release];
    if(pickupObjects) [pickupObjects release];
    if(multipleBlockPickupDefaults)[multipleBlockPickupDefaults release];

    if(allCages)[allCages release];
    if(boundCounts)[boundCounts release];
    if(totalCountSprites)[totalCountSprites release];
    if(userAddedBlocks)[userAddedBlocks release];
    
    [gw release];
    
    [super dealloc];
}

@end
