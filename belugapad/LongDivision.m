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
#import "BLMath.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "UsersService.h"
#import "DWNWheelGameObject.h"

const float kSpaceBetweenNumbers=280.0f;
const float kSpaceBetweenRows=80.0f;
const float kRenderBlockWidth=1000.0f;
const float kScaleOfLesserBlocks=0.6f;

@interface LongDivision()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation LongDivision

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
        self.NoScaleLayer=[[CCLayer alloc]init];
        topSection=[[CCLayer alloc]init];
        bottomSection=[[CCLayer alloc]init];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolNoScaleLayer:self.NoScaleLayer];
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
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];

    // work out the current total
//    currentTotal=nWheel.OutputValue/(pow((double)startColValue,-1));
    currentTotal=nWheel.OutputValue;
    
//    for(int i=0;i<[selectedNumbers count];i++)
//    {
//        float curMultiplier=[[rowMultipliers objectAtIndex:i]floatValue];
//        int curNumber=[[selectedNumbers objectAtIndex:i] intValue];
//        
//        currentTotal=currentTotal+(curNumber*curMultiplier);
//        
//    }
    
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
//    NSArray *currentRow=[numberRows objectAtIndex:activeRow];
//    CCLayer *thisLayer=[numberLayers objectAtIndex:activeRow];
    
//    for (CCLabelTTF *lbl in currentRow)
//    {
//        CGPoint realLabelPos=[thisLayer convertToWorldSpace:lbl.position];
//        
//        float distToActive=[BLMath DistanceBetween:realLabelPos and:ccp(cx, realLabelPos.y)];
//        float prop=distToActive/150;
//        float opac=(1-prop)*400;
//        if(opac<150)opac=150;
//        if(opac>255)opac=255;
//        
//        [lbl setOpacity:opac];
//    }
    if(!hideRenderLayer){
        for(int n=0;n<[nWheel.pickerViewSelection count];n++)
        {
                [self checkBlock:n];
        }
        [self updateBlock];
    }       
    if(evalMode==kProblemEvalAuto && !hasEvaluated)
        [self evalProblem];

}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    dividend=[[pdef objectForKey:DIVIDEND] floatValue];
    divisor=[[pdef objectForKey:DIVISOR] floatValue];
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    goodBadHighlight=[[pdef objectForKey:GOOD_BAD_HIGHLIGHT] boolValue];
    renderBlockLabels=[[pdef objectForKey:RENDERBLOCK_LABELS] boolValue];
    hideRenderLayer=[[pdef objectForKey:HIDE_RENDERLAYER] boolValue];
    if([pdef objectForKey:START_COLUMN_VALUE])
        startColValue=[[pdef objectForKey:START_COLUMN_VALUE]floatValue];
    else
        startColValue=100;
    
    columnsInPicker=[[pdef objectForKey:COLUMNS_IN_PICKER]intValue];

    
}

-(void)populateGW
{
    [renderLayer addChild:topSection];
    [renderLayer addChild:bottomSection];
    
    selectedNumbers=[[NSMutableArray alloc]init];
    rowMultipliers=[[NSMutableArray alloc]init];
    renderedBlocks=[[NSMutableArray alloc]init];
    
    // add the selector to the middle of the screen
    
    CCSprite *selector=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/selection_pointer.png")];
    [selector setPosition:ccp(cx,cy)];
    [selector setOpacity:50];
    [renderLayer addChild:selector];
    
    // add the big multiplier behind the numbers
    CCLabelTTF *multiplier=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"x%g",divisor] fontName:SOURCE fontSize:200.0f];
    [multiplier setPosition:ccp(820,202)];
    [multiplier setOpacity:25];
    [renderLayer addChild:multiplier];
    
    lblCurrentTotal=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
    [lblCurrentTotal setPosition:ccp(cx,50)];
    [renderLayer addChild:lblCurrentTotal];
    
    line=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/line.png")];
    [line setPosition:ccp(cx,550)];
    [topSection addChild:line];
    
    if(hideRenderLayer){[topSection setVisible:NO];}
    else{
        // set up start and end marker
        startMarker=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/marker.png")];
        endMarker=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/marker.png")];
        [startMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x-(line.contentSize.width/2)+5, line.position.y)]];
        [endMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x+(line.contentSize.width/2)-5, line.position.y)]];
        CCLabelTTF *start=[CCLabelTTF labelWithString:@"0" fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
        CCLabelTTF *end=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", dividend] fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
        [start setPosition:ccp(10,60)];
        [end setPosition:ccp(10,60)];
        [startMarker addChild:start];
        [endMarker addChild:end];
        
        [self.NoScaleLayer addChild:startMarker];
        [self.NoScaleLayer addChild:endMarker];
    }
    
    [self setupNumberWheel];
    
    //[self createVisibleNumbers];
}

