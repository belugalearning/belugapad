//
//  PlaceValue.m
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PlaceValue.h"
#import "MenuScene.h"
#import "global.h"
#import "BLMath.h"
#import "SimpleAudioEngine.h"
#import "IceDiv.h"
#import "ToolConsts.h"
#import "PlaceValueConsts.h"
#import "DWGameWorld.h"
#import "Daemon.h"
#import "ToolHost.h"


static float kPropXNetSpace=0.087890625f;
static float kPropYColumnOrigin=0.75f;
static float kCageYOrigin=0.08f;
static float kPropYColumnHeader=0.85f;
static NSString *kDefaultSprite=@"obj-placevalue-unit.png";

@implementation PlaceValue

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    problemDef=pdef;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
     
        self.BkgLayer=[[CCLayer alloc]init];
        self.ForeLayer=[[CCLayer alloc]init];
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        [self setupBkgAndTitle];

        [self readPlist:pdef];
        
        [self populateGW];

        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
    
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        // Set the lastCount to 0 - this is for counting problems.
        
        lastCount = 0; 

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
    if(autoHideStatusLabel)
    {
        timeToHideStatusLabel+=delta;
        if(timeToHideStatusLabel>=kTimeToAutoMove)
        {
            [problemCompleteLabel setVisible:NO];
            autoHideStatusLabel=NO;
            timeToHideStatusLabel=0.0f;
        }
    }
}

-(void)setupProblem
{
    touching = NO;
}

