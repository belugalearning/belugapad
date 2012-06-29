//
//  PieSplitter.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "PieSplitter.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "BLMath.h"

#import "DWPieSplitterContainerGameObject.h"
#import "DWPieSplitterPieGameObject.h"
#import "DWPieSplitterSliceGameObject.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "UsersService.h"
#import "AppDelegate.h"

static float kTimeToPieShake=7.0f;

@interface PieSplitter()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation PieSplitter

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
    
    // compare our status to the gamestate
    if([activeCon count]<1 && [activePie count]<1)gameState=kGameCannotSplit;
    else if(((!hasSplit &&[activeCon count]>1 && [activePie count]>0 && !reqCorrectPieSquaresToSplit) || (!hasSplit && [activeCon count]==divisor && [activePie count]==dividend && reqCorrectPieSquaresToSplit)))gameState=kGameReadyToSplit;

    else if([activeCon count]>1 && [activePie count]>0 && hasSplit)gameState=kGameSlicesActive;
    
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
    if(timeSinceInteractionOrShake>kTimeToPieShake)
    {
        [self animShake];
        timeSinceInteractionOrShake=0;
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
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType=[[pdef objectForKey:REJECT_TYPE] intValue];    
    showReset=[[pdef objectForKey:SHOW_RESET]boolValue];
    startProblemSplit=[[pdef objectForKey:START_PROBLEM_SPLIT]boolValue];
    reqCorrectPieSquaresToSplit=[[pdef objectForKey:SPLIT_WITH_CORRECT_NUMBERS]boolValue];
    numberOfCagedPies=[[pdef objectForKey:NUMBER_CAGED_PIES]intValue];
    numberOfCagedContainers=[[pdef objectForKey:NUMBER_CAGED_SQUARES]intValue];

    
    if([pdef objectForKey:NUMBER_CAGED_PIES])
        numberOfCagedPies=[[pdef objectForKey:NUMBER_CAGED_PIES]intValue];
    else
        numberOfCagedPies=20;
    
    if([pdef objectForKey:NUMBER_CAGED_SQUARES])
        numberOfCagedContainers=[[pdef objectForKey:NUMBER_CAGED_SQUARES]intValue];
    else
        numberOfCagedContainers=20;
    
    if([pdef objectForKey:SHOW_RESET_SLICES])
        showResetSlicesToPies=[[pdef objectForKey:SHOW_RESET_SLICES]boolValue];
    else 
        showResetSlicesToPies=YES;
    
    
    numberOfActivePies=[[pdef objectForKey:NUMBER_ACTIVE_PIES]intValue];
    numberOfActiveContainers=[[pdef objectForKey:NUMBER_ACTIVE_SQUARES]intValue];
    dividend=[[pdef objectForKey:DIVIDEND]intValue];
    divisor=[[pdef objectForKey:DIVISOR]intValue];
    
    showReset=[[pdef objectForKey:SHOW_RESET] boolValue];
    
    // if the problem should be showing a reset button
    if(showReset)
    {
        CCSprite *resetBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ui/reset.png")];
        [resetBtn setPosition:ccp(lx-(kPropXCommitButtonPadding*lx), ly-(kPropXCommitButtonPadding*lx))];
        [resetBtn setTag:3];
        [resetBtn setOpacity:0];
        [self.ForeLayer addChild:resetBtn z:2];        
    }
    
    if(showResetSlicesToPies)
    {
        resetSlices=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/reset-slices.png")];
        [resetSlices setPosition:ccp(35,580)];
        [resetSlices setTag:3];
        [resetSlices setOpacity:0];
        [resetSlices setScale:0.5f];
        [self.ForeLayer addChild:resetSlices];
    }
    
    
    int totalSlices=dividend*divisor;
    slicesInEachPie=totalSlices/divisor;
}

-(void)populateGW
{
    renderLayer = [[CCLayer alloc] init];
    activeCon=[[[NSMutableArray alloc]init]retain];
    activePie=[[[NSMutableArray alloc]init]retain];
    
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    pieBox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/dropzone.png")];
    conBox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/dropzone.png")];
    
    [pieBox setPosition:ccp(cx,475)];
    [conBox setPosition:ccp(cx,240)];
    
    [pieBox setOpacity:50];
    [conBox setOpacity:50];
    
    [pieBox setVisible:NO];
    [conBox setVisible:NO];
    
    
    
    [renderLayer addChild:pieBox];
    [renderLayer addChild:conBox];
    
    [self createPieAtMount];
    [self createContainerAtMount];

    for (int i=0;i<numberOfActiveContainers;i++)
    {
        [self createActiveContainer];
    }
    
    for(int i=0;i<numberOfActivePies;i++)
    {
        [self createActivePie];
    }
    
    [self reorderActiveContainers];
    [self reorderActivePies];
    
    [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:-1];
    
    if(startProblemSplit)[self splitPies];
    
    
}