-(void)setupNumberWheel
{
    DWNWheelGameObject *w=[DWNWheelGameObject alloc];
    [gw populateAndAddGameObject:w withTemplateName:@"TnumberWheel"];
    w.Components=columnsInPicker;
    w.Position=ccp(250,200);
    w.RenderLayer=renderLayer;
    w.SpriteFileName=@"/images/numberwheel/3slots.png";
    [w handleMessage:kDWsetupStuff];
//    w.InputValue=000;
//    w.OutputValue=w.InputValue;
//    [w handleMessage:kDWupdateObjectData];
    nWheel=w;
}

-(void)createVisibleNumbers
{
    numberRows=[[NSMutableArray alloc]init];
    numberLayers=[[NSMutableArray alloc]init];

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
            CCLabelTTF *number=[CCLabelTTF labelWithString:currentNumber fontName:CHANGO fontSize:60.0f];
            [number setPosition:ccp((lx/2)+(i*kSpaceBetweenNumbers), 220-(r*kSpaceBetweenRows))];
            [thisLayer addChild:number];
            [thisRow addObject:number];
            
        }
        
        [numberRows addObject:thisRow];
        [numberLayers addObject:thisLayer];
        
        rowMultiplierT=rowMultiplierT*10;
        
        [thisRow release];
    }
    
    //currentRowPos=startRow;
    activeRow=currentRowPos;
    
    
    
    for(int i=0;i<[numberLayers count];i++)
    {
        CCLayer *moveLayer=[numberLayers objectAtIndex:i];
        [moveLayer setPosition:ccp(moveLayer.position.x,currentRowPos*kSpaceBetweenRows)];
    }

}


#pragma mark - render interaction
-(void)updateLabels:(CGPoint)position
{
    [markerText setString:[NSString stringWithFormat:@"%g", currentTotal*divisor]];
//    [marker setPosition:[topSection convertToWorldSpace:position]];
    [marker setPosition:position];
    [startMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x-(line.contentSize.width/2)+2, line.position.y)]];
    [endMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x+(line.contentSize.width/2)-2, line.position.y)]];
}

-(void)updateBlock
{
    // if the marker and it's text don't exist - create
    if(!marker && !markerText)
    {
        marker=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/marker.png")];
        [marker setPosition:[topSection convertToWorldSpace:ccp(line.position.x-(line.contentSize.width/2), line.position.y+30)]];
        markerText=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
        [markerText setPosition:ccp(10,65)];    
        [marker addChild:markerText];
        [self.NoScaleLayer addChild:marker];
    }
    
    cumulativeTotal=0;
    CGPoint markerPos=CGPointZero;
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
            currentYScale = currentYScale*kScaleOfLesserBlocks;
            startBase=currentBase;
        }
        
        // then set the options on our current iteration
        CCSprite *curSprite=[[renderedBlocks objectAtIndex:i]objectForKey:MY_SPRITE];

        [curSprite setScaleY:currentYScale];
        [curSprite setPosition:[topSection convertToWorldSpace:ccp(curOffset+line.position.x+((curSprite.contentSize.width*curSprite.scaleX)/2)-(line.contentSize.width/2)+cumulativeTotal, line.position.y+((curSprite.contentSize.height*curSprite.scaleY)/2)-20)]];
        if(renderBlockLabels)
        {
            for(CCLabelTTF *lbl in curSprite.children)
            {
                [lbl setPosition:ccp(curSprite.position.x,curSprite.position.y+50)];
            }
                                                
        }
        cumulativeTotal=cumulativeTotal+(curSprite.contentSize.width*curSprite.scaleX);
        markerPos=ccp(curSprite.position.x+((curSprite.contentSize.width*curSprite.scaleX)/2), curSprite.position.y+40);
    }
    if(markerPos.x==0 && markerPos.y==0)[marker setVisible:NO];
    else [marker setVisible:YES];
    [self updateLabels:markerPos];
}

