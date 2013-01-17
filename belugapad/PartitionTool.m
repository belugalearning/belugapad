//
//  PartitionTool.m
//  belugapad
//
//  Created by David Amphlett on 29/03/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "PartitionTool.h"
#import "global.h"
#import "ToolHost.h"
#import "DWPartitionObjectGameObject.h"
#import "DWPartitionRowGameObject.h"
#import "DWPartitionStoreGameObject.h"
#import "SimpleAudioEngine.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "LoggingService.h"
#import "UsersService.h"
#import "AppDelegate.h"
#import "InteractionFeedback.h"

@interface PartitionTool()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

static float kTimeToMountedShake=7.0f;

@implementation PartitionTool
#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    problemDef=pdef;
    
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
    timeSinceInteractionOrShake+=delta;
    if(timeSinceInteractionOrShake>kTimeToMountedShake)
    {
        BOOL isWinning=[self evalExpression];
        
        if(!hasUsedBlock) {
            for(NSArray *a in mountedObjects)
            {
                for(DWPartitionObjectGameObject *pogo in a)
                {
                    [pogo.BaseNode runAction:[InteractionFeedback shakeAction]];
                }
            }
            timeSinceInteractionOrShake=0.0f;
        }
        if(isWinning)[toolHost shakeCommitButton];
    }

}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    // All our stuff needs to go into vars to read later
    
    initBars = [pdef objectForKey:INIT_BARS];
    [initBars retain];
    initObjects = [pdef objectForKey:INIT_OBJECTS];
    [initObjects retain];
    initCages = [pdef objectForKey:INIT_CAGES];
    [initCages retain];
    solutionsDef = [pdef objectForKey:SOLUTIONS];
    [solutionsDef retain];
    
    evalMode = [[pdef objectForKey:EVAL_MODE] intValue];
    
    rejectMode = [[pdef objectForKey:REJECT_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    
    if([pdef objectForKey:NUMBER_TO_STACK])
        numberToStack = [[pdef objectForKey:NUMBER_TO_STACK] intValue];
    else
        numberToStack = 2;
    
    if([pdef objectForKey:USE_BLOCK_SCALING])
        useBlockScaling = [[pdef objectForKey:USE_BLOCK_SCALING] boolValue];
    else
        useBlockScaling=YES;
    
    createdRows = [[NSMutableArray alloc]init];
    [createdRows retain];
    
    mountedObjects = [[NSMutableArray alloc]init];
    [mountedObjects retain];
    
    //see if we have eval_target for eval against fixed figure
    if([pdef objectForKey:@"EVAL_TARGET"])
    {
        hasEvalTarget=YES;
        explicitEvalTarget=[[pdef objectForKey:@"EVAL_TARGET"] integerValue];
    }
}

-(void)populateGW
{
    float yStartPos=582;
    // do stuff with our INIT_BARS (DWPartitionRowGameObject)
    
    for (int i=0;i<[initBars count]; i++)
    {
        
        float xStartPos=(cx-((([[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue]+2)*50)/2)+25);

            DWPartitionRowGameObject *prgo = [DWPartitionRowGameObject alloc];
            [gw populateAndAddGameObject:prgo withTemplateName:@"TpartitionRow"];
            prgo.Position=ccp(xStartPos,yStartPos);
            prgo.Length = [[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue];
            prgo.Locked = [[[initBars objectAtIndex:i] objectForKey:LOCKED] boolValue];
        
        
        [createdRows addObject:prgo];
    yStartPos = yStartPos-100;
    }
    
    // do stuff with our INIT_CAGES (DWPartitionStoreGameObject)
    for (int i=0;i<[initCages count]; i++)
    {
        int qtyForThisStore=[[[initCages objectAtIndex:i] objectForKey:QUANTITY] intValue];
        int numberStacked=0;
        NSMutableArray *currentVal=[[NSMutableArray alloc]init];
        for (int ic=0;ic<qtyForThisStore;ic++)
        {
            DWPartitionObjectGameObject *pogo = [DWPartitionObjectGameObject alloc];
            [gw populateAndAddGameObject:pogo withTemplateName:@"TpartitionObject"];
            pogo.IndexPos=i;
            
            pogo.Position=ccp(25-(numberStacked*2),650-(i*65)+(numberStacked*3)); 
            
            pogo.Length=[[[initCages objectAtIndex:i] objectForKey:LENGTH] intValue];
            
            if([[initCages objectAtIndex:i] objectForKey:LABEL])
            {
                pogo.Label=[CCLabelTTF labelWithString:[[initCages objectAtIndex:i] objectForKey:LABEL] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            }
            
            if(!useBlockScaling){
                pogo.IsScaled=YES;
                pogo.NoScaleBlock=YES;
            }
            
            pogo.MountPosition = pogo.Position;
            
            
            if(numberStacked<numberToStack)numberStacked++;
            [currentVal addObject:pogo];
        }
        [mountedObjects addObject:currentVal];
    }
    
    // do stuff with our INIT_OBJECTS (DWPartitionObjectGameObject)    
    for (int i=0;i<[initObjects count]; i++)
    {
        //pogo.Position=ccp(512,284);
        int insRow=[[[initObjects objectAtIndex:i] objectForKey:PUT_IN_ROW] intValue];
        int insLength=[[[initObjects objectAtIndex:i] objectForKey:LENGTH] intValue];
        NSString *fillText=[[NSString alloc]init];
        DWPartitionObjectGameObject *pogo = [DWPartitionObjectGameObject alloc];
        [gw populateAndAddGameObject:pogo withTemplateName:@"TpartitionObject"];   
        
        //[pogo.Mounts addObject:[createdRows objectAtIndex:insRow]];
        pogo.Length = insLength;
        
        pogo.InitedObject=YES;

        if([[initObjects objectAtIndex:i]objectForKey:LABEL]) fillText = [[initObjects objectAtIndex:i]objectForKey:LABEL];
        else fillText=[NSString stringWithFormat:@"%d", insLength];
        
        pogo.Label = [CCLabelTTF labelWithString:fillText fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        
        DWPartitionRowGameObject *prgo = (DWPartitionRowGameObject*)[createdRows objectAtIndex:insRow];
        NSDictionary *pl=[NSDictionary dictionaryWithObject:prgo forKey:MOUNT];
        [pogo handleMessage:kDWsetMount andPayload:pl withLogLevel:-1];
        pogo.Position = prgo.Position;
        pogo.MountPosition = prgo.Position;
        [prgo handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:0];
    }

}

-(void)reorderMountedObjects
{
    // this reorders blocks on the active cages - so that we can't end up in a position where there are gaps in the stacking
    // mountedobjects is handled in the touchesbegan, end and populategw
    for (int i=0;i<[mountedObjects count]; i++)
    {
        int qtyForThisStore=[[mountedObjects objectAtIndex:i] count];
        int numberStacked=0;
        for (int ic=0;ic<qtyForThisStore;ic++)
        {
            DWPartitionObjectGameObject *pogo=[[mountedObjects objectAtIndex:i] objectAtIndex:ic];
            
            pogo.Position=ccp(25-(numberStacked*2),650-(i*65)+(numberStacked*3)); 
            
            
            if(numberStacked<numberToStack)numberStacked++;

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
    timeSinceInteractionOrShake=0.0f;
    
    
    [gw Blackboard].PickupObject=nil;
    
    NSMutableDictionary *pl=[[[NSMutableDictionary alloc] init] autorelease];
    [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
    [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
    
    //broadcast search for pickup object gw
    [gw handleMessage:kDWareYouAPickupTarget andPayload:pl withLogLevel:-1];
    
    if([gw Blackboard].PickupObject!=nil)
    {
        [gw.Blackboard.PickupObject handleMessage:kDWstopAllActions];
        DWPartitionObjectGameObject *pogo=(DWPartitionObjectGameObject*)gw.Blackboard.PickupObject;
        [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:-1];
        gw.Blackboard.DropObject=nil;
        gw.Blackboard.PickupOffset = location;
        
        // check where our object was - no mount = cage. mount = row.
        [loggingService logEvent:(pogo.Mount ? BL_PA_NB_TOUCH_BEGIN_ON_ROW : BL_PA_NB_TOUCH_BEGIN_ON_CAGED_OBJECT)
            withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:pogo.ObjectValue] forKey:@"objectValue"]];
        
        previousMount=pogo.Mount;
        
        [pogo handleMessage:kDWunsetMount];

        
        //this is just a signal for the GO to us, pickup object is retained on the blackboard
        [pogo handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
        
        // remove it from being a mounted object -- if it's not an init object
        if(!pogo.InitedObject && [[mountedObjects objectAtIndex:pogo.IndexPos] containsObject:pogo])
            [[mountedObjects objectAtIndex:pogo.IndexPos] removeObject:pogo];
        
        [self reorderMountedObjects];
        
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
        
        [pogo logInfo:@"this object was picked up" withData:0];
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    if([gw Blackboard].PickupObject != nil)
    {
        NSMutableDictionary *pl=[[[NSMutableDictionary alloc] init] autorelease];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:-1];
        
        
        DWPartitionObjectGameObject *pogo = (DWPartitionObjectGameObject*)[gw Blackboard].PickupObject;

        //previously removex b/c of log perf - restored for testing with sans-Couchbase logging
        [loggingService logEvent:BL_PA_NB_TOUCH_MOVE_MOVE_BLOCK
            withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:pogo.ObjectValue] forKey:@"objectValue"]];
        
        hasMovedBlock=YES;

        
        pogo.MovePosition = location;
        [[gw Blackboard].PickupObject handleMessage:kDWmoveSpriteToPosition];
        
        if(gw.Blackboard.DropObject == nil)
        {
            [pogo handleMessage:kDWunsetMount];
        }
    }

}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;

    NSMutableDictionary *pl=[[[NSMutableDictionary alloc] init] autorelease];
    [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
    [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
    
    if(hasMovedBlock)[loggingService logEvent:BL_PA_NB_TOUCH_MOVE_MOVE_BLOCK withAdditionalData:nil];
    
    if([gw Blackboard].PickupObject!=nil)
    {
        gw.Blackboard.DropObject = nil;
        [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:-1];
        DWPartitionObjectGameObject *pogo = (DWPartitionObjectGameObject*)[gw Blackboard].PickupObject;
        
        if([gw Blackboard].DropObject!=nil)
        {

            DWPartitionRowGameObject *prgo = (DWPartitionRowGameObject*)[gw Blackboard].DropObject;
            
            [pogo handleMessage:kDWsetMount andPayload:[NSDictionary dictionaryWithObject:prgo forKey:MOUNT] withLogLevel:-1];
            hasUsedBlock=YES;
            
            // touch ended on a row so we've set it. log it's value
            [loggingService logEvent:BL_PA_NB_TOUCH_END_ON_ROW
                withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:pogo.ObjectValue] forKey:@"objectValue"]];
        }
        else
        {
            if(((DWPartitionObjectGameObject*)gw.Blackboard.PickupObject).InitedObject)
            {
                [gw.Blackboard.PickupObject handleMessage:kDWsetMount andPayload:[NSDictionary dictionaryWithObject:previousMount forKey:MOUNT] withLogLevel:0];
            }
            else {
                [pogo handleMessage:kDWmoveSpriteToHome];
                [[mountedObjects objectAtIndex:pogo.IndexPos] addObject:gw.Blackboard.PickupObject];
                
                [gw handleMessage:kDWhighlight andPayload:nil withLogLevel:-1];  
                
                // log that we dropped into space
                [loggingService logEvent:BL_PA_NB_TOUCH_END_IN_SPACE
                    withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:pogo.ObjectValue] forKey:@"objectValue"]];
            }
        }
    }
    
    [self reorderMountedObjects];
    
    [gw handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:-1];
    
    [gw Blackboard].PickupObject=nil;
    hasMovedBlock=NO;

}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    hasMovedBlock=NO;
}

#pragma mark - evaluation and reject
-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    toolHost.PpExpr=[BAExpressionTree treeWithRoot:[BAEqualsOperator operator]];
    
    //add an initial integer to the chained equality if eval_target is in use
    if(hasEvalTarget)
    {
        [toolHost.PpExpr.root addChild:[BAInteger integerWithIntValue:explicitEvalTarget]];
    }
    
    //loop rows
    for (DWPartitionRowGameObject *prgo in createdRows) {

        //create child to the equality
        //BAAdditionOperator *rowAdd=[BAAdditionOperator operator];
        //[toolHost.PpExpr.root addChild:rowAdd];
        
        int cumRowLength=0;
        
        for(DWPartitionObjectGameObject *pogo in prgo.MountedObjects)
        {
            //create child to the addition
            //disabled -- we can't add more or less than two values, sum internally
            //[rowAdd addChild:[BAInteger integerWithIntValue:pogo.Length]];
            
            cumRowLength+=pogo.Length;
        }
        
        //add the accumulated row length as an integer child to the equality
        [toolHost.PpExpr.root addChild:[BAInteger integerWithIntValue:cumRowLength]];
    }
    
    //print expression
    NSLog(@"%@", [toolHost.PpExpr xmlStringValue]);
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:toolHost.PpExpr.root andTree:toolHost.PpExpr];
    
    return [q assumeAndEvalEqualityAtRoot];
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
        if(rejectMode==kProblemRejectOnCommit && rejectType==kProblemAutomatedTransition)[self resetProblemFromReject];
        else if(rejectType==kProblemResetOnReject)[toolHost resetProblem];
        else [toolHost showProblemIncompleteMessage];
    }
}

