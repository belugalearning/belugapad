//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FractionBuilder.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"
#import "LoggingService.h"
#import "AppDelegate.h"

#import "SGGameWorld.h"
#import "SGFbuilderFraction.h"
#import "SGFractionBuilderRender.h"


@interface FractionBuilder()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    id<Moveable,Interactive>currentMarker;
    id<MoveableChunk,ConfigurableChunk>currentChunk;
    
}

@end

@implementation FractionBuilder

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
        
        gw = [[SGGameWorld alloc] initWithGameScene:renderLayer];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        renderLayer = [[CCLayer alloc] init];
        [self.ForeLayer addChild:renderLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        
        
        [self readPlist:pdef];
        [self populateGW];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

#pragma mark - loops

-(void)doUpdateOnTick:(ccTime)delta
{
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
    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    // All our stuff needs to go into vars to read later
//INIT_FRACTIONS: Array
//    INIT_FRACTIONS\Item: Dictionary
//    
//    INIT_FRACTIONS\Item\FRACTION_MODE: Number
//    INIT_FRACTIONS\Item\POS_Y: Number
//    INIT_FRACTIONS\Item\MARKER_START_POSITION: Number (implicitly splits the fraction into chunks)
//    INIT_FRACTIONS\Item\VALUE: Number
//    
//DIVIDEND: Number
//DIVISOR: Number
    initFractions=[pdef objectForKey:INIT_FRACTIONS];
    [initFractions retain];
    
    solutionsDef=[pdef objectForKey:SOLUTIONS];
    [solutionsDef retain];
    
    dividend=[[pdef objectForKey:DIVIDEND] intValue];
    divisor=[[pdef objectForKey:DIVISOR] intValue];
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    
}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;

    // loop through our init fractions
    for(NSDictionary *d in initFractions)
    {
        // set up the fraction
        id<Configurable, Interactive> fraction;
        fraction=[[[SGFbuilderFraction alloc] initWithGameWorld:gw andRenderLayer:renderLayer andPosition:ccp(cx,[[d objectForKey:POS_Y]floatValue])] autorelease];
        
        // determine its mode
        fraction.FractionMode=[[d objectForKey:FRACTION_MODE]intValue];
        
        // and where the marker starts
        if([d objectForKey:MARKER_START_POSITION])
            fraction.MarkerStartPosition=[[d objectForKey:MARKER_START_POSITION]intValue];
        else
            fraction.MarkerStartPosition=1;
        
        // give it a value (ie, 1)
        fraction.Value=[[d objectForKey:VALUE]floatValue];
        
        // and a tag - a way of later identifying it
        fraction.Tag=[[d objectForKey:TAG]intValue];
        
        // shoow a label with the current expressed fraction?
        fraction.ShowCurrentFraction=[[d objectForKey:SHOW_CURRENT_FRACTION]boolValue];
        
        // and should this label be able to show equivs?
        if([d objectForKey:SHOW_EQUIVALENT_FRACTIONS])
            fraction.ShowEquivalentFractions=[[d objectForKey:SHOW_EQUIVALENT_FRACTIONS]boolValue];
        
        [fraction setup];
        
        // if this is set, split the fraction
        if([[d objectForKey:CREATE_CHUNKS_ON_INIT]boolValue])
            [self splitThisBar:fraction into:fraction.MarkerStartPosition];
        // and if it should start hidden, hide!
        if([[d objectForKey:START_HIDDEN]boolValue])
            [fraction hideFraction];
    }
    
}