-(void)populateGW
{
    gw = [[DWGameWorld alloc] initWithGameScene:self];
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    float ropeWidth = kPropXNetSpace*lx;

    columnInfo = [[NSMutableArray alloc] init];
    [columnInfo retain];
    
    float currentColumnValue = firstColumnValue;
    
    for (int i=0; i<numberOfColumns; i++)
    {
        CGPoint thisColumnOrigin = ccp(-((ropeWidth*ropesforColumn)/2.0f)+(ropeWidth/2.0f)+(i*(kPropXColumnSpacing*lx)), ly*kPropYColumnOrigin); 
        
        NSMutableDictionary *currentColumnInfo = [[NSMutableDictionary alloc] init];
        [currentColumnInfo setObject:[NSNumber numberWithFloat:currentColumnValue] forKey:COL_VALUE];
        [currentColumnInfo setObject:[NSString stringWithFormat:@"%gs", currentColumnValue] forKey:COL_LABEL];
        
        [columnInfo addObject:currentColumnInfo];
        
        if(showColumnHeader)
        {
            CCLabelTTF *columnHeader = [CCLabelTTF labelWithString:[currentColumnInfo objectForKey:COL_LABEL] fontName:TITLE_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            [columnHeader setPosition:ccp(i*(kPropXColumnSpacing*lx), ly*kPropYColumnHeader)];
            [renderLayer addChild:columnHeader z:5];
        }
        
        currentColumnValue = (currentColumnValue/columnBaseValue);
        
        DLog(@"Reset current column value to %f", currentColumnValue);
        
        NSMutableArray *newCol = [[NSMutableArray alloc] init];
        
        [gw.Blackboard.AllStores addObject:newCol];
        
        // set the layer position
        
        float layerPositionX = (cx-(defaultColumn*(kPropXColumnSpacing*lx)));
        [renderLayer setPosition:ccp(layerPositionX, 0)];
        
        if(currentColumnValue == defaultColumn)
        {   
            gw.Blackboard.CurrentStore = newCol;
            currentColumnIndex = i;
        }

    
        for (int iRow=0; iRow<rows; iRow++)
        {
            NSMutableArray *RowArray = [[NSMutableArray alloc] init];        
            [newCol addObject:RowArray];
            
            CGPoint rowOrigin=ccp(thisColumnOrigin.x, thisColumnOrigin.y-(iRow*ropeWidth)); 
            
            for(int iRope=0; iRope<ropesforColumn; iRope++)
            {
                CGPoint containerOrigin=ccp(rowOrigin.x+(iRope*ropeWidth), rowOrigin.y);
                DWGameObject *go = [gw addGameObjectWithTemplate:@"TplaceValueContainer"];
                [[go store] setObject:[NSNumber numberWithFloat:containerOrigin.x] forKey:POS_X];
                [[go store] setObject:[NSNumber numberWithFloat:containerOrigin.y] forKey:POS_Y];
                [[go store] setObject:[NSNumber numberWithFloat:iRow] forKey:PLACEVALUE_ROW];
                [[go store] setObject:[NSNumber numberWithFloat:i] forKey:PLACEVALUE_COLUMN];
                [[go store] setObject:[NSNumber numberWithFloat:iRope] forKey:PLACEVALUE_ROPE];
                [[go store] setObject:[[currentColumnInfo objectForKey:COL_VALUE] stringValue] forKey:OBJECT_VALUE];
                
                [RowArray addObject:go];
                
            }
        }
        
        if(showCage) 
        {
            // create cage
            DWGameObject *colCage = [gw addGameObjectWithTemplate:@"TplaceValueCage"];
            [[colCage store] setObject:[NSNumber numberWithBool:YES] forKey:ALLOW_MULTIPLE_MOUNT];
            [[colCage store] setObject:[NSNumber numberWithFloat:i*(kPropXColumnSpacing*lx)] forKey:POS_X];
            [[colCage store] setObject:[NSNumber numberWithFloat:ly*kCageYOrigin] forKey:POS_Y];
            [[colCage store] setObject:[[currentColumnInfo objectForKey:COL_VALUE] stringValue] forKey:OBJECT_VALUE];
            
            
            NSString *currentColumnValueKey = [[currentColumnInfo objectForKey:COL_VALUE] stringValue];
            
            if([columnSprites objectForKey:currentColumnValueKey])
            {
                [[colCage store] setObject:[columnSprites objectForKey:currentColumnValueKey] forKey:SPRITE_FILENAME];
            }
            else
            {
                [[colCage store] setObject:kDefaultSprite forKey:SPRITE_FILENAME];                
            }

        }
    
    }

    for(int i=0; i<(initObjects.count); i++)
    {
        NSDictionary *curDict = [initObjects objectAtIndex:i];
        int insCol = [[curDict objectForKey:PUT_IN_COL] intValue];
        int insRow = [[curDict objectForKey:PUT_IN_ROW] intValue];
        int count = [[curDict objectForKey:NUMBER] intValue];     
        for(int i=0; i<count; i++)
        {
            DWGameObject *block = [gw addGameObjectWithTemplate:@"TplaceValueObject"];
            
            NSDictionary *pl = [NSDictionary dictionaryWithObject:[[[gw.Blackboard.AllStores objectAtIndex:insCol] objectAtIndex:insRow] objectAtIndex:i] forKey:MOUNT];
            [[block store] setObject:[[[columnInfo objectAtIndex:insCol] objectForKey:COL_VALUE] stringValue] forKey:OBJECT_VALUE];

            
            
            NSString *currentColumnValueKey = [[[columnInfo objectAtIndex:insCol] objectForKey:COL_VALUE] stringValue];
            
            if([columnSprites objectForKey:currentColumnValueKey])
            {
                [[block store] setObject:[columnSprites objectForKey:currentColumnValueKey] forKey:SPRITE_FILENAME];
            }
            [block handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
            
        }
        DLog(@"col %d, rows %d, count %d", insCol, insRow, count);

    }

    [renderLayer setPosition:ccp(cx-(currentColumnIndex*(kPropXColumnSpacing*lx)), 0)];
    
}

-(void)setupBkgAndTitle
{
    problemCompleteLabel=[CCLabelTTF labelWithString:@"" fontName:TITLE_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemCompleteLabel setColor:kLabelCompleteColor];
    [problemCompleteLabel setPosition:ccp(cx, cy*kLabelCompletePVYOffsetHalfProp)];
    [problemCompleteLabel setVisible:NO];
    [self.ForeLayer addChild:problemCompleteLabel z:5];
    
    CCSprite *btnFwd=[CCSprite spriteWithFile:@"btn-fwd.png"];
    [btnFwd setPosition:kButtonNextToolPos];
    [self.ForeLayer addChild:btnFwd z:2];
    
    condensePanel=[CCSprite spriteWithFile:@"cmpanel.png"];
    [condensePanel setPosition:ccp(100, cy)];
    [condensePanel setVisible:NO];
    [self.ForeLayer addChild:condensePanel z:1];
    
    mulchPanel=[CCSprite spriteWithFile:@"cmpanel.png"];
    [mulchPanel setPosition:ccp(lx-100, cy)];
    [mulchPanel setVisible:NO];
    [self.ForeLayer addChild:mulchPanel z:1];
    
}

-(void)readPlist:(NSDictionary*)pdef
{	
    [gw logInfo:[NSString stringWithFormat:@"started problem"] withData:0];
    
    //render problem label
    problemDescLabel=[CCLabelTTF labelWithString:[pdef objectForKey:PROBLEM_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    //[problemDescLabel setColor:kLabelTitleColor];
    
    [self.ForeLayer addChild:problemDescLabel];
    
    if([[pdef objectForKey:DEFAULT_COL] intValue])
    { defaultColumn = [[pdef objectForKey:DEFAULT_COL] intValue]; }
    else { defaultColumn = 0; }
    
    columnBaseValue = [[pdef objectForKey:COL_BASE_VALUE] floatValue];
    firstColumnValue = [[pdef objectForKey:FIRST_COL_VALUE] floatValue];
    numberOfColumns = [[pdef objectForKey:NUMBER_COLS] floatValue];
    
    ropesforColumn = [[pdef objectForKey:ROPES_PER_COL] intValue];
    rows = [[pdef objectForKey:ROWS_PER_COL] intValue];
    showCage = [[pdef objectForKey:SHOW_CAGE] boolValue];
    showCount = [[pdef objectForKey:SHOW_COUNT] boolValue];
    showValue = [[pdef objectForKey:SHOW_VALUE] boolValue];
    showCountOnBlock = [[pdef objectForKey:SHOW_COUNT_BLOCK] boolValue];
    showColumnHeader = [[pdef objectForKey:SHOW_COL_HEADER] boolValue];
    showBaseSelection = [[pdef objectForKey:SHOW_BASE_SELECTION] boolValue];
    
    //objects
    NSArray *objects=[pdef objectForKey:INIT_OBJECTS];
    initObjects = objects;
    
    //retain solutions dict
    solutionsDef=[pdef objectForKey:SOLUTION];
    [solutionsDef retain];
    
    //look for column specific sprites
    columnSprites = [pdef objectForKey:COLUMN_SPRITES];
    [columnSprites retain];
    
    NSNumber *rMode=[pdef objectForKey:REJECT_MODE];
    if (rMode) rejectMode=[rMode intValue];
    
    NSNumber *eMode=[pdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    
    //show commit button if evalOnCommit
    if(evalMode==kProblemEvalOnCommit)
    {
        CCSprite *commitBtn=[CCSprite spriteWithFile:@"commit.png"];
        [commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [self.ForeLayer addChild:commitBtn z:2];
    }
    if(showCount||showValue)
    {
        if(showCount && !showValue)
        {
            countLabel=[CCLabelTTF labelWithString:@"count" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            [countLabel setPosition:ccp(lx-(kPropXCountLabelPadding*lx), kPropYCountLabelPadding*ly)];   
            [self.ForeLayer addChild:countLabel];
        }
        else if(!showCount && showValue)
        {
            countLabel=[CCLabelTTF labelWithString:@"sum" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            [countLabel setPosition:ccp(lx-(kPropXCountLabelPadding*lx), kPropYCountLabelPadding*ly)];   
            [self.ForeLayer addChild:countLabel];
        }
        else if(showCount && showValue)
        {
            countLabel=[CCLabelTTF labelWithString:@"count x sum y" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            [countLabel setPosition:ccp(lx-(kPropXCountLabelPadding*lx), kPropYCountLabelPadding*ly)];   
            [self.ForeLayer addChild:countLabel];
        }
    }

    
}

-(void)problemStateChanged
{
    totalObjectValue=0;
    
    for(int c=0; c<gw.Blackboard.AllStores.count; c++)
    {
        for (int i=0; i<[[gw.Blackboard.AllStores objectAtIndex:c]count]; i++)
        {
            for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:i]count]; o++)
            {
                DWGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:(i)] objectAtIndex:o];
                if([[goC store] objectForKey:MOUNTED_OBJECT])
                {
                    float objectValue = [[[goC store] objectForKey:OBJECT_VALUE] floatValue];
                    
                    totalObjectValue = totalObjectValue+objectValue;
                }   
            }
        }
    }
    
    NSString *solutionType = [solutionsDef objectForKey:SOLUTION_TYPE];
    
    if([solutionType isEqualToString:COUNT_SEQUENCE])
    {
        if(gw.Blackboard.SelectedObjects.count < lastCount)
        {
            lastCount = 0;
        }
        else
        {
            lastCount++;
            if(showCountOnBlock)
            {
                CCSprite *s=[[gw.Blackboard.LastSelectedObject store] objectForKey:MY_SPRITE];
                CGPoint pos=[s position];
                countLabelBlock=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", gw.Blackboard.SelectedObjects.count] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [countLabelBlock setPosition:pos];
                [self.ForeLayer addChild:countLabelBlock z:10];
                CCFadeOut *labelFade = [CCFadeOut actionWithDuration:kTimeToFadeButtonLabel];
                [countLabelBlock runAction:labelFade];
                
                
            }
        }
            DLog(@"(COUNT_SEQUENCE) Selected %d lastCount %d", gw.Blackboard.SelectedObjects.count, lastCount);
    }
    if(showCount||showValue)
    {
        if(showCount && !showValue)
        {
            NSLog(@"should be countin' %d", gw.Blackboard.SelectedObjects.count);
            [countLabel setString:[NSString stringWithFormat:@"count: %d", gw.Blackboard.SelectedObjects.count]];
            
        }
        else if(!showCount && showValue)
        {
            [countLabel setString:[NSString stringWithFormat:@"sum: %g", totalObjectValue]];
        }
        else if(showCount && showValue)
        {
            [countLabel setString:[NSString stringWithFormat:@"count: %d / sum: %g", gw.Blackboard.SelectedObjects.count, totalObjectValue]];
        }
    }

    if(evalMode == kProblemEvalAuto)
    {
        [self evalProblem];
    }
}

-(void)evalProblem
{
    
    NSString *solutionType = [solutionsDef objectForKey:SOLUTION_TYPE];

    if([solutionType isEqualToString:COUNT_SEQUENCE])
    {
        [self evalProblemCountSeq];
    }
    else if([solutionType isEqualToString:TOTAL_COUNT])
    {
        [self evalProblemTotalCount];
    }
    else if([solutionType isEqualToString:MATRIX_MATCH])
    {
        [self evalProblemMatrixMatch];
    }

}
-(void)doWinning
{
    [problemCompleteLabel setString:@"problem complete! well done!"];
    autoMoveToNextProblem=YES;
    [problemCompleteLabel setVisible:YES];    
}
-(void)doIncorrect
{
    [problemCompleteLabel setString:@"problem incomplete."];
    autoHideStatusLabel=YES;
    [problemCompleteLabel setVisible:YES];
    [gw handleMessage:kDWdeselectAll andPayload:nil withLogLevel:0];
}
-(void)evalProblemCountSeq
{
    if(lastCount == [[solutionsDef objectForKey:SOLUTION_VALUE] intValue])
    {
        [self doWinning];
    }
    else if(lastCount != [[solutionsDef objectForKey:SOLUTION_VALUE] intValue] && evalMode==kProblemEvalOnCommit)
    {
        [self doIncorrect];
    }
}
-(void)evalProblemTotalCount
{
    float totalCount=0;
    float expectedCount = [[solutionsDef objectForKey:SOLUTION_VALUE] floatValue];
    
    for(int c=0; c<gw.Blackboard.AllStores.count; c++)
    {
        
    
    
        for (int i=0; i<[[gw.Blackboard.AllStores objectAtIndex:c]count]; i++)
        {
            for(int o=0; o<[[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:i]count]; o++)
            {
                DWGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:(i)] objectAtIndex:o];
                if([[goC store] objectForKey:MOUNTED_OBJECT])
                {
                    float objectValue = [[[goC store] objectForKey:OBJECT_VALUE] floatValue];
                    
                    totalCount = totalCount+objectValue;
                }   
            }
        }
    }
    
    if(totalCount == expectedCount)
    {
        [self doWinning];
    }
    else if(totalCount != expectedCount && evalMode==kProblemEvalOnCommit)
    {
        [self doIncorrect];
    }
}

-(void)evalProblemMatrixMatch
{
    float solutionsFound = 0;
    
    // for each column
    for(int c=0; c<gw.Blackboard.AllStores.count; c++)
    {
        
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
                DWGameObject *goC = [[[gw.Blackboard.AllStores objectAtIndex:c] objectAtIndex:(i)] objectAtIndex:o];
                if([[goC store] objectForKey:MOUNTED_OBJECT])
                {
                    countAtRow[i] = countAtRow[i] + 1;
                }   
            }
        }
        
        NSArray *solutionMatrix = [solutionsDef objectForKey:SOLUTION_MATRIX];
        
        for(int o=0; o<solutionMatrix.count; o++)
        {
            NSDictionary *solDict = [solutionMatrix objectAtIndex:o];
            int curRow = [[solDict objectForKey:PUT_IN_ROW] intValue];
            
            if(countAtRow[curRow] == [[solDict objectForKey:NUMBER] intValue])
            {
                solutionsFound++;
                //TODO: Attach XP/partial progress here
            }
            else
            {
                //TODO: Attach partial failure here
            }
            
        }
        
        if(solutionsFound == solutionMatrix.count)
        {
            [self doWinning];
        }
        else if(solutionsFound != solutionMatrix.count && evalMode==kProblemEvalOnCommit)
        {
            [self doIncorrect];
        }
    }
    
}