-(void)updateLabels
{
    for(int i=0;i<[activeCon count];i++)
    {
        DWPieSplitterContainerGameObject *cont=[activeCon objectAtIndex:i];
        NSString *thisConVal=[[NSString alloc]init];
        int slicesInCont=[cont.mySlices count];
        float thisVal=(float)slicesInCont/(float)[activeCon count];
        if(labelType==kLabelShowDecimal) thisConVal=[NSString stringWithFormat:@"%.02g", thisVal];
        if(labelType==kLabelShowFraction) { 
            int fullPies=slicesInCont/[activeCon count];
            int extraSlices=slicesInCont-(fullPies*[activeCon count]);
            if(fullPies==0)thisConVal=[NSString stringWithFormat:@"%d/%d", slicesInCont, [activeCon count]];
            else if(fullPies>0 && extraSlices==0)thisConVal=[NSString stringWithFormat:@"%d", fullPies];
            else if(fullPies>0 && extraSlices>0)thisConVal=[NSString stringWithFormat:@"%d %d/%d", fullPies, extraSlices, [activeCon count]];
        }
        if(!cont.textString)cont.textString=[[NSString alloc]init];
        cont.textString=thisConVal;
    }
    [gw handleMessage:kDWupdateLabels andPayload:nil withLogLevel:-1];
}

#pragma mark - object interaction
-(void)createPieAtMount
{
    DWPieSplitterPieGameObject *pie = [DWPieSplitterPieGameObject alloc];
    [gw populateAndAddGameObject:pie withTemplateName:@"TpieSplitterPie"];
    pie.Position=ccp(35,700);
    pie.MountPosition=pie.Position;
    //if(hasSplit)[self splitPie:pie];
    newPie=pie;
    createdPies++;
}

-(void)createContainerAtMount
{
    DWPieSplitterContainerGameObject *cont = [DWPieSplitterContainerGameObject alloc];
    [gw populateAndAddGameObject:cont withTemplateName:@"TpieSplitterContainer"];
    cont.Position=ccp(35,640);
    cont.MountPosition=cont.Position;
    newCon=cont;
    createdCont++;
}

-(void)createActivePie
{
    DWPieSplitterPieGameObject *pie = [DWPieSplitterPieGameObject alloc];
    [gw populateAndAddGameObject:pie withTemplateName:@"TpieSplitterPie"];
    pie.Position=ccp(0,pieBox.position.y);
    pie.MountPosition=ccp(35,700);
    [pie.mySprite setScale:1.0f];
    pie.ScaledUp=YES;
    if(hasSplit)
        [self splitPie:pie];
    
    [activePie addObject:pie];
}

-(void)createActiveContainer
{
    DWPieSplitterContainerGameObject *cont = [DWPieSplitterContainerGameObject alloc];
    [gw populateAndAddGameObject:cont withTemplateName:@"TpieSplitterContainer"];
    cont.Position=ccp(0,conBox.position.y);
    cont.MountPosition=ccp(35,640);
    [cont.mySpriteTop setScale:1.0f];
    [cont.mySpriteMid setScale:1.0f];
    [cont.mySpriteBot setScale:1.0f];
    cont.ScaledUp=YES;
    [activeCon addObject:cont];
}

-(void)addGhostPie
{
    [pieBox setVisible:YES];

    DWPieSplitterPieGameObject *pie = [DWPieSplitterPieGameObject alloc];
    ghost=pie;
    
    [gw populateAndAddGameObject:pie withTemplateName:@"TpieSplitterPie"];
    pie.Position=ccp(([activePie count]+0.5)*(lx/[activePie count]), pieBox.position.y);
    pie.MountPosition=ccp(35,700);
    [pie.mySprite setScale:1.0f];
    pie.ScaledUp=YES;
    [activePie addObject:pie];
    [pie handleMessage:kDWsetupStuff];
    [pie.mySprite setOpacity:25];
    [pie.touchOverlay setOpacity:25];
    [self reorderActivePies];
}

