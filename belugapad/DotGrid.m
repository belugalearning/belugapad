//
//  DotGrid.m
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DotGrid.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "DWDotGridAnchorGameObject.h"
#import "DWDotGridHandleGameObject.h"
#import "DWDotGridTileGameObject.h"
#import "DWDotGridShapeGameObject.h"
#import "DWDotGridShapeGroupGameObject.h"
#import "DWNWheelGameObject.h"
#import "BLMath.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "LoggingService.h"
#import "UsersService.h"
#import "AppDelegate.h"

@interface DotGrid()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation DotGrid
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
        
        gw = [[DWGameWorld alloc] initWithGameScene:self];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        loggingService = ac.loggingService;
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [self readPlist:pdef];
        [self populateGW];
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        debugLogging=NO;
        
        gw.Blackboard.inProblemSetup = NO;        
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
    
    if(disableDrawing && drawMode==kAnyStartAnchorValid)
    {
        if(isMovingDown)
            [anchorLayer setPosition:ccp(anchorLayer.position.x,anchorLayer.position.y+10)];
            
        if(isMovingUp)
            [anchorLayer setPosition:ccp(anchorLayer.position.x,anchorLayer.position.y-10)];
            
        if(isMovingLeft)
            [anchorLayer setPosition:ccp(anchorLayer.position.x+10,anchorLayer.position.y)];
        
        if(isMovingRight)
            [anchorLayer setPosition:ccp(anchorLayer.position.x-10,anchorLayer.position.y)];
    }
    
//    if(!sumWheel && [numberWheels count]>=2)
//        [self createSumWheel];
    
    if([self checkForCorrectShapeSizes])
        [self createAllWheels];
    
}



#pragma mark - gameworld population
-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    // All our stuff needs to go into vars to read later
    
    drawMode=[[pdef objectForKey:DRAW_MODE] intValue];
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    
    evalType=[[pdef objectForKey:DOTGRID_EVAL_TYPE] intValue];
    
    if(evalType==kProblemFactorDimensions) // factor dimensions eval
    {
        //force into check dimensions eval, and create the factors
        evalType=kProblemCheckDimensions;
        
        NSNumber *ft=[pdef objectForKey:@"DOTGRID_EVAL_FACTORS_OF"];
        if(ft)
        {
            int ftmax=[ft intValue];
            NSMutableArray *reqdFactorShapes=[[NSMutableArray alloc] init];
            
            for(int i=1; i<ftmax; i++)
            {
                if(!(ftmax % i))
                {
                    //this is a factor, create an x/y array with these numbers
                    NSArray *fs=[NSArray arrayWithObjects:[NSNumber numberWithInt:i], [NSNumber numberWithInt:ftmax/i], nil];
                    [reqdFactorShapes addObject:fs];
                }
            }
            
            reqShapes=reqdFactorShapes;
        }
    }
    else if([pdef objectForKey:REQUIRED_SHAPES])
    {
        //if not factors eval, check for required shapes
        reqShapes=[pdef objectForKey:REQUIRED_SHAPES];
        [reqShapes retain];
    }
    
    
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    evalDividend=[[pdef objectForKey:DOTGRID_EVAL_DIVIDEND] intValue];
    evalDivisor=[[pdef objectForKey:DOTGRID_EVAL_DIVISOR] intValue];
    evalTotalSize=[[pdef objectForKey:DOTGRID_EVAL_TOTALSIZE] intValue];
    showDraggableBlock=[[pdef objectForKey:SHOW_DRAGGABLE_BLOCK]boolValue];
    renderWidthHeightOnShape=[[pdef objectForKey:RENDER_SHAPE_DIMENSIONS]boolValue];
    selectWholeShape=[[pdef objectForKey:SELECT_WHOLE_SHAPE]boolValue];
    useShapeGroups=[[pdef objectForKey:USE_SHAPE_GROUPS]boolValue];
    shapeGroupSize=[[pdef objectForKey:SHAPE_GROUP_SIZE]floatValue];
    shapeBaseSize=[[pdef objectForKey:SHAPE_BASE_SIZE]floatValue];
    disableDrawing=[[pdef objectForKey:DISABLE_DRAWING]boolValue];
    solutionNumber=[[pdef objectForKey:SOLUTION_VALUE]intValue];
    autoAddition=[[pdef objectForKey:AUTO_UPDATE_WHEEL]boolValue];
    showMoreOrLess=[[pdef objectForKey:SHOW_MORE_LESS_ARROWS]boolValue];
    isIntroPlist=[[pdef objectForKey:IS_INTRO_PLIST]boolValue];
    nonPropEvalX=[[pdef objectForKey:DOTGRID_EVAL_NONPROP_X]intValue];
    nonPropEvalY=[[pdef objectForKey:DOTGRID_EVAL_NONPROP_Y]intValue];
    
    numberWheelComponents=[[NSString stringWithFormat:@"%d", solutionNumber] length];
    
    showCount=[pdef objectForKey:SHOW_COUNT];
    
    if([pdef objectForKey:ANCHOR_SPACE])
        spaceBetweenAnchors=[[pdef objectForKey:ANCHOR_SPACE] intValue];
    else 
        spaceBetweenAnchors=74;
    
    if(spaceBetweenAnchors==85)
        spaceBetweenAnchors=74;

    if(spaceBetweenAnchors==80)
        spaceBetweenAnchors=74;


    
    startX=[[pdef objectForKey:START_X] intValue];
    startY=[[pdef objectForKey:START_Y] intValue];
    if([pdef objectForKey:INIT_OBJECTS])initObjects=[pdef objectForKey:INIT_OBJECTS];
    if(initObjects)[initObjects retain];
    if([pdef objectForKey:HIDDEN_ROWS])hiddenRows=[pdef objectForKey:HIDDEN_ROWS];
    if(hiddenRows)[hiddenRows retain];
    if([pdef objectForKey:DO_NOT_SIMPLIFY_FRACTIONS])doNotSimplifyFractions=[[pdef objectForKey:DO_NOT_SIMPLIFY_FRACTIONS]boolValue];
    else doNotSimplifyFractions=NO;
   
    
    showNumberWheel=[[pdef objectForKey:SHOW_NUMBERWHEEL_FOR_SHAPES]boolValue];
    showCountBubble=[[pdef objectForKey:SHOW_COUNT_BUBBLE]boolValue];
    
    if(showNumberWheel)
        numberWheels=[[NSMutableArray alloc]init];
    
    if(isIntroPlist)
    {
        spaceBetweenAnchors=74;
        showCount=@"SHOW_FRACTION";
        useShapeGroups=NO;
        drawMode=kAnyStartAnchorValid;
        evalMode=kProblemEvalAuto;
        evalType=kProblemIntroPlist;
        renderWidthHeightOnShape=YES;
        disableDrawing=YES;
        showNumberWheel=NO;
        showCountBubble=NO;
        autoAddition=NO;
        doNotSimplifyFractions=NO;
        showDraggableBlock=YES;
    }
    if(evalType==kProblemGridMultiplication)
    {
        showMoreOrLess=YES;
    }
    
}