-(void)checkBlock:(int)thisRow
{
    // we need to find out where this block should go
    //float myBase=[[rowMultipliers objectAtIndex:thisRow]floatValue];
    
//    int selectedForRow=[[selectedNumbers objectAtIndex:thisRow]intValue];

    int selectedNumber=thisRow-([nWheel.pickerViewSelection count]-1);
    selectedNumber=fabsf(selectedNumber);
    int selectedForRow=[[nWheel.pickerViewSelection objectAtIndex:selectedNumber]intValue];
    
    int countOfRenderedForRow=0;
    int indexOfLastRenderedAtMyBase=0;
    
    //int adjustedIndex=(thisRow-[nWheel.pickerViewSelection count]);
    
    float myBase=startColValue/pow((double)10,selectedNumber);
    
    NSDictionary *lastRBDictAtMyBase=nil;
    
    for (NSMutableDictionary *rbdict in renderedBlocks) {
        float rbbase=[[rbdict objectForKey:ROW_MULTIPLIER] floatValue];
        if(rbbase==myBase)
        {
            countOfRenderedForRow++;
            lastRBDictAtMyBase=rbdict;
        }
        else if(rbbase<myBase)
        {
            break;
        }
        indexOfLastRenderedAtMyBase++;
    }
    
    if(countOfRenderedForRow<selectedForRow)
    {
        [self createBlockAtIndex:indexOfLastRenderedAtMyBase withBase:myBase];
    }
    
    if(countOfRenderedForRow>selectedForRow)
    {
        if(lastRBDictAtMyBase)
        {
            CCSprite *remSprite=[lastRBDictAtMyBase objectForKey:MY_SPRITE];
            [remSprite removeFromParentAndCleanup:YES];
            [renderedBlocks removeObject:lastRBDictAtMyBase];
        }
    }
}

-(void)createBlockAtIndex:(int)index withBase:(float)base
{
    NSMutableDictionary *curDict=[[NSMutableDictionary alloc]init];
//    float myBase=[[rowMultipliers objectAtIndex:activeRow]floatValue];
    float myBase=base;
    CCSprite *curBlock=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/renderblock.png")];
    float calc=0.0f;
    
    [curBlock setPosition:ccp(line.position.x+((curBlock.contentSize.width*curBlock.scaleX)/2-(line.contentSize.width/2))+cumulativeTotal, line.position.y+15)];
    [curBlock setScaleX:(divisor*myBase/dividend*line.contentSize.width)/curBlock.contentSize.width];
    [curDict setObject:curBlock forKey:MY_SPRITE];
    [curDict setObject:[NSNumber numberWithFloat:base] forKey:ROW_MULTIPLIER];
    [renderedBlocks insertObject:curDict atIndex:index];

//    if(renderBlockLabels) {
//        CCLabelTTF *blockValue=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", base] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
//        [blockValue setColor:ccc3(0,255,0)];
//        [blockValue setPosition:curBlock.position];
//        [curBlock addChild:blockValue];
//    }
    calc=-curBlock.contentSize.width*curBlock.scaleX;
    
    //GJ: what is this set for -- curDict never goes anywhere
    [curDict setObject:[NSNumber numberWithFloat:calc] forKey:OFFSET];
    [curDict release];
    
    [self.NoScaleLayer addChild:curBlock];
}


