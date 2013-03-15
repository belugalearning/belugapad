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
#import "InteractionFeedback.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "LoggingService.h"
#import "UsersService.h"
#import "AppDelegate.h"
#import "SimpleAudioEngine.h"

@interface TimesTables()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

static float kTimeToHeaderBounce=7.0f;

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
        loggingService = ac.loggingService;
        
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
    
    timeSinceInteractionOrDropHeader+=delta;
    
    if(timeSinceInteractionOrDropHeader>kTimeToHeaderBounce)
    {
        BOOL isWinning=[self evalExpression];
        if(!hasUsedHeaderX)
        {

            NSMutableArray *a=[headerLabels objectAtIndex:0];
            
            for(CCLabelTTF *l in a)
            {
                [l runAction:[InteractionFeedback dropAndBounceAction]];
            }
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_timestable_interaction_feedback_rows_and_columns_shaking.wav")];
            timeSinceInteractionOrDropHeader=0.0f;
        }
        else if(!hasUsedHeaderY)
        {
            NSMutableArray *a=[headerLabels objectAtIndex:1];
            
            for(CCLabelTTF *l in a)
            {
                [l runAction:[InteractionFeedback dropAndBounceAction]];
            }
            
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_timestable_interaction_feedback_rows_and_columns_shaking.wav")];
            timeSinceInteractionOrDropHeader=0.0f;
        }
        
        if(isWinning)[toolHost shakeCommitButton];
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

    spaceBetweenAnchors=46;
    startX=[[pdef objectForKey:START_X] intValue];
    startY=[[pdef objectForKey:START_Y] intValue];
    operatorMode=[[pdef objectForKey:OPERATOR_MODE]intValue];
    operatorMode=2;
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
    if([pdef objectForKey:DISABLED_TILES])disabledTiles=[pdef objectForKey:DISABLED_TILES];
    
    
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

    [usersService notifyStartingFeatureKey:@"TIMESTABLES_SELECT_TILE"];
}

