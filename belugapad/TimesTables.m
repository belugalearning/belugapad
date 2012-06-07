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
#import "UsersService.h"
#import "AppDelegate.h"

@interface TimesTables()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation TimesTables

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

#pragma mark - gameworld setup and population
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
    selectionMode=[[pdef objectForKey:SELECTION_MODE]intValue];
    if([pdef objectForKey:REVEAL_ALL_TILES])revealAllTiles=[[pdef objectForKey:REVEAL_ALL_TILES]boolValue];
    else revealAllTiles=NO;
    
    
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
    
    if([pdef objectForKey:SOLUTION_MODE])solutionType=[[pdef objectForKey:SOLUTION_MODE]intValue];
    if(solutionType==kSolutionVal)
    {
        solutionValue=[[pdef objectForKey:SOLUTION_VALUE]intValue];
        solutionComponent=[[pdef objectForKey:SOLUTION_COMPONENT]intValue];
        
    }
    
    
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
    
    int amtForX=(int)((lx-spaceBetweenAnchors*3)/spaceBetweenAnchors)+1;
    int amtForY=(int)((ly-spaceBetweenAnchors*3)/spaceBetweenAnchors)+1;
    
    rowTints=[[NSMutableArray alloc] init];
    colTints=[[NSMutableArray alloc] init];
    
    for (int i=0; i<amtForY; i++) { [rowTints addObject:[NSNumber numberWithBool:NO]]; }
    for (int i=0; i<amtForX; i++) { [colTints addObject:[NSNumber numberWithBool:NO]]; }
    
    for (int iRow=0; iRow<amtForX; iRow++)
    {
        NSMutableArray *currentCol=[[NSMutableArray alloc]init];
        
        for(int iCol=0; iCol<amtForY; iCol++)
        {
            // create our start position and gameobject
            float yStartPos=(iCol+1.5)*spaceBetweenAnchors;
            DWTTTileGameObject *tile = [DWTTTileGameObject alloc];
            [gw populateAndAddGameObject:tile withTemplateName:@"TtimestablesTile"];
            
            if(iRow==amtForX-1 && iCol==0)
            {
                tile.isCornerPiece=YES;
                tile.Disabled=YES;
            }
            else if(iRow==amtForX-1)
            {
                tile.isEndXPiece=YES;
                tile.Disabled=YES;
            }
            else if(iCol==0)
            {
                tile.isEndYPiece=YES;
                tile.Disabled=YES;
            }
        
            
            if(iRow==0 && showYAxis)
            {
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", yStartNumber+1] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [curLabel setPosition:ccp(xStartPos-spaceBetweenAnchors,yStartPos)];
                [curLabel setTag:2];
                [curLabel setOpacity:0];

                if(!tile.isEndYPiece)
                {
                    [self.ForeLayer addChild:curLabel];
                }
                [yHeaders addObject:curLabel];
                yStartNumber--;
            }
            
            if(iCol==amtForY-1 && showXAxis) {
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", xStartNumber]fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [curLabel setPosition:ccp(xStartPos,yStartPos+spaceBetweenAnchors)];
                if(!tile.isEndXPiece)
                {
                    [self.ForeLayer addChild:curLabel];
                    [xHeaders addObject:curLabel];
                }

                [curLabel setTag:2];
                [curLabel setOpacity:0];
                
            }
            
            tile.Position=ccp(xStartPos,yStartPos);
            tile.myXpos=xStartNumber;
            tile.myYpos=startY+((ly-spaceBetweenAnchors*3)/spaceBetweenAnchors)-iCol;
            tile.operatorType=operatorMode;
            tile.Size=spaceBetweenAnchors;
            NSLog(@"iRow %d amtForX %d // iCol %d amtForY %d", iRow, amtForX, iCol, amtForY);

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


}

#pragma mark - grid interaction
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

    if(revealAllTiles)
    {
        for(int r=0;r<[ttMatrix count];r++)
        {
            NSArray *curCol=[ttMatrix objectAtIndex:r];
            
            for(int c=0;c<[curCol count];c++)
            {

                DWTTTileGameObject *tile=[curCol objectAtIndex:c];                
                [tile handleMessage:kDWswitchSelection];
                
            }
        }
        
    }
}

-(void)tintRow:(int)thisRow
{
    BOOL haveLogged=NO;
    BOOL tinted=[[rowTints objectAtIndex:thisRow] boolValue];
    
    for(int i=0;i<[ttMatrix count];i++)
    {
        DWTTTileGameObject *tile=[[ttMatrix objectAtIndex:i]objectAtIndex:thisRow];
        if(tile.Disabled)continue;
        
        if(tinted)
        {
            //untint -- so long as it's not in a row
            if (![[colTints objectAtIndex:i] boolValue]) {
                [tile.mySprite setColor:ccc3(255,255,255)];
            
            if(!haveLogged)[usersService logProblemAttemptEvent:kProblemAttemptTimesTablesTouchBeginUnhighlightRow withOptionalNote:[NSString stringWithFormat:@"{\"unhighlightrow\":%d}",thisRow]];
            haveLogged=YES;
            }
        }
        else {
            //tint it
            [tile.mySprite setColor:ccc3(0,255,0)];
            
            if(!haveLogged)[usersService logProblemAttemptEvent:kProblemAttemptTimesTablesTouchBeginHighlightRow withOptionalNote:[NSString stringWithFormat:@"{\"highlightrow\":%d}",thisRow]];
            haveLogged=YES;
        }
    }
    
    [rowTints replaceObjectAtIndex:thisRow withObject:[NSNumber numberWithBool:!tinted]];
 
}