-(void)resetProblemFromReject
{
    // check our reject mode is correct
    if(rejectMode==kProblemRejectOnCommit)
    {
        // show the problem incomplete message
        [toolHost showProblemIncompleteMessage];

        // start our for loop
        for(int i=0;i<createdRows.count;i++)
        {
            // set the current row
            DWPartitionRowGameObject *prgo=[createdRows objectAtIndex:i];
        
            //set the count of objects on that row
            int count=[prgo.MountedObjects count];
            
            //and if the row isn't locked
            if(!prgo.Locked){
                for (int o=count-1;o>=0;o--)
                {
                    // set the current object and send it home - resetting the mount for any inited objects
                    DWPartitionObjectGameObject *pogo=[prgo.MountedObjects objectAtIndex:o];
                    [pogo handleMessage:kDWmoveSpriteToHome];
                    if(pogo.InitedObject) [pogo handleMessage:kDWsetMount andPayload:[NSDictionary dictionaryWithObject:prgo forKey:MOUNT] withLogLevel:0];
                }
            }
        }

    }
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
    [gw writeLogBufferToDiskWithKey:@"PartitionTool"];
    
    //tear down
    [gw release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    if(initBars) [initBars release];
    if(initObjects) [initObjects release];
    if(initCages) [initCages release];
    if(solutionsDef) [solutionsDef release];
    if(createdRows) [createdRows release];
    if(mountedObjects) [mountedObjects release];
    [super dealloc];
}

@end