-(void)populateGW
{
    gameState=kNoState;
    dotMatrix=[[NSMutableArray alloc]init];
    renderLayer = [[CCLayer alloc] init];
    anchorLayer = [[CCLayer alloc]init];
    [self.ForeLayer addChild:renderLayer];
    [self.ForeLayer addChild:anchorLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    

    float xStartPos=spaceBetweenAnchors*1.8;
    
    int anchorsOnX=(lx-spaceBetweenAnchors*2)/spaceBetweenAnchors;
    int anchorsOnY=(ly-spaceBetweenAnchors*2)/spaceBetweenAnchors;

    
    if(disableDrawing && drawMode==kAnyStartAnchorValid){
        anchorsOnX=anchorsOnX*3;
        anchorsOnY=anchorsOnY*3;
    }
    for (int iRow=0; iRow<anchorsOnX; iRow++)
    {
        NSMutableArray *currentCol=[[NSMutableArray alloc]init];
        BOOL currentRowHidden=NO;
        
        for(int iCol=0; iCol<anchorsOnY; iCol++)
        {
            // create our start position and gameobject
            float yStartPos=(iCol+1)*spaceBetweenAnchors;
            DWDotGridAnchorGameObject *anch = [DWDotGridAnchorGameObject alloc];
            [gw populateAndAddGameObject:anch withTemplateName:@"TdotgridAnchor"];
            anch.Position=ccp(xStartPos,yStartPos);
            anch.myXpos=iRow;
            anch.myYpos=iCol;
            anch.RenderLayer=anchorLayer;
            
            // set the hidden property for every anchor on this row if 
            if(hiddenRows && [hiddenRows objectForKey:[NSString stringWithFormat:@"%d", iCol]]) {
                currentRowHidden=[[hiddenRows objectForKey:[NSString stringWithFormat:@"%d", iCol]] boolValue];
                if(currentRowHidden) {
                    anch.Hidden=YES;
                    anch.Disabled=YES;
                }
            }
        
            
            
            // check - if the game is in a specified start anchor mode
            // if it is, then our gameobject needs to have properties set!
            if((iRow==startX && iCol==startY) && drawMode==kSpecifiedStartAnchor)
            {
                anch.Disabled=NO;
                
                //anch.StartAnchor=YES;
                //NSLog(@"THIS ANCHOR IS *ENABLED* (x %d / y %d)", anch.myXpos, anch.myYpos);
            }
            else if((iRow==0 && iCol==0) && drawMode==kNoDrawing)
            {
                anch.Disabled=YES;
            }
            else if((iRow!=startX || iCol!=startY) && (drawMode==kNoDrawing || drawMode==kStartAnchor)) {
                //NSLog(@"THIS ANCHOR IS *DISABLED* (x %d / y %d)", anch.myXpos, anch.myYpos);
                anch.Disabled=YES;
            }

            [currentCol addObject:anch];
            [anch release];

        }
        
        xStartPos=xStartPos+spaceBetweenAnchors;
        [dotMatrix addObject:currentCol];
        [currentCol release];
        
    }    
    
    // if we're using startanchor mode then we need to draw a 1x1 square from the startx/y pos
    if(drawMode==kStartAnchor)
    {
        gw.Blackboard.FirstAnchor=[[dotMatrix objectAtIndex:startX] objectAtIndex:startY];
        gw.Blackboard.LastAnchor=[[dotMatrix objectAtIndex:startX+1] objectAtIndex:startY+1];
        
        [self checkAnchorsAndUseResizeHandle:YES andShowMove:NO andPrecount:nil andDisabled:NO];
    }
    
    for(int i=0;i<[initObjects count];i++)
    {
        NSMutableDictionary *curObject=[initObjects objectAtIndex:i];
        
        int curStartX=[[curObject objectForKey:START_X] intValue];
        int curStartY=[[curObject objectForKey:START_Y] intValue];
        int curEndX=[[curObject objectForKey:END_X] intValue];
        int curEndY=[[curObject objectForKey:END_Y] intValue];
        NSArray *preCountedTiles=[curObject objectForKey:PRE_COUNTED_TILES];
        BOOL disabled = [[curObject objectForKey:DISABLE_COUNTING] boolValue];
        BOOL showMove = [[curObject objectForKey:SHOW_MOVE] boolValue];
        BOOL showResize = [[curObject objectForKey:SHOW_RESIZE] boolValue];
        
        gw.Blackboard.FirstAnchor=[[dotMatrix objectAtIndex:curStartX] objectAtIndex:curStartY];
        gw.Blackboard.LastAnchor=[[dotMatrix objectAtIndex:curEndX] objectAtIndex:curEndY];

        
        [self checkAnchorsAndUseResizeHandle:showResize andShowMove:showMove andPrecount:preCountedTiles andDisabled:disabled];
    }
    
    if(showDraggableBlock)
    {
        dragBlock=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/dotgrid/DG_sq40.png")];
        [dragBlock setPosition:ccp(55,650)];
        [renderLayer addChild:dragBlock];
    }

    
    if(evalType==kProblemNonProportionalGrid)
    {
        showDraggableBlock=NO;
        disableDrawing=YES;
        useShapeGroups=YES;
        shapeBaseSize=1;
        drawMode=0;
        solutionNumber=nonPropEvalX*nonPropEvalY;
        
        numberWheelComponents=[[NSString stringWithFormat:@"%d", solutionNumber] length];
        int xlen=[[NSString stringWithFormat:@"%d", nonPropEvalX] length];
        int ylen=[[NSString stringWithFormat:@"%d", nonPropEvalY] length];
        
        NSMutableArray *reqNonPropShapes=[[NSMutableArray alloc]init];
        NSArray *fs=[NSArray arrayWithObjects:[NSNumber numberWithInt:xlen], [NSNumber numberWithInt:ylen], nil];
        [reqNonPropShapes addObject:fs];
        
        reqShapes=reqNonPropShapes;
        [reqShapes retain];
        
        int tStartX=1;
        int tStartY=3;
        int tEndX=startX+xlen;
        int tEndY=startY+ylen;
        
        gw.Blackboard.FirstAnchor=[[dotMatrix objectAtIndex:tStartX] objectAtIndex:tStartY];
        gw.Blackboard.LastAnchor=[[dotMatrix objectAtIndex:tEndX] objectAtIndex:tEndY];
        
        
        [self checkAnchorsAndUseResizeHandle:NO andShowMove:NO andPrecount:nil andDisabled:NO];
    }

}

-(void)setupIntroOverlay
{
    introLayer=[[CCLayer alloc]init];
    [self.ForeLayer addChild:introLayer z:100];
    
    introOverlay=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/countingtimer/ct_intro_overlay.png")];
    introCommit=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/HR_Commit_Enabled.png")];
    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"You drew shapes 'n' ting. Press commit to continue."] fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
    
    [introCommit setPosition:ccp(2*cx-40, 2*cy - 30)];
    
    [l setPosition:ccp(cx,cy)];
    [l setColor:ccc3(255,0,0)];
    [introOverlay setPosition:ccp(cx,cy)];
    
    [introLayer addChild:introOverlay];
    [introLayer addChild:introCommit];
    [introLayer addChild:l];
    showingIntroOverlay=YES;
}

#pragma mark - drawing methods
-(void)draw
{
    CGPoint firstAnchor=((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).Position;
    
    CGPoint lastAnchor=((DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor).Position;
    
    firstAnchor=[anchorLayer convertToWorldSpace:firstAnchor];
    lastAnchor=[anchorLayer convertToWorldSpace:lastAnchor];
    
    CGPoint nodeLastTouch=lastTouch;
    
    if(gameState==kStartAnchor)
    {
        CGPoint points[4];
        points[0]=firstAnchor;
        points[2]=nodeLastTouch;
        points[1]=CGPointMake(points[2].x, points[0].y);
        points[3]=CGPointMake(points[0].x, points[2].y);
        
        CGPoint *first=&points[0];
        
        ccDrawPoly(first, 4, YES);
        
        points[2]=lastAnchor;
        points[1]=CGPointMake(points[2].x, points[0].y);
        points[3]=CGPointMake(points[0].x, points[2].y);
        
        ccDrawFilledPoly(first, 4, ccc4FFromccc4B(ccc4(255,255,255,5)));
        
        
    }
    
    if(gameState==kResizeShape)
    {
        
        CGPoint points[4];
        points[0]=firstAnchor;
        
        points[2]=nodeLastTouch;
        points[1]=CGPointMake(points[2].x, points[0].y);
        points[3]=CGPointMake(points[0].x, points[2].y);
        
        CGPoint *first=&points[0];
        
        ccDrawPoly(first, 4, YES);
        
        points[2]=lastAnchor;
        points[1]=CGPointMake(points[2].x, points[0].y);
        points[3]=CGPointMake(points[0].x, points[2].y);
        
        ccDrawFilledPoly(first, 4, ccc4FFromccc3B(ccc3(230,0,0)));
    }
}
-(void)checkAnchors
{
    [self checkAnchorsAndUseResizeHandle:YES andShowMove:NO andPrecount:nil andDisabled:NO];
}
-(void)checkAnchorsAndUseResizeHandle:(BOOL)showResize andShowMove:(BOOL)showMove andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled
{
    // only run if we have a first and last anchor point
    if(gw.Blackboard.FirstAnchor && gw.Blackboard.LastAnchor)
    {
        OrderedAnchors orderedAnchs=[self checkAndChangeAnchorPoints:(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor and:(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor];
        NSMutableArray *anchorsForShape=[[NSMutableArray alloc]init];
        DWDotGridAnchorGameObject *anchStart=orderedAnchs.firstAnchor;
        DWDotGridAnchorGameObject *anchEnd=orderedAnchs.lastAnchor;
        BOOL failedChecksHidden=NO;
        BOOL failedChecksExistingTile=NO;
        
        anchEnd.resizeHandle=YES;
        
        // if the start X point is to the left of the end X point
        if(anchStart.myXpos < anchEnd.myXpos)
        {
            // start the loop
            for(int x=anchStart.myXpos;x<anchEnd.myXpos;x++)
            {
                // then check whether we're going up or down
                if(anchStart.myYpos < anchEnd.myYpos)
                {
                    // this is if the end point is higher in the grid
                    for(int y=anchStart.myYpos;y<anchEnd.myYpos;y++)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        // if current anchor is disabled AND we're not in problem setup AND not in the game state we want OR if the current anchor already has a tile on it

                        if(((curAnch.Disabled || curAnch.Hidden) && !gw.Blackboard.inProblemSetup && !gameState==kStartAnchor))failedChecksHidden=YES;
                        if(curAnch.tile)failedChecksExistingTile=YES;

//                        if(x==anchEnd.myXpos-1 && y==anchEnd.myYpos-1 && showResize)
//                            curAnch.resizeHandle=YES;
//                        else
//                            curAnch.resizeHandle=NO;
                        
                        if(x==anchEnd.myXpos-1 && y==anchStart.myYpos && showResize)
                            curAnch.resizeHandle=YES;
                        else
                            curAnch.resizeHandle=NO;
                        
                        if(x==anchStart.myXpos && y==anchEnd.myYpos-1 && showMove)
                            curAnch.moveHandle=YES;
                        else
                            curAnch.moveHandle=NO;
                        
                        [anchorsForShape addObject:curAnch];
                    }
                }
                else {
                    // and this is lower
                    for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        
                        if(((curAnch.Disabled || curAnch.Hidden) && !gw.Blackboard.inProblemSetup && !gameState==kStartAnchor))failedChecksHidden=YES;
                        if(curAnch.tile)failedChecksExistingTile=YES;

//                        if(x==anchEnd.myXpos-1 && y==anchEnd.myYpos+1 && showResize)
//                            curAnch.resizeHandle=YES;
//                        else
//                            curAnch.resizeHandle=NO;
                        
                        if(x==anchEnd.myXpos-1 && y==anchEnd.myYpos && showResize)
                            curAnch.resizeHandle=YES;
                        else
                            curAnch.resizeHandle=NO;
                        
                        if(x==anchStart.myXpos && y==anchStart.myYpos-1 && showMove)
                            curAnch.moveHandle=YES;
                        else
                            curAnch.moveHandle=NO;
                        
                        
                        [anchorsForShape addObject:curAnch];
                    } 
                }
            }
        }
        else {
            // start the loop
            for(int x=anchStart.myXpos-1;x>anchEnd.myXpos-1;x--)
            {
                // then check whether we're going up or down
                if(anchStart.myYpos < anchEnd.myYpos)
                {
                    // this is if the end point is higher in the grid
                    for(int y=anchStart.myYpos;y<anchEnd.myYpos;y++)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        if(((curAnch.Disabled || curAnch.Hidden) && !gw.Blackboard.inProblemSetup && !gameState==kSpecifiedStartAnchor))failedChecksHidden=YES;
                        if(curAnch.tile)failedChecksExistingTile=YES;
                        [anchorsForShape addObject:curAnch];

                        if(x==anchStart.myXpos-1 && y==anchStart.myYpos && showResize)
                            curAnch.resizeHandle=YES;
                        else
                            curAnch.resizeHandle=NO;

                        if(x==anchEnd.myXpos && y==anchEnd.myYpos-1 && showMove)
                            curAnch.moveHandle=YES;
                        else
                            curAnch.moveHandle=NO;
                    }
                }
                else {
                    // and this is lower
                    for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        if(((curAnch.Disabled || curAnch.Hidden) && !gw.Blackboard.inProblemSetup && !gameState==kSpecifiedStartAnchor))failedChecksHidden=YES;
                        if(curAnch.tile)failedChecksExistingTile=YES;
                        [anchorsForShape addObject:curAnch];
                        
                        if(x==anchEnd.myXpos+1 && y==anchEnd.myYpos && showResize)
                            curAnch.resizeHandle=YES;
                        else
                            curAnch.resizeHandle=NO;
                        
                        if(x==anchEnd.myXpos && y==anchStart.myYpos-1 && showMove)
                            curAnch.moveHandle=YES;
                        else
                            curAnch.moveHandle=NO;
                        
                    }
                }
            }

        }
        
        if(failedChecksExistingTile||failedChecksHidden)
        {
            if(failedChecksExistingTile) [loggingService logEvent:BL_PA_DG_TOUCH_END_INVALID_CREATE_EXISTING_TILE withAdditionalData:nil];
            if(failedChecksHidden) [loggingService logEvent:BL_PA_DG_TOUCH_END_INVALID_CREATE_HIDDEN withAdditionalData:nil];
            return;
        }
        
        if(!useShapeGroups)
            [self createShapeWithAnchorPoints:anchorsForShape andPrecount:preCountedTiles andDisabled:Disabled];
        else
            [self createShapeGroupAndShapesWithAnchorPoints:anchorsForShape andPrecount:preCountedTiles andDisabled:Disabled];
        
        
//        for(int i=0;i<[anchorsForShape count];i++)
//        {
//            DWDotGridAnchorGameObject *wanch = [anchorsForShape objectAtIndex:i];
//            NSLog(@"shape in matrix (%d/%d): x %d / y %d", i, [anchorsForShape count], wanch.myXpos, wanch.myYpos);
//        }

        [anchorsForShape release];
    }
}

