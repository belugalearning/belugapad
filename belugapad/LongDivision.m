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

    float rowMultiplierT=0.1f;
    
    // we have 3 visible at any one time, so this is the current rows
    for(int r=0;r<3;r++)
    {
        NSMutableArray *thisRow=[[NSMutableArray alloc]init];
        
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
}

-(void)populateGW
{
    [renderLayer addChild:topSection];
    [renderLayer addChild:bottomSection];
    
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
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    
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
            CCLayer *moveLayer = [numberLayers objectAtIndex:1];
                      
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
        // this code snaps to a number
        CGPoint diff=[BLMath SubtractVector:location from:touchStart];
        diff = ccp(diff.x, 0);
        int offsetPos=0;
        CCLayer *moveLayer = [numberLayers objectAtIndex:1];
        float floatNumberPos=-diff.x/120.0f;
        if(floatNumberPos>0.5f){
            floatNumberPos=-(floatNumberPos-0.5);
            currentNumberPos+=(int)floatNumberPos+1;
            offsetPos=(int)floatNumberPos+1;
        }       
        else {
            currentNumberPos+=(int)floatNumberPos; 
            offsetPos=(int)floatNumberPos;
        }
        
        NSLog(@"floatNumberPos %f", floatNumberPos);

        if(currentNumberPos<0)currentNumberPos=0;
        if(currentNumberPos>9)currentNumberPos=9;
        NSLog(@"currentNumberPos %d", currentNumberPos);
        NSLog(@"touchStart x %f / y %f", touchStart.x, touchStart.y);
        NSLog(@"touchEnd x %f / y %f", location.x, location.y);
        float remainder=fabsf(floatNumberPos)-fabsf(offsetPos);
        if(diff.x<0) remainder=-remainder;
        float moveBy=remainder*120;
        NSLog(@"moveBy %f", moveBy);
    
        //[moveLayer runAction:[CCMoveBy actionWithDuration:0.5f position:ccp(moveBy,0)]];
        [moveLayer runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(currentNumberPos*-120,0)]];
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

    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    
    [super dealloc];
}
@end
