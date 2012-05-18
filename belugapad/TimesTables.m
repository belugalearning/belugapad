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
    
    if([pdef objectForKey:SOLUTIONS])solutionsDef=[pdef objectForKey:SOLUTIONS];
    if([pdef objectForKey:ACTIVE_ROWS])activeRows=[pdef objectForKey:ACTIVE_ROWS];
    if([pdef objectForKey:ACTIVE_COLS])activeCols=[pdef objectForKey:ACTIVE_COLS];
    
    if(operatorMode==0)operatorName=@"add";
    else if(operatorMode==1)operatorName=@"sub";
    else if(operatorMode==2)operatorName=@"mul";
    else if(operatorMode==3)operatorName=@"div";
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
    [self.ForeLayer addChild:operator];
    
    // render the times table grid
    
    for (int iRow=0; iRow<(int)(lx-spaceBetweenAnchors*3)/spaceBetweenAnchors; iRow++)
    {
        NSMutableArray *currentCol=[[NSMutableArray alloc]init];
        BOOL currentRowHidden=NO;
        
        for(int iCol=0; iCol<(int)(ly-spaceBetweenAnchors*3)/spaceBetweenAnchors; iCol++)
        {
            
            // create our start position and gameobject
            float yStartPos=(iCol+1.5)*spaceBetweenAnchors;
            
            if(iRow==0 && showYAxis)
            {
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", yStartNumber] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [curLabel setPosition:ccp(xStartPos-spaceBetweenAnchors,yStartPos)];
                [self.ForeLayer addChild:curLabel];
                yStartNumber--;
            }
            
            if(iCol==(int)((ly-spaceBetweenAnchors*3)/spaceBetweenAnchors)-1 && showXAxis) {
                CCLabelTTF *curLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", xStartNumber]fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [curLabel setPosition:ccp(xStartPos,yStartPos+spaceBetweenAnchors)];
                [self.ForeLayer addChild:curLabel];
            }
            
            DWTTTileGameObject *tile = [DWTTTileGameObject alloc];
            [gw populateAndAddGameObject:tile withTemplateName:@"TtimestablesTile"];
            tile.Position=ccp(xStartPos,yStartPos);
            tile.myXpos=xStartNumber;
            tile.myYpos=startY+((ly-spaceBetweenAnchors*3)/spaceBetweenAnchors)-(iCol+1);
            
            if(activeRows && !tile.Disabled)
            {
                for(NSNumber *n in activeRows)
                {
                    int this=[n intValue];
                    if(this==tile.myXpos){tile.Disabled=NO;break;}
                    else{tile.Disabled=YES;}
                }
            }
            
//            if(activeCols && !tile.Disabled)
//            {
//                for(NSNumber *n in activeCols)
//                {
//                    int this=[n intValue];
//                    if(this==tile.myYpos){tile.Disabled=NO;break;}
//                    else{tile.Disabled=YES;}
//                }
//            }
            
            NSLog(@"iRow = %d, iCol = %d, tile.myXpos = %d, tile.myYpos = %d", iRow, iCol, tile.myXpos, tile.myYpos);
            
            
            // set the hidden property for every anchor on this row if 
//            if(hiddenRows && [hiddenRows objectForKey:[NSString stringWithFormat:@"%d", iCol]]) {
//                currentRowHidden=[[hiddenRows objectForKey:[NSString stringWithFormat:@"%d", iCol]] boolValue];
//                if(currentRowHidden) {
//                    tile.Disabled=YES;
//                }
//            }
        

            
            [currentCol addObject:tile];
            

        }
        
        xStartNumber++;
        xStartPos=xStartPos+spaceBetweenAnchors;
        [ttMatrix addObject:currentCol];
        
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
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    
    
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
 

     
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    // empty selected objects
}

-(BOOL)evalExpression
{
    return YES;
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
    [gw writeLogBufferToDiskWithKey:@"DotGrid"];
    
    //tear down
    [gw release];
    if(ttMatrix)[ttMatrix release];
    if(activeCols)[activeCols release];
    if(activeRows)[activeRows release];
    if(solutionsDef)[solutionsDef release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    

    [super dealloc];
}
@end