-(OrderedAnchors)checkAndChangeAnchorPoints:(DWDotGridAnchorGameObject*)fa and:(DWDotGridAnchorGameObject*)la
{
    //DWDotGridAnchorGameObject *fa=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
    //DWDotGridAnchorGameObject *la=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
    
    OrderedAnchors orderedAnchs;
    
    CGPoint bottomLeft=ccp(fa.myXpos, fa.myYpos);
    CGPoint topRight=ccp(la.myXpos, la.myYpos);
    
    int topMostY=0;
    int leftMostX=0;
    int botMostY=0;
    int rightMostX=0;
    
    if(bottomLeft.y<topRight.y)
    {
        topMostY=topRight.y;
        botMostY=bottomLeft.y;
    }
    else
    {
        topMostY=bottomLeft.y;
        botMostY=topRight.y;
    }
    
    if(bottomLeft.x<topRight.x)
    {
        leftMostX=bottomLeft.x;
        rightMostX=topRight.x;
    }
    else
    {
        leftMostX=topRight.x;
        rightMostX=bottomLeft.x;
    }
    
    orderedAnchs.firstAnchor=[[dotMatrix objectAtIndex:leftMostX]objectAtIndex:topMostY];
    orderedAnchs.lastAnchor=[[dotMatrix objectAtIndex:rightMostX]objectAtIndex:botMostY];

    return orderedAnchs;
}

-(void)checkAnchorsOfExistingShape:(DWDotGridShapeGameObject*)thisShape
{
    NSMutableArray *anchorsForShape=[[NSMutableArray alloc]init];
    DWDotGridAnchorGameObject *anchStart=thisShape.firstAnchor;
    DWDotGridAnchorGameObject *anchEnd=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
    OrderedAnchors orderedAnchs=[self checkAndChangeAnchorPoints:anchStart and:anchEnd];
    
    anchStart=orderedAnchs.firstAnchor;
    anchEnd=orderedAnchs.lastAnchor;
    
    BOOL failedChecksHidden=NO;
    BOOL failedChecksExistingTile=NO;
    
    // if the start X point is to the left of the end X point
    if(anchStart.myXpos < anchEnd.myXpos)
    {
        // start the loop
        for(int x=anchStart.myXpos;x<anchEnd.myXpos;x++)
        {
            if(debugLogging)
                NSLog(@"current x %d", x);
            // then check whether we're going up or down
            if(anchStart.myYpos < anchEnd.myYpos)
            {
                // this is if the end point is higher in the grid
                for(int y=anchStart.myYpos;y<anchEnd.myYpos;y++)
                {
                    DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                    // if current anchor is disabled AND we're not in problem setup AND not in the game state we want OR if the current anchor already has a tile on it
                    
                    //if((curAnch.tile || curAnch.Disabled) && !gw.Blackboard.inProblemSetup && (!gameState==kStartAnchor))return;
                    if(curAnch.Hidden)failedChecksHidden=YES;
                    if(curAnch.tile && ![thisShape.tiles containsObject:curAnch.tile])failedChecksExistingTile=YES;
                    
                    if(x==anchEnd.myXpos-1 && y==anchEnd.myYpos && thisShape.resizeHandle)
                        curAnch.resizeHandle=YES;
                    else
                        curAnch.resizeHandle=NO;

                    [anchorsForShape addObject:curAnch];
                }
            }
            else {
                // and this is lower
                for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                {
                    DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                    
                    //if((curAnch.tile || curAnch.Disabled) && !gw.Blackboard.inProblemSetup && (!gameState==kStartAnchor||!gameState==kResizeShape))return;
                    if(curAnch.Hidden)failedChecksHidden=YES;
                    if(curAnch.tile && ![thisShape.tiles containsObject:curAnch.tile])failedChecksExistingTile=YES;
                    if(x==anchEnd.myXpos-1 && y==anchEnd.myYpos && thisShape.resizeHandle)
                        curAnch.resizeHandle=YES;
                    else curAnch.resizeHandle=NO;

                    [anchorsForShape addObject:curAnch];
                } 
            }
        }
    }
    else {
        // start the loop
        for(int x=anchStart.myXpos-1;x>anchEnd.myXpos-1;x--)
        {
            if(debugLogging)
                NSLog(@"current x %d", x);
            // then check whether we're going up or down
            if(anchStart.myYpos < anchEnd.myYpos)
            {
                // this is if the end point is higher in the grid
                for(int y=anchStart.myYpos;y<anchEnd.myYpos;y++)
                {
                    DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                    if(curAnch.Hidden)failedChecksHidden=YES;
                    if(curAnch.tile && ![thisShape.tiles containsObject:curAnch.tile])failedChecksExistingTile=YES;
                    if(x==anchStart.myXpos-1 && y==anchStart.myYpos && thisShape.resizeHandle)
                        curAnch.resizeHandle=YES;
                    else curAnch.resizeHandle=NO;          
                    [anchorsForShape addObject:curAnch];
                    
                }
            }
            else {
                // and this is lower
                for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                {
                    DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                    if(curAnch.Hidden)failedChecksHidden=YES;
                    if(curAnch.tile && ![thisShape.tiles containsObject:curAnch.tile])failedChecksExistingTile=YES;
                    if(x==anchEnd.myXpos+1 && y==anchEnd.myYpos && thisShape.resizeHandle)
                        curAnch.resizeHandle=YES;
                    else curAnch.resizeHandle=NO;
                    [anchorsForShape addObject:curAnch];

                } 
            }
        }
        
    }

    if(failedChecksHidden||failedChecksExistingTile)
    {
        thisShape.resizeHandle.Position=thisShape.lastAnchor.Position;
        [thisShape.resizeHandle handleMessage:kDWupdateSprite];
        if(failedChecksHidden) [loggingService logEvent:BL_PA_DG_TOUCH_END_INVALID_RESIZE_HIDDEN withAdditionalData:nil];
        if(failedChecksExistingTile) [loggingService logEvent:BL_PA_DG_TOUCH_END_INVALID_RESIZE_EXISTING_TILE withAdditionalData:nil];
        return;
    }
    
    for(int i=0;i<[anchorsForShape count];i++)
    {
        DWDotGridAnchorGameObject *wanch = [anchorsForShape objectAtIndex:i];
        
        if(debugLogging)
            NSLog(@"shape in matrix (%d/%d): x %d / y %d", i, [anchorsForShape count], wanch.myXpos, wanch.myYpos);
    }
    
    thisShape.lastAnchor=anchEnd;
    
    [self modifyThisShape:thisShape withTheseAnchors:anchorsForShape];
    
    [anchorsForShape release];
}

