//
//  LongDivision.m
//  belugapad
//
//  Created by David Amphlett on 25/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "LongDivision.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "DWDotGridAnchorGameObject.h"
#import "DWDotGridHandleGameObject.h"
#import "DWDotGridTileGameObject.h"
#import "DWDotGridShapeGameObject.h"
#import "BLMath.h"

@implementation LongDivision
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
        topSection=[[[CCLayer alloc]init] autorelease];
        bottomSection=[[[CCLayer alloc]init] autorelease];
        
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
    
    float currentTotal=0;

    for(int i=0;i<[selectedNumbers count];i++)
    {
        float curMultiplier=[[rowMultipliers objectAtIndex:i]floatValue];
        int curNumber=[[selectedNumbers objectAtIndex:i] intValue];
        
        currentTotal=currentTotal+(curNumber*curMultiplier);
        
    }
    
[lblCurrentTotal setString:[NSString stringWithFormat:@"%g", currentTotal]];
}


-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    dividend=[[pdef objectForKey:DIVIDEND] floatValue];
    divisor=[[pdef objectForKey:DIVISOR] floatValue];
    

    
    
}

-(void)createVisibleNumbers
{
    numberRows=[[NSMutableArray alloc]init];
    numberLayers=[[NSMutableArray alloc]init];
    [numberRows retain];
    [numberLayers retain];

    float rowMultiplierT=0.001f;
    
    // we have 3 visible at any one time, so this is the current rows
    for(int r=0;r<8;r++)
    {
        NSMutableArray *thisRow=[[NSMutableArray alloc]init];
        
        // add the current multiplier to our array of multipliers
        [rowMultipliers addObject:[NSNumber numberWithFloat:rowMultiplierT]];
        [selectedNumbers addObject:[NSNumber numberWithInt:0]];
        NSLog(@"selectednumber count %d", [selectedNumbers count]);
        
        // create a layer for each row of numbers
        CCLayer *thisLayer=[[[CCLayer alloc]init]autorelease];
        [bottomSection addChild:thisLayer];
        // now, on each row, create our 10 numbers
        
        for(int i=0;i<10;i++)
        {
              
            NSString *currentNumber=[NSString stringWithFormat:@"%g", i*rowMultiplierT];
            CCLabelTTF *number=[CCLabelTTF labelWithString:currentNumber fontName:PROBLEM_DESC_FONT fontSize:60.0f];
            [number setPosition:ccp((lx/2)+(i*120), 300-(r*80))];
            [thisLayer addChild:number];
            if(r!=1)[number setOpacity:50];
            [thisRow addObject:number];
            
        }
        
        [numberRows addObject:thisRow];
        [numberLayers addObject:thisLayer];
        
        rowMultiplierT=rowMultiplierT*10;
    }
    
    currentRowPos=0;
    activeRow=currentRowPos+1;
}