-(void)populateGW
{
    is12x12=YES;
    
    NSString *operatorFileName=[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/timestables/TT_Operator.png"), operatorName];
    ttMatrix=[[NSMutableArray alloc]init];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    int amtForX=10;
    int amtForY=10;
    float yPos=(amtForY+1.5)*spaceBetweenAnchors;
    float xStartPos=300;

    if(is12x12)
    {
        amtForX=12;
        amtForY=12;
        yPos=(amtForY+0.5)*spaceBetweenAnchors;
    }
    
    int xStartNumber=startX;
    int yStartNumber=amtForY-1;
    
    
    CCSprite *operator = [CCSprite spriteWithFile:operatorFileName];
    
    [operator setTag:1];
    [operator setOpacity:0];
    [operator setPosition:ccp(xStartPos-spaceBetweenAnchors,yPos+15)];
    [self.ForeLayer addChild:operator];
    
    NSMutableArray *xHeaders=[[NSMutableArray alloc]init];
    NSMutableArray *yHeaders=[[NSMutableArray alloc]init];
    [headerLabels addObject:xHeaders];
    [headerLabels addObject:yHeaders];
    
    // render the times table grid
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
            
            if(is12x12)yStartPos=(iCol+0.5)*spaceBetweenAnchors;
            
            yStartPos+=15;
            
            DWTTTileGameObject *tile = [DWTTTileGameObject alloc];
            [gw populateAndAddGameObject:tile withTemplateName:@"TtimestablesTile"];        
            
            if(iRow==0 && showYAxis)
            {
                CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/TT_Number_BG.png")];
                [s setPosition:ccp(xStartPos-spaceBetweenAnchors,yStartPos)];
                [s setTag:1];
                [s setOpacity:0];
            
                
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", yStartNumber+1] fontName:CHANGO fontSize:20.0f];
                [curLabel setPosition:ccp(s.contentSize.width/2, s.contentSize.height/2)];
                [curLabel setTag:2];
                [curLabel setOpacity:0];

                if(!tile.isEndYPiece)
                {
                    [self.ForeLayer addChild:s];
                    [s addChild:curLabel];
                }

                [yHeaders addObject:s];
                yStartNumber--;
            }
            
            if(iCol==amtForY-1 && showXAxis) {
                
                    
                CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/TT_Number_BG.png")];
                [s setPosition:ccp(xStartPos,yStartPos+spaceBetweenAnchors)];
                [s setTag:1];
                [s setOpacity:0];
                
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", xStartNumber]fontName:CHANGO fontSize:20.0f];
                [curLabel setPosition:ccp(s.contentSize.width/2, s.contentSize.height/2)];
                
                if(!tile.isEndXPiece)
                {
                    [self.ForeLayer addChild:s];
                    [s addChild:curLabel];
                    [xHeaders addObject:s];
                }

                [curLabel setTag:2];
                [curLabel setOpacity:0];
                
            }
            
            tile.Position=ccp(xStartPos,yStartPos);
            tile.myXpos=xStartNumber;
            tile.myYpos=amtForY-iCol;
            tile.operatorType=operatorMode;
            tile.Size=spaceBetweenAnchors;
            NSLog(@"iRow %d amtForX %d // iCol %d amtForY %d", iRow, amtForX, iCol, amtForY);

            [currentCol addObject:tile];
            
            [tile release];

        }
        
        xStartNumber++;
        xStartPos=xStartPos+spaceBetweenAnchors;
        [ttMatrix addObject:currentCol];

        [currentCol release];
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
    
    
    if(disabledTiles)
    {
        for(NSDictionary *d in disabledTiles)
        {
            int thisX=[[d objectForKey:@"X"]intValue];
            int thisY=[[d objectForKey:@"Y"]intValue];
            
            DWTTTileGameObject *t=[[ttMatrix objectAtIndex:thisX-1] objectAtIndex:fabs(thisY-amtForY)];
            
            t.Disabled=YES;
        }
    }
    
    [xHeaders release];
    [yHeaders release];
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
    hasUsedHeaderY=YES;
    BOOL haveLogged=NO;
    BOOL tinted=[[rowTints objectAtIndex:thisRow] boolValue];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_timestable_general_row_or_column_highlighted.wav")];
    
    for(int i=0;i<[ttMatrix count];i++)
    {
        DWTTTileGameObject *tile=[[ttMatrix objectAtIndex:i]objectAtIndex:thisRow];
        if(tile.Disabled)continue;
        
        if(tinted)
        {
            //untint -- so long as it's not in a row
            if (![[colTints objectAtIndex:i] boolValue])
            {
                CCSprite *rowSprite=[[headerLabels objectAtIndex:1] objectAtIndex:thisRow];
                CCLabelTTF *l=[rowSprite.children objectAtIndex:0];
                [l setColor:ccc3(255,255,255)];
                
                [rowSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Number_BG.png")]];
                [tile.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Grid_Block.png")]];
            
                if(!haveLogged)
                {
                    [loggingService logEvent:BL_PA_TT_TOUCH_BEGIN_UNHIGHLIGHT_ROW
                        withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:thisRow] forKey:@"unhighlightRow"]];
                    haveLogged=YES;
                }
            }
        }
        else {
            //tint it
            CCSprite *rowSprite=[[headerLabels objectAtIndex:1] objectAtIndex:thisRow];
            CCLabelTTF *l=[rowSprite.children objectAtIndex:0];
            [l setColor:ccc3(0,0,0)];
            [rowSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Number_BG_Highlighted.png")]];
            [tile.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Grid_Block_Highlighted.png")]];
            
            if(!haveLogged)
            {
                [loggingService logEvent:BL_PA_TT_TOUCH_BEGIN_HIGHLIGHT_ROW
                    withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:thisRow] forKey:@"highlightRow"]];
                haveLogged=YES;
            }
        }
    }
    
    [rowTints replaceObjectAtIndex:thisRow withObject:[NSNumber numberWithBool:!tinted]];
 
}

