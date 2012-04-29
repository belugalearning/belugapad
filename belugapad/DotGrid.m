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
#import "BLMath.h"

@implementation DotGrid
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
        
        
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [self readPlist:pdef];
        [self populateGW];
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        gw.Blackboard.inProblemSetup = NO;
        gw.Blackboard.FirstAnchor=(DWDotGridAnchorGameObject*)[[DWGameObject alloc]init];
        gw.Blackboard.LastAnchor=(DWDotGridAnchorGameObject*)[[DWGameObject alloc]init];
        gw.Blackboard.FirstAnchor=nil;
        gw.Blackboard.LastAnchor=nil;
        
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
}

-(void)draw
{
    if(gameState==kStartAnchor)
    {
        CGPoint points[4];
        points[0]=((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).Position;
        points[2]=lastTouch;
        points[1]=CGPointMake(points[2].x, points[0].y);
        points[3]=CGPointMake(points[0].x, points[2].y);
        
        CGPoint *first=&points[0];
        
        ccDrawPoly(first, 4, YES);
        
        points[2]=((DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor).Position;
        points[1]=CGPointMake(points[2].x, points[0].y);
        points[3]=CGPointMake(points[0].x, points[2].y);
        
        ccDrawFilledPoly(first, 4, ccc4FFromccc4B(ccc4(255,255,255,5)));
        
        
    }
    
    if(gameState==kResizeShape)
    {
        
    }
}

-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    // All our stuff needs to go into vars to read later
    
    drawMode=[[pdef objectForKey:DRAW_MODE] intValue];
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    evalType=[[pdef objectForKey:DOTGRID_EVAL_TYPE] intValue];
    spaceBetweenAnchors=[[pdef objectForKey:ANCHOR_SPACE] intValue];
    startX=[[pdef objectForKey:START_X] intValue];
    startY=[[pdef objectForKey:START_Y] intValue];
    if([pdef objectForKey:INIT_OBJECTS])initObjects=[pdef objectForKey:INIT_OBJECTS];
    if(initObjects)[initObjects retain];
    if([pdef objectForKey:HIDDEN_ROWS])hiddenRows=[pdef objectForKey:HIDDEN_ROWS];
    if(hiddenRows)[hiddenRows retain];


    
}

-(void)populateGW
{
    gameState=kNoState;
    dotMatrix=[[NSMutableArray alloc]init];
    [dotMatrix retain];
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    

    float xStartPos=spaceBetweenAnchors*1.5;
    
    for (int iRow=0; iRow<(int)(lx-spaceBetweenAnchors*2)/spaceBetweenAnchors; iRow++)
    {
        NSMutableArray *currentCol=[[NSMutableArray alloc]init];
        BOOL currentRowHidden=NO;
        
        for(int iCol=0; iCol<(int)(ly-spaceBetweenAnchors*2)/spaceBetweenAnchors; iCol++)
        {
            // create our start position and gameobject
            float yStartPos=(iCol+1)*spaceBetweenAnchors;
            DWDotGridAnchorGameObject *anch = [DWDotGridAnchorGameObject alloc];
            [gw populateAndAddGameObject:anch withTemplateName:@"TdotgridAnchor"];
            anch.Position=ccp(xStartPos,yStartPos);
            anch.myXpos=iRow;
            anch.myYpos=iCol;
            
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
                anch.StartAnchor=YES;
                //NSLog(@"THIS ANCHOR IS *ENABLED* (x %d / y %d)", anch.myXpos, anch.myYpos);
            }
            else if((iRow!=startX || iCol!=startY) && drawMode==kSpecifiedStartAnchor) {
                //NSLog(@"THIS ANCHOR IS *DISABLED* (x %d / y %d)", anch.myXpos, anch.myYpos);
                anch.Disabled=YES;
            }
            
            [currentCol addObject:anch];
            

        }
        
        xStartPos=xStartPos+spaceBetweenAnchors;
        [dotMatrix addObject:currentCol];
        
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

}
-(void)checkAnchors
{
    [self checkAnchorsAndUseResizeHandle:YES andShowMove:YES andPrecount:nil andDisabled:NO];
}
-(void)checkAnchorsAndUseResizeHandle:(BOOL)showResize andShowMove:(BOOL)showMove andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled
{
    // only run if we have a first and last anchor point
    if(gw.Blackboard.FirstAnchor && gw.Blackboard.LastAnchor)
    {
        NSMutableArray *anchorsForShape=[[NSMutableArray alloc]init];
        DWDotGridAnchorGameObject *anchStart=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
        DWDotGridAnchorGameObject *anchEnd=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
        
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

                        if((curAnch.Disabled && !gw.Blackboard.inProblemSetup && !gameState==kStartAnchor)||curAnch.tile)return;
                        if(x==anchEnd.myXpos-1 && y==anchStart.myYpos && showResize)curAnch.resizeHandle=YES;
                        if(x==anchStart.myXpos && y==anchEnd.myYpos-1 && showMove)curAnch.moveHandle=YES;
                        [anchorsForShape addObject:curAnch];
                    }
                }
                else {
                    // and this is lower
                    for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        
                        if((curAnch.Disabled && !gw.Blackboard.inProblemSetup && !gameState==kStartAnchor)||curAnch.tile)return;
                        if(x==anchEnd.myXpos-1 && y==anchEnd.myYpos && showResize)curAnch.resizeHandle=YES;
                        if(x==anchStart.myXpos && y==anchStart.myYpos-1 && showMove)curAnch.moveHandle=YES;
                        [anchorsForShape addObject:curAnch];
                    } 
                }
            }
        }
        else {
            // start the loop
            for(int x=anchStart.myXpos-1;x>anchEnd.myXpos-1;x--)
            {
                NSLog(@"current x %d", x);
                // then check whether we're going up or down
                if(anchStart.myYpos < anchEnd.myYpos)
                {
                    // this is if the end point is higher in the grid
                    for(int y=anchStart.myYpos;y<anchEnd.myYpos;y++)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        if((curAnch.Disabled && !gw.Blackboard.inProblemSetup && !gameState==kStartAnchor)||curAnch.tile)return;
                        [anchorsForShape addObject:curAnch];
                        if(x==anchStart.myXpos-1 && y==anchStart.myYpos && showResize)curAnch.resizeHandle=YES;
                        if(x==anchEnd.myXpos && y==anchEnd.myYpos-1 && showMove)curAnch.moveHandle=YES;
                    }
                }
                else {
                    // and this is lower
                    for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        if((curAnch.Disabled && !gw.Blackboard.inProblemSetup && !gameState==kStartAnchor)||curAnch.tile)return;
                        [anchorsForShape addObject:curAnch];
                        if(x==anchEnd.myXpos+1 && y==anchEnd.myYpos && showResize)curAnch.resizeHandle=YES;
                        if(x==anchEnd.myXpos && y==anchStart.myYpos-1 && showMove)curAnch.moveHandle=YES;
                    } 
                }
            }

        }
        [self createShapeWithAnchorPoints:anchorsForShape andPrecount:preCountedTiles andDisabled:Disabled];        
        for(int i=0;i<[anchorsForShape count];i++)
        {
            DWDotGridAnchorGameObject *wanch = [anchorsForShape objectAtIndex:i];
            NSLog(@"shape in matrix (%d/%d): x %d / y %d", i, [anchorsForShape count], wanch.myXpos, wanch.myYpos);
        }

    }
}