-(void)checkAnchorsOfExistingShapeGroup:(DWDotGridShapeGroupGameObject*)thisShapeGroup
{
    gw.Blackboard.FirstAnchor=thisShapeGroup.firstAnchor;
    
    
    [thisShapeGroup handleMessage:kDWdismantle];
    
    [self checkAnchors];
    
}

-(void)createShapeGroupAndShapesWithAnchorPoints:(NSArray*)anchors andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled
{
    if(evalType==kProblemNonProportionalGrid)
    {
        
        DWDotGridShapeGroupGameObject *sGroup=[DWDotGridShapeGroupGameObject alloc];
        [gw populateAndAddGameObject:sGroup withTemplateName:@"TdotgridShapeGroup"];

        int xlen=[[NSString stringWithFormat:@"%d", nonPropEvalX] length];
        int ylen=[[NSString stringWithFormat:@"%d", nonPropEvalY] length];
        
        int remX=nonPropEvalX;
        
        int baseStartX=1;
        if(xlen>1) baseStartX=pow(10, xlen-1);
        
        int baseStartY=1;
        if(ylen>1) baseStartY=pow(10, xlen-1);
        
        int xpos=0;
        
        int tStartX=1;
        int tStartY=3;
        int tEndX=tStartX+xlen;
        int tEndY=tStartY+ylen;
        
        for(int xi=baseStartX; xi>0; xi=xi/10)
        {
            int thisXVal=(remX/xi) * xi;
            int ypos=ylen-1;
            int remY=nonPropEvalY;
            
            for(int yi=baseStartY; yi>0; yi=yi/10)
            {
                int thisYVal=(remY/yi) * yi;
                
                if(thisXVal*thisYVal==0)continue;
                
                //in here create a shape at xpos, ypos with value thisXVal*thisYVal
                NSMutableArray *shapeAnchs=[[NSMutableArray alloc] init];
                DWDotGridAnchorGameObject *a=[[dotMatrix objectAtIndex:tStartX+xpos] objectAtIndex:tStartY+ypos];
                DWDotGridAnchorGameObject *b=[[dotMatrix objectAtIndex:tStartX+xpos+1] objectAtIndex:tStartY+ypos-1];
                
//                DWDotGridAnchorGameObject *a=[[dotMatrix objectAtIndex:tStartX] objectAtIndex:tStartY];
//                DWDotGridAnchorGameObject *b=[[dotMatrix objectAtIndex:tEndX] objectAtIndex:tEndY];
                
                gw.Blackboard.FirstAnchor=a;
                gw.Blackboard.LastAnchor=b;
                
                [shapeAnchs addObject:a];

                DWDotGridShapeGameObject *shape=[self createShapeWithAnchorPoints:shapeAnchs andPrecount:nil andDisabled:NO andGroup:sGroup];
                shape.shapeGroup=sGroup;
                shape.firstAnchor=a;
                
                shape.firstAnchor=[[dotMatrix objectAtIndex:tStartX] objectAtIndex:tStartY];
                shape.lastAnchor=[[dotMatrix objectAtIndex:tEndX] objectAtIndex:tEndY];
//                shape.firstBoundaryAnchor=a;
//                shape.lastBoundaryAnchor=b;
                shape.firstBoundaryAnchor=shape.firstAnchor;
                shape.lastBoundaryAnchor=shape.lastAnchor;

                shape.autoUpdateWheel=autoAddition;
                shape.value=thisXVal*thisYVal;
                shape.ShapeX=thisXVal;
                shape.ShapeY=thisYVal;
                
                NSLog(@"this shape val %d - this y val %d, this x val %d", thisXVal*thisYVal, thisYVal, thisXVal);
                
                [shapeAnchs release];

                
                if(xpos==0)
                {
                    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", thisYVal] fontName:CHANGO fontSize:20.0f];
                    [l setPosition:ccp(a.Position.x-50,a.Position.y+40)];
                    [l setTag:2];
                    [l setOpacity:0];
                    [renderLayer addChild:l];
                    //create y label with thisYVal
                    
                    


                }
                
                if(ypos==ylen-1)
                {
                    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", thisXVal] fontName:CHANGO fontSize:20.0f];
                    [l setPosition:ccp(245+(xpos*75),475)];
                    [l setTag:2];
                    [l setOpacity:0];
                    [renderLayer addChild:l];
                }
                
                ypos--;
                remY-=thisYVal;
            }
            
            //create x label with thisXVal
            
            xpos++;
            remX-=thisXVal;
        }
        
        
        
        
    
        return;
    }
    
    if(shapeBaseSize>0){
        
        DWDotGridShapeGroupGameObject *sGroup=[DWDotGridShapeGroupGameObject alloc];
        [gw populateAndAddGameObject:sGroup withTemplateName:@"TdotgridShapeGroup"];
        
        DWDotGridAnchorGameObject *sAnch=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
        DWDotGridAnchorGameObject *lAnch=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
        
        int sgW=abs(lAnch.myXpos - sAnch.myXpos);
        int sgH=abs(lAnch.myYpos - sAnch.myYpos);
        
        if(sgW<shapeBaseSize && sgH<shapeBaseSize)
        {
            DWDotGridShapeGameObject *shape=[self createShapeWithAnchorPoints:anchors andPrecount:nil andDisabled:NO andGroup:sGroup];
            
            shape.firstBoundaryAnchor=sAnch;
            shape.lastBoundaryAnchor=lAnch;
            
            if(debugLogging)
                NSLog(@"shape group first anch x %d y %d, last anch x %d y %d",sAnch.myXpos, sAnch.myYpos, lAnch.myXpos, lAnch.myYpos);
            
            sGroup.firstAnchor=sAnch;
            sGroup.lastAnchor=lAnch;
            
            [sGroup.shapesInMe addObject:shape];
            
            if(shape.resizeHandle && !sGroup.resizeHandle)
                sGroup.resizeHandle=shape.resizeHandle;
            return;

        }
        
        for(int widthChunk=0; widthChunk<sgW; widthChunk+=shapeBaseSize)
        {
            // 0
            // 10 (if sg is less than 10, won't be hit)
            
            int thisShapeW=shapeBaseSize;
            if(sgW < widthChunk+shapeBaseSize) thisShapeW=sgW-widthChunk;
            
            for (int heightChunk=0; heightChunk<sgH; heightChunk+=shapeBaseSize)
            {
                int thisShapeH=shapeBaseSize;
                if(sgH<heightChunk+shapeBaseSize) thisShapeH=sgH-heightChunk;
                
                //here draw a shape from widthChunk, heightChunk with dimensions thisShapeW, thisShapeH
                int shapeOriginX=sAnch.myXpos+widthChunk;
                int shapeOriginY=sAnch.myYpos-heightChunk-1;
                
                //if(sgH==1)shapeOriginY-=1;

                DWDotGridAnchorGameObject *firstdrawn=nil;
                DWDotGridAnchorGameObject *lastDrawn=nil;
                
                NSMutableArray *shapeAnchs=[[NSMutableArray alloc] init];
                for (DWDotGridAnchorGameObject *a in anchors) {
                    if(a.myXpos>=shapeOriginX && a.myXpos<shapeOriginX+thisShapeW
                       && a.myYpos<=shapeOriginY && a.myYpos>shapeOriginY-thisShapeH)
                    {
                        if(!firstdrawn)firstdrawn=a;
                        lastDrawn=a;
                        
                        [shapeAnchs addObject:a];
                        
                        if(debugLogging)
                            NSLog(@"creating shape at %d, %d", a.myXpos, a.myYpos);
                    }
                }
                
                DWDotGridShapeGameObject *shape=[self createShapeWithAnchorPoints:shapeAnchs andPrecount:nil andDisabled:NO andGroup:sGroup];
                
                [shapeAnchs release];
                
                lastDrawn=[[dotMatrix objectAtIndex:lastDrawn.myXpos+1]objectAtIndex:lastDrawn.myYpos];
                firstdrawn=[[dotMatrix objectAtIndex:firstdrawn.myXpos]objectAtIndex:firstdrawn.myYpos+1];
                
                if(debugLogging)
                    NSLog(@"firstdrawn x %d y %d, lastdrawn x %d y %d", firstdrawn.myXpos, firstdrawn.myYpos, lastDrawn.myXpos, lastDrawn.myYpos);
                
                
                shape.firstBoundaryAnchor=firstdrawn;
                shape.lastBoundaryAnchor=lastDrawn;
                shape.autoUpdateWheel=autoAddition;
                shape.ShapeX=fabsf(firstdrawn.myXpos-lastDrawn.myXpos);
                shape.ShapeY=fabsf(firstdrawn.myYpos-lastDrawn.myYpos);
                
                for(DWDotGridTileGameObject *t in shape.tiles)
                {
                    [t handleMessage:kDWsetupStuff];
                }
                
                
                [sGroup.shapesInMe addObject:shape];
                
                if(shape.resizeHandle && !sGroup.resizeHandle)
                    sGroup.resizeHandle=shape.resizeHandle;
            }
        }
        
        sGroup.firstAnchor=sAnch;
        sGroup.lastAnchor=lAnch;
        sGroup.countLabelType=showCount;
//        
//        int startXPos=0;
//        int endXPos=0;
//        int startYPos=0;
//        int endYPos=0;
//        int lengthOfX=0;
//        int lengthOfY=0;
//        BOOL first=NO;
//        NSMutableArray *theseShapes=[[NSMutableArray alloc]init];
//        
//        for(DWDotGridAnchorGameObject *a in anchors)
//        {
//            if(!first)
//            {
//                startXPos=a.myXpos;
//                startYPos=a.myYpos;
//                endXPos=startXPos;
//                endYPos=startYPos;
//                first=YES;
//            }
//            else
//            {
//                if(a.myXpos<startXPos)
//                    startXPos=a.myXpos;
//                if(a.myYpos<startYPos)
//                    startXPos=a.myYpos;
//                if(a.myXpos>endXPos)
//                    endXPos=a.myXpos;
//                if(a.myYpos>endYPos)
//                    endYPos=a.myYpos;
//            }
//        }
//        
//        lengthOfX=endXPos-startXPos;
//        lengthOfY=endYPos-startYPos;
//        
//        if(lengthOfX>=shapeBaseSize)
//        {
//            float shapesRequired=lengthOfX/shapeBaseSize;
//            float full=(int)shapesRequired;
//            float remainder=shapesRequired-full;
//            
//            if(remainder>0.0f)
//                shapesRequired+=1;
//            
//            for(int i=0;i<shapesRequired;i++)
//            {
//                NSMutableArray *thisShape=[[NSMutableArray alloc]init];
//                [theseShapes addObject:thisShape];
//            }
//            
//            
//
////            for(DWDotGridAnchorGameObject *a in anchors)
////            {
////                if(a.myXpos>=startXPos && a.myXpos<=startXPos+shapeBaseSize)
////                    [thisShap addObject:a];
////            }
//            
//        }
//        
//        if(lengthOfY>=shapeBaseSize)
//        {
//            
//        }
//        
//        NSLog(@"lengthOfX=%d, lengthOfY=%d, startXPos=%d, endXPos=%d, startYPos=%d, endYPos=%d", lengthOfX, lengthOfY, startXPos, endXPos, startYPos, endYPos);
    }
    
    if(shapeGroupSize>0){
        float shapesRequired=[anchors count]/(float)shapeGroupSize;
        float full=(int)shapesRequired;
        float remainder=shapesRequired-full;
        
        if(remainder>0.0f)
            shapesRequired+=1;
        
        //if(shapesRequired<1)shapesRequired++;
        if(debugLogging)
            NSLog(@"shapes required %d - anchor count %d - remainder %g - full %g", (int)shapesRequired, [anchors count], remainder, full);
        
        NSMutableArray *shapeAnchors=[[[NSMutableArray alloc]init]autorelease];
        
        for(int i=0;i<(int)shapesRequired;i++)
        {
            NSMutableArray *shape=[[NSMutableArray alloc]init];
            [shapeAnchors addObject:shape];
        }
        
        
        for(int i=0;i<[anchors count];i++)
        {
            int thisArray=i/shapeGroupSize;
            DWDotGridAnchorGameObject *a=[anchors objectAtIndex:i];
            [[shapeAnchors objectAtIndex:thisArray] addObject:a];
        }
        
        DWDotGridShapeGroupGameObject *shapegrp=[DWDotGridShapeGroupGameObject alloc];
        [gw populateAndAddGameObject:shapegrp withTemplateName:@"TdotgridShapeGroup"];
        
        for(NSMutableArray *a in shapeAnchors)
        {
            DWDotGridShapeGameObject *newShape=[self createShapeWithAnchorPoints:a andPrecount:nil andDisabled:NO andGroup:shapegrp];
            
            [shapegrp.shapesInMe addObject:newShape];
            
            if(newShape.resizeHandle && !shapegrp.resizeHandle)
                shapegrp.resizeHandle=newShape.resizeHandle;
                
        }
        
        shapegrp.firstAnchor=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
        shapegrp.lastAnchor=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
        shapegrp.countLabelType=showCount;
    }
}