#pragma mark - touches events
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
    
    //previousNumberPos=[[selectedNumbers objectAtIndex:activeRow]intValue];
    //previousRow=activeRow;
    
    
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
//        if(location.y > 190 && location.y < 250)
//        {
//            startedInActiveRow=YES;
//            CCLayer *curLayer=[numberLayers objectAtIndex:activeRow];
//            currentNumberPos=fabsf((int)curLayer.position.x/kSpaceBetweenNumbers);
//        }        
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
        movedTopSection=YES;
        CGPoint diff=[BLMath SubtractVector:lastTouch from:location];
        diff = ccp(diff.x, 0);
        [topSection setPosition:ccpAdd(topSection.position, diff)];
        
    }
    
    if(bottomTouch)
    {
//        BOOL verticalTouch=NO;
//        BOOL horizontTouch=NO;
//        float touchMovementHoriz=fabsf(touchStart.x-location.x);
//        float touchMovementVerti=fabsf(touchStart.y-location.y);
//
//        
//        if(touchMovementHoriz>15.0f)horizontTouch=YES;
//        if(touchMovementVerti>10.0f)verticalTouch=YES;
//        
//        
//        if(horizontTouch && startedInActiveRow && !doingVerticalDrag) {
//            
//            doingHorizontalDrag=YES;
//            CGPoint diff=[BLMath SubtractVector:lastTouch from:location];
//            diff = ccp(diff.x, 0);
//            CCLayer *moveLayer = [numberLayers objectAtIndex:activeRow];
//            [moveLayer setPosition:ccpAdd(moveLayer.position, diff)];
//            int scrollByNumber=fabsf((int)moveLayer.position.x/kSpaceBetweenNumbers);
//
//            for(int i=0;i<[renderedBlocks count];i++)
//            {
//                NSMutableDictionary *curObj=[renderedBlocks objectAtIndex:i];
//                CCSprite *curSprite=[curObj objectForKey:MY_SPRITE];
//                float updateOffset=[BLMath DistanceBetween:location and:touchStart]/curSprite.contentSize.width*curSprite.scaleX;
//                [curObj setObject:[NSNumber numberWithFloat:updateOffset] forKey:OFFSET];
//            }
//                           
//            if(scrollByNumber!=currentNumberPos)
//            {
//                currentNumberPos=scrollByNumber;
//                [selectedNumbers replaceObjectAtIndex:activeRow withObject:[NSNumber numberWithInt:currentNumberPos]];
//            }
//
//        
//        }
//        
//        if(verticalTouch && !doingHorizontalDrag)
//        {
//            doingVerticalDrag=YES;
//            for(int i=0;i<[numberLayers count];i++)
//            {
//                CCLayer *moveLayer=[numberLayers objectAtIndex:i];
//                CGPoint diff=[BLMath SubtractVector:lastTouch from:location];
//                diff = ccp(0, diff.y);
//                [moveLayer setPosition:ccpAdd(moveLayer.position, diff)];
//                
//            }
//        }
        
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
    
    if(doingHorizontalDrag)
    {
//        [loggingService logEvent:BL_PA_LD_TOUCH_MOVE_MOVE_ROW withAdditionalData:nil];
//        CGPoint diff=[BLMath SubtractVector:location from:touchStart];
//        diff = ccp(diff.x, 0);
//        
//        CCLayer *moveLayer = [numberLayers objectAtIndex:activeRow];
//
//        float distMoved=diff.x / kSpaceBetweenNumbers;
//        float absDistMoved=fabsf(distMoved);
//        
//        int absRoundedIncrMoved=(int)(absDistMoved + 0.5f);
//        
//        int roundedMove=absRoundedIncrMoved;
//        if(distMoved<0)roundedMove=-roundedMove;
//        
//        currentNumberPos=previousNumberPos+roundedMove;
//                
//        //truncate to fixed bounds
//        if(currentNumberPos<0)currentNumberPos=0;
//        if(currentNumberPos>9)currentNumberPos=9;
//        
//        if(distMoved<0)
//            [loggingService logEvent:BL_PA_LD_TOUCH_END_DECREMENT_ACTIVE_NUMBER
//                withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentNumberPos] forKey:@"selectedNumber"]];
//        else
//            [loggingService logEvent:BL_PA_LD_TOUCH_END_INCREMENT_ACTIVE_NUMBER
//                withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentNumberPos] forKey:@"selectedNumber"]];
//        
//        
//        //reposition layer, relative to the number indicated (incrementing line means moving it left, hence x moved negative as n moves positive)
//        [moveLayer runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(currentNumberPos*-kSpaceBetweenNumbers,moveLayer.position.y)]];
//        [selectedNumbers replaceObjectAtIndex:activeRow withObject:[NSNumber numberWithInt:currentNumberPos]];

        
    }
    
    if(doingVerticalDrag)
    {
//        CGPoint diff=[BLMath SubtractVector:location from:touchStart];
//        diff = ccp(0, diff.y);
//        
//        //the quantity of increments moved
//        float floatRowPos=fabsf(diff.y)/kSpaceBetweenRows;
//        
//        //the remainder of the movement past the last whole increment
//        float remainder=floatRowPos - (int)floatRowPos;
//        
//        //by how much should the line be incremented
//        int incrementor=0;
//        
//        //round up
//        if(remainder>0.5f)
//            incrementor=(int)floatRowPos+1;
//        //round down
//        else
//            incrementor=(int)floatRowPos;
//        if(diff.y > 0) // incrementing line
//            currentRowPos-=incrementor;
//        
//        else 
//            currentRowPos+=incrementor;
//                 
//        //truncate to fixed bounds
//        if(currentRowPos<0)currentRowPos=0;
//        if(currentRowPos>7)currentRowPos=7;
//  
//        activeRow=currentRowPos;
//        [loggingService logEvent:BL_PA_LD_TOUCH_END_CHANGE_ACTIVE_ROW
//            withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:activeRow] forKey:@"activeRow"]];
//                
//        //reposition layer, relative to the number indicated (incrementing line means moving it left, hence x moved negative as n moves positive)
//        
//        for(int i=0;i<[numberLayers count];i++)
//        {
//            CCLayer *moveLayer=[numberLayers objectAtIndex:i];
//            [moveLayer runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(moveLayer.position.x,currentRowPos*kSpaceBetweenRows)]];
//        }
        
    }
    if(movedTopSection) [loggingService logEvent:BL_PA_LD_TOUCH_END_PAN_TOP_SECTION withAdditionalData:nil];
    
    
    topTouch=NO;
    bottomTouch=NO;
    startedInActiveRow=NO;
    doingHorizontalDrag=NO;
    doingVerticalDrag=NO;
    movedTopSection=NO;
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
    movedTopSection=NO;
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    return YES;

}

-(void)evalProblem
{
    BOOL isWinning=expressionIsEqual;
    
    if(isWinning)
    {
        hasEvaluated=YES;
        [toolHost doWinning];
    }
    else {
        if(evalMode==kProblemEvalOnCommit)
        {
            [toolHost showProblemIncompleteMessage]; 
            [toolHost resetProblem];
        }
    }
    
}

#pragma mark - meta question align
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
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [renderLayer release];
    [self.NoScaleLayer release];
    
    [topSection release];
    [bottomSection release];
    
    //tear down
    if(numberRows)[numberRows release];
    if(numberLayers)[numberLayers release];
    if(selectedNumbers)[selectedNumbers release];
    if(rowMultipliers)[rowMultipliers release];
    if(renderedBlocks)[renderedBlocks release];

    [gw release];
        
    [super dealloc];
}
@end