-(void)createShapeWithAnchorPoints:(NSArray*)anchors andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled
{
    
    DWDotGridShapeGameObject *shape=[DWDotGridShapeGameObject alloc];           
    [gw populateAndAddGameObject:shape withTemplateName:@"TdotgridShape"];
    shape.Disabled=Disabled;
    shape.tiles=[[NSMutableArray alloc]init];
    int numberCounted=0;


        for(int i=0;i<[anchors count];i++)
        {
            DWDotGridAnchorGameObject *curAnch = [anchors objectAtIndex:i];
            curAnch.Disabled=YES;
            DWDotGridTileGameObject *tile = [DWDotGridTileGameObject alloc];
            [gw populateAndAddGameObject:tile withTemplateName:@"TdotgridTile"];
            
            tile.tileType=kNoBorder;
            tile.tileSize=spaceBetweenAnchors;
            tile.Position=ccp(curAnch.Position.x+spaceBetweenAnchors/2, curAnch.Position.y+spaceBetweenAnchors/2);
            //[tile handleMessage:kDWsetupStuff];
            [shape.tiles addObject:tile];
            curAnch.tile=tile;
            // if we have pre counting tiles on
            if(preCountedTiles){
                NSDictionary *thisTile=[[NSDictionary alloc]init];
                if(numberCounted<[preCountedTiles count]) thisTile=[preCountedTiles objectAtIndex:numberCounted];
                
                if(curAnch.myXpos == [[thisTile objectForKey:POS_X] intValue] && curAnch.myYpos == [[thisTile objectForKey:POS_Y]intValue])
                {
                    numberCounted++;
                    tile.Selected=YES;
                }
            }
            
            if(curAnch.resizeHandle)
            {
                DWDotGridHandleGameObject *rshandle = [DWDotGridHandleGameObject alloc];
                [gw populateAndAddGameObject:rshandle withTemplateName:@"TdotgridHandle"];
                rshandle.handleType=kResizeHandle;
                rshandle.Position=ccp(curAnch.Position.x+spaceBetweenAnchors,curAnch.Position.y);
                shape.resizeHandle=rshandle;
                rshandle.myShape=shape;
                
            }
            
            if(curAnch.moveHandle)
            {
                DWDotGridHandleGameObject *mvhandle = [DWDotGridHandleGameObject alloc];
                [gw populateAndAddGameObject:mvhandle withTemplateName:@"TdotgridHandle"];
                mvhandle.handleType=kMoveHandle;
                mvhandle.Position=ccp(curAnch.Position.x, curAnch.Position.y+spaceBetweenAnchors);
                shape.moveHandle=mvhandle;
                mvhandle.myShape=shape;

            }
        }
    
[gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:-1];
    
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    lastTouch=location;
    
    
    [gw Blackboard].PickupObject=nil;
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    [gw handleMessage:kDWswitchSelection andPayload:pl withLogLevel:-1];
    if(gw.Blackboard.FirstAnchor && !((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).tile) {
        ((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).Disabled=YES;
        gameState=kStartAnchor; 
    }
    
    if(gw.Blackboard.CurrentHandle) {
        if(((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).handleType == kResizeShape) gameState=kResizeShape;
        if(((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).handleType == kResizeShape) gameState=kMoveShape;
        
    }
    
    
 }

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    
    if(gameState==kNoState)
    {
        
    }
    
    if(gameState==kStartAnchor)
    {
        if(gw.Blackboard.FirstAnchor) [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];   
    }
    
    if(gameState==kResizeShape)
    {
        if(gw.Blackboard.CurrentHandle) [gw.Blackboard.CurrentHandle handleMessage:kDWuseThisHandle];    
    }
    
    if(gameState==kMoveShape)
    {
        if(gw.Blackboard.CurrentHandle) [((DWDotGridHandleGameObject*)gw.Blackboard.CurrentHandle).myShape handleMessage:kDWmoveShape];         
    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
//    DWDotGridAnchorGameObject *anchStart=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
//    DWDotGridAnchorGameObject *anchEnd=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
//    
//    NSLog(@"anchStart x %d y %d / anchEnd x %d y %d", anchStart.myXpos, anchStart.myYpos, anchEnd.myXpos, anchEnd.myYpos);
    
    
    // Draw object, empty selected objects - make sure that no objects say they're selected
    if(gameState==kStartAnchor) { 
        [self checkAnchors];
        ((DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor).Disabled=NO;
    }
    
    
    gw.Blackboard.FirstAnchor=nil;
    gw.Blackboard.LastAnchor=nil;
    gw.Blackboard.CurrentHandle=nil;
    
    
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


    [gw.Blackboard.SelectedObjects removeAllObjects];
}

-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    
    for (DWGameObject *go in [gw AllGameObjects]) {
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
                
                NSLog(@"shape of %d / %d", selectedCount, tileCount);
            }
        }
    }
    
    //return YES;
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

}

-(float)metaQuestionTitleYLocation
{
    return kLabelTitleYOffsetHalfProp*cy;
}

-(float)metaQuestionAnswersYLocation
{
    return kMetaQuestionYOffsetPlaceValue*cy;
}

-(void) dealloc
{
    //write log on problem switch
    [gw writeLogBufferToDiskWithKey:@"DotGrid"];
    
    //tear down
    [gw release];
    if(dotMatrix)[dotMatrix release];
    if(initObjects)[initObjects release];
    if(hiddenRows)[hiddenRows release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    

    [super dealloc];
}
@end