-(DWDotGridShapeGameObject*)createShapeWithAnchorPoints:(NSArray*)anchors andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled
{
    return [self createShapeWithAnchorPoints:anchors andPrecount:preCountedTiles andDisabled:Disabled andGroup:nil];
}

-(DWDotGridShapeGameObject*)createShapeWithAnchorPoints:(NSArray*)anchors andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled andGroup:(DWGameObject*)shapeGroup
{
 
    
    OrderedAnchors orderedAnchs=[self checkAndChangeAnchorPoints:(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor and:(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor];
    
    DWDotGridShapeGameObject *shape=[DWDotGridShapeGameObject alloc];
    [gw populateAndAddGameObject:shape withTemplateName:@"TdotgridShape"];
    shape.Disabled=Disabled;
    shape.RenderLayer=anchorLayer;
    shape.firstAnchor=orderedAnchs.firstAnchor;
    shape.lastAnchor=orderedAnchs.lastAnchor;
    //shape.firstAnchor=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
    //shape.lastAnchor=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
    shape.tiles=[[NSMutableArray alloc]init];
    shape.SelectAllTiles=selectWholeShape;
    shape.RenderDimensions=renderWidthHeightOnShape;
    shape.countLabelType=showCount;
    shape.shapeGroup=shapeGroup;
    
    if(showMoreOrLess)
    {
        shape.hintArrowX=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/dotgrid/DG_More_X.png")];
        shape.hintArrowY=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/dotgrid/DG_More_X.png")];
        [shape.hintArrowX setVisible:NO];
        [shape.hintArrowY setVisible:NO];
        
        [shape.RenderLayer addChild:shape.hintArrowX];
        [shape.RenderLayer addChild:shape.hintArrowY];
    }
    
    int numberCounted=0;


        for(int i=0;i<[anchors count];i++)
        {
            DWDotGridAnchorGameObject *curAnch = [anchors objectAtIndex:i];
            curAnch.Disabled=YES;
            DWDotGridTileGameObject *tile = [DWDotGridTileGameObject alloc];
            [gw populateAndAddGameObject:tile withTemplateName:@"TdotgridTile"];
            
            tile.myAnchor=curAnch;
            tile.tileType=kNoBorder;
            tile.tileSize=spaceBetweenAnchors;
            tile.RenderLayer=anchorLayer;
            tile.myShape=shape;
            tile.Position=ccp(curAnch.Position.x+spaceBetweenAnchors/2, curAnch.Position.y+spaceBetweenAnchors/2);
            //[tile handleMessage:kDWsetupStuff];
            [shape.tiles addObject:tile];
            curAnch.tile=tile;
            // if we have pre counting tiles on
            if(preCountedTiles){

                if(numberCounted<[preCountedTiles count]) 
                {
                    NSDictionary *thisTile=[preCountedTiles objectAtIndex:numberCounted];              
                
                    if(curAnch.myXpos == [[thisTile objectForKey:POS_X] intValue] && curAnch.myYpos == [[thisTile objectForKey:POS_Y]intValue])
                    {
                        numberCounted++;
                        tile.Selected=YES;
                    }
                }

            }
            
            [tile handleMessage:kDWsetupStuff];
            
            if(curAnch.resizeHandle)
            {
                DWDotGridHandleGameObject *rshandle = [DWDotGridHandleGameObject alloc];
                [gw populateAndAddGameObject:rshandle withTemplateName:@"TdotgridHandle"];
                rshandle.RenderLayer=anchorLayer;
                rshandle.handleType=kResizeHandle;
                rshandle.Position=ccp(curAnch.Position.x+spaceBetweenAnchors,curAnch.Position.y);
                //rshandle.Position=((DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor).Position;
                shape.resizeHandle=rshandle;
                rshandle.myShape=shape;
                [rshandle handleMessage:kDWsetupStuff];
                [rshandle release];
                
            }
            
            if(curAnch.moveHandle)
            {
                DWDotGridHandleGameObject *mvhandle = [DWDotGridHandleGameObject alloc];
                [gw populateAndAddGameObject:mvhandle withTemplateName:@"TdotgridHandle"];
                mvhandle.handleType=kMoveHandle;
                mvhandle.Position=ccp(curAnch.Position.x, curAnch.Position.y+spaceBetweenAnchors);
                shape.moveHandle=mvhandle;
                mvhandle.myShape=shape;
                
                [mvhandle release];

            }
            
            [curAnch release];
            [tile release];
        }
    
    [shape handleMessage:kDWsetupStuff andPayload:nil withLogLevel:-1];
    
    
    if (!gw.Blackboard.inProblemSetup)
    {
        [loggingService logEvent:BL_PA_DG_TOUCH_END_CREATE_SHAPE
            withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[anchors count]] forKey:@"numTiles"]];
    }
    return shape;
}