-(void)tintCol:(int)thisCol
{
    hasUsedHeaderX=YES;
    BOOL haveLogged=NO;
    BOOL tinted=[[colTints objectAtIndex:thisCol] boolValue];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_timestable_general_row_or_column_highlighted.wav")];
    
    for(int i=0;i<[[ttMatrix objectAtIndex:thisCol]count];i++)
    {
        DWTTTileGameObject *tile=[[ttMatrix objectAtIndex:thisCol]objectAtIndex:i];
        if(tile.Disabled)continue;

        if(tinted)
        {
            //untint -- so long as it's not in a row
            if (![[rowTints objectAtIndex:i] boolValue])
            {
                CCSprite *rowSprite=[[headerLabels objectAtIndex:0] objectAtIndex:thisCol];
                CCLabelTTF *l=[rowSprite.children objectAtIndex:0];
                [l setColor:ccc3(255,255,255)];
                [rowSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Number_BG.png")]];
                [tile.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Grid_Block.png")]];
            
                if (!haveLogged)
                {
                    [loggingService logEvent:BL_PA_TT_TOUCH_BEGIN_UNHIGHLIGHT_COLUMN
                        withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:thisCol] forKey:@"unhighlightCol"]];
                    haveLogged=YES;
                }
                
            }
        }
        else {
            //tint it
            CCSprite *rowSprite=[[headerLabels objectAtIndex:0] objectAtIndex:thisCol];
            CCLabelTTF *l=[rowSprite.children objectAtIndex:0];
            [l setColor:ccc3(0,0,0)];

            [rowSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Number_BG_Highlighted.png")]];
            [tile.mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/timestables/TT_Grid_Block_Highlighted.png")]];
            if(!haveLogged)
            {
                [loggingService logEvent:BL_PA_TT_TOUCH_BEGIN_HIGHLIGHT_COLUMN
                    withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:thisCol] forKey:@"highlightCol"]];
                haveLogged=YES;
            }
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
    lastTouch=location;
    timeSinceInteractionOrDropHeader=0.0f;
    
    
    [gw Blackboard].PickupObject=nil;
    
    for(int o=0;o<[headerLabels count];o++)
    {
        NSArray *theseNumbers=[headerLabels objectAtIndex:o];
        
        for(int i=0;i<[theseNumbers count];i++)
        {
            CCSprite *curLabel=[theseNumbers objectAtIndex:i];
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
        NSMutableArray *selectedTiles=[[NSMutableArray alloc]init];
        
        for(int o=0;o<[gw.Blackboard.SelectedObjects count];o++)
        {
            DWTTTileGameObject *selTile=[gw.Blackboard.SelectedObjects objectAtIndex:o];
            
            for(int i=0;i<[solutionsDef count];i++)
            {
                if(selTile.Selected && ![selectedTiles containsObject:selTile])[selectedTiles addObject:selTile];
                
                NSMutableDictionary *curDict=[solutionsDef objectAtIndex:i];
                int thisAnsX=[[curDict objectForKey:POS_X]intValue];
                int thisAnsY=[[curDict objectForKey:POS_Y]intValue];
                NSLog(@"thisAnsX=%d, thisAnsY=%d, myXpos=%d, myYpos=%d", thisAnsX, thisAnsY, selTile.myXpos, selTile.myYpos);
                
                if(thisAnsX==selTile.myXpos && thisAnsY==selTile.myYpos && !switchXYforAnswer)
                {
                    answersFound++;
                }
                else if(thisAnsY==selTile.myXpos && thisAnsX==selTile.myYpos && switchXYforAnswer)
                {
                    answersFound++;
                }
            }
        }
        
        BOOL isCorrect=NO;
        
        if(answersFound==[solutionsDef count] && answersFound==[selectedTiles count])
            isCorrect=YES;
        else
            isCorrect=NO;
        
        [selectedTiles release];
        
        return isCorrect;
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

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    
}

#pragma mark - dealloc
-(void) dealloc
{
    [renderLayer release];
    
    if(ttMatrix)[ttMatrix release];
    if(activeCols)[activeCols release];
    if(activeRows)[activeRows release];
    if(headerLabels)[headerLabels release];
    if(solutionsDef)[solutionsDef release];
    if(revealRows)[revealRows release];
    if(revealCols)[revealCols release];
    if(revealTiles)[revealTiles release];
    
    [rowTints release];
    [colTints release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];

    [gw release];

    [super dealloc];
}
@end
