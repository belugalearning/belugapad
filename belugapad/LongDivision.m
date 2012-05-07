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

    // work out the current total
    currentTotal=0;

    for(int i=0;i<[selectedNumbers count];i++)
    {
        float curMultiplier=[[rowMultipliers objectAtIndex:i]floatValue];
        int curNumber=[[selectedNumbers objectAtIndex:i] intValue];
        
        currentTotal=currentTotal+(curNumber*curMultiplier);
        
    }
    
    //effective 4-digit precision evaluation test
    int prec=10000;
    int sum=(int)(currentTotal*divisor*prec);
    int idividend=(int)(dividend*prec);
    expressionIsEqual=(sum==idividend);
        
    // this sets the good/bad sum indicator if the mode is enabled
    if(goodBadHighlight) 
    {
        if(expressionIsEqual)
            [lblCurrentTotal setColor:ccc3(0, 255,0)];
        else 
            [lblCurrentTotal setColor:ccc3(255,0,0)];
    }
    
    // then update the actual text of it
    [lblCurrentTotal setString:[NSString stringWithFormat:@"%g", currentTotal]];
    
    
    // this sets the fade amount of each row proportional to it's current position
    for(int l=0;l<[numberRows count];l++)
    {
        
        NSArray *currentRow=[numberRows objectAtIndex:l];
        CCLayer *thisLayer=[numberLayers objectAtIndex:l];
        for(CCLabelTTF *lbl in currentRow)
        {
            CGPoint realLabelPos=[thisLayer convertToWorldSpace:lbl.position];

            float distToActive=[BLMath DistanceBetween:realLabelPos and:ccp(realLabelPos.x, 220)];
            float prop=distToActive/150;
            float opac=(1-prop)*150;
            if(opac<0)opac=0;
            if(opac==150)opac=255;
            
            [lbl setOpacity:opac];
        }
        
    }
    
    
    // this re-iterates back through the active row and sorts our side-side fading out
    NSArray *currentRow=[numberRows objectAtIndex:activeRow];
    CCLayer *thisLayer=[numberLayers objectAtIndex:activeRow];
    
    for (CCLabelTTF *lbl in currentRow)
    {
        CGPoint realLabelPos=[thisLayer convertToWorldSpace:lbl.position];
        
        float distToActive=[BLMath DistanceBetween:realLabelPos and:ccp(cx, realLabelPos.y)];
        float prop=distToActive/150;
        float opac=(1-prop)*400;
        if(opac<150)opac=150;
        if(opac>255)opac=255;
        
        [lbl setOpacity:opac];
    }
    
    if(evalMode==kProblemEvalAuto)[self evalProblem];
    [self updateBlock];
}


-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    dividend=[[pdef objectForKey:DIVIDEND] floatValue];
    divisor=[[pdef objectForKey:DIVISOR] floatValue];
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    goodBadHighlight=[[pdef objectForKey:GOOD_BAD_HIGHLIGHT] boolValue];
    

    
    
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
            [thisRow addObject:number];
            
        }
        
        [numberRows addObject:thisRow];
        [numberLayers addObject:thisLayer];
        
        rowMultiplierT=rowMultiplierT*10;
    }
    
    currentRowPos=0;
    activeRow=currentRowPos+1;
}

-(void)updateLabels:(CGPoint)position
{
    [markerText setString:[NSString stringWithFormat:@"%g", currentTotal*3]];
    [marker setPosition:position];
}

