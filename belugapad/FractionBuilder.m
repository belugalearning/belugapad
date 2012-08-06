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
    
    for(NSDictionary *d in initFractions)
    {
        id<Configurable, Interactive> fraction;
        fraction=[[[SGFbuilderFraction alloc] initWithGameWorld:gw andRenderLayer:renderLayer andPosition:ccp(cx,[[d objectForKey:POS_Y]floatValue])] autorelease];
        fraction.FractionMode=[[d objectForKey:FRACTION_MODE]intValue];
        
        if([d objectForKey:MARKER_START_POSITION])
            fraction.MarkerStartPosition=[[d objectForKey:MARKER_START_POSITION]intValue];
        else
            fraction.MarkerStartPosition=1;
        
        fraction.Value=[[d objectForKey:VALUE]floatValue];
        fraction.Tag=[[d objectForKey:TAG]intValue];
        
        if([d objectForKey:SHOW_EQUIVALENT_FRACTIONS])
            fraction.ShowEquivalentFractions=[[d objectForKey:SHOW_EQUIVALENT_FRACTIONS]boolValue];
        
        [fraction setup];
        
        if([[d objectForKey:CREATE_CHUNKS_ON_INIT]boolValue])[self splitThisBar:fraction into:fraction.MarkerStartPosition];
        if([[d objectForKey:START_HIDDEN]boolValue])[fraction hideFraction];
    }
    
}

#pragma mark - interaction
-(void)splitThisBar:(id)thisBar into:(int)thisManyChunks
{
    id<Interactive,Configurable> curBar=thisBar;
    if([curBar.Chunks count]>0)
        [curBar removeChunks];
    
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
    
    if(currentMarker)
        [currentMarker moveMarkerTo:location];
    
    if(currentChunk)
    {
        currentChunk.Position=location;
        [currentChunk moveChunk];
        
//        for(id<MoveableChunk> chunk in selectedChunks)
//        {
//            if(chunk==currentChunk)continue;
//            float diffX=[BLMath DistanceBetween:ccp(currentChunk.Position.x,0) and:ccp(chunk.Position.x,0)];
//            float diffY=[BLMath DistanceBetween:ccp(0,currentChunk.Position.y) and:ccp(0,currentChunk.Position.y)];
//            NSLog(@"diffX %f, diffY %f", diffX, diffY);
//            chunk.Position=ccp(location.x+diffX,location.y+diffY);
//            [chunk moveChunk];
//        }
    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    float distFromStartToEnd=[BLMath DistanceBetween:touchStartPos and:location];
    
    if(currentMarker)
    {
        [currentMarker snapToNearestPos];
        
        if(startMarkerPos!=currentMarker.MarkerPosition)
        {
            [currentMarker ghostChunk];

        }
        
        [self splitThisBar:currentMarker into:currentMarker.MarkerPosition+1];
        
    }
    
    if(currentChunk)
    {
        if(distFromStartToEnd<10.0f)
        {
            if(!selectedChunks)selectedChunks=[[NSMutableArray alloc]init];
            
            if(!currentChunk.Selected)[selectedChunks addObject:currentChunk];
            else [selectedChunks removeObject:currentChunk];
            [currentChunk changeChunkSelection];
        }
        
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Configurable)])
            {
                if([currentChunk checkForChunkDropIn:go])
                    [currentChunk changeChunk:currentChunk toBelongTo:go];
                    //TODO: this is when we'd check the parent vs current host
                    // if different, we need to reassign
            }
        }
    }
    
    isTouching=NO;
    currentMarker=nil;
    currentChunk=nil;
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(currentMarker)
        [currentMarker snapToNearestPos];
    
    
    isTouching=NO;
    currentMarker=nil;
    currentChunk=nil;
    // empty selected objects
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    int solutionsFound=0;
    
    for(NSDictionary *s in solutionsDef)
    {
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Interactive)])
            {
                id<Interactive> thisFraction=go;
                NSLog(@"found interactive obj (tag %d)", thisFraction.Tag);
                
                if(thisFraction.Tag==[[s objectForKey:TAG]intValue])
                {      
                    float foundValue=0.0f;
                    float expectedTotal=[[s objectForKey:VALUE]floatValue];
                    
                    for(id<ConfigurableChunk> thisGO in thisFraction.Chunks)
                    {
                        NSLog(@"this chunk is worth %f", thisGO.Value);
                        foundValue+=thisGO.Value;
                    }
                 
                    if(foundValue==expectedTotal)
                        solutionsFound++;
                    
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