-(void)addGhostContainer
{
    [conBox setVisible:YES];
    
    DWPieSplitterContainerGameObject *cont = [DWPieSplitterContainerGameObject alloc];
    ghost=cont;
    
    [gw populateAndAddGameObject:cont withTemplateName:@"TpieSplitterContainer"];
    cont.Position=ccp(([activeCon count]+0.5)*(lx/[activeCon count]), conBox.position.y);
    cont.MountPosition=ccp(35,700);
    [cont.mySpriteTop setScale:1.0f];
    [cont.mySpriteMid setScale:1.0f];
    [cont.mySpriteBot setScale:1.0f];
    cont.ScaledUp=YES;
    [activeCon addObject:cont];
    [cont handleMessage:kDWsetupStuff];
    [cont.mySpriteTop setOpacity:25];
    [cont.mySpriteMid setOpacity:25];
    [cont.mySpriteBot setOpacity:25];
    [self reorderActiveContainers];
}

-(void)removeGhost
{
    if(ghost){
        if([activePie containsObject:ghost])[activePie removeObject:ghost];
        if([activeCon containsObject:ghost])[activeCon removeObject:ghost];
        [ghost handleMessage:kDWdismantle];
        [gw delayRemoveGameObject:ghost];
        ghost=nil;
    }
}

-(void)reorderActivePies
{

    for(DWPieSplitterPieGameObject *p in activePie)
    {
        p.Position=ccp(([activePie indexOfObject:p]+0.5)*(lx/[activePie count]), pieBox.position.y);
        [p.mySprite runAction:[CCMoveTo actionWithDuration:0.3f position:p.Position]];
    }
}

-(void)reorderActiveContainers
{
    NSLog(@"current activeCon count %d", [activeCon count]);
    for(int i=0;i<[activeCon count];i++)
    {
        DWPieSplitterContainerGameObject *c=[activeCon objectAtIndex:i];
        if(!c.ScaledUp)continue;
        
        c.Position=ccp((i+0.5)*(lx/[activeCon count]), conBox.position.y+((int)[activeCon count]/10)*100);
        [c.BaseNode runAction:[CCMoveTo actionWithDuration:0.3f position:c.Position]];
    }
}

-(void)splitPie:(DWPieSplitterPieGameObject*)p
{
        [p handleMessage:kDWsplitActivePies];
        p.numberOfSlices=[activeCon count];
        p.HasSplit=YES;
        
        for(int i=0;i<p.numberOfSlices;i++)
        {
            DWPieSplitterSliceGameObject *slice = [DWPieSplitterSliceGameObject alloc];
            [gw populateAndAddGameObject:slice withTemplateName:@"TpieSplitterSlice"];
            slice.Position=p.Position;
            slice.myPie=p;
            if(!p.mySlices)p.mySlices=[[NSMutableArray alloc]init];
            slice.SpriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice%d.png", [activeCon count]];
            slice.Rotation=(360/p.numberOfSlices)*i;
            [p.mySlices addObject:slice];
            [slice handleMessage:kDWsetupStuff];
        }
        
    
    hasSplit=YES;
    gameState=kGameSlicesActive;
}

-(void)splitPies
{
    for(DWPieSplitterPieGameObject *p in activePie)
    {
        [p handleMessage:kDWsplitActivePies];
        p.numberOfSlices=[activeCon count];
        p.HasSplit=YES;
        
        for(int i=0;i<p.numberOfSlices;i++)
        {
            DWPieSplitterSliceGameObject *slice = [DWPieSplitterSliceGameObject alloc];
            [gw populateAndAddGameObject:slice withTemplateName:@"TpieSplitterSlice"];
            slice.Position=p.Position;
            slice.myPie=p;
            if(!p.mySlices)p.mySlices=[[NSMutableArray alloc]init];
            slice.SpriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice%d.png", [activeCon count]];
            slice.Rotation=(360/p.numberOfSlices)*i;
            [p.mySlices addObject:slice];
            [slice handleMessage:kDWsetupStuff];
        }
        
        
        hasSplit=YES;
        gameState=kGameSlicesActive;
    }
}

-(void)removeSlices
{
    for (DWPieSplitterContainerGameObject *p in activePie)
    {
        NSLog(@"hit pie");
        for (DWPieSplitterSliceGameObject *s in p.mySlices)
        {
            NSLog(@"dismantle and remove GO");
            [s handleMessage:kDWdismantle];
            [gw delayRemoveGameObject:s];
        }
    }
}

#pragma mark - animation

-(void)animShake
{
    CCEaseInOut *ml1=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.05f position:ccp(-10, 0)] rate:2.0f];
    CCEaseInOut *mr1=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.1f position:ccp(20, 0)] rate:2.0f];
    CCEaseInOut *ml2=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:0.05f position:ccp(-10, 0)] rate:2.0f];
    CCSequence *s=[CCSequence actions:ml1, mr1, ml2, nil];
    CCRepeat *r=[CCRepeat actionWithAction:s times:4];
    
    CCEaseInOut *oe=[CCEaseInOut actionWithAction:r rate:2.0f];
    
    if([activePie count]<1)[newPie.mySprite runAction:oe];

    
}

