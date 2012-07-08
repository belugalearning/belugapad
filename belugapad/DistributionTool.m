//
//  DistributionTool.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DistributionTool.h"

#import "ToolTemplateSG.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"

#import "SGGameWorld.h"
#import "SGDtoolBlock.h"
#import "SGDtoolBlockRender.h"

#define DRAW_DEPTH 1


@interface DistributionTool()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
    // and then any specifics we need for this tool
    id<Moveable,Transform> currentPickupObject;
    
}

@end

@implementation DistributionTool

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

-(void)doUpdate:(ccTime)delta
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
    for (int i=0; i<DRAW_DEPTH; i++)
    {
        for(id go in [gw AllGameObjects]) {
            if([go conformsToProtocol:@protocol(Pairable)])
                [((id<Pairable>)go) draw:i];
        }
    } 
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];    
    
}

-(void)populateGW
{
    // set our renderlayer
    gw.Blackboard.RenderLayer = renderLayer;
    
    // init our array for use with the created gameobjects
    for(int i=0;i<5;i++)
    {
        id<Configurable, Selectable> newblock;
        newblock=[[[SGDtoolBlock alloc] initWithGameWorld:gw andRenderLayer:renderLayer andPosition:ccp(cx-200+(100*i),cy)] autorelease];
        
        [newblock setup];
        
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
    
    
    // loop over 
    for(id thisObj in gw.AllGameObjects)
    {
        if([thisObj conformsToProtocol:@protocol(Moveable)])
        {
            id <Moveable, Transform> cObj=thisObj;
            
            if(CGRectContainsPoint(cObj.mySprite.boundingBox, location))
            {
                currentPickupObject=thisObj;
                break;
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
    
    if(currentPickupObject)
    {

        // check that the shape is being moved within bounds of the screen
        if((location.x>=35.0f&&location.x<=lx-35.0f) && (location.y>=35.0f&&location.y<=ly-35.0f))
        {
            // set it's position and move it!
            currentPickupObject.Position=location;
            [currentPickupObject move];
        }
        
        // then for each other moveable thing, check if we're proximate
        for(id go in gw.AllGameObjects)
        {
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                [go amIProximateTo:location];
            }
        }
    }
    
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
    // check there's a pickupobject
    if(currentPickupObject)
    {
        CGPoint curPOPos=currentPickupObject.Position;
        // check all the gamobjects and search for a moveable object
        for(id go in gw.AllGameObjects)
        {
            if(go==currentPickupObject)
            {
                [go resetTint];
                continue;
            }
            if([go conformsToProtocol:@protocol(Moveable)])
            {
                // return whether the object is proximate to our current pickuobject
                BOOL proximateToPickupObject=[go amIProximateTo:curPOPos];
                [go resetTint];
                if(proximateToPickupObject)[go pairMeWith:currentPickupObject];
                else [go unpairMeFrom:currentPickupObject];
                
                [self evalUniqueShapes];
                
            }
        }
    }
    currentPickupObject=nil;
    
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    currentPickupObject=nil;
    // empty selected objects
}

#pragma mark - evaluation

-(NSMutableArray*)evalUniqueShapes
{
    NSMutableArray *checkedObjects=[[NSMutableArray alloc]init];
    NSMutableArray *foundShapes=[[NSMutableArray alloc]init];
    
    // loop through each object in the gameworld
    for(id go in gw.AllGameObjects)
    {
        if([go conformsToProtocol:@protocol(Pairable)])
        {
            // cast the go as a pairable to use properties
            id<Pairable> pairableGO=(id<Pairable>)go;
            
            // for each object in the pairedobjects array
            for(id<Pairable> pairedObj in pairableGO.PairedObjects)
            {
                // we need to know if this is already in checked objects - if it's not, add it
                if(![checkedObjects containsObject:pairedObj])
                    [checkedObjects addObject:pairedObj];
                else
                    continue;
                
                //we need our arrays to contain arrays of each shape so
                //if the count of fondshapes is <1 we must be starting so we need to add a shape
                if([foundShapes count]<1)
                {
                    NSMutableArray *shape=[[NSMutableArray alloc]init];
                    [shape addObject:pairedObj];
                    [foundShapes addObject:shape];
                }
                
                else if([foundShapes count]>0)
                {
                    BOOL noArrayFound;
                    // but if it's greater we need to loop through the existing shape arrays
                    for (NSMutableArray *a in foundShapes)
                    {
                        // loop through each object in the current paired objects paired objects
                        for(id<Pairable> fsGO in pairedObj.PairedObjects)
                        {
                            // and if the array contains one of the paired objects - we know it already exists
                            if([a containsObject:fsGO])
                            {
                                // so add it to the current shape and set the bool to NO and break the loop
                                [a addObject:pairedObj];
                                noArrayFound=NO;
                                break;
                            }
                            else
                            {
                                // but if after all this we find no array to stick our object in, confirm that we've not found an array
                                noArrayFound=YES;
                            }
                        }
                    }
                    
                    // and if we haven't found a matching array, stick it into a new array that we add to found shapes
                    if(noArrayFound)
                    {
                        NSMutableArray *shape=[[NSMutableArray alloc]init];
                        [shape addObject:pairedObj];
                        [foundShapes addObject:shape];
                    }
                }
                
            }
            
        }
    }
    
    for(int i=0;i<[foundShapes count];i++)
    {
        NSLog(@"recurse shape %d", i);
        for(int fs=0; fs<[[foundShapes objectAtIndex:i] count];fs++)
        {
            NSLog(@"object %d", fs);
        }
    }
    
    return foundShapes;
    
}

-(BOOL)evalExpression
{
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
    
    //tear down
    [gw release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    
    [super dealloc];
}
@end