-(void)snapLayerToPosition
{
    float layerPositionX = (cx-(currentColumnIndex*(kPropXColumnSpacing*lx)));
    CCMoveTo *moveLayer = [CCMoveTo actionWithDuration:kLayerSnapAnimationTime position:ccp(layerPositionX, 0)];
    CCEaseIn *moveLayerGently = [CCEaseIn actionWithAction:moveLayer rate:kLayerSnapAnimationTime];
    [renderLayer runAction:moveLayerGently]; 
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];

    // set the touch start pos for evaluation
    touchStartPos = location;
    
    [toolHost.Zubi setMode:kDaemonModeFollowing];
    [toolHost.Zubi setTarget:location];    
    
    if(location.x>kButtonNextToolHitXOffset && location.y>kButtonToolbarHitBaseYOffset)
    {
    
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.3f scene:[IceDiv scene]]];
    }
    else if (CGRectContainsPoint(kRectButtonCommit, location) && evalMode==kProblemEvalOnCommit)
    {
        [self evalProblem];
    }
    else 
    {
        
        [gw Blackboard].PickupObject=nil;
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        [pl setObject:[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE] forKey:OBJECT_VALUE];
        
        //broadcast search for pickup object gw
        [gw handleMessage:kDWareYouAPickupTarget andPayload:pl withLogLevel:0];
        
        if([gw Blackboard].PickupObject!=nil)
        {
            
            gw.Blackboard.PickupOffset = location;
            // At this point we can still cancel the tap
            potentialTap = YES;
            
            //this is just a signal for the GO to us, pickup object is retained on the blackboard
            [[gw Blackboard].PickupObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.wav"];
            
            [[gw Blackboard].PickupObject logInfo:@"this object was picked up" withData:0];
        }
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    CGPoint prevLoc = [touch previousLocationInView:[touch view]];
    prevLoc = [[CCDirector sharedDirector] convertToGL: prevLoc];
    [toolHost.Zubi setTarget:location];
    
    
    if([BLMath DistanceBetween:touchStartPos and:touchEndPos] >= fabs(kTapSlipResetThreshold) && potentialTap)
    {
        touchStartPos = ccp(0, 0);
        touchEndPos = ccp(0, 0);
        potentialTap = NO;
    }

    else if(touching && [gw Blackboard].PickupObject==nil)
    {
        CGPoint diff = ccpSub(location, prevLoc);
        diff = ccp(diff.x, 0);
        [renderLayer setPosition:ccpAdd(renderLayer.position, diff)];
    }
    
    if([gw Blackboard].PickupObject!=nil)
    {
        CGPoint diff=[BLMath SubtractVector:prevLoc from:location];
        
        //mod location by pickup offset
        float posX = [[[gw.Blackboard.PickupObject store] objectForKey:POS_X] floatValue];
        float posY = [[[gw.Blackboard.PickupObject store] objectForKey:POS_Y] floatValue];
        
        posX = posX + diff.x;
        posY = posY + diff.y;
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];        

        if(gw.Blackboard.SelectedObjects.count == columnBaseValue && [gw.Blackboard.SelectedObjects containsObject:gw.Blackboard.PickupObject])
        {
            //flag we're in inBlockTransition
            inBlockTransition=YES;
            
            if([BLMath rectContainsPoint:location x:0 y:0 w:200 h:ly] && currentColumnIndex>0)
            {
                inCondenseArea=YES;
                [condensePanel setVisible:YES];
            }
            else
            {
                inCondenseArea=NO;
                [condensePanel setVisible:NO];
            }
            
            for(int go=0;go<gw.Blackboard.SelectedObjects.count;go++)
            {
                DWGameObject *thisObject = [[[gw Blackboard] SelectedObjects] objectAtIndex:go];

                float x=[[[thisObject store] objectForKey:POS_X] floatValue];
                float y=[[[thisObject store] objectForKey:POS_Y] floatValue];

                [pl setObject:[NSNumber numberWithFloat:x+diff.x] forKey:POS_X];
                [pl setObject:[NSNumber numberWithFloat:y+diff.y] forKey:POS_Y];

                
                [thisObject handleMessage:kDWupdateSprite andPayload:pl withLogLevel:0];
                
            }
        }
        
        
        else
        {
            if([BLMath rectContainsPoint:location x:lx-200 y:0 w:200 h:ly] && currentColumnIndex<([gw.Blackboard.AllStores count]-1))
            {
                inMulchArea=YES;
                [mulchPanel setVisible:YES];
            }
            else
            {
                inMulchArea=NO;
                [mulchPanel setVisible:NO];
            }
            
            [pl setObject:[NSNumber numberWithFloat:posX] forKey:POS_X];
            [pl setObject:[NSNumber numberWithFloat:posY] forKey:POS_Y];
            [[gw Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:pl withLogLevel:-1];
        }
        
    }

}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //remove all condense/mulch/transition state
    inBlockTransition=NO;
    inCondenseArea=NO;
    inMulchArea=NO;
    [mulchPanel setVisible:NO];
    [condensePanel setVisible:NO];
    
    touching=NO;
}

