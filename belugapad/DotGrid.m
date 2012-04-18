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
        
        ccDrawFilledPoly(first, 4, ccc4f(1, 1, 1, 1));
        
    }
}

-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    // All our stuff needs to go into vars to read later
    
    drawMode=[[pdef objectForKey:DRAW_MODE] intValue];
    spaceBetweenAnchors=[[pdef objectForKey:ANCHOR_SPACE] intValue];
    startX=[[pdef objectForKey:START_X] intValue];
    startY=[[pdef objectForKey:START_Y] intValue];

    
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
        
        for(int iCol=0; iCol<(int)(ly-spaceBetweenAnchors*2)/spaceBetweenAnchors; iCol++)
        {
            // create our start position and gameobject
            float yStartPos=(iCol+1)*spaceBetweenAnchors;
            DWDotGridAnchorGameObject *anch = [DWDotGridAnchorGameObject alloc];
            [gw populateAndAddGameObject:anch withTemplateName:@"TdotgridAnchor"];
            anch.Position=ccp(xStartPos,yStartPos);
            
            anch.myXpos=iRow;
            anch.myYpos=iCol;
            
            // check - if the game is in a specified start anchor mode
            // if it is, then our gameobject needs to have properties set!
            if((iRow==startX && iCol==startY) && drawMode==kSpecifiedStartAnchor)
            {
                anch.Disabled=NO;
                anch.StartAnchor=YES;
                NSLog(@"THIS ANCHOR IS *ENABLED* (x %d / y %d)", anch.myXpos, anch.myYpos);
            }
            else if((iRow!=startX || iCol!=startY) && drawMode==kSpecifiedStartAnchor) {
                NSLog(@"THIS ANCHOR IS *DISABLED* (x %d / y %d)", anch.myXpos, anch.myYpos);
                anch.Disabled=YES;
            }
            
            [currentCol addObject:anch];
            
        }
        
        xStartPos=xStartPos+spaceBetweenAnchors;
        [dotMatrix addObject:currentCol];
        
    }    

}

-(void)checkAnchors
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
                        if(curAnch.Disabled)return;
                        if(x==anchEnd.myXpos-1 && y==anchStart.myYpos)curAnch.resizeHandle=YES;
                        if(x==anchStart.myXpos && y==anchEnd.myYpos-1)curAnch.moveHandle=YES;
                        [anchorsForShape addObject:curAnch];
                    }
                }
                else {
                    // and this is lower
                    for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        if(curAnch.Disabled)return;
                        if(x==anchEnd.myXpos-1 && y==anchEnd.myYpos)curAnch.resizeHandle=YES;
                        if(x==anchStart.myXpos && y==anchStart.myYpos-1)curAnch.moveHandle=YES;
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
                        if(curAnch.Disabled)return;
                        [anchorsForShape addObject:curAnch];
                        if(x==anchStart.myXpos-1 && y==anchStart.myYpos)curAnch.resizeHandle=YES;
                        if(x==anchEnd.myXpos && y==anchEnd.myYpos-1)curAnch.moveHandle=YES;
                    }
                }
                else {
                    // and this is lower
                    for(int y=anchStart.myYpos-1;y>anchEnd.myYpos-1;y--)
                    {
                        DWDotGridAnchorGameObject *curAnch = [[dotMatrix objectAtIndex:x]objectAtIndex:y];
                        if(curAnch.Disabled)return;
                        [anchorsForShape addObject:curAnch];
                        if(x==anchEnd.myXpos+1 && y==anchEnd.myYpos)curAnch.resizeHandle=YES;
                        if(x==anchEnd.myXpos && y==anchStart.myYpos-1)curAnch.moveHandle=YES;
                    } 
                }
            }

        }
        [self createShapeWithAnchorPoints:anchorsForShape];        
        for(int i=0;i<[anchorsForShape count];i++)
        {
            DWDotGridAnchorGameObject *wanch = [anchorsForShape objectAtIndex:i];
            NSLog(@"shape in matrix (%d/%d): x %d / y %d", i, [anchorsForShape count], wanch.myXpos, wanch.myYpos);
        }

    }
}