-(void)modifyThisShape:(DWDotGridShapeGameObject*)thisShape withTheseAnchors:(NSArray*)anchors
{
    NSMutableArray *removeObjects=[[NSMutableArray alloc]init];
    DWDotGridAnchorGameObject *rsAnchor=[DWDotGridAnchorGameObject alloc];
    int dupeAnchors=0;
    
    
    if([anchors count]<1)return;
    
    for(int i=0;i<[anchors count];i++)
    {
        for(int c=0;c<[thisShape.tiles count];c++)
        {
            DWDotGridTileGameObject *tile=[thisShape.tiles objectAtIndex:c];
            if ([anchors containsObject:tile.myAnchor])dupeAnchors++;
            if(tile.myAnchor.resizeHandle)rsAnchor=tile.myAnchor;
        }
    }
    
//    if(dupeAnchors<1)
//    {
//        thisShape.resizeHandle.Position=ccp(rsAnchor.Position.x+spaceBetweenAnchors,rsAnchor.Position.y);
//        [thisShape.resizeHandle handleMessage:kDWmoveSpriteToPosition];
//        
//        return;
//    }
    
    // we are deleting

        for(DWDotGridTileGameObject *tile in thisShape.tiles)
        {
            if(![anchors containsObject:tile.myAnchor])
            {
                DWDotGridAnchorGameObject *anch=tile.myAnchor;
                anch.tile=nil;
                anch.resizeHandle=NO;
                anch.moveHandle=NO;
                [removeObjects addObject:tile];
                
            }

        }
        
        for(int i=0;i<[removeObjects count];i++)
        {
            DWDotGridTileGameObject *tile=[removeObjects objectAtIndex:i];
            tile.myAnchor=nil;
            [tile handleMessage:kDWdismantle];
            [thisShape.tiles removeObject:tile];
            [gw delayRemoveGameObject:tile];
        }
    
        // loop through the anchors we've been given
        for(DWDotGridAnchorGameObject *curAnch in anchors)
        {
            if(curAnch.tile)continue;
            else {
                DWDotGridTileGameObject *tile = [DWDotGridTileGameObject alloc];
                [gw populateAndAddGameObject:tile withTemplateName:@"TdotgridTile"];
                tile.myAnchor=curAnch;
                tile.tileType=kNoBorder;
                tile.tileSize=spaceBetweenAnchors;
                tile.Position=ccp(curAnch.Position.x+spaceBetweenAnchors/2, curAnch.Position.y+spaceBetweenAnchors/2);
                tile.RenderLayer=thisShape.RenderLayer;
                //[tile handleMessage:kDWsetupStuff];
                [thisShape.tiles addObject:tile];
                curAnch.tile=tile;
                tile.myAnchor=curAnch;
                tile.myShape=thisShape;
                
                [tile release];
            }

        }
    

    OrderedAnchors orderedAnchs=[self checkAndChangeAnchorPoints:(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor and:(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor];
    
    thisShape.firstAnchor=orderedAnchs.firstAnchor;
    thisShape.lastAnchor=orderedAnchs.lastAnchor;
    [thisShape.myHeight removeFromParentAndCleanup:YES];
    [thisShape.myWidth removeFromParentAndCleanup:YES];
    thisShape.myWidth=nil;
    thisShape.myHeight=nil;
    [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:-1];
    if(thisShape.MyNumberWheel)[thisShape handleMessage:kDWupdateObjectData];

//    for(int i=0;i<[thisShape.tiles count];i++)
//    {
//        DWDotGridTileGameObject *tile=[thisShape.tiles objectAtIndex:i];
//        [tile.mySprite setOpacity:150];
//    }
    
    thisShape.resizeHandle.Position=thisShape.lastAnchor.Position;
    [thisShape.resizeHandle handleMessage:kDWmoveSpriteToPosition];
    
    [loggingService logEvent:BL_PA_DG_TOUCH_END_RESIZE_SHAPE
        withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[thisShape.tiles count]] forKey:@"numTiles"]];
    
//    [removeObjects release];
//    [rsAnchor release];
}


-(void)removeDeadWheel:(DWNWheelGameObject*)thisWheel
{
    if(sumWheel==thisWheel)
        sumWheel=nil;
    
    [numberWheels removeObject:thisWheel];
    
    for(int i=0;i<[numberWheels count];i++)
    {
        DWNWheelGameObject *w=[numberWheels objectAtIndex:i];
        w.Position=ccp(lx-140,(ly-120)-100*i);
    }
    
    if([numberWheels count]<2 && sumWheel)
    {
        DWNWheelGameObject *tempSum=sumWheel;
        [tempSum handleMessage:kDWdismantle];
        sumWheel=nil;
        [self removeDeadWheel:tempSum];
    }
}

-(void)updateSumWheel
{
    if([numberWheels count]<2)return;
    
    NSString *str=@"";
    int totalVal=0;
    
    for(int i=0;i<[numberWheels count]-1;i++)
    {
        DWNWheelGameObject *w=[numberWheels objectAtIndex:i];
        if(w==sumWheel)continue;
        str=@"";
        
        for(NSNumber *n in w.pickerViewSelection)
        {
            str=[NSString stringWithFormat:@"%@%d", str, [n intValue]];
        }
        
        totalVal+=[str intValue];
        
        if(debugLogging)
            NSLog(@"(%d) totalVal %d", i, totalVal);
    }
    
    sumWheel.InputValue=totalVal;
    [sumWheel handleMessage:kDWupdateObjectData];
}

-(void)createAllWheels
{
    if(!showNumberWheel)return;
    if([numberWheels count]>0)return;

    for(int i=0;i<[gw.AllGameObjects count];i++)
    {
        if([[gw.AllGameObjects objectAtIndex:i] isKindOfClass:[DWDotGridShapeGameObject class]])
        {
            DWDotGridShapeGameObject *s=[gw.AllGameObjects objectAtIndex:i];
            if(!s.MyNumberWheel)
            {
                DWNWheelGameObject *w=[DWNWheelGameObject alloc];
                [gw populateAndAddGameObject:w withTemplateName:@"TnumberWheel"];
                
                w.RenderLayer=renderLayer;
                w.Position=ccp(lx-140,(ly-120)-100*[numberWheels count]);
                w.AssociatedGO=s;
                w.Components=numberWheelComponents;
                w.SpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ov.png",w.Components];
                w.HasCountBubble=showCountBubble;
                w.CountBubbleRenderLayer=anchorLayer;
                
                if(s.ShapeX>0 && s.ShapeY>0){
                    w.Label=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g x %g", s.ShapeX, s.ShapeY] fontName:SOURCE fontSize:20.0f];
                    if(gw.Blackboard.inProblemSetup){
                        [w.Label setTag:2];
                        [w.Label setOpacity:0];
                    }
                    [w.RenderLayer addChild:w.Label];
                }
                [w handleMessage:kDWsetupStuff];
                [w handleMessage:kDWupdateLabels];
                
                s.MyNumberWheel=w;
                [s.resizeHandle handleMessage:kDWdismantle];
                
                if([numberWheels count]<2)
                    [numberWheels addObject:w];
                else
                    [numberWheels insertObject:w atIndex:[numberWheels count]-1];
            }
        }
    }
    
    [self createSumWheel];
}

-(void)createSumWheel
{
    if(![numberWheels count]>=2)
        return;
    
    if(sumWheel)return;
    
    //if(![self checkForCorrectShapeSizes])return;
    
    DWNWheelGameObject *w=[DWNWheelGameObject alloc];
    [gw populateAndAddGameObject:w withTemplateName:@"TnumberWheel"];
    
    w.RenderLayer=renderLayer;
    w.Components=numberWheelComponents;
    w.Position=ccp(lx-140,(ly-120)-100*[numberWheels count]);
    w.SpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ov.png",w.Components];
    w.HasCountBubble=NO;
    w.Label=[CCLabelTTF labelWithString:@"Total" fontName:SOURCE fontSize:20.0f];
    [w.RenderLayer addChild:w.Label];
    [w handleMessage:kDWsetupStuff];
    [w handleMessage:kDWupdateLabels];
    [numberWheels addObject:w];
    
    sumWheel=w;
}

