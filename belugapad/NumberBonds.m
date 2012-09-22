//
//  NumberBonds.m
//  belugapad
//
//  Created by David Amphlett on 29/03/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "NumberBonds.h"
#import "global.h"
#import "ToolHost.h"
#import "DWNBondObjectGameObject.h"
#import "DWNBondRowGameObject.h"
#import "DWNBondStoreGameObject.h"
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

@interface NumberBonds()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

static float kTimeToMountedShake=7.0f;

@implementation NumberBonds
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
                for(DWNBondObjectGameObject *pogo in a)
                {
                    [pogo.BaseNode runAction:[InteractionFeedback shakeAction]];
                }
            }
        }
        timeSinceInteractionOrShake=0.0f;
        if(isWinning)[toolHost shakeCommitButton];
    }
    
    [self updateLabels];

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
    
    solutionMode = [[pdef objectForKey:SOLUTION_MODE]intValue];
    
    if(solutionMode==kSolutionRowMatch)
    {
        solutionsDef = [pdef objectForKey:SOLUTIONS];
        [solutionsDef retain];
    }
    else if(solutionMode==kSolutionFreeform)
    {
        solutionValue = [[pdef objectForKey:SOLUTION_VALUE]intValue];
    }

    
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
        useBlockScaling = YES;
    
    if([pdef objectForKey:SHOW_BADGES])
        showBadgesOnCages = [[pdef objectForKey:SHOW_BADGES]boolValue];
    else
    showBadgesOnCages = YES;
    
    createdRows = [[NSMutableArray alloc]init];
    
    mountedObjects = [[NSMutableArray alloc]init];
    mountedObjectBadges = [[NSMutableArray alloc]init];
    mountedObjectLabels = [[NSMutableArray alloc]init];
}

