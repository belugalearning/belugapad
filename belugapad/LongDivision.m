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

const float kSpaceBetweenNumbers=180;
const float kSpaceBetweenRows=80;

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
    
    if(((float)currentTotal*(float)divisor)!=fabsf(dividend))
        [lblCurrentTotal setColor:ccc3(255,0,0)];
    else 
        [lblCurrentTotal setColor:ccc3(0,255,0)];
    [lblCurrentTotal setString:[NSString stringWithFormat:@"%g", currentTotal]];
    
        
    for(int l=0;l<[numberRows count];l++)
    {
        
        NSArray *currentRow=[numberRows objectAtIndex:l];
        CCLayer *thisLayer=[numberLayers objectAtIndex:l];
        for(CCLabelTTF *lbl in currentRow)
        {
            CGPoint realLabelPos=[thisLayer convertToWorldSpace:lbl.position];
            //CGPoint realLabelPos=lbl.position;
            //float distToFade=0;
            float distToActive=[BLMath DistanceBetween:realLabelPos and:ccp(realLabelPos.x, 220)];

//            if(realLabelPos.y>220)
//                distToFade=[BLMath DistanceBetween:realLabelPos and:ccp(realLabelPos.x, 380)];
//            else 
//                distToFade=[BLMath DistanceBetween:realLabelPos and:ccp(realLabelPos.x, 50)];
            
            float prop=distToActive/150;
            float opac=(1-prop)*255;
            if(opac<0)opac=0;
            if(opac>255)opac=255;
            
            
            
            //if(opac<25)opac=0;
            [lbl setOpacity:opac];
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
            [number setPosition:ccp((lx/2)+(i*kSpaceBetweenNumbers), 300-(r*kSpaceBetweenRows))];
            [thisLayer addChild:number];
            //if(r!=1)[number setOpacity:50];
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
    
    line=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/line.png")];
    [line setPosition:ccp(cx,550)];
    [topSection addChild:line];
    
    [self createVisibleNumbers];
}
-(void)handlePassThruScaling:(float)scale
{
        if(topTouch && currentTouchCount>1)
            [topSection setScale:scale];
}
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    lastTouch=location;
    touchStart=location;
    currentTouchCount+=[touches count];
    NSLog(@"touch count %d", currentTouchCount);
    
    
    for(UITouch *t in touches)
    {
        CGPoint location=[t locationInView: [t view]];
        location=[[CCDirector sharedDirector] convertToGL:location];
        if(location.y>cx)topTouch=YES;
        
    }
    if(location.y<cx && currentTouchCount==1)bottomTouch=YES;
    
    if(topTouch)NSLog(@"touching top");
    
    
    if(bottomTouch)
    {
        
        // this is the currently selected row
        if(location.y > 190 && location.y < 250)
        {
            startedInActiveRow=YES;
            CCLayer *curLayer=[numberLayers objectAtIndex:activeRow];
            currentNumberPos=fabsf((int)curLayer.position.x/kSpaceBetweenNumbers);
            NSLog(@"currentpos - %d", currentNumberPos);
        }        
    }
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    NSLog(@"touch count ivar %d nsset %d", currentTouchCount, [touches count]);
    //NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    
    if(topTouch && currentTouchCount==1)
    {
            CGPoint diff=[BLMath SubtractVector:lastTouch from:location];
            diff = ccp(diff.x, 0);
            [topSection setPosition:ccpAdd(topSection.position, diff)];
        
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
    currentTouchCount-=[touches count];
    isTouching=NO;
    
    if(doingHorizontalDrag)
    {
        CGPoint diff=[BLMath SubtractVector:location from:touchStart];
        diff = ccp(diff.x, 0);
        
        CCLayer *moveLayer = [numberLayers objectAtIndex:activeRow];

        //the quantity of increments moved
        float floatNumberPos=fabsf(diff.x)/kSpaceBetweenNumbers;
        
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
        [moveLayer runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(currentNumberPos*-kSpaceBetweenNumbers,moveLayer.position.y)]];
        [selectedNumbers replaceObjectAtIndex:activeRow withObject:[NSNumber numberWithInt:currentNumberPos]];
    }
    
    if(doingVerticalDrag)
    {
        CGPoint diff=[BLMath SubtractVector:location from:touchStart];
        diff = ccp(0, diff.y);
        
        //the quantity of increments moved
        float floatRowPos=fabsf(diff.y)/kSpaceBetweenRows;
        
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
        if(diff.y > 0) // incrementing line
            currentRowPos-=incrementor;
        
        else 
            currentRowPos+=incrementor;
        
        //truncate to fixed bounds
        if(currentRowPos<-1)currentRowPos=-1;
        if(currentRowPos>6)currentRowPos=6;
  
        activeRow=currentRowPos+1;
        
        //reposition layer, relative to the number indicated (incrementing line means moving it left, hence x moved negative as n moves positive)
        
        for(int i=0;i<[numberLayers count];i++)
        {
            CCLayer *moveLayer=[numberLayers objectAtIndex:i];
            [moveLayer runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(moveLayer.position.x,currentRowPos*kSpaceBetweenRows)]];
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
    currentTouchCount-=[touches count];
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