-(void)tintCol:(int)thisCol
{
    BOOL haveLogged=NO;
    BOOL tinted=[[colTints objectAtIndex:thisCol] boolValue];

    for(int i=0;i<[[ttMatrix objectAtIndex:thisCol]count];i++)
    {
        DWTTTileGameObject *tile=[[ttMatrix objectAtIndex:thisCol]objectAtIndex:i];
        if(tile.Disabled)continue;

        if(tinted)
        {
            //untint -- so long as it's not in a row
            if (![[rowTints objectAtIndex:i] boolValue]) {
                [tile.mySprite setColor:ccc3(255,255,255)];
            
            if(!haveLogged)[usersService logProblemAttemptEvent:kProblemAttemptTimesTablesTouchBeginUnhighlightColumn withOptionalNote:[NSString stringWithFormat:@"{\"unhighlightcol\":%d}",thisCol]];
            haveLogged=YES;
                
            }
        }
        else {
            //tint it
            [tile.mySprite setColor:ccc3(0,255,0)];
            
            if(!haveLogged)[usersService logProblemAttemptEvent:kProblemAttemptTimesTablesTouchBeginHighlightColumn withOptionalNote:[NSString stringWithFormat:@"{\"highlightcol\":%d}",thisCol]];
            haveLogged=YES;
        }
    }
    
    [colTints replaceObjectAtIndex:thisCol withObject:[NSNumber numberWithBool:!tinted]];
        
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
    
    
    [gw Blackboard].PickupObject=nil;
    
    for(int o=0;o<[headerLabels count];o++)
    {
        NSArray *theseNumbers=[headerLabels objectAtIndex:o];
        
        for(int i=0;i<[theseNumbers count];i++)
        {
            CCLabelTTF *curLabel=[theseNumbers objectAtIndex:i];
            CGRect boundingBox=CGRectMake(curLabel.position.x-(spaceBetweenAnchors/2), curLabel.position.y-(spaceBetweenAnchors/2), spaceBetweenAnchors, spaceBetweenAnchors);
            if(CGRectContainsPoint(boundingBox, location))
            {
                if(o==0 && allowHighlightY) [self tintCol:i];
                if(o==1 && allowHighlightX) [self tintRow:i];
            }
        }
    }
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    
    
    if(gw.Blackboard.LastSelectedObject)
    {
        if(selectionMode==kSelectSingle)
        {
            // if there's another selection, send the handletap message
            if([gw.Blackboard.SelectedObjects count]>0)
            {
                for(DWTTTileGameObject *t in gw.Blackboard.SelectedObjects)
                {
                    [t handleMessage:kDWhandleTap];
                }
            }
            
            [gw.Blackboard.LastSelectedObject handleMessage:kDWhandleTap];
        }
        else if(selectionMode==kSelectMulti)
        {
            [gw.Blackboard.LastSelectedObject handleMessage:kDWhandleTap];   
        }
        
        
        if(showCalcBubble)[gw.Blackboard.LastSelectedObject handleMessage:kDWshowCalcBubble];
        if(evalMode==kProblemEvalAuto)[self evalProblem];
    }
    
    
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
    gw.Blackboard.LastSelectedObject=nil;

     
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    gw.Blackboard.LastSelectedObject=nil;
    // empty selected objects
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    if(!solutionsDef && solutionType==kMatrixMatch)return NO;
    if([gw.Blackboard.SelectedObjects count]<[solutionsDef count] && solutionType==kMatrixMatch)return NO;
    
    int answersFound=0;
    if(solutionType==kMatrixMatch)
    {
        
        
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
    
    if(solutionType==kSolutionVal)
    {
        for(int o=0;o<[gw.Blackboard.SelectedObjects count];o++)
        {
            DWTTTileGameObject *selTile=[gw.Blackboard.SelectedObjects objectAtIndex:o];
            NSLog(@"selTile X=%d, selTile Y=%d", selTile.myXpos, selTile.myYpos);
            

                int thisAnsX=selTile.myXpos;
                int thisAnsY=selTile.myYpos;
                
                if(operatorMode==kOperatorAdd)
                    if(thisAnsX+thisAnsY==solutionValue && (thisAnsX==solutionComponent||thisAnsY==solutionComponent))answersFound++;
                if(operatorMode==kOperatorSub)
                    if(thisAnsX-thisAnsY==solutionValue && (thisAnsX==solutionComponent||thisAnsY==solutionComponent))answersFound++;
                if(operatorMode==kOperatorMul)
                    if(thisAnsX*thisAnsY==solutionValue && (thisAnsX==solutionComponent||thisAnsY==solutionComponent))answersFound++;
                if(operatorMode==kOperatorDiv)
                    if(thisAnsX/thisAnsY==solutionValue && (thisAnsX==solutionComponent||thisAnsY==solutionComponent))answersFound++;
                
        }

        
        
        if(answersFound>0)return YES;
    }
    
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