-(void)createShapeWithAnchorPoints:(NSArray*)anchors
{
    DWDotGridShapeGameObject *shape=[[DWDotGridShapeGameObject alloc]init];
    shape.tiles=[[NSMutableArray alloc]init];
    //direction - 0 fwd
    //          - 1 rvs

        for(int i=0;i<[anchors count];i++)
        {
            DWDotGridAnchorGameObject *curAnch = [anchors objectAtIndex:i];
            curAnch.Disabled=YES;
            DWDotGridTileGameObject *tile = [DWDotGridTileGameObject alloc];
            [gw populateAndAddGameObject:tile withTemplateName:@"TdotgridTile"];
            
            tile.tileType=kNoBorder;
            tile.Position=ccp(curAnch.Position.x+spaceBetweenAnchors/2, curAnch.Position.y+spaceBetweenAnchors/2);
            [tile handleMessage:kDWsetupStuff];
            [shape.tiles addObject:tile];
            
            if(curAnch.resizeHandle)
            {
                DWDotGridHandleGameObject *rshandle = [DWDotGridHandleGameObject alloc];
                [gw populateAndAddGameObject:rshandle withTemplateName:@"TdotgridHandle"];
                rshandle.handleType=kResizeHandle;
                rshandle.Position=ccp(curAnch.Position.x+spaceBetweenAnchors,curAnch.Position.y);
                [rshandle handleMessage:kDWsetupStuff];
            }
            
            if(curAnch.moveHandle)
            {
                DWDotGridHandleGameObject *mvhandle = [DWDotGridHandleGameObject alloc];
                [gw populateAndAddGameObject:mvhandle withTemplateName:@"TdotgridHandle"];
                mvhandle.handleType=kMoveHandle;
                mvhandle.Position=ccp(curAnch.Position.x, curAnch.Position.y+spaceBetweenAnchors);
                [mvhandle handleMessage:kDWsetupStuff];
            }
        }
      
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;
    
    
    [gw Blackboard].PickupObject=nil;
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    if(gw.Blackboard.FirstAnchor) gameState=kStartAnchor;
    
    
 }

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    //if([BLMath DistanceBetween:location and:lastTouch]>spaceBetweenAnchors/1.5)
    //{
    lastTouch=location;
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    if(gw.Blackboard.FirstAnchor) [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];   
    //}
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    isTouching=NO;
    gameState=kNoState;
    
//    DWDotGridAnchorGameObject *anchStart=(DWDotGridAnchorGameObject*)gw.Blackboard.FirstAnchor;
//    DWDotGridAnchorGameObject *anchEnd=(DWDotGridAnchorGameObject*)gw.Blackboard.LastAnchor;
//    
//    NSLog(@"anchStart x %d y %d / anchEnd x %d y %d", anchStart.myXpos, anchStart.myYpos, anchEnd.myXpos, anchEnd.myYpos);
    [self checkAnchors];
    
    
    gw.Blackboard.FirstAnchor=nil;
    gw.Blackboard.LastAnchor=nil;
    
    // Draw object, empty selected objects - make sure that no objects say they're selected
    
    
    for(int i=0;i<[gw.Blackboard.SelectedObjects count];i++)
    {
        DWDotGridAnchorGameObject *anch = [gw.Blackboard.SelectedObjects objectAtIndex:i];
        anch.CurrentlySelected=NO;
    }
    [gw.Blackboard.SelectedObjects removeAllObjects];
     
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    // empty selected objects
    gw.Blackboard.FirstAnchor=nil;
    gw.Blackboard.LastAnchor=nil;

    // empty selected objects
    for(int i=0;i<[gw.Blackboard.SelectedObjects count];i++)
    {
        DWDotGridAnchorGameObject *anch = [gw.Blackboard.SelectedObjects objectAtIndex:i];
        anch.CurrentlySelected=NO;
    }
    [gw.Blackboard.SelectedObjects removeAllObjects];
}

-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    
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


-(void) dealloc
{
    //write log on problem switch
    [gw writeLogBufferToDiskWithKey:@"DotGrid"];
    
    //tear down
    [gw release];
    [dotMatrix release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    

    [super dealloc];
}
@end
