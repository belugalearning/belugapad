//
//  DotGrid.m
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "TimesTables.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "BLMath.h"
#import "DWTTTileGameObject.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"

@implementation TimesTables
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
        
        [self revealRows];
        
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
}


-(void)readPlist:(NSDictionary*)pdef
{
    activeRows=nil;
    activeCols=nil;
    revealRows=nil;
    revealCols=nil;
    headerLabels=[[NSMutableArray alloc]init];
    
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    spaceBetweenAnchors=[[pdef objectForKey:ANCHOR_SPACE] intValue];
    startX=[[pdef objectForKey:START_X] intValue];
    startY=[[pdef objectForKey:START_Y] intValue];
    operatorMode=[[pdef objectForKey:OPERATOR_MODE]intValue];
    if([pdef objectForKey:SHOW_X_AXIS])showXAxis=[[pdef objectForKey:SHOW_X_AXIS]boolValue];
    else showXAxis=YES;
    
    if([pdef objectForKey:SHOW_Y_AXIS])showYAxis=[[pdef objectForKey:SHOW_Y_AXIS]boolValue];
    else showYAxis=YES;
    
    if([pdef objectForKey:ALLOW_X_HIGHLIGHT])allowHighlightX=[[pdef objectForKey:ALLOW_X_HIGHLIGHT]boolValue];
    else allowHighlightX=YES;
    
    if([pdef objectForKey:ALLOW_Y_HIGHLIGHT])allowHighlightY=[[pdef objectForKey:ALLOW_Y_HIGHLIGHT]boolValue];
    else allowHighlightY=YES;
    
    if([pdef objectForKey:SHOW_CALC_BUBBLE])showCalcBubble=[[pdef objectForKey:SHOW_CALC_BUBBLE]boolValue];
    else showCalcBubble=NO;
    
    if([pdef objectForKey:SWITCH_XY_ANSWER])switchXYforAnswer=[[pdef objectForKey:SWITCH_XY_ANSWER]boolValue];
    else switchXYforAnswer=NO;
    
    if([pdef objectForKey:SOLUTIONS])solutionsDef=[pdef objectForKey:SOLUTIONS];
    if([pdef objectForKey:ACTIVE_ROWS])activeRows=[pdef objectForKey:ACTIVE_ROWS];
    if([pdef objectForKey:ACTIVE_COLS])activeCols=[pdef objectForKey:ACTIVE_COLS];
    if([pdef objectForKey:REVEAL_ROWS])revealRows=[pdef objectForKey:REVEAL_ROWS];
    if([pdef objectForKey:REVEAL_COLS])revealCols=[pdef objectForKey:REVEAL_COLS];
    if([pdef objectForKey:REVEAL_TILES])revealTiles=[pdef objectForKey:REVEAL_TILES];
    
    
    if(operatorMode==0)operatorName=@"add";
    else if(operatorMode==1)operatorName=@"sub";
    else if(operatorMode==2)operatorName=@"mul";
    else if(operatorMode==3)operatorName=@"div";
    
    [activeRows retain];
    [activeCols retain];
    [revealRows retain];
    [revealCols retain];
    [revealTiles retain];
    [solutionsDef retain];
}