#pragma mark - interaction
-(void)splitThisBar:(id)thisBar into:(int)thisManyChunks
{
    // choose the bar and check it has no chunks - if it does, remove them
    id<Interactive,Configurable> curBar=thisBar;
    if([curBar.Chunks count]>0)
        [curBar removeChunks];
    
    // loop ofver to create our number of chunks
    for(int i=0;i<thisManyChunks;i++)
    {
        // return the created object
        id<ConfigurableChunk> go=[thisBar createChunk];
        
        // if it's been selected (ie if the fraction has auto shade switched on)
        // alloc the array and add the object
        if(go.Selected)
        {
            if(!selectedChunks)selectedChunks=[[NSMutableArray alloc] init];
            [selectedChunks addObject:go];
        }
    }
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
    touchStartPos=location;
    
    // loop through to check for fraction touches or chunk touches
    for(id thisObj in gw.AllGameObjects)
    {
        if([thisObj conformsToProtocol:@protocol(Moveable)])
        {
            id <Moveable,Interactive> cObj=thisObj;
            
            if([cObj amIProximateTo:location])
            {
                currentMarker=cObj;
                startMarkerPos=cObj.MarkerPosition;
                return;
            }
        }
        
        if([thisObj conformsToProtocol:@protocol(MoveableChunk)])
        {
            id<ConfigurableChunk,MoveableChunk> cObj=thisObj;
            if([cObj amIProximateTo:location])
            {
                [loggingService logEvent:BL_PA_FB_TOUCH_BEGIN_PICKUP_CHUNK withAdditionalData:nil];
                currentChunk=cObj;
                return;
            }
        }
        
    }
    
    
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;
    
    // if we have these things, handle them differently
    
    if(currentMarker)
    {
        hasMovedMarker=YES;
        [currentMarker moveMarkerTo:location];
    }
    if(currentChunk)
    {
        hasMovedChunk=YES;
        currentChunk.Position=location;
        [currentChunk moveChunk];
        
        for(id<MoveableChunk> chunk in selectedChunks)
        {
            if(chunk==currentChunk)continue;
            float diffX=[BLMath DistanceBetween:ccp(currentChunk.Position.x,0) and:ccp(chunk.Position.x,0)];
            float diffY=[BLMath DistanceBetween:ccp(0,currentChunk.Position.y) and:ccp(0,currentChunk.Position.y)];
            
            NSLog(@"diffX %f, diffY %f", diffX, diffY);
            chunk.Position=ccp(location.x+diffX,location.y+diffY);
            [chunk moveChunk];
        }
    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    float distFromStartToEnd=[BLMath DistanceBetween:touchStartPos and:location];
    
    // if we were moving the marker
    if(currentMarker)
    {
        // first snap it to a number
        [currentMarker snapToNearestPos];
        
        // then if the 2 numbers differ, make out ghost chunks
        if(startMarkerPos!=currentMarker.MarkerPosition)
            [currentMarker ghostChunk];

        // and split dat bar!
        [self splitThisBar:currentMarker into:currentMarker.MarkerPosition+1];
        [loggingService logEvent:BL_PA_FB_CREATE_CHUNKS withAdditionalData:[NSString stringWithFormat:@"{ chunks : %d }",currentMarker.MarkerPosition+1]];
        
    }
    
    // if we were moving a chunk
    if(currentChunk)
    {
        // and distance <10, select the chunk
        if(distFromStartToEnd<10.0f)
        {
            [currentChunk changeChunkSelection];
            if(!selectedChunks)selectedChunks=[[NSMutableArray alloc]init];
            
            if(!currentChunk.Selected)[selectedChunks addObject:currentChunk];
            else [selectedChunks removeObject:currentChunk];
            return;
        }
        
        // then check for a chunk drop in a fraction
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Configurable)])
            {
                if([currentChunk checkForChunkDropIn:go])
                {
                    [loggingService logEvent:BL_PA_FB_MOUNT_TO_FRACTION withAdditionalData:[NSString stringWithFormat:@"{ tag : %d }", ((id<Interactive>)go).Tag]];
                    [currentChunk changeChunk:currentChunk toBelongTo:go];
                }
                    //TODO: this is when we'd check the parent vs current host
                    // if different, we need to reassign
                else{
                    [currentChunk returnToParentSlice];
                }
            }
        }
    }
    
    if(hasMovedChunk)
        [loggingService logEvent:BL_PA_FB_TOUCH_MOVE_MOVE_CHUNK withAdditionalData:nil];
    if(hasMovedMarker)
        [loggingService logEvent:BL_PA_FB_TOUCH_MOVE_MOVE_MARKER withAdditionalData:nil];
    
    hasMovedChunk=NO;
    hasMovedMarker=NO;
    isTouching=NO;
    currentMarker=nil;
    currentChunk=nil;
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(currentMarker)
        [currentMarker snapToNearestPos];
    
    
    isTouching=NO;
    hasMovedChunk=NO;
    hasMovedMarker=NO;
    currentMarker=nil;
    currentChunk=nil;
    // empty selected objects
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    int solutionsFound=0;
    NSMutableArray *foundSolution=[[NSMutableArray alloc]init];
    NSMutableArray *solvedFractions=[[NSMutableArray alloc]init];
    
    for(NSDictionary *s in solutionsDef)
    {
        if([foundSolution containsObject:s])continue;
        
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Interactive)] && ![solvedFractions containsObject:go])
            {
                id<Interactive> thisFraction=go;
                NSLog(@"found interactive obj (tag %d)", thisFraction.Tag);
                
                if(thisFraction.Tag==[[s objectForKey:TAG]intValue])
                {      
                    int totalSelectedChunks=0;
                    BOOL dividendMatch=NO;
                    BOOL divisorMatch=NO;
                    
                    for(id<ConfigurableChunk> chunk in thisFraction.Chunks)
                    {
                        if(chunk.Selected)
                            totalSelectedChunks++;
                        if(chunk.Selected)
                            NSLog(@"chunk selected!");
                    }
                    
                    if(totalSelectedChunks==[[s objectForKey:DIVIDEND]intValue])
                        dividendMatch=YES;
                    
                    if(thisFraction.MarkerPosition+1==[[s objectForKey:DIVISOR]intValue])
                        divisorMatch=YES;
                    
                    if(dividendMatch && divisorMatch){
                        solutionsFound++;
                        [foundSolution addObject:s];
                        [solvedFractions addObject:thisFraction];
                    }
                    if(dividendMatch && divisorMatch)
                        NSLog(@"solutions found: %d", solutionsFound);
                }
            }
        }
    }
    
    if(solutionsFound==[solutionsDef count])
        return YES;
    else
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
    
    [renderLayer release];
    if(initFractions)[initFractions release];
    if(solutionsDef)[solutionsDef release];
    if(selectedChunks)[selectedChunks release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
