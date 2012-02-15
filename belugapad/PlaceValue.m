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

static float kPropXNetSpace=0.087890625f;
static float kPropYColumnOrigin=0.75f;
static float kCageYOrigin=0.08f;

@implementation PlaceValue

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    
    PlaceValue *layer=[PlaceValue node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id)init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        [self setupBkgAndTitle];

        
        [self listProblemFiles];
        [self readPlist];
        
        //setup daemon
        daemon=[[Daemon alloc] initWithLayer:self andRestingPostion:ccp(kPropXDaemonRest*lx, kPropXDaemonRest*lx) andLy:ly];
        
        [self populateGW];

        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [self schedule:@selector(doUpdate:) interval:1.0f/kScheduleUpdateLoopTFPS];
    
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        // Set the lastCount to 0 - this is for counting problems.
        
        lastCount = 0; 
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
	[gw doUpdate:delta];
    [daemon doUpdate:delta];
    
    if(autoMoveToNextProblem)
    {
        timeToAutoMoveToNextProblem+=delta;
        if(timeToAutoMoveToNextProblem>=kTimeToAutoMove)
        {
            [self resetToNextProblem];
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
//    numberofIntegerColumns = 1;
//    numberofDecimalColumns = 0;
//    ropesforColumn = 5;
//    rows = 5;
//    defaultColumn = 1.0f;
    currentColumn = 1.0f;
    touching = NO;
}

-(void)populateGW
{
    gw = [[DWGameWorld alloc] initWithGameScene:self];
    
    float ropeWidth = kPropXNetSpace*lx;
    CGPoint columnOrigin = ccp(cx-((ropeWidth*ropesforColumn)/2.0f)+(ropeWidth/2.0f), ly*kPropYColumnOrigin); 

    for (int iRow=0; iRow<rows; iRow++)
    {
        NSMutableArray *RowArray = [[NSMutableArray alloc] init];        
        [gw.Blackboard.AllStores addObject:RowArray];
        
        CGPoint rowOrigin=ccp(columnOrigin.x, columnOrigin.y-(iRow*ropeWidth)); 
        
        for(int iRope=0; iRope<ropesforColumn; iRope++)
        {
            CGPoint containerOrigin=ccp(rowOrigin.x+(iRope*ropeWidth), rowOrigin.y);
            DWGameObject *go = [gw addGameObjectWithTemplate:@"TplaceValueContainer"];
            [[go store] setObject:[NSNumber numberWithFloat:containerOrigin.x] forKey:POS_X];
            [[go store] setObject:[NSNumber numberWithFloat:containerOrigin.y] forKey:POS_Y];
            [[go store] setObject:[NSNumber numberWithFloat:iRow] forKey:PLACEVALUE_ROW];
            [[go store] setObject:[NSNumber numberWithFloat:1] forKey:PLACEVALUE_COLUMN];
            [[go store] setObject:[NSNumber numberWithFloat:iRope] forKey:PLACEVALUE_ROPE];
            DLog(@"containerorigin x %f y %f", containerOrigin.x, containerOrigin.y);
            
            [RowArray addObject:go];
            
        }
    }
    
    // create cage
    DWGameObject *colCage = [gw addGameObjectWithTemplate:@"TplaceValueCage"];
    [[colCage store] setObject:[NSNumber numberWithFloat:cx] forKey:POS_X];
    [[colCage store] setObject:[NSNumber numberWithFloat:ly*kCageYOrigin] forKey:POS_Y];

    
    for(int i=0; i<(initObjects.count); i++)
    {
        NSDictionary *curDict = [initObjects objectAtIndex:i];
        int insCol = [[curDict objectForKey:PUT_IN_COL] intValue];
        int insRow = [[curDict objectForKey:PUT_IN_ROW] intValue];
        int count = [[curDict objectForKey:NUMBER] intValue];
        
        for(int i=0; i<count; i++)
        {
            DWGameObject *block = [gw addGameObjectWithTemplate:@"TplaceValueObject"];
            
            NSDictionary *pl = [NSDictionary dictionaryWithObject:[[gw.Blackboard.AllStores objectAtIndex:insRow] objectAtIndex:i] forKey:MOUNT];
            
            [block handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
            
        }
        DLog(@"col %d, rows %d, count %d", insCol, insRow, count);
    }

    
}

-(void)setupBkgAndTitle
{
    CCSprite *bkg=[CCSprite spriteWithFile:@"bg-ipad.png"];
    [bkg setPosition:ccp(cx, cy)];
    [self addChild:bkg z:0];
    
    problemCompleteLabel=[CCLabelTTF labelWithString:@"" fontName:TITLE_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemCompleteLabel setColor:kLabelCompleteColor];
    [problemCompleteLabel setPosition:ccp(cx, cy*kLabelCompletePVYOffsetHalfProp)];
    [problemCompleteLabel setVisible:NO];
    [self addChild:problemCompleteLabel z:5];
    
    CCSprite *btnFwd=[CCSprite spriteWithFile:@"btn-fwd.png"];
    [btnFwd setPosition:kButtonNextToolPos];
    [self addChild:btnFwd z:2];
    
    
}
-(void) resetToNextProblem
{
    //write log on problem switch
    [gw writeLogBufferToDiskWithKey:@"PlaceValue"];
    
    //tear down
    [gw release];
    
    gw=nil;
    
    [daemon release];
    
    [self removeAllChildrenWithCleanup:YES];
    
    currentProblemIndex++;
    if(currentProblemIndex>=[problemFiles count])
        currentProblemIndex=0;
    
    [solutionsDef release];
    solutionsDef=nil;
    
    
    //set up
    touching=NO;
    
    [self setupBkgAndTitle];

    [self readPlist];
    
        daemon=[[Daemon alloc] initWithLayer:self andRestingPostion:ccp(kPropXDaemonRest*lx, kPropXDaemonRest*lx) andLy:ly];

    [self populateGW];
    
    [gw Blackboard].hostCX = cx;
    [gw Blackboard].hostCY = cy;
    [gw Blackboard].hostLX = lx;
    [gw Blackboard].hostLY = ly;

    [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
    
    // Set the lastCount to 0 - this is for counting problems.
    
    lastCount = 0; 
    
}

-(void)listProblemFiles
{
    currentProblemIndex=0;
    
    NSString *broot=[[NSBundle mainBundle] bundlePath];
    NSArray *allFiles=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:broot error:nil];
    problemFiles=[allFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH 'placevalue-problem'"]];
    
    [problemFiles retain];
}
-(void)readPlist
{
    NSString *broot=[[NSBundle mainBundle] bundlePath];
    NSString *pfile=[broot stringByAppendingPathComponent:[problemFiles objectAtIndex:currentProblemIndex]];
	NSDictionary *pdef=[NSDictionary dictionaryWithContentsOfFile:pfile];
	
    //DLog(@"started problem: %@", pfile);
    [gw logInfo:[NSString stringWithFormat:@"started problem: %@", pfile] withData:0];
    
    //render problem label
    problemDescLabel=[CCLabelTTF labelWithString:[pdef objectForKey:PROBLEM_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    //[problemDescLabel setColor:kLabelTitleColor];
    
    [self addChild:problemDescLabel];
    
    // set the vars for our gw!
    
    numberofIntegerColumns = [[pdef objectForKey:NUMBER_INTEGER_COLS] intValue];
    numberofDecimalColumns = [[pdef objectForKey:NUMBER_DECIMAL_COLS] intValue];
    ropesforColumn = [[pdef objectForKey:ROPES_PER_COL] intValue];
    rows = [[pdef objectForKey:ROWS_PER_COL] intValue];
    defaultColumn = [[pdef objectForKey:DEFAULT_COL] floatValue];
    
    DLog(@"intcol %d deccol %d ropes %d rows %d defaultcol %f", numberofIntegerColumns, numberofDecimalColumns, ropesforColumn, rows, defaultColumn);
    
    //create problem file name
    CCLabelBMFont *flabel=[CCLabelBMFont labelWithString:[problemFiles objectAtIndex:currentProblemIndex] fntFile:@"visgrad1.fnt"];
    [flabel setPosition:kDebugProblemLabelPos];
    [flabel setOpacity:kDebugLabelOpacity];
    [self addChild:flabel];
    
    //objects
    NSArray *objects=[pdef objectForKey:INIT_OBJECTS];
    initObjects = objects;
    
    //retain solutions dict
    solutionsDef=[pdef objectForKey:SOLUTION];
    [solutionsDef retain];
    
    NSNumber *rMode=[pdef objectForKey:REJECT_MODE];
    if (rMode) rejectMode=[rMode intValue];
    
    NSNumber *eMode=[pdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
    
    //show commit button if evalOnCommit
    if(evalMode==kProblemEvalOnCommit)
    {
        CCSprite *commitBtn=[CCSprite spriteWithFile:@"commit.png"];
        [commitBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), kPropXCommitButtonPadding*lx)];
        [self addChild:commitBtn];
    }

    
}

-(void)problemStateChanged
{
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
        }
            DLog(@"(COUNT_SEQUENCE) Selected %d lastCount %d", gw.Blackboard.SelectedObjects.count, lastCount);
    }
    
    if(evalMode == kProblemEvalAuto)
    {
        [self evalProblem];
    }
}

-(void)evalProblem
{
    
    NSString *solutionType = [solutionsDef objectForKey:SOLUTION_TYPE];
    //int result;
    DLog(@"evalProblem called for problem type: %@", solutionType);
    
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
    DLog(@"problem complete"); 
    [problemCompleteLabel setString:@"problem complete! well done!"];
    autoMoveToNextProblem=YES;
    [problemCompleteLabel setVisible:YES];    
}
-(void)doIncorrect
{
    DLog(@"problem incomplete"); 
    [problemCompleteLabel setString:@"problem incomplete."];
    autoHideStatusLabel=YES;
    [problemCompleteLabel setVisible:YES];
    [gw handleMessage:kDWdeselectAll andPayload:nil withLogLevel:0];
}
-(void)evalProblemCountSeq
{
    if(lastCount == [[solutionsDef objectForKey:SOLUTION_VALUE] intValue])
    {
        DLog(@"(COUNT_SEQUENCE) match");
        [self doWinning];
    }
    else if(lastCount != [[solutionsDef objectForKey:SOLUTION_VALUE] intValue] && evalMode==kProblemEvalOnCommit)
    {
        [self doIncorrect];
    }
}
-(void)evalProblemTotalCount
{
    int totalCount=0;
    int expectedCount = [[solutionsDef objectForKey:SOLUTION_VALUE] intValue];
    for (int i=0; i<gw.Blackboard.AllStores.count; i++)
    {
        for(int o=0; o<[[gw.Blackboard.AllStores objectAtIndex:i]count]; o++)
        {
            DWGameObject *goC = [[gw.Blackboard.AllStores objectAtIndex:(i)] objectAtIndex:o];
            if([[goC store] objectForKey:MOUNTED_OBJECT])
            {
                totalCount++;
                DLog(@"(TOTAL_COUNT) Found block in row %d col %d (count %d)", i, o, totalCount);
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
    int countAtRow[gw.Blackboard.AllStores.count];
    
    for (int i=0; i<gw.Blackboard.AllStores.count; i++)
    {
        countAtRow[i] = 0;
    }
    
    for (int i=0; i<gw.Blackboard.AllStores.count; i++)
    {
        for(int o=0; o<[[gw.Blackboard.AllStores objectAtIndex:i]count]; o++)
        {
            DWGameObject *goC = [[gw.Blackboard.AllStores objectAtIndex:(i)] objectAtIndex:o];
            if([[goC store] objectForKey:MOUNTED_OBJECT])
            {
                countAtRow[i] = countAtRow[i] + 1;
                DLog(@"(MATRIX_MATCH) Found %d blocks on row %d", countAtRow[i], i);
            }   
        }
    }
    
    NSArray *solutionMatrix = [solutionsDef objectForKey:SOLUTION_MATRIX];
    int solutionsFound = 0;
    
    
    for(int o=0; o<solutionMatrix.count; o++)
    {
        NSDictionary *solDict = [solutionMatrix objectAtIndex:o];
        int curRow = [[solDict objectForKey:PUT_IN_ROW] intValue];
        
        DLog(@"(MATRIX_MATCH) Found in this row: %d", countAtRow[curRow]);
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

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    // set the touch start pos for evaluation
    touchStartPos = location;
    
    [daemon setMode:kDaemonModeFollowing];
    [daemon setTarget:location];    
    
    if(location.x>kButtonNextToolHitXOffset && location.y>kButtonToolbarHitBaseYOffset)
    {
    
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.3f scene:[IceDiv scene]]];
    }
    else if (location.x<cx && location.y > kButtonToolbarHitBaseYOffset)
    {
        [self resetToNextProblem];
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
        
        //broadcast search for pickup object gw
        [gw handleMessage:kDWareYouAPickupTarget andPayload:pl withLogLevel:0];
        
        if([gw Blackboard].PickupObject!=nil)
        {
            
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
    [daemon setTarget:location];
    
    if([BLMath DistanceBetween:touchStartPos and:touchEndPos] >= fabs(kTapSlipResetThreshold) && potentialTap)
    {
        DLog(@"reset tap");
        touchStartPos = ccp(0, 0);
        touchEndPos = ccp(0, 0);
        potentialTap = NO;
    }

    
    if([gw Blackboard].PickupObject!=nil)
    {
        //mod location by pickup offset
        location=[BLMath SubtractVector:[gw Blackboard].PickupOffset from:location];
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [[gw Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:pl withLogLevel:-1];
    }

}
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    // set the touch end position for evaluation
    touchEndPos = location;
    
    [daemon setTarget:location];
    [daemon setMode:kDaemonModeWaiting];
    
    // evaluate the distance between start/end pos.
    
    if([BLMath DistanceBetween:touchStartPos and:touchEndPos] < fabs(kTapSlipThreshold) && potentialTap)
        {
            DLog(@"register tap - start/end positions were under %f", kTapSlipThreshold);
            [[gw Blackboard].PickupObject handleMessage:kDWswitchSelection andPayload:nil withLogLevel:0];
        }
    
    if([gw Blackboard].PickupObject!=nil)
    {
        [gw Blackboard].DropObject=nil;
                        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:0];
        
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
            [[gw Blackboard].PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:0];
        }
        [gw Blackboard].PickupObject = nil;
    }
    potentialTap=NO;
}
@end