-(void)populateGW
{
    NSString *operatorFileName=[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/timestables/operator-%@.png"), operatorName];
    ttMatrix=[[NSMutableArray alloc]init];
    [ttMatrix retain];
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    

    float xStartPos=spaceBetweenAnchors*2;

    int xStartNumber=startX;
    int yStartNumber=startY+((ly-spaceBetweenAnchors*3)/spaceBetweenAnchors)-1;
    
    CCSprite *operator = [CCSprite spriteWithFile:operatorFileName];
    [operator setPosition:ccp(xStartPos-spaceBetweenAnchors,ly-spaceBetweenAnchors*1.5)];
    [operator setTag:1];
    [operator setOpacity:0];
    [self.ForeLayer addChild:operator];

    NSMutableArray *xHeaders=[[NSMutableArray alloc]init];
    NSMutableArray *yHeaders=[[NSMutableArray alloc]init];
    [headerLabels addObject:xHeaders];
    [headerLabels addObject:yHeaders];
    [headerLabels retain];
    
    // render the times table grid
    
    for (int iRow=0; iRow<(int)(lx-spaceBetweenAnchors*3)/spaceBetweenAnchors; iRow++)
    {
        NSMutableArray *currentCol=[[NSMutableArray alloc]init];
        
        for(int iCol=0; iCol<(int)(ly-spaceBetweenAnchors*3)/spaceBetweenAnchors; iCol++)
        {
            
            // create our start position and gameobject
            float yStartPos=(iCol+1.5)*spaceBetweenAnchors;
            
            if(iRow==0 && showYAxis)
            {
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", yStartNumber] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [curLabel setPosition:ccp(xStartPos-spaceBetweenAnchors,yStartPos)];
                [curLabel setTag:2];
                [curLabel setOpacity:0];
                [self.ForeLayer addChild:curLabel];
                [yHeaders addObject:curLabel];
                yStartNumber--;
            }
            
            if(iCol==(int)((ly-spaceBetweenAnchors*3)/spaceBetweenAnchors)-1 && showXAxis) {
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", xStartNumber]fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [curLabel setPosition:ccp(xStartPos,yStartPos+spaceBetweenAnchors)];
                [self.ForeLayer addChild:curLabel];
                [curLabel setTag:2];
                [curLabel setOpacity:0];
                [xHeaders addObject:curLabel];
            }
            
            DWTTTileGameObject *tile = [DWTTTileGameObject alloc];
            [gw populateAndAddGameObject:tile withTemplateName:@"TtimestablesTile"];
            tile.Position=ccp(xStartPos,yStartPos);
            tile.myXpos=xStartNumber;
            tile.myYpos=startY+((ly-spaceBetweenAnchors*3)/spaceBetweenAnchors)-(iCol+1);
            tile.operatorType=operatorMode;
            tile.Size=spaceBetweenAnchors;
            
            //NSLog(@"iRow = %d, iCol = %d, tile.myXpos = %d, tile.myYpos = %d", iRow, iCol, tile.myXpos, tile.myYpos);
            

            [currentCol addObject:tile];
            

        }
        
        xStartNumber++;
        xStartPos=xStartPos+spaceBetweenAnchors;
        [ttMatrix addObject:currentCol];

        
    }    
    
    if(activeCols || activeRows)
    {
        for(int r=0;r<[ttMatrix count];r++)
        {
            NSArray *curCol=[ttMatrix objectAtIndex:r];
            
            for(int c=0;c<[curCol count];c++)
            {
                int thisX=0;
                int thisY=0;
                DWTTTileGameObject *tile=[curCol objectAtIndex:c];
                
                
            
                for(NSNumber *n in activeCols)
                {
                    thisX=[n intValue];
                    if(thisX==tile.myXpos)break;
                }
        
                for(NSNumber *n in activeRows)
                {
                    thisY=[n intValue];
                    if(thisY==tile.myYpos)break;
                }
            
                if(tile.myXpos == thisX || tile.myYpos == thisY)
                {
                    tile.Disabled=NO;
                }
                else {
                    tile.Disabled=YES;
                }
                
            }
        }
    }

    
    // add the selection ring to the scene
//    selection=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/selectionbox.png")];
//    [renderLayer addChild:selection z:100];
//    [selection setVisible:NO];
    
}

-(void)revealRows
{
    
    if(revealCols || revealRows)
    {
        for(int r=0;r<[ttMatrix count];r++)
        {
            NSArray *curCol=[ttMatrix objectAtIndex:r];
            
            for(int c=0;c<[curCol count];c++)
            {
                int thisX=0;
                int thisY=0;
                DWTTTileGameObject *tile=[curCol objectAtIndex:c];
                
                
                
                for(NSNumber *n in revealCols)
                {
                    thisX=[n intValue];
                    if(thisX==tile.myXpos)break;
                }
                
                for(NSNumber *n in revealRows)
                {
                    thisY=[n intValue];
                    if(thisY==tile.myYpos)break;
                }
                
                if(tile.myXpos == thisX || tile.myYpos == thisY)
                {
                    [tile handleMessage:kDWswitchSelection];
                }
                
            }
        }
    }
    
    if(revealTiles)
    {
        for(int r=0;r<[ttMatrix count];r++)
        {
            NSArray *curCol=[ttMatrix objectAtIndex:r];
            
            for(int c=0;c<[curCol count];c++)
            {
                int thisX=0;
                int thisY=0;
                DWTTTileGameObject *tile=[curCol objectAtIndex:c];
                
                for(int p=0;p<[revealTiles count];p++)
                {
                    thisX=[[[revealTiles objectAtIndex:p] objectForKey:POS_X]intValue];
                    thisY=[[[revealTiles objectAtIndex:p] objectForKey:POS_Y]intValue];
                    
                    if(tile.myXpos == thisX && tile.myYpos == thisY)
                    {
                        [tile handleMessage:kDWswitchSelection];
                    }
                }
                
            }
        }

    }
}

-(void)tintRow:(int)thisRow
{
    for(int i=0;i<[ttMatrix count];i++)
    {
        DWTTTileGameObject *tile=[[ttMatrix objectAtIndex:i]objectAtIndex:thisRow];
        if(tile.Disabled)continue;
        if(thisRow == currentXHighlightNo && currentXHighlight && tile.myYpos!=currentYHighlight && !currentYHighlight)[tile.mySprite setColor:ccc3(255,255,255)];
        else [tile.mySprite setColor:ccc3(0,255,0)];
        
    }
    
    if(thisRow == currentXHighlightNo && currentXHighlight)
    {
        currentXHighlight=NO;
        currentXHighlightNo=-1;
    }
    else { 
        currentXHighlight=YES;
        currentXHighlightNo=thisRow;
    }
    
    
}

-(void)tintCol:(int)thisCol
{
    for(int i=0;i<[[ttMatrix objectAtIndex:thisCol]count];i++)
    {
        DWTTTileGameObject *tile=[[ttMatrix objectAtIndex:thisCol]objectAtIndex:i];
        if(tile.Disabled)continue;
        if(thisCol == currentYHighlightNo && currentYHighlight)[tile.mySprite setColor:ccc3(255,255,255)];
        else [tile.mySprite setColor:ccc3(0,255,0)];
    }
    
    if(thisCol == currentYHighlightNo && currentYHighlight)
    {
        currentYHighlight=NO;
        currentYHighlightNo=-1;
    }
    else { 
        currentYHighlight=YES;
        currentYHighlightNo=thisCol;
    }
    
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
    
    for(int o=0;o<[headerLabels count];o++)
    {
        NSArray *theseNumbers=[headerLabels objectAtIndex:o];
        
        for(int i=0;i<[theseNumbers count];i++)
        {
            CCLabelTTF *curLabel=[theseNumbers objectAtIndex:i];
            if(CGRectContainsPoint(curLabel.boundingBox, location))
            {
                if(o==0 && allowHighlightY) [self tintCol:i];
                if(o==1 && allowHighlightX) [self tintRow:i];
            }
        }
    }
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    
    
    if(gw.Blackboard.LastSelectedObject && showCalcBubble)[gw.Blackboard.LastSelectedObject handleMessage:kDWshowCalcBubble];
    if(gw.Blackboard.LastSelectedObject && evalMode==kProblemEvalAuto) [self evalProblem];
    
    
 }

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;
    
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    //gw.Blackboard.LastSelectedObject=nil;

     
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    //gw.Blackboard.LastSelectedObject=nil;
    // empty selected objects
}