#pragma mark - touch events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    lastTouch=location;
    
    
    if([gw.Blackboard.SelectedObjects count]>0)
    {
        for(CCLabelTTF *l in gw.Blackboard.SelectedObjects)
        {
            [l removeFromParentAndCleanup:YES];
        }
    }
    
    [gw Blackboard].PickupObject=nil;
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    
    if(showDraggableBlock && CGRectContainsPoint(dragBlock.boundingBox, location))
    {
        hitDragBlock=YES;
        NSString *fileStr=[NSString stringWithFormat:@"/images/dotgrid/DG_sq%d.png",spaceBetweenAnchors];
        newBlock=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(fileStr)];
        [newBlock setPosition:location];
        [renderLayer addChild:newBlock];
    }
    
    // if a handle responds saying it's been touched
    if(gw.Blackboard.CurrentHandle) {
        
        // check the handle type and whether or not the shape is disabled (generally disabled shapes won't have handles but it could be specified)
        
        if(((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).handleType == kResizeHandle && !((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).myShape.Disabled) {
                gameState=kResizeShape;
            
            DWDotGridShapeGameObject *curShape=((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).myShape;
            
            //    for(int i=0;i<[curShape.tiles count];i++)
            //    {
            //        DWDotGridTileGameObject *tile=[curShape.tiles objectAtIndex:i];
            //        [tile.mySprite setOpacity:150];
            //    }
            
            [loggingService logEvent:BL_PA_DG_TOUCH_BEGIN_RESIZE_SHAPE
                withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[curShape.tiles count]] forKey:@"numTiles"]];
            
            [curShape handleMessage:kDWresizeShape];
                
             
                
            return;
        }
        

        if(((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).handleType == kMoveHandle && !((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).myShape.Disabled) 
        {
                gameState=kMoveShape;
                [((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).myShape handleMessage:kDWresizeShape];
                return;
        }
        
    }
        
    // if we get past having a handle, then send a switchselection
    [gw handleMessage:kDWswitchSelection andPayload:pl withLogLevel:-1];
    
    if(!gw.Blackboard.ProximateObject){
    
        if(gw.Blackboard.FirstAnchor && !((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).tile && !disableDrawing) {
            ((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).Disabled=YES;
            gameState=kStartAnchor;
            [loggingService logEvent:BL_PA_DG_TOUCH_BEGIN_CREATE_SHAPE withAdditionalData:nil];
        }
        
        else if(disableDrawing)
        {
            movingLayer=YES;
            gw.Blackboard.FirstAnchor=nil;
        }

    }
    
 }

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    CGPoint prevLoc = [touch previousLocationInView:[touch view]];
    prevLoc = [[CCDirector sharedDirector] convertToGL: prevLoc];
    
    lastTouch=location;
    
    if(location.x>lx-60)
        isMovingRight=YES;
    else
        isMovingRight=NO;
    
    if(location.x<60)
        isMovingLeft=YES;
    else
        isMovingLeft=NO;
    
    if(location.y>ly-60)
        isMovingUp=YES;
    else
        isMovingUp=NO;
    
    if(location.y<60)
        isMovingDown=YES;
    else
        isMovingDown=NO;
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    
    // if they can move the layer and haven't picked up a new block
    if(movingLayer && !hitDragBlock)
    {
        CGPoint diff=ccpSub(location, prevLoc);
        [anchorLayer setPosition:ccpAdd(anchorLayer.position, diff)];
        
        return;
    }
    if(hitDragBlock)
    {
        [newBlock setPosition:location];

//        CGPoint searchLoc=ccp(newBlock.position.x-(newBlock.contentSize.width/2), newBlock.position.y-(newBlock.contentSize.height/2));
        CGPoint searchLoc=ccp(newBlock.position.x-(newBlock.contentSize.width/2), newBlock.position.y+(newBlock.contentSize.height/2));
        // set the search location to the bottom left of the square
        NSMutableDictionary *nb=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:[anchorLayer convertToNodeSpace:searchLoc]] forKey:POS];
        [gw handleMessage:kDWareYouADropTarget andPayload:nb withLogLevel:-1];
        
        if(gw.Blackboard.FirstAnchor)
        {
            DWDotGridAnchorGameObject *fa=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
            
            //NSLog(@"fa.myXPos+1 = %d, dotMatrix count = %d, fa.myYPos+1 = %d, dotMatrix objAtIndex(%d) count = %d", fa.myXpos+1, [dotMatrix count], fa.myYpos+1, fa.myXpos+1, [[dotMatrix objectAtIndex:fa.myXpos+1] count]);
            
            if(fa.myXpos+1<=[dotMatrix count]-1)
            {
//                if(fa.myYpos+1<=[[dotMatrix objectAtIndex:fa.myXpos] count]-1)
                if(fa.myYpos-1>=0)
                    gw.Blackboard.LastAnchor=[[dotMatrix objectAtIndex:fa.myXpos+1] objectAtIndex:fa.myYpos-1];
            }
        }
        
    }
    
    if(gameState==kNoState)
    {
        
    }
    
    if(gameState==kStartAnchor)
    {
        if(gw.Blackboard.FirstAnchor) [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];   
    }
    
    if(gameState==kResizeShape)
    {
        [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
            
        ((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).Position=[anchorLayer convertToNodeSpace:location];

        [gw.Blackboard.CurrentHandle handleMessage:kDWmoveSpriteToPosition];
        
    }
    
    if(gameState==kMoveShape)
    {
       
    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
    
    if(hitDragBlock && CGRectContainsPoint(newBlock.boundingBox, location))
    {
        DWDotGridAnchorGameObject *fa=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
        DWDotGridAnchorGameObject *la=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
        if(debugLogging)
            NSLog(@"first X %d Y %d, last X %d Y %d", fa.myXpos, fa.myYpos, la.myXpos, la.myYpos);
        [self checkAnchors];
    }
    
    // Draw object, empty selected objects - make sure that no objects say they're selected
    if(gameState==kStartAnchor) { 
        [self checkAnchors];
        ((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).Disabled=NO;
    }
    
    if(gameState==kResizeShape)
    {
        DWDotGridHandleGameObject * cHandle=(DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle;
        if(!useShapeGroups)
            [self checkAnchorsOfExistingShape:cHandle.myShape];
        else
            [self checkAnchorsOfExistingShapeGroup:(DWDotGridShapeGroupGameObject*)cHandle.myShape.shapeGroup];
    }
    
    if(showMoreOrLess)
    {
        CorrectSizeInfo retInfo=[self getShapeSizeInfo];
//        NSMutableArray *reqShapesCopy=[NSMutableArray arrayWithArray:reqShapes];
//        NSMutableArray *hintedShapes=[NSMutableArray arrayWithArray:retInfo.matchedGOs];
        [reqShapesCopy removeObjectsInArray:retInfo.matchedShapes];
        
        if([reqShapesCopy count]>0){
        
            if([reqShapes count]!=[retInfo.matchedShapes count])
            {
                for(int i=0;i<[gw.AllGameObjects count];i++)
                {
                    if([reqShapesCopy count]==0)break;
                    
                    if([[gw.AllGameObjects objectAtIndex:i]isKindOfClass:[DWDotGridShapeGameObject class]])
                    {

                        DWDotGridShapeGameObject *sg=[gw.AllGameObjects objectAtIndex:i];
                        if(debugLogging)
                            NSLog(@"Check sg %d", (int)sg);
//                        if([retInfo.matchedGOs containsObject:sg])
//                            continue;
                        
                        if([retInfo.matchedGOs containsObject:sg])
                        {
                            [sg.hintArrowX setVisible:NO];
                            [sg.hintArrowY setVisible:NO];
                            continue;
                        }
                        
                        DWDotGridAnchorGameObject *fa=sg.firstAnchor;
                        DWDotGridAnchorGameObject *la=sg.lastAnchor;
                        
                        
                        int expX=[[[reqShapesCopy objectAtIndex:0] objectAtIndex:0]intValue];
                        int expY=[[[reqShapesCopy objectAtIndex:0] objectAtIndex:1]intValue];
                        
//                        [checkShape addObject:[NSNumber numberWithFloat:expX]];
//                        [checkShape addObject:[NSNumber numberWithFloat:expY]];
//                        
//                        if([retInfo.matchedShapes containsObject:checkShape])
//                            continue;
                        
                        
                        int curX=fabsf(fa.myXpos-la.myXpos);
                        int curY=fabsf(fa.myYpos-la.myYpos);
                        
                        [sg.hintArrowX setPosition:ccp(sg.centreX,sg.bottom-(sg.hintArrowX.contentSize.height))];
                        [sg.hintArrowY setPosition:ccp(sg.right+(sg.hintArrowX.contentSize.width/1.5),sg.centreY)];
                        [sg.hintArrowX setVisible:YES];
                        [sg.hintArrowY setVisible:YES];
                        
                        if(curX<expX){
                            [sg.hintArrowX setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/dotgrid/DG_More_X.png")]];
                        }else if(curX>expX){
                            [sg.hintArrowX setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/dotgrid/DG_Less_X.png")]];
                        }else if(curX==expX){
                            [sg.hintArrowX setVisible:NO];
                        }
                        
                        if(curY<expY){
                            [sg.hintArrowY setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/dotgrid/DG_More_Y.png")]];
                        }else if(curY>expY){
                            [sg.hintArrowY setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/dotgrid/DG_Less_Y.png")]];
                        }else if(curY==expY){
                            [sg.hintArrowY setVisible:NO];
                        }
                        
                        if(curX==expX && curY==expY){
                            [sg.hintArrowX setVisible:NO];
                            [sg.hintArrowY setVisible:NO];
                            [reqShapesCopy removeObjectAtIndex:0];
//                            [hintedShapes addObject:sg];
                            
                            if(debugLogging)
                                NSLog(@"count hinted %d, reqShapes %d", [retInfo.matchedGOs count], [reqShapesCopy count]);
                        }
                    }
                }
            }
        }
    }
    
    if(CGRectContainsPoint(introCommit.boundingBox,location))
    {
        hitIntroCommit=YES;
    }
    
    if(sumWheel)[self updateSumWheel];
    
    if(evalMode==kProblemEvalAuto)[self evalProblem];
    

    
    gw.Blackboard.FirstAnchor=nil;
    gw.Blackboard.LastAnchor=nil;
    gw.Blackboard.CurrentHandle=nil;
    gw.Blackboard.ProximateObject=nil;
    if(hitDragBlock)[newBlock removeFromParentAndCleanup:YES];
    hitDragBlock=NO;
    movingLayer=NO;
    
    isMovingLeft=NO;
    isMovingRight=NO;
    isMovingUp=NO;
    isMovingDown=NO;
    
    [gw.Blackboard.SelectedObjects removeAllObjects];
    gameState=kNoState;

     
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    // empty selected objects
    gw.Blackboard.FirstAnchor=nil;
    gw.Blackboard.LastAnchor=nil;    
    gw.Blackboard.CurrentHandle=nil;
    gw.Blackboard.ProximateObject=nil;
    if(hitDragBlock)[newBlock removeFromParentAndCleanup:YES];
    hitDragBlock=NO;
    movingLayer=NO;
    
    isMovingLeft=NO;
    isMovingRight=NO;
    isMovingUp=NO;
    isMovingDown=NO;

    [gw.Blackboard.SelectedObjects removeAllObjects];
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    
    BOOL isForceReturnNo=NO;
    
    //if(toolHost.PpExpr) [toolHost.PpExpr release];
    
    //create base equality
    toolHost.PpExpr=[BAExpressionTree treeWithRoot:[BAEqualsOperator operator]];
    
    NSMutableArray *tileCounts=[[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *selectedCounts=[[[NSMutableArray alloc] init] autorelease];
    
    for (DWGameObject *go in gw.AllGameObjects) {
        if([go isKindOfClass:[DWDotGridShapeGameObject class]])
        {
            DWDotGridShapeGameObject *sgo=(DWDotGridShapeGameObject*)go;
            
            //ignore disabled shapes
            if(!sgo.Disabled)
            {
                int tileCount=0;
                int selectedCount=0;
                
                for (DWDotGridTileGameObject *tgo in sgo.tiles) {
                    tileCount++;
                    if(tgo.Selected)selectedCount++;
                }
                
                [tileCounts addObject:[NSNumber numberWithInt:tileCount]];
                [selectedCounts addObject:[NSNumber numberWithInt:selectedCount]];
                
                if(debugLogging)
                    NSLog(@"shape of %d / %d", selectedCount, tileCount);
            }
        }
    }
    
    //evaluted wrong by default if no shapes found
    if(tileCounts.count == 0) return NO;
    
    else if(evalType==kProblemTotalShapeSize)
    {
        int tileCountSum=0;
        for (NSNumber *n in tileCounts) {
            tileCountSum+=[n intValue];
        }
        
        //add left part (an integer as in pdef)
        [toolHost.PpExpr.root addChild:[BAInteger integerWithIntValue:evalTotalSize]];
        
        //add right part (total of tiles drawn)
        [toolHost.PpExpr.root addChild:[BAInteger integerWithIntValue:tileCountSum]];
    }
    
    else if(evalType==kProblemSumOfFractions)
    {
        //create left part as dividend/divisor
        BADivisionOperator *leftdiv=[BADivisionOperator operator];
        [toolHost.PpExpr.root addChild:leftdiv];
        
        [leftdiv addChild:[BAInteger integerWithIntValue:evalDividend]];
        [leftdiv addChild:[BAInteger integerWithIntValue:evalDivisor]];
        
        if(!doNotSimplifyFractions) [leftdiv simplifyIntegerDivision];
        
        //if there was only one shape, then add it as division to root equality -- if not, create an addition for all divisions on right
        if(tileCounts.count==1)
        {
            if([[selectedCounts objectAtIndex:0] intValue]==0)
            {
                [toolHost.PpExpr.root addChild:[BAInteger integerWithIntValue:0]];
                isForceReturnNo=YES;
            }
            else {
                BADivisionOperator *rightdiv=[BADivisionOperator operator];
                [toolHost.PpExpr.root addChild:rightdiv];
                
                [rightdiv addChild:[BAInteger integerWithIntValue:[[selectedCounts objectAtIndex:0] intValue]]];
                [rightdiv addChild:[BAInteger integerWithIntValue:[[tileCounts objectAtIndex:0] intValue]]];
                
                if(!doNotSimplifyFractions)[rightdiv simplifyIntegerDivision];
            }

        }
        else {
            //add all the divisions together
            BAAdditionOperator *rightadd=[BAAdditionOperator operator];
            [toolHost.PpExpr.root addChild:rightadd];
            
            for (int i; i<[tileCounts count]; i++) {
                if([[selectedCounts objectAtIndex:i] intValue]==0)
                {
                    [rightadd addChild:[BAInteger integerWithIntValue:0]];
                    isForceReturnNo=YES;
                }
                else {
                    BADivisionOperator *div=[BADivisionOperator operator];
                    [rightadd addChild:div];
                    
                    [div addChild:[BAInteger integerWithIntValue:[[selectedCounts objectAtIndex:i] intValue]]];
                    [div addChild:[BAInteger integerWithIntValue:[[tileCounts objectAtIndex:i] intValue]]];                    
                    
                    if(!doNotSimplifyFractions)[div simplifyIntegerDivision];
                }
            }
        }
    }
    else if(evalType==kProblemGridMultiplication)
    {
        if(![self checkForCorrectShapeSizes])return NO;
        else if([self checkForCorrectShapeSizes] && solutionNumber==sumWheel.OutputValue)return YES;
        else return NO;
        
    }
    else if(evalType==kProblemCheckDimensions)
    {
        return [self checkForCorrectShapeSizes];
    }
    else if(evalType==kProblemNonProportionalGrid)
    {
        if(![self checkForCorrectShapeSizes])return NO;
        else if([self checkForCorrectShapeSizes] && solutionNumber==sumWheel.OutputValue)return YES;
        else return NO;
    }
    else if(evalType==kProblemIntroPlist)
    {
        if(!showingIntroOverlay && [[tileCounts objectAtIndex:0]intValue]>1)
        {
            [self setupIntroOverlay];
            return NO;
        }
        else if(showingIntroOverlay && hitIntroCommit)
        {
            return YES;
        }
        else{
            return NO;
        }
    }
    else {
        //no eval mode specified, return no
        return NO;
    }
    
    NSLog(@"%@", [toolHost.PpExpr xmlStringValue]);
    
    if (isForceReturnNo) {
        return NO;
    }
    else {
        BATQuery *q=[[BATQuery alloc] initWithExpr:toolHost.PpExpr.root andTree:toolHost.PpExpr];
        BOOL res=[q assumeAndEvalEqualityAtRoot];
        [q release];
        return res;
    }
}

-(CorrectSizeInfo)getShapeSizeInfo
{
    CorrectSizeInfo retInfo;
    int correctShapes=0;
    NSMutableArray *matchShapes=[[NSMutableArray alloc]init];
    NSMutableArray *matchGOs=[[NSMutableArray alloc]init];
    
    if(!reqShapesCopy)reqShapesCopy=[[NSMutableArray arrayWithArray:reqShapes]retain];
    
    //for each object that conforms to being a shapegroup
    for(int i=0;i<[gw.AllGameObjects count];i++)
    {
        if([[gw.AllGameObjects objectAtIndex:i]isKindOfClass:[DWDotGridShapeGameObject class]])
        {
            DWDotGridShapeGameObject *sg=[gw.AllGameObjects objectAtIndex:i];
            DWDotGridAnchorGameObject *fa=sg.firstAnchor;
            DWDotGridAnchorGameObject *la=sg.lastAnchor;
            
            int dimensionX=fabsf(fa.myXpos-la.myXpos);
            int dimensionY=fabsf(fa.myYpos-la.myYpos);
            
            // check each shape in REQUIRED_SHAPES
            for(NSArray *a in [NSMutableArray arrayWithArray:reqShapes])
            {
                if([matchShapes containsObject:a])continue;
                
                BOOL xMatch=NO;
                BOOL yMatch=NO;
//                for(int i=0;i<[a count];i++)
//                {
//                    if(dimensionX==[[a objectAtIndex:i]intValue]&&!xMatch)xMatch=YES;
//                    else if(dimensionY==[[a objectAtIndex:i]intValue]&&!yMatch)yMatch=YES;
//                    
//                }

                
                if(dimensionX==[[a objectAtIndex:0]intValue]&&!xMatch)xMatch=YES;
                else if(dimensionY==[[a objectAtIndex:1]intValue]&&!yMatch)yMatch=YES;
                
                if(xMatch&&yMatch)
                {
                    [sg.resizeHandle handleMessage:kDWdismantle];
                    sg.resizeHandle=nil;
                    [matchShapes addObject:a];
                    [matchGOs addObject:sg];
                    
                    if(debugLogging)
                        NSLog(@"Adding gameObject sg: %d to matchedGOs", (int)sg);
                    
                    //[reqShapesCopy removeObject:a];
                    correctShapes++;

                }
            }
            
        }
    }
    
    retInfo.matchedShapes=matchShapes;
    retInfo.matchedGOs=matchGOs;
    
    if(correctShapes==[reqShapes count])
    {
        retInfo.canEval=YES;
    }
    
    
    return retInfo;
}

-(BOOL)checkForCorrectShapeSizes
{
    int correctShapes=0;
    NSMutableArray *matchShapes=[[NSMutableArray alloc]init];
    NSMutableArray *matchObjects=[[NSMutableArray alloc]init];
    //for each object that conforms to being a shapegroup
    for(int i=0;i<[gw.AllGameObjects count];i++)
    {
        if([[gw.AllGameObjects objectAtIndex:i]isKindOfClass:[DWDotGridShapeGameObject class]])
        {
            DWDotGridShapeGameObject *sg=[gw.AllGameObjects objectAtIndex:i];
            DWDotGridAnchorGameObject *fa=nil;
            DWDotGridAnchorGameObject *la=nil;
            
            if(useShapeGroups)
            {
                fa=sg.firstBoundaryAnchor;
                la=sg.lastBoundaryAnchor;
            }
            else
            {
                fa=sg.firstAnchor;
                la=sg.lastAnchor;
            }
            
            int dimensionX=fabsf(fa.myXpos-la.myXpos);
            int dimensionY=fabsf(fa.myYpos-la.myYpos);
            
            // check each shape in REQUIRED_SHAPES
            for(NSArray *a in reqShapes)
            {
                if([matchShapes containsObject:a])continue;
                if([matchObjects containsObject:sg])continue;
                
                BOOL xMatch=NO;
                BOOL yMatch=NO;
                if(dimensionX==[[a objectAtIndex:0]intValue]&&!xMatch)xMatch=YES;
                else if(dimensionY==[[a objectAtIndex:1]intValue]&&!yMatch)yMatch=YES;
                
                
//                for(int i=0;i<[a count];i++)
//                {
//                    if(dimensionX==[[a objectAtIndex:i]intValue]&&!xMatch)xMatch=YES;
//                    else if(dimensionY==[[a objectAtIndex:i]intValue]&&!yMatch)yMatch=YES;

                    
//                }
                
                if(xMatch&&yMatch)
                {
                    [matchShapes addObject:a];
                    [matchObjects addObject:sg];
                    correctShapes++;
                }
            }
            
        }
    }
    
    if(correctShapes==[reqShapes count])
    {
        return YES;
    }
    
    
    return NO;
}

-(void)evalProblem
{
    BOOL isWinning=[self evalExpression];
    
    if(isIntroPlist && !isWinning)return;
    
    if(isWinning)
    {
        [toolHost doWinning];
    }
    else {
        if(evalMode==kProblemEvalOnCommit){
            [toolHost doIncomplete];
            [toolHost resetProblem];
        }
    }

}

-(void)resetProblem
{
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
    if(dotMatrix)[dotMatrix release];
    if(initObjects)[initObjects release];
    if(hiddenRows)[hiddenRows release];
    if(numberWheels)[numberWheels release];
    
    [renderLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];

    gw=nil;

    [super dealloc];
}
@end