-(void)populateGW
{
    [renderLayer addChild:topSection];
    [renderLayer addChild:bottomSection];
    
    selectedNumbers=[[NSMutableArray alloc]init];
    [selectedNumbers retain];
    rowMultipliers=[[NSMutableArray alloc]init];
    [rowMultipliers retain];
    
    // add the selector to the middle of the screen
    
    CCSprite *selector=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/selection_pointer.png")];
    [selector setPosition:ccp(cx,cy)];
    [selector setOpacity:50];
    [renderLayer addChild:selector];
    
    // add the big multiplier behind the numbers
    CCLabelTTF *multiplier=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"x%g",divisor] fontName:PROBLEM_DESC_FONT fontSize:200.0f];
    [multiplier setPosition:ccp(820,202)];
    [multiplier setOpacity:25];
    [renderLayer addChild:multiplier];
    
    lblCurrentTotal=[CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [lblCurrentTotal setPosition:ccp(100,745)];
    [renderLayer addChild:lblCurrentTotal];
    
    [self createVisibleNumbers];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;
    touchStart=location;
    
    if(location.y>cx)topTouch=YES;
    if(location.y<cx)bottomTouch=YES;
    
    if(topTouch)NSLog(@"touching top");
    
    
    if(bottomTouch)
    {
        
        // this is the currently selected row
        if(location.y > 190 && location.y < 250)
        {
            startedInActiveRow=YES;
        }        
    }
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    //NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    
    if(topTouch)
    {
        
    }
    
    if(bottomTouch)
    {
        BOOL verticalTouch=NO;
        BOOL horizontTouch=NO;
        float touchMovementHoriz=fabsf(touchStart.x-location.x);
        float touchMovementVerti=fabsf(touchStart.y-location.y);

        
        if(touchMovementHoriz>15.0f)horizontTouch=YES;
        if(touchMovementVerti>10.0f)verticalTouch=YES;
        
        
        if(horizontTouch && startedInActiveRow && !doingVerticalDrag) {
        
            doingHorizontalDrag=YES;
            CGPoint diff=[BLMath SubtractVector:lastTouch from:location];
            diff = ccp(diff.x, 0);
            CCLayer *moveLayer = [numberLayers objectAtIndex:activeRow];
                      
            [moveLayer setPosition:ccpAdd(moveLayer.position, diff)];

        
        }
        
        if(verticalTouch && !doingHorizontalDrag)
        {
            doingVerticalDrag=YES;
            for(int i=0;i<[numberLayers count];i++)
            {
                CCLayer *moveLayer=[numberLayers objectAtIndex:i];
                CGPoint diff=[BLMath SubtractVector:lastTouch from:location];
                diff = ccp(0, diff.y);
                [moveLayer setPosition:ccpAdd(moveLayer.position, diff)];
                
                
            }
        }
        
    }
 
    lastTouch=location;
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    isTouching=NO;
    
    if(doingHorizontalDrag)
    {
        CGPoint diff=[BLMath SubtractVector:location from:touchStart];
        diff = ccp(diff.x, 0);
        
        CCLayer *moveLayer = [numberLayers objectAtIndex:activeRow];

        //the quantity of increments moved
        float floatNumberPos=fabsf(diff.x)/120.0f;
        
        //the remainder of the movement past the last whole increment
        float remainder=floatNumberPos - (int)floatNumberPos;
        
        //by how much should the line be incremented
        int incrementor=0;
        
        //round up
        if(remainder>0.5f)
            incrementor=(int)floatNumberPos+1;
        //round down
        else
            incrementor=(int)floatNumberPos;
        
        //if the diff in x is positive, the number wants to go up (end point of x is less that of start point) 
        if(diff.x > 0) // incrementing line
            currentNumberPos+=incrementor;
        //otherwise the number on the line goes down
        else 
            currentNumberPos-=incrementor;
        
        //truncate to fixed bounds
        if(currentNumberPos<0)currentNumberPos=0;
        if(currentNumberPos>9)currentNumberPos=9;
        
        //reposition layer, relative to the number indicated (incrementing line means moving it left, hence x moved negative as n moves positive)
        [moveLayer runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(currentNumberPos*-120,moveLayer.position.y)]];
        [selectedNumbers replaceObjectAtIndex:activeRow withObject:[NSNumber numberWithInt:currentNumberPos]];
    }
    
    if(doingVerticalDrag)
    {
        CGPoint diff=[BLMath SubtractVector:location from:touchStart];
        diff = ccp(0, diff.y);
        
        //the quantity of increments moved
        float floatRowPos=fabsf(diff.y)/80.0f;
        NSLog(@"floatrowpos %f", floatRowPos);
        
        //the remainder of the movement past the last whole increment
        float remainder=floatRowPos - (int)floatRowPos;
        
        //by how much should the line be incremented
        int incrementor=0;
        
        //round up
        if(remainder>0.5f)
            incrementor=(int)floatRowPos+1;
        //round down
        else
            incrementor=(int)floatRowPos;
        
        NSLog(@"incrementor %d", incrementor);
        
        //if the diff in x is positive, the number wants to go up (end point of x is less that of start point) 
        if(diff.y > 0) // incrementing line
            currentRowPos-=incrementor;
        //otherwise the number on the line goes down
        else 
            currentRowPos+=incrementor;
        NSLog(@"currentrowpos %d", currentRowPos);
        
        //truncate to fixed bounds
        if(currentRowPos<-1)currentRowPos=-1;
        if(currentRowPos>6)currentRowPos=6;
  
        activeRow=currentRowPos+1;
        
        NSLog(@"currentrowpos %d", currentRowPos);
        //reposition layer, relative to the number indicated (incrementing line means moving it left, hence x moved negative as n moves positive)
        
        for(int i=0;i<[numberLayers count];i++)
        {
            CCLayer *moveLayer=[numberLayers objectAtIndex:i];
            [moveLayer runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(moveLayer.position.x,currentRowPos*80)]];
            for(CCLabelTTF *lbl in moveLayer.children)
            {
                if(i == activeRow) [lbl setOpacity:255];
                else [lbl setOpacity:50];
            }
            
        }
        
    }
    
    topTouch=NO;
    bottomTouch=NO;
    startedInActiveRow=NO;
    doingHorizontalDrag=NO;
    doingVerticalDrag=NO;
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    topTouch=NO;
    bottomTouch=NO;
    startedInActiveRow=NO;
    doingHorizontalDrag=NO;
    doingVerticalDrag=NO;
}

-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    
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
    [gw writeLogBufferToDiskWithKey:@"LongDivision"];
    
    //tear down
    [gw release];
    if(numberRows)[numberRows release];
    if(numberLayers)[numberLayers release];
    if(selectedNumbers)[selectedNumbers release];
    if(rowMultipliers)[rowMultipliers retain];

    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    
    [super dealloc];
}
@end