-(BOOL)evalExpression
{
    if(!solutionsDef)return NO;
    if([gw.Blackboard.SelectedObjects count]<[solutionsDef count])return NO;
    
    int answersFound=0;
    
    for(int o=0;o<[gw.Blackboard.SelectedObjects count];o++)
    {
        DWTTTileGameObject *selTile=[gw.Blackboard.SelectedObjects objectAtIndex:o];
        NSLog(@"selTile X=%d, selTile Y=%d", selTile.myXpos, selTile.myYpos);
        
        for(int i=0;i<[solutionsDef count];i++)
        {
            NSMutableDictionary *curDict=[solutionsDef objectAtIndex:i];
            int thisAnsX=[[curDict objectForKey:POS_X]intValue];
            int thisAnsY=[[curDict objectForKey:POS_Y]intValue];
            NSLog(@"thisAnsX=%d, thisAnsY=%d", thisAnsX, thisAnsY);
            
            if(thisAnsX==selTile.myXpos && thisAnsY==selTile.myYpos && !switchXYforAnswer)answersFound++;
            else if(thisAnsY==selTile.myXpos && thisAnsX==selTile.myYpos && switchXYforAnswer)answersFound++;
        }
    }
    
    
    if(answersFound==[solutionsDef count])return YES;
    else return NO;

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

-(void)resetProblem
{
    [toolHost showProblemIncompleteMessage];
    [toolHost resetProblem];
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
    [gw writeLogBufferToDiskWithKey:@"TimesTables"];
    
    //tear down
    [gw release];
    if(ttMatrix)[ttMatrix release];
    if(activeCols)[activeCols release];
    if(activeRows)[activeRows release];
    if(headerLabels)[headerLabels release];
    if(solutionsDef)[solutionsDef release];
    if(revealRows)[revealRows release];
    if(revealCols)[revealCols release];
    if(revealTiles)[revealTiles release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    

    [super dealloc];
}
@end