-(void)populateGW
{

    int dockSize=[initCages count]+2;
    float dockPieceYPos=582.0f;
    float initBarStartYPos=582.0f;
    float initCageStartYPos=dockPieceYPos-43;
    float initCageBadgePos=initCageStartYPos+2;
    
    float dockMidSpacing=0.0f;
    
    if(useBlockScaling)
        dockMidSpacing=35.0f;
    else
        dockMidSpacing=60.0f;
    
    NSString *middleAsset=[NSString stringWithFormat:@"/images/partition/NB_Dock_Middle%d.png",(int)dockMidSpacing];
    
    for(int i=0;i<dockSize;i++)
    {
        CCSprite *dockPiece=nil;
        
        if(i==0)
            dockPiece=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/partition/NB_Dock_Top.png")];
        else if(i==dockSize-1)
            dockPiece=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/partition/NB_Dock_Bottom.png")];
        else
            dockPiece=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(middleAsset)];
        
        
        [dockPiece setPosition:ccp(25,dockPieceYPos)];
        [dockPiece setTag:1];
        [dockPiece setOpacity:0];
        [renderLayer addChild:dockPiece];
        
        if(i==0)
            dockPieceYPos-=43.0f;
        else if(i==dockSize-2)
            dockPieceYPos-=42.0f;
        else
            dockPieceYPos-=dockMidSpacing;
        
    }

    // do stuff with our INIT_BARS (DWNBondRowGameObject)
    
    for (int i=0;i<[initBars count]; i++)
    {
        
        float xStartPos=(cx+200-((([[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue]+2)*50)/2)+25);
        
        DWNBondRowGameObject *prgo = [DWNBondRowGameObject alloc];
        [gw populateAndAddGameObject:prgo withTemplateName:@"TnBondRow"];
        prgo.Position=ccp(xStartPos,initBarStartYPos);
        prgo.Length = [[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue];
        prgo.Locked = [[[initBars objectAtIndex:i] objectForKey:LOCKED] boolValue];
    
        [createdRows addObject:prgo];
        initBarStartYPos-=100;
        
        [prgo release];
    }
    
    // do stuff with our INIT_CAGES (DWNBondStoreGameObject)
    for (int i=0;i<[initCages count]; i++)
    {
        int qtyForThisStore=[[[initCages objectAtIndex:i] objectForKey:QUANTITY] intValue];
        int thisLength=0;
        NSMutableArray *currentVal=[[NSMutableArray alloc]init];
        for (int ic=0;ic<qtyForThisStore;ic++)
        {
            DWNBondObjectGameObject *pogo = [DWNBondObjectGameObject alloc];
            [gw populateAndAddGameObject:pogo withTemplateName:@"TnBondObject"];
            pogo.IndexPos=i;
            
            //pogo.Position=ccp(25-(numberStacked*2),650-(i*65)+(numberStacked*3));
            pogo.Length=[[[initCages objectAtIndex:i] objectForKey:LENGTH] intValue];
            thisLength=pogo.Length;
            
            if([[initCages objectAtIndex:i] objectForKey:LABEL])
            {
                pogo.Label=[CCLabelTTF labelWithString:[[initCages objectAtIndex:i] objectForKey:LABEL] fontName:@"Source Sans Pro" fontSize:PROBLEM_DESC_FONT_SIZE];
            }
            
            if(!useBlockScaling){
                pogo.IsScaled=YES;
                pogo.NoScaleBlock=YES;
                pogo.Position=ccp(20,initCageStartYPos-(i*dockMidSpacing));
            }
            else
            {
                pogo.Position=ccp(20,initCageStartYPos-(i*dockMidSpacing));
            }
            
            pogo.MountPosition = pogo.Position;
            
            
            [currentVal addObject:pogo];
        }
        [mountedObjects addObject:currentVal];
        
        if(showBadgesOnCages)
        {
            
            CCSprite *thisBadge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/partition/NB_Notification.png")];
            CCLabelTTF *thisLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",[[mountedObjects objectAtIndex:i]count]] fontName:@"Source Sans Pro" fontSize:16.0f];
            
            if(!useBlockScaling)
                [thisBadge setPosition:ccp(20+(50*thisLength),initCageBadgePos-(i*dockMidSpacing-10))];
            else
                [thisBadge setPosition:ccp(20+(50*(thisLength*0.5)),initCageBadgePos-(i*dockMidSpacing-10))];
            [thisLabel setPosition:ccp(15,12)];
            
            [renderLayer addChild:thisBadge z:1000];
            [thisBadge addChild:thisLabel];
            
            [thisBadge setTag:3];
            [thisLabel setTag:3];
            [thisBadge setOpacity:0];
            [thisLabel setOpacity:0];
            
            [mountedObjectLabels addObject:thisLabel];
            [mountedObjectBadges addObject:thisBadge];
        }
        
        [currentVal release];
    }
    
    // do stuff with our INIT_OBJECTS (DWNBondObjectGameObject)    
    for (int i=0;i<[initObjects count]; i++)
    {
        //pogo.Position=ccp(512,284);
        int insRow=[[[initObjects objectAtIndex:i] objectForKey:PUT_IN_ROW] intValue];
        int insLength=[[[initObjects objectAtIndex:i] objectForKey:LENGTH] intValue];
        NSString *fillText=[[NSString alloc]init];
        DWNBondObjectGameObject *pogo = [DWNBondObjectGameObject alloc];
        [gw populateAndAddGameObject:pogo withTemplateName:@"TnBondObject"];   
        
        //[pogo.Mounts addObject:[createdRows objectAtIndex:insRow]];
        pogo.Length = insLength;
        
        pogo.InitedObject=YES;

        if([[initObjects objectAtIndex:i]objectForKey:LABEL]) fillText = [[initObjects objectAtIndex:i]objectForKey:LABEL];
        else fillText=[NSString stringWithFormat:@"%d", insLength];
        
        pogo.Label = [CCLabelTTF labelWithString:fillText fontName:CHANGO fontSize:PROBLEM_DESC_FONT_SIZE];
        
        DWNBondRowGameObject *prgo = (DWNBondRowGameObject*)[createdRows objectAtIndex:insRow];
        NSDictionary *pl=[NSDictionary dictionaryWithObject:prgo forKey:MOUNT];
        [pogo handleMessage:kDWsetMount andPayload:pl withLogLevel:-1];
        pogo.Position = prgo.Position;
        pogo.MountPosition = prgo.Position;
        [prgo handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:0];
        
        [fillText release];
        [pogo release];
    }

}

-(void)updateLabels
{
    for(int i=0;i<[mountedObjectLabels count];i++)
    {
        NSArray *thisArray=[mountedObjects objectAtIndex:i];
        CCLabelTTF *thisLabel=[mountedObjectLabels objectAtIndex:i];
        CCSprite *thisSprite=[mountedObjectBadges objectAtIndex:i];
        
        if([thisArray count]>0)
        {
            [thisSprite setVisible:YES];
            [thisLabel setVisible:YES];
            thisLabel.string=[NSString stringWithFormat:@"%d",[thisArray count]];
        }
        else
        {
            [thisSprite setVisible:NO];
            [thisLabel setVisible:NO];
        }
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
            DWNBondObjectGameObject *pogo=[[mountedObjects objectAtIndex:i] objectAtIndex:ic];
            
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
        DWNBondObjectGameObject *pogo=(DWNBondObjectGameObject*)gw.Blackboard.PickupObject;
        pogo.lastZIndex=[pogo.BaseNode zOrder];
        [pogo.BaseNode setZOrder:10000];
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
        
        //[self reorderMountedObjects];
        
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
        
        
        DWNBondObjectGameObject *pogo = (DWNBondObjectGameObject*)[gw Blackboard].PickupObject;

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
        DWNBondObjectGameObject *pogo = (DWNBondObjectGameObject*)[gw Blackboard].PickupObject;
        [pogo.BaseNode setZOrder:pogo.lastZIndex];
        
        if([gw Blackboard].DropObject!=nil)
        {

            DWNBondRowGameObject *prgo = (DWNBondRowGameObject*)[gw Blackboard].DropObject;
            
            [pogo handleMessage:kDWsetMount andPayload:[NSDictionary dictionaryWithObject:prgo forKey:MOUNT] withLogLevel:-1];
            hasUsedBlock=YES;
            
            // touch ended on a row so we've set it. log it's value
            [loggingService logEvent:BL_PA_NB_TOUCH_END_ON_ROW
                withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:pogo.ObjectValue] forKey:@"objectValue"]];
        }
        else
        {
            if(((DWNBondObjectGameObject*)gw.Blackboard.PickupObject).InitedObject)
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
    
    //[self reorderMountedObjects];
    
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
    if(solutionMode==kSolutionTopRow)
    {
        //returns YES if the tool expression evaluates succesfully
        toolHost.PpExpr=[BAExpressionTree treeWithRoot:[BAEqualsOperator operator]];
        
        //loop rows
        for (DWNBondRowGameObject *prgo in createdRows) {

            //create child to the equality
            //BAAdditionOperator *rowAdd=[BAAdditionOperator operator];
            //[toolHost.PpExpr.root addChild:rowAdd];
            
            int cumRowLength=0;
            
            for(DWNBondObjectGameObject *pogo in prgo.MountedObjects)
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
        
        BOOL ret= [q assumeAndEvalEqualityAtRoot];
        
        [q release];
        
        return ret;
    }
    else if(solutionMode==kSolutionRowMatch)
    {
        int foundSolutions=0;
        NSMutableArray *correctRows=[[NSMutableArray alloc]init];
        NSMutableArray *usedSolutions=[[NSMutableArray alloc]init];
        
//        NSMutableArray *solCopy=[NSMutableArray arrayWithArray:solutionsDef
        
        // for each row, we need to find whether their make-up is a solution
        for(DWNBondRowGameObject *r in createdRows)
        {
            if([correctRows containsObject:r])continue;
            // for each row, check each solution
            for(NSArray *a in solutionsDef)
            {
                // we assume at the start that everything is right
                BOOL matchedAllObjects=YES; 
                // if there's no objects in this row, continue - if the row's already correct, continue
                if([r.MountedObjects count]==0)continue;
                if([usedSolutions containsObject:a])continue;
                
                // loop through each mounted object
                for(int v=0;v<[r.MountedObjects count];v++)
                {
                    if(matchedAllObjects)
                    {
                        // if the count in the array and amount of objects differ, we know we're in the wrong place
                        if(![a count]==[r.MountedObjects count])
                        {
                            matchedAllObjects=NO;
                            break;
                        }
                        
                        // get our 2 values to compare
                        int reqVal=[[a objectAtIndex:v]intValue];
                        int thisVal=((DWNBondObjectGameObject*)[r.MountedObjects objectAtIndex:v]).Length;
                        

                        // then check them - and either set them as matched, or not
                        if(reqVal!=thisVal)
                        {
                            matchedAllObjects=NO;
                            continue;
                        }
                        if(matchedAllObjects && reqVal==thisVal)
                        {
                            matchedAllObjects=YES;
                        }
                    }
                    
                }
                
                if(matchedAllObjects)
                {
                    // if they match, add to a correctrows array and increase the found solutions
                    [correctRows addObject:r];
                    [usedSolutions addObject:a];
                    foundSolutions++;
                    continue;
                }
            }
            
        }
        
        [usedSolutions release];
        [correctRows release];
        
        if(foundSolutions==[createdRows count])
            return YES;
        else 
            return NO;
        
    }
    else if(solutionMode==kSolutionFreeform)
    {
        BOOL ret=YES;
        
        for(DWNBondRowGameObject *prgo in createdRows)
        {
            int thisRowVal=0;
            
            for(DWNBondObjectGameObject *pogo in prgo.MountedObjects)
            {
                thisRowVal+=pogo.Length;
            }
            
            if(thisRowVal==solutionValue && ret)
                ret=YES;
            else 
                ret=NO;
        }
        
        return ret;
    }
    else 
    {
        return NO;
    }
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
            DWNBondRowGameObject *prgo=[createdRows objectAtIndex:i];
        
            //set the count of objects on that row
            int count=[prgo.MountedObjects count];
            
            //and if the row isn't locked
            if(!prgo.Locked){
                for (int o=count-1;o>=0;o--)
                {
                    // set the current object and send it home - resetting the mount for any inited objects
                    DWNBondObjectGameObject *pogo=[prgo.MountedObjects objectAtIndex:o];
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
    [renderLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //removing manual releases here -- causing msg_send issue
//    if(initBars) [initBars release];
//    if(initObjects) [initObjects release];
//    if(initCages) [initCages release];
//    if(solutionsDef) [solutionsDef release];
    if(createdRows) [createdRows release];
    if(mountedObjects) [mountedObjects release];
    if(mountedObjectLabels) [mountedObjectLabels release];
    if(mountedObjectBadges) [mountedObjectBadges release];
    
    //tear down
    [gw release];
    
    [super dealloc];
}

@end