-(void)updateBlock
{
    // if the marker and it's text don't exist - create
    if(!marker && !markerText)
    {
        marker=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/marker.png")];
        [marker setPosition:ccp(line.position.x-(line.contentSize.width/2), line.position.y+30)];
        markerText=[CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        [markerText setPosition:ccp(0,65)];    
        [marker addChild:markerText];
        [topSection addChild:marker];
    }
    
    cumulativeTotal=0;
    CGPoint markerPos;
    float currentYScale=1.0f;
    float startBase=0;
    
    for(int i=0;i<[renderedBlocks count];i++)
    {
        //float curOffset=[[[renderedBlocks objectAtIndex:i] objectForKey:OFFSET]floatValue];
        float curOffset=0.0f;
        // if the startbase is 0, set it equal to the current base, then sort out scaling based upon that 
        float currentBase=[[[renderedBlocks objectAtIndex:i]objectForKey:ROW_MULTIPLIER]floatValue];
        if(startBase==0)startBase=currentBase;
        
        if(currentBase<startBase)
        {
            currentYScale = currentYScale*0.8f;
            startBase=currentBase;
        }
        
        // then set the options on our current iteration
        CCSprite *curSprite=[[renderedBlocks objectAtIndex:i]objectForKey:MY_SPRITE];
        [curSprite setScaleY:currentYScale];
        [curSprite setPosition:ccp(curOffset+line.position.x+((curSprite.contentSize.width*curSprite.scaleX)/2)-(line.contentSize.width/2)+cumulativeTotal, line.position.y+30)];
        cumulativeTotal=cumulativeTotal+(curSprite.contentSize.width*curSprite.scaleX);
        markerPos=ccp(curSprite.position.x+((curSprite.contentSize.width*curSprite.scaleX)/2), curSprite.position.y+40);
    }
    [self updateLabels:markerPos];
}

-(void)checkBlock
{
    // we need to find out where this block should go
    float myBase=[[rowMultipliers objectAtIndex:activeRow]floatValue];
    
    if(renderedBlocks.count==0)
    {
        [self createBlockAtIndex:0 withBase:[[rowMultipliers objectAtIndex:activeRow]floatValue]];
    }
    else 
    {
        // this is when we're creating an object
        if(creatingObject)
        //if(creatingObject && (previousNumberPos!=currentNumberPos || previousRow!=activeRow))
        {
            // we need to look at what exists currently
            for(int i=0;i<[renderedBlocks count];i++)
            {
                NSDictionary *curDict=[renderedBlocks objectAtIndex:i];
                float theirBase=[[curDict objectForKey:ROW_MULTIPLIER]floatValue];
                
                if(theirBase<myBase)
                {
                    if(i==0)[self createBlockAtIndex:i withBase:myBase];
                    else [self createBlockAtIndex:i-1 withBase:myBase];
                    return;
                }
            }
            // if nowt init, create the block at the end
            [self createBlockAtIndex:[renderedBlocks count] withBase:myBase];
        }
        
        
        // remove object if needed
        if(destroyingObject)
        {
            for(int i=0;i<[renderedBlocks count];i++)
            {
                NSDictionary *curDict=[renderedBlocks objectAtIndex:i];
                float theirBase=[[curDict objectForKey:ROW_MULTIPLIER]floatValue];
                
                if(theirBase==myBase)
                {
                    CCSprite *curSprite=[curDict objectForKey:MY_SPRITE];
                    [curSprite removeFromParentAndCleanup:YES];
                    [renderedBlocks removeObjectAtIndex:i];
                    return;
                }
            }
        }
    }
}

-(void)createBlockAtIndex:(int)index withBase:(float)base
{
    NSMutableDictionary *curDict=[[NSMutableDictionary alloc]init];
    float myBase=[[rowMultipliers objectAtIndex:activeRow]floatValue];
    CCSprite *curBlock=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/renderblock.png")];
    float calc=0.0f;
    
    [curBlock setPosition:line.position];
    [curBlock setScaleX:(divisor*myBase/dividend*line.contentSize.width)/curBlock.contentSize.width];
    [curDict setObject:curBlock forKey:MY_SPRITE];
    [curDict setObject:[NSNumber numberWithFloat:base] forKey:ROW_MULTIPLIER];
    [renderedBlocks insertObject:curDict atIndex:index];

    
    calc=-curBlock.contentSize.width*curBlock.scaleX;
    
    [curDict setObject:[NSNumber numberWithFloat:calc] forKey:OFFSET];
    
    [topSection addChild:curBlock];
}

-(void)populateGW
{
    [renderLayer addChild:topSection];
    [renderLayer addChild:bottomSection];
    
    selectedNumbers=[[NSMutableArray alloc]init];
    [selectedNumbers retain];
    rowMultipliers=[[NSMutableArray alloc]init];
    [rowMultipliers retain];
    renderedBlocks=[[NSMutableArray alloc]init];
    [renderedBlocks retain];
    
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
    [lblCurrentTotal setPosition:ccp(cx,50)];
    [renderLayer addChild:lblCurrentTotal];
    
    line=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/line.png")];
    [line setPosition:ccp(cx,550)];
    [topSection addChild:line];
    
    
    
    [self createVisibleNumbers];
}
-(void)handlePassThruScaling:(float)scale
{
        if(topTouch && currentTouchCount>1 && scale>0)
            [topSection setScaleX:scale];
}
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToWorldSpace:location];
    lastTouch=location;
    touchStart=location;
    currentTouchCount+=[touches count];
    NSLog(@"touch count %d", currentTouchCount);
    
    previousNumberPos=[[selectedNumbers objectAtIndex:activeRow]intValue];
    previousRow=activeRow;
    
    
    for(UITouch *t in touches)
    {
        CGPoint location=[t locationInView: [t view]];
        location=[[CCDirector sharedDirector] convertToGL:location];
        if(location.y>cx)topTouch=YES;
        
    }
    if(location.y<cx && currentTouchCount==1)bottomTouch=YES;
    
    
    
    if(bottomTouch)
    {
        
        // this is the currently selected row
        if(location.y > 190 && location.y < 250)
        {
            startedInActiveRow=YES;
            CCLayer *curLayer=[numberLayers objectAtIndex:activeRow];
            currentNumberPos=fabsf((int)curLayer.position.x/kSpaceBetweenNumbers);
        }        
    }
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
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
            int scrollByNumber=fabsf((int)moveLayer.position.x/kSpaceBetweenNumbers);

            for(int i=0;i<[renderedBlocks count];i++)
            {
                NSMutableDictionary *curObj=[renderedBlocks objectAtIndex:i];
                CCSprite *curSprite=[curObj objectForKey:MY_SPRITE];
                float updateOffset=[BLMath DistanceBetween:location and:touchStart]/curSprite.contentSize.width*curSprite.scaleX;
                [curObj setObject:[NSNumber numberWithFloat:updateOffset] forKey:OFFSET];
            }
                           
            
            if(location.x<lastTouch.x)
            {
                creatingObject=YES;
                destroyingObject=NO;
            }
            if(location.x>lastTouch.x)
            {
                creatingObject=NO;
                destroyingObject=YES;
            }
            
            if(scrollByNumber!=previousNumberPos)
            {
                [self checkBlock];
                previousNumberPos=scrollByNumber;
            }

        
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
    location=[self.ForeLayer convertToNodeSpace:location];
    currentTouchCount-=[touches count];
    isTouching=NO;
    creatingObject=NO;
    destroyingObject=NO;
    
    if(doingHorizontalDrag)
    {
        //if(location.x<lastTouch.x)creatingObject=YES;
        //if(location.x>lastTouch.x)destroyingObject=YES;
        
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

        
        if(location.x<lastTouch.x)
            creatingObject=YES;
        
        if(location.x>lastTouch.x)
            destroyingObject=YES;
        
        if(currentNumberPos!=previousNumberPos)
            [self checkBlock];
        
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
    creatingObject=NO;
    destroyingObject=NO;
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
    creatingObject=NO;
    destroyingObject=NO;
}

-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    
    if(currentTotal==(dividend/divisor))return YES;
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
        if(evalMode==kProblemEvalOnCommit)
        {
            [toolHost showProblemIncompleteMessage]; 
            [toolHost resetProblem];
        }
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
    if(rowMultipliers)[rowMultipliers release];
    if(renderedBlocks)[renderedBlocks release];

    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    
    [super dealloc];
}
@end