-(void)doTransitionWithIncrement:(int)incr
{
    int tranCount=1;
    if(incr>0) tranCount=10;
    int space=0;
    
    //work out if we have space
    for (int r=[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex+incr] count]-1; r>=0; r--) {
        NSMutableArray *row=[[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex+incr] objectAtIndex:r];
        for (int c=[row count]-1; c>=0; c--)
        {
            DWGameObject *co=[row objectAtIndex:c];
            if(![[co store] objectForKey:MOUNTED_OBJECT])
            {
                space++;
            }
        }
    }
    
    if(space<tranCount) return;

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
    
    //change column index
    currentColumnIndex+=incr;
    gw.Blackboard.CurrentStore=[gw.Blackboard.AllStores objectAtIndex:currentColumnIndex];
    
    [self snapLayerToPosition];
        
    for (int itran=0; itran<tranCount; itran++) {
            
        //create a new object
        NSString *currentColumnValueKey=[[[columnInfo objectAtIndex:currentColumnIndex] objectForKey:COL_VALUE] stringValue];

        DWGameObject *go=[gw addGameObjectWithTemplate:@"TplaceValueObject"];
        
        //drop target etc expects a string -- so we'll send one
        [[go store] setObject:currentColumnValueKey forKey:OBJECT_VALUE];
        
        if([columnSprites objectForKey:currentColumnValueKey])
        {
            [[go store] setObject:[columnSprites objectForKey:currentColumnValueKey] forKey:SPRITE_FILENAME];
        }
        
        [go handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        BOOL foundMount=NO;
        
        //find a mount for this object
        for (int r=[gw.Blackboard.CurrentStore count]-1; r>=0; r--) {
            NSMutableArray *row=[gw.Blackboard.CurrentStore objectAtIndex:r];
            for (int c=[row count]-1; c>=0; c--)
            {
                DWGameObject *co=[row objectAtIndex:c];
                if(![[co store] objectForKey:MOUNTED_OBJECT])
                {
                    //use this as a mount
                    NSDictionary *pl=[NSDictionary dictionaryWithObject:co forKey:MOUNT];
                    [go handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
                    
                    foundMount=YES;
                    
                    break;
                }
            }
        }
    }
}

-(void)doCondenseFromLocation:(CGPoint)location
{
    [self doTransitionWithIncrement:-1];
}

-(void)doMulchFromLocation:(CGPoint)location
{
    [self doTransitionWithIncrement:1];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    // set the touch end position for evaluation
    touchEndPos = location;
    
    [toolHost.Zubi setTarget:location];
    [toolHost.Zubi setMode:kDaemonModeWaiting];
    
    inBlockTransition=NO;
    
    //do mulching / condensing
    if (inMulchArea) {
        [self doMulchFromLocation:location];
        
        inMulchArea=NO;
        [mulchPanel setVisible:NO];        
    }
    if(inCondenseArea)
    {
        [self doCondenseFromLocation:location];
        
        inCondenseArea=NO;
        [condensePanel setVisible:NO];
    }
    
    if(fabsf(touchStartPos.x-touchEndPos.x)>kMovementForSnapColumn && [gw Blackboard].PickupObject==nil)
    {
        if(touchStartPos.x < touchEndPos.x)
        {

            if(currentColumnIndex < 1) { currentColumnIndex = 0; }
            else { currentColumnIndex--; }
        
            gw.Blackboard.CurrentStore = [gw.Blackboard.AllStores objectAtIndex:currentColumnIndex];   
            
            [self snapLayerToPosition];
        }
        else
        {
            
            if(currentColumnIndex >= (numberOfColumns-1)) { currentColumnIndex = numberOfColumns-1; }
            else { currentColumnIndex++; }
            
            gw.Blackboard.CurrentStore = [gw.Blackboard.AllStores objectAtIndex:currentColumnIndex];   
            
            [self snapLayerToPosition];
          
        }
    }
    else if(fabsf(touchStartPos.x-touchEndPos.x)<kMovementForSnapColumn && [gw Blackboard].PickupObject==nil)
    {
        [self snapLayerToPosition];
    }
    
    // evaluate the distance between start/end pos.
    
    if([BLMath DistanceBetween:touchStartPos and:touchEndPos] < fabs(kTapSlipThreshold) && potentialTap)
    {
            [[gw Blackboard].PickupObject handleMessage:kDWswitchSelection andPayload:nil withLogLevel:0];
    
    }
    
    if(gw.Blackboard.SelectedObjects.count == columnBaseValue && showBaseSelection)
    {
        if(gw.Blackboard.SelectedObjects.count == columnBaseValue)
        {
            for(int go=0; go<gw.Blackboard.SelectedObjects.count; go++)
            {
                DWGameObject *goO = [[[gw Blackboard] SelectedObjects] objectAtIndex:go];
                [goO handleMessage:kDWswitchBaseSelection andPayload:nil withLogLevel:0];
            }
        }
    }
    else
    {
        for(int go=0; go<gw.Blackboard.SelectedObjects.count; go++)
        {
            DWGameObject *goO = [[[gw Blackboard] SelectedObjects] objectAtIndex:go];
            [goO handleMessage:kDWswitchBaseSelectionBack andPayload:nil withLogLevel:0];
        }
    }

    
    if([gw Blackboard].PickupObject!=nil)
    {
        [gw Blackboard].DropObject=nil;
                        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        if(gw.Blackboard.SelectedObjects.count == columnBaseValue)
        {
            // TODO: Decide behaviour when the column base amount is selected
        }
        else 
        {
            [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:0];
        }
        if([gw Blackboard].DropObject != nil)
        {
            //tell the picked-up object to mount on the dropobject
            [pl removeAllObjects];
            [pl setObject:[gw Blackboard].DropObject forKey:MOUNT];
            [[gw Blackboard].PickupObject handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
            
            [[gw Blackboard].PickupObject handleMessage:kDWputdown andPayload:nil withLogLevel:0];         
            [[gw Blackboard].PickupObject logInfo:@"this object was mounted" withData:0];
            [[gw Blackboard].DropObject logInfo:@"mounted object on this go" withData:0];
            
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        }
        else
        {
            if(gw.Blackboard.SelectedObjects.count == columnBaseValue)
            {
                for(int goC=0; goC<gw.Blackboard.SelectedObjects.count; goC++)
                {
                    DWGameObject *go = [gw.Blackboard.SelectedObjects objectAtIndex:goC];
                    [go handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:0];
                }
            }
            [[gw Blackboard].PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:0];
        }
        [gw Blackboard].PickupObject = nil;
    }
    potentialTap=NO;
}
-(void) dealloc
{
    //write log on problem switch
    [gw writeLogBufferToDiskWithKey:@"PlaceValue"];
    
    //tear down
    [gw release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [solutionsDef release];
    [columnInfo release];
    
    [super dealloc];
}

@end