-(void)balanceContainers
{
    //int maxPXtoMove=100;
    int stepper=20;
    BOOL isGreater;
    BOOL isLess;

    
    // loop through containers
    for (int i=0;i<[activeCon count];i++)
    {
        DWPieSplitterContainerGameObject *c=[activeCon objectAtIndex:i];
        
        // set an amount to reposition by
        float myYPos=stepper*[c.mySlices count];

        // take the local nodespace of the container's world position
        CGPoint adjPos=[c.BaseNode convertToNodeSpace:c.Position];
        
        
        // if it's less we need to know as there're a couple of clauses to check against
        if(myYPos<c.RealYPosOffset)isLess=YES;
        
        // but we set the offset first anyway in case it's greater
        c.RealYPosOffset=myYPos; 
        
        if(isLess){
//            [c.BaseNode runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:1.0f position:[c.BaseNode convertToWorldSpace:ccp(adjPos.x,myYPos)]]]];NSLog(@"myYPos %g",myYPos);}
            
            // if slices are 0 and we're decreasing - we need to be right to the top again
            if(c.RealYPosOffset==stepper && [c.mySlices count]==0)c.RealYPosOffset=0;
            // else - set mypos as normal
            else c.RealYPosOffset=myYPos;

        }
        
        // then set the position using our offset
        [c.BaseNode setPosition:[c.BaseNode convertToWorldSpace:ccp(adjPos.x, adjPos.y-c.RealYPosOffset)]];
             
//        NSLog(@"mySlices = %d, myOffset = %g, myYPos = %g, yPos = %g", [c.mySlices count], c.RealYPosOffset, myYPos, c.BaseNode.position.y);
        
        isGreater=NO;
        isLess=NO;
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
    lastTouch=location;
    timeSinceInteractionOrShake=0;
    
    gw.Blackboard.PickupObject=nil;
    gw.Blackboard.DropObject=nil;
    
    // get our number of active slices
    for(DWPieSplitterContainerGameObject *c in activeCon)
    {
        numberOfCagedSlices+=[c.mySlices count];
    }
    
    
    if(gameState==kGameSlicesActive)
    {
        if(CGRectContainsPoint(resetSlices.boundingBox, location))
        {
            for(DWPieSplitterContainerGameObject *c in activeCon)
            {
                for(DWPieSplitterSliceGameObject *s in c.mySlices)
                {
                    [s handleMessage:kDWunsetMount];
                    [s handleMessage:kDWmoveSpriteToHome];
                }
                [c handleMessage:kDWunsetAllMountedObjects];
            }
        }

    }
    
    if(gameState==kGameReadyToSplit || gameState==kGameSlicesActive)
    {
        for(DWPieSplitterPieGameObject *p in activePie)
        {
            if(CGRectContainsPoint(p.mySprite.boundingBox, location) && !p.HasSplit)
            {
                [self splitPie:p];
                return;
            }
        }
    }
    
    // check the labels have been tapped, or not
    for(DWPieSplitterContainerGameObject *c in activeCon)
    {
        if(CGRectContainsPoint(c.myText.boundingBox, [c.mySpriteTop convertToNodeSpace:location]))
        {
            if(labelType==kLabelShowDecimal)labelType=kLabelShowFraction;
            else if(labelType==kLabelShowFraction)labelType=kLabelShowDecimal;
            return;
        }
    }
    
    NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    [gw handleMessage:kDWcanITouchYou andPayload:pl withLogLevel:-1];
    
    if(gw.Blackboard.PickupObject)
    {
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]] && !((DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject).ScaledUp)[self addGhostPie];
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
        {
            DWPieSplitterContainerGameObject *cont=(DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject;
            
            if(!cont.ScaledUp && numberOfCagedSlices==0) 
                [self addGhostContainer];
            else if(numberOfCagedSlices>0)
                gw.Blackboard.PickupObject=nil;
        }
    }

    if (CGRectContainsPoint(kRectButtonReset, location) && showReset)
        [toolHost resetProblem];
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
        
    if(gw.Blackboard.PickupObject)
    {

        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
            ((DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject).Position=location;
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]])
            ((DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject).Position=location;
        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterSliceGameObject class]])
            ((DWPieSplitterSliceGameObject*)gw.Blackboard.PickupObject).Position=location;
        
        [gw.Blackboard.PickupObject handleMessage:kDWmoveSpriteToPosition andPayload:nil withLogLevel:-1];
        
        // if we haven't yet created a new object, do it now
        if(!createdNewCon && createdCont <= numberOfCagedContainers)
        {
            [self createContainerAtMount];
            createdNewCon=YES;
        }
        if(!createdNewPie && createdPies <= numberOfCagedPies)
        {
            [self createPieAtMount];
            createdNewPie=YES;
        }
        
        if(createdNewCon||createdNewPie)[gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:-1];

    }
    
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    
    NSLog(@"touch location %@", NSStringFromCGPoint(location));
    
    if(gw.Blackboard.PickupObject)
    {
        [self removeGhost];        
        // is a container?
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
        {
            DWPieSplitterContainerGameObject *cont=(DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject;
        
            // first hide the box again
            [conBox setVisible:NO];
            
            // then check whether the touch end was in the bounding box 
            if(CGRectContainsPoint(conBox.boundingBox, location))
            {
                // if this object isn't in the array, add it
                if(![activeCon containsObject:cont])[activeCon addObject:cont];
                if(hasSplit && numberOfCagedSlices==0)
                {
                    [self removeSlices];
                    [self splitPies];
                }
                
            }
            else {
                // if we're not landing on the dropzone and were previously there, remove object from array
                if([activeCon containsObject:cont])[activeCon removeObject:cont];

                // and if it wasn't - eject it back to it's mount
                [gw.Blackboard.PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:-1];
            }
            
            [self reorderActiveContainers];
        }
        
        
        // is a pie?
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]])
        {
            DWPieSplitterPieGameObject *pie=(DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject;
            
            // hide the box
            [pieBox setVisible:NO];
            
            // then check whether the touch end was in the bounding box 
            if(CGRectContainsPoint(pieBox.boundingBox, location))
            {
                // if this object isn't in the array, add it
                if(![activePie containsObject:pie])[activePie addObject:pie];
            }
            else {
                // if we're not landing on the dropzone and were previously there, remove object from array
                if([activePie containsObject:pie])[activePie removeObject:pie];
                
                // and if it wasn't - eject it back to it's mount
                [gw.Blackboard.PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:-1];
            }
            
            [self reorderActivePies];
        }
        
        // is a slice?
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterSliceGameObject class]])
        {
            NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
            [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:-1];
            
            DWPieSplitterContainerGameObject *cont=[[DWPieSplitterContainerGameObject alloc]init];
            if(gw.Blackboard.DropObject)cont=(DWPieSplitterContainerGameObject*)gw.Blackboard.DropObject;

            
            // if we have a dropobject then we need to be mounted to it
            if(gw.Blackboard.DropObject)
            {
                [gw.Blackboard.PickupObject handleMessage:kDWsetMount];
                [gw.Blackboard.DropObject handleMessage:kDWsetMountedObject];
            }
            else {
                DWPieSplitterSliceGameObject *slice=(DWPieSplitterSliceGameObject *)gw.Blackboard.PickupObject;
                DWPieSplitterContainerGameObject *cont=(DWPieSplitterContainerGameObject *)slice.myCont;
                
                slice.Position=location;
                [cont handleMessage:kDWunsetMountedObject];
                [slice handleMessage:kDWunsetMount];
                [slice handleMessage:kDWmoveSpriteToHome];
            }
        }
        
    }
    
    [self balanceContainers];
    
    isTouching=NO;
    createdNewCon=NO;
    createdNewPie=NO;
    numberOfCagedSlices=0;
    gw.Blackboard.PickupObject=nil;
    gw.Blackboard.DropObject=nil;
    
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
//    [self balanceContainers];
    
    isTouching=NO;
    createdNewCon=NO;
    createdNewPie=NO;
    numberOfCagedSlices=0;
    gw.Blackboard.PickupObject=nil;
    gw.Blackboard.DropObject=nil;

}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    if([activeCon count]==divisor)
    {
        int correctCon=0;
        
        for(int i=0;i<[activeCon count];i++)
        {
            DWPieSplitterContainerGameObject *cont=[activeCon objectAtIndex:i];
            
            if([cont.mySlices count]==slicesInEachPie){
                correctCon++;
            }
        }
        
        if(correctCon==[activeCon count])return YES;
        
    }
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
    [gw writeLogBufferToDiskWithKey:@"PieSplitter"];
    
    //tear down
    [gw release];
    
    if(activePie)[activePie release];
    if(activeCon)[activeCon release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    
    [super dealloc];
}
@end
