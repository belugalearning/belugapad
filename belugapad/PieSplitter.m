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
#import "LoggingService.h"
#import "DWPieSplitterContainerGameObject.h"
#import "DWPieSplitterPieGameObject.h"
#import "DWPieSplitterSliceGameObject.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "UsersService.h"
#import "AppDelegate.h"
#import "SimpleAudioEngine.h"
static float kTimeToPieShake=7.0f;

@interface PieSplitter()
{
@private
    ContentService *contentService;
    UsersService *usersService;
    LoggingService *loggingService;
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
    
    movementLayer = [[CCLayer alloc]init];
    gw.Blackboard.MovementLayer=movementLayer;
    [renderLayer addChild:movementLayer];
    
    createdCont=1;
    createdPies=1;
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType=[[pdef objectForKey:REJECT_TYPE] intValue];    
    showReset=[[pdef objectForKey:SHOW_RESET]boolValue];
    startProblemSplit=[[pdef objectForKey:START_PROBLEM_SPLIT]boolValue];
    reqCorrectPieSquaresToSplit=[[pdef objectForKey:SPLIT_WITH_CORRECT_NUMBERS]boolValue];

    
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
    
    if([pdef objectForKey:SHOW_NEW_PIES_CONTAINERS])
        showNewPieCont=[[pdef objectForKey:SHOW_NEW_PIES_CONTAINERS]boolValue];
    else
        showNewPieCont=YES;
    
    if([pdef objectForKey:MOVE_INIT_OBJECTS])
        moveInitObjects=[[pdef objectForKey:MOVE_INIT_OBJECTS]boolValue];
    else
        moveInitObjects=YES;
    
    if(!showNewPieCont)
        moveInitObjects=NO;
    
//#define DO_NOT_SHOW_NEW_PIES_CONTAINERS @"DO_NOT_SHOW_NEW_PIES_CONTAINERS"
//#define DISALLOW_MOVE_INIT_PIES @"DISALLOW_MOVE_INIT_PIES"
    
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
    
    showResetSlicesToPies=NO;
    
    if(showResetSlicesToPies)
    {
        resetSlices=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/reset-slices.png")];
        [resetSlices setPosition:ccp(35,450)];
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
    activeCon=[[NSMutableArray alloc]init];
    activePie=[[NSMutableArray alloc]init];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    startProblemSplit=YES;
    
    if(showNewPieCont){
        CCSprite *tabs=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/drag_tabs.png")];
        [tabs setAnchorPoint:ccp(0,0.5)];
        [tabs setPosition:ccp(0,500)];
        [renderLayer addChild:tabs];
    }
    pieBox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/dropzone.png")];
    conBox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/dropzone.png")];
    
    [pieBox setPosition:ccp(cx+96,475)];
    [conBox setPosition:ccp(cx+96,240)];
    
    [pieBox setOpacity:50];
    [conBox setOpacity:50];
    
    [pieBox setVisible:NO];
    [conBox setVisible:NO];
    
    
    
    [renderLayer addChild:pieBox];
    [renderLayer addChild:conBox];
    
    if(showNewPieCont){
    
        [self createPieAtMount];
        [self createContainerAtMount];
    }
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
    if(gw.Blackboard.inProblemSetup)return;
    for(int i=0;i<[activeCon count];i++)
    {
        DWPieSplitterContainerGameObject *cont=[activeCon objectAtIndex:i];
    
        
//        NSString *thisConVal=@"";
        int slicesInCont=[cont.mySlices count];
        float thisVal=(float)slicesInCont/(float)[activeCon count];
        if(labelType==kLabelShowDecimal)
        {
            [cont.wholeNum setVisible:NO];
            [cont.fractNum setVisible:NO];
            [cont.fractDenom setVisible:NO];
            [cont.fractLine setVisible:NO];
            [cont.decimalNum setVisible:YES];
            cont.decimalNum.string=[NSString stringWithFormat:@"%.02g", thisVal];
        }
        if(labelType==kLabelShowFraction) {
            
            [cont.wholeNum setVisible:YES];
            [cont.fractNum setVisible:YES];
            [cont.fractDenom setVisible:YES];
            [cont.fractLine setVisible:YES];
            [cont.decimalNum setVisible:NO];
            
            int fullPies=slicesInCont/[activeCon count];
            int extraSlices=slicesInCont-(fullPies*[activeCon count]);
            if(fullPies==0){
                [cont.wholeNum setVisible:NO];
                cont.fractNum.string=[NSString stringWithFormat:@"%d", slicesInCont];
                cont.fractDenom.string=[NSString stringWithFormat:@"%d", [activeCon count]];
//                thisConVal=[NSString stringWithFormat:@"%d/%d", slicesInCont, [activeCon count]];
            }
            else if(fullPies>0 && extraSlices==0)
            {
                [cont.fractDenom setVisible:NO];
                [cont.fractNum setVisible:NO];
                [cont.fractLine setVisible:NO];
                cont.wholeNum.string=[NSString stringWithFormat:@"%d", fullPies];
//                thisConVal=[NSString stringWithFormat:@"%d", fullPies];
            }
            else if(fullPies>0 && extraSlices>0)
            {
                cont.wholeNum.string=[NSString stringWithFormat:@"%d", fullPies];
                cont.fractNum.string=[NSString stringWithFormat:@"%d", extraSlices];
                cont.fractDenom.string=[NSString stringWithFormat:@"%d", [activeCon count]];
//                thisConVal=[NSString stringWithFormat:@"%d %d/%d", fullPies, extraSlices, [activeCon count]];
            }
        }
//        if(!cont.textString)cont.textString=@"";
//        cont.textString=thisConVal;
        
    }
    [gw handleMessage:kDWupdateLabels andPayload:nil withLogLevel:-1];
}

#pragma mark - object interaction
-(BOOL)allContainersEqual
{
    int lasNum=-1;
    for(DWPieSplitterContainerGameObject *c in activeCon)
    {
        if(lasNum==-1)lasNum=[c.mySlices count];
        
        if(lasNum!=[c.mySlices count])return NO;
        
        if([c.mySlices count]==0)return NO;
    }
    
    return YES;
}

-(void)tintThroughAllSlices
{
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_pie_splitter_equal.wav")];
    for(DWPieSplitterContainerGameObject *c in activeCon)
    {
        for(DWPieSplitterSliceGameObject *s in c.mySlices)
        {
            CCTintTo *tt=[CCTintTo actionWithDuration:0.2f red:0 green:220 blue:0];
            CCTintTo *tb=[CCTintTo actionWithDuration:0.2f red:255 green:255 blue:255];
            CCSequence *sq=[CCSequence actions:tt, tb, nil];
            
            [s.mySprite runAction:sq];
        }
    }
}

-(void)createPieAtMount
{
    createdPies++;
    DWPieSplitterPieGameObject *pie = [DWPieSplitterPieGameObject alloc];
    [gw populateAndAddGameObject:pie withTemplateName:@"TpieSplitterPie"];
    pie.Position=ccp(52,544);
    pie.MountPosition=pie.Position;
    pie.Touchable=YES;
    //if(hasSplit)[self splitPie:pie];
    newPie=pie; 
    
    [pie release];
}

-(void)createContainerAtMount
{
    createdCont++;
    DWPieSplitterContainerGameObject *cont = [DWPieSplitterContainerGameObject alloc];
    [gw populateAndAddGameObject:cont withTemplateName:@"TpieSplitterContainer"];
    cont.Position=ccp(62,456);
    cont.MountPosition=cont.Position;
    cont.Touchable=YES;
    newCon=cont;
    
    [cont release];
}

-(void)createActivePie
{
    DWPieSplitterPieGameObject *pie = [DWPieSplitterPieGameObject alloc];
    [gw populateAndAddGameObject:pie withTemplateName:@"TpieSplitterPie"];
    pie.Position=ccp(0,pieBox.position.y);
    pie.MountPosition=ccp(52,544);
    [pie.mySprite setScale:1.0f];
    pie.ScaledUp=YES;
    if(hasSplit)
        [self splitPie:pie];
    
    if(gw.Blackboard.inProblemSetup)
        pie.Touchable=moveInitObjects;
    else
        pie.Touchable=YES;
    
    [activePie addObject:pie];
    
    [pie release];
}

-(void)createActiveContainer
{
    DWPieSplitterContainerGameObject *cont = [DWPieSplitterContainerGameObject alloc];
    [gw populateAndAddGameObject:cont withTemplateName:@"TpieSplitterContainer"];
    cont.Position=ccp(0,conBox.position.y);
    cont.MountPosition=ccp(62,456);
    [cont.mySprite setScale:1.0f];
    cont.ScaledUp=YES;
    
    if(gw.Blackboard.inProblemSetup)
        cont.Touchable=moveInitObjects;
    else
        cont.Touchable=YES;
    
    [activeCon addObject:cont];
    
    [cont release];
}

-(void)addGhostPie
{
//    [pieBox setVisible:YES];
    DWPieSplitterPieGameObject *pie = [DWPieSplitterPieGameObject alloc];
    ghost=pie;
    [activePie addObject:pie];
    
    int currentIndex=0;
    int currentYPos=0;
    int maxPerRow=5;
    
    if([activePie count]<5)
        maxPerRow=[activePie count];
    
    for(DWPieSplitterPieGameObject *p in activePie)
    {
        currentIndex++;
        if(currentIndex>=5){
            currentIndex=0;
            currentYPos++;
        }
    }
    
    
    [gw populateAndAddGameObject:pie withTemplateName:@"TpieSplitterPie"];
    //pie.Position=ccp((currentIndex+0.5)*(lx/[activePie count]), (pieBox.position.y+45)-(110*currentYPos));
    pie.Position=ccp((currentIndex+0.5)*((lx-100)/maxPerRow)+100, (pieBox.position.y+45)-(110*currentYPos));
    pie.MountPosition=ccp(35,700);
    [pie.mySprite setScale:1.0f];
    pie.ScaledUp=YES;
    [pie handleMessage:kDWsetupStuff];
    [pie.mySprite setOpacity:25];
    [pie.touchOverlay setOpacity:25];
    [self reorderActivePies];
    
    [pie release];
}

-(void)addGhostContainer
{
//    [conBox setVisible:YES];
    
    DWPieSplitterContainerGameObject *cont = [DWPieSplitterContainerGameObject alloc];
    ghost=cont;
    
    [gw populateAndAddGameObject:cont withTemplateName:@"TpieSplitterContainer"];
    
    cont.Position=ccp(([activeCon count]+0.5)*(lx/[activeCon count]), conBox.position.y);
    cont.MountPosition=ccp(35,700);
    [cont.mySprite setScale:1.0f];
    cont.ScaledUp=YES;
    [activeCon addObject:cont];
    [cont handleMessage:kDWsetupStuff];
    [cont.mySprite setOpacity:25];

    [self reorderActiveContainers];
    
    [cont release];
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
    int currentIndex=0;
    int currentYPos=0;
    int maxPerRow=5;
    
    if([activePie count]<5)
        maxPerRow=[activePie count];
    
    for(DWPieSplitterPieGameObject *p in activePie)
    {
     
        if([p.mySprite numberOfRunningActions]>0)
            [p.mySprite stopAllActions];
        
        p.Position=ccp((currentIndex+0.5)*((lx-100)/maxPerRow)+100, (pieBox.position.y+45)-(110*currentYPos));
        
        for(DWPieSplitterSliceGameObject *s in p.mySlices)
        {
            s.mySprite.position=ccp(p.mySprite.contentSize.width/2,2+(p.mySprite.contentSize.height/2));
//            [s handleMessage:kDWmoveSpriteToHome];
//
////            [s.mySprite runAction:[CCMoveTo actionWithDuration:0.3f position:[s.mySprite convertToNodeSpace:p.Position]]];
        }
        
        [p.mySprite runAction:[CCMoveTo actionWithDuration:0.3f position:p.Position]];
        currentIndex++;
        
        if(currentIndex>=5){
            currentIndex=0;
            currentYPos++;
        }
    }
}

-(void)reorderActiveContainers
{
    int currentIndex=0;
    int currentYPos=0;
    int maxPerRow=5;
    
    if([activeCon count]<5)
        maxPerRow=[activeCon count];
    
    for(int i=0;i<[activeCon count];i++)
    {
        DWPieSplitterContainerGameObject *c=[activeCon objectAtIndex:i];
        if(!c.ScaledUp)continue;
//        p.Position=ccp((currentIndex+1)*((lx-100)/maxPerRow), (pieBox.position.y+45)-(110*currentYPos));
        c.Position=ccp((currentIndex+0.5)*((lx-100)/maxPerRow)+100, (conBox.position.y+45)-(140*currentYPos));
        [c.BaseNode runAction:[CCMoveTo actionWithDuration:0.3f position:c.Position]];
        currentIndex++;
        
        if(currentIndex>=5){
            currentIndex=0;
            currentYPos++;
        }
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
            
//            slice.Position=p.Position;
            slice.Position=ccp(p.Position.x,p.Position.y+2);
            slice.myPie=p;
            if(!p.mySlices)p.mySlices=[[[NSMutableArray alloc]init]autorelease];
            slice.SpriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice%d.png", [activeCon count]];
            slice.Rotation=(360/p.numberOfSlices)*i;
            [p.mySlices addObject:slice];
            [slice handleMessage:kDWsetupStuff];
            
            [slice release];
        }
        
    
    hasSplit=YES;
    gameState=kGameSlicesActive;
}

-(void)splitPies
{
    for(DWPieSplitterPieGameObject *p in activePie)
    {
        if(p.mySlices.count>0)[p.mySlices removeAllObjects];
        [p handleMessage:kDWsplitActivePies];
        p.numberOfSlices=[activeCon count];
        p.HasSplit=YES;
        
        for(int i=0;i<p.numberOfSlices;i++)
        {
            DWPieSplitterSliceGameObject *slice = [DWPieSplitterSliceGameObject alloc];
            [gw populateAndAddGameObject:slice withTemplateName:@"TpieSplitterSlice"];
            slice.Position=ccp(p.Position.x,p.Position.y+3);
            slice.myPie=p;
            if(!p.mySlices)p.mySlices=[[[NSMutableArray alloc]init] autorelease];
            slice.SpriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice%d.png", [activeCon count]];
            slice.Rotation=(360/p.numberOfSlices)*i;
            [p.mySlices addObject:slice];
            [slice handleMessage:kDWsetupStuff];
            
            [slice release];
        }
        
        
        hasSplit=YES;
        gameState=kGameSlicesActive;
    }
}

-(void)resetSlicesToPies
{
        [loggingService logEvent:BL_PA_PS_RETURN_SLICES_TO_PIE withAdditionalData:nil];
        
        for(DWPieSplitterContainerGameObject *c in activeCon)
        {
            for(DWPieSplitterSliceGameObject *s in c.mySlices)
            {
                [s handleMessage:kDWunsetMount];
                [s handleMessage:kDWmoveSpriteToHome];
            }
            [c handleMessage:kDWunsetAllMountedObjects];
        }
        
        for(DWPieSplitterPieGameObject *p in activePie)
        {
            [p handleMessage:kDWreorderPieSlices];
        }
}

-(void)removeSlices
{
    for (DWPieSplitterPieGameObject *p in activePie)
    {

        for (DWPieSplitterSliceGameObject *s in p.mySlices)
        {
            [s handleMessage:kDWdismantle];
            [gw delayRemoveGameObject:s];
        }
        
        [p.mySlices removeAllObjects];
        
    }
    for (DWPieSplitterContainerGameObject *p in activeCon)
    {
        [p.mySlices removeAllObjects];
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
-(void)balanceLayer
{
    //NSLog(@"layer pos before: %@", NSStringFromCGPoint(movementLayer.position));
    float incOffset=50.0f;
    // first we need the average position of all of our nodes
    float sumOfAllContainers=0.0f;
    float layerOffset=0.0f;
    float objectValue=1.0f/activeCon.count;
    
    for(DWPieSplitterContainerGameObject *c in activeCon)
    {
        sumOfAllContainers+=[c.mySlices count]*objectValue;
    }
    
    layerOffset=sumOfAllContainers/[activeCon count]*(incOffset);
    lastLayerOffset=layerOffset;
    
    //NSLog(@"layerOffset: %f, sumOfAllContainers %f, activeCon count %d", layerOffset, sumOfAllContainers, [activeCon count]);
    [movementLayer runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(movementLayer.position.x, layerOffset)]];
    //NSLog(@"layer pos after: %@", NSStringFromCGPoint(movementLayer.position));
    
}
-(void)balanceContainers
{
    if([activeCon count]>5)return;
    //int maxPXtoMove=100;
    int stepper=10;
    BOOL isLess=NO;

    
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
        
        CCMoveTo *mt=nil;
        
        // then set the position using our offset
        if([c.mySlices count]==0)
            //[c.BaseNode setPosition:[c.BaseNode convertToWorldSpace:ccp(adjPos.x, adjPos.y-c.RealYPosOffset-lastLayerOffset)]];
            mt=[CCMoveTo actionWithDuration:0.3f position:[c.BaseNode convertToWorldSpace:ccp(adjPos.x, adjPos.y-c.RealYPosOffset-lastLayerOffset)]];
        else
            mt=[CCMoveTo actionWithDuration:0.3f position:[c.BaseNode convertToWorldSpace:ccp(adjPos.x, adjPos.y-c.RealYPosOffset-lastLayerOffset)]];
//            [c.BaseNode setPosition:[c.BaseNode convertToWorldSpace:ccp(adjPos.x, adjPos.y-c.RealYPosOffset)]];
        
        CCEaseBounceOut *ebo=[CCEaseBounceOut actionWithAction:mt];
        
        [c.BaseNode runAction:ebo];
        

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
            [self resetSlicesToPies];
        }
    }
    
    if(gameState==kGameReadyToSplit || gameState==kGameSlicesActive)
    {
        for(DWPieSplitterPieGameObject *p in activePie)
        {
            if(CGRectContainsPoint(p.mySprite.boundingBox, location) && !p.HasSplit)
            {
                [self splitPie:p];
                [loggingService logEvent:BL_PA_PS_SPLIT_PIE withAdditionalData:nil];
                return;
            }
        }
    }
    
    // check the labels have been tapped, or not
    for(DWPieSplitterContainerGameObject *c in activeCon)
    {
        if(CGRectContainsPoint([c returnLabelBox], [c.labelNode convertToNodeSpace:location]))
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
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_pie_splitter_pickup.wav")];
        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]] && !((DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject).ScaledUp){
//            [self addGhostPie];
            [loggingService logEvent:BL_PA_PS_TOUCH_BEGIN_TOUCH_CAGED_PIE withAdditionalData:nil];
        }
        else
        {
            [loggingService logEvent:BL_PA_PS_TOUCH_BEGIN_TOUCH_MOUNTED_PIE withAdditionalData:nil];
        }
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
        {
            DWPieSplitterContainerGameObject *cont=(DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject;
            
            if(!cont.ScaledUp && numberOfCagedSlices==0)
            {
//                [self addGhostContainer];
                [loggingService logEvent:BL_PA_PS_TOUCH_BEGIN_TOUCH_CAGED_SQUARE withAdditionalData:nil];
            }
            else if(cont.ScaledUp)
            {
                [loggingService logEvent:BL_PA_PS_TOUCH_BEGIN_TOUCH_MOUNTED_SQUARE withAdditionalData:nil];
            }
//            else if(numberOfCagedSlices>0)
//            {
//                gw.Blackboard.PickupObject=nil;
//            }
        }
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterSliceGameObject class]])
        {
            if(sparkles)sparkles=NO;
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

        BOOL needPieAtMount=NO;
        BOOL needContAtMount=NO;

        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]]){
            
            if(!madeGhost&&CGRectContainsPoint(pieBox.boundingBox, location)){
                [self addGhostPie];
                madeGhost=YES;
            }
            else if(madeGhost&&!CGRectContainsPoint(pieBox.boundingBox, location)){
                [self removeGhost];
                [self reorderActivePies]; 
                madeGhost=NO;
                [pieBox setVisible:NO];
            }
        }

        else if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
        {
                if(!madeGhost&&CGRectContainsPoint(conBox.boundingBox, location)){
                    [self addGhostContainer];
                    madeGhost=YES;
                }
                else if(madeGhost&&!CGRectContainsPoint(conBox.boundingBox, location)){
                    [self removeGhost];
                    [self reorderActiveContainers];
                    [conBox setVisible:NO];
                    madeGhost=NO;
                }
        }
    
        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterContainerGameObject class]])
        {
            ((DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject).Position=location;
            if(!((DWPieSplitterContainerGameObject*)gw.Blackboard.PickupObject).ScaledUp)
                needContAtMount=YES;
            
            hasMovedSquare=YES;
        }
        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterPieGameObject class]])
        {
            ((DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject).Position=location;
            if(!((DWPieSplitterPieGameObject*)gw.Blackboard.PickupObject).ScaledUp)
                needPieAtMount=YES;
            
            hasMovedPie=YES;
        }
        
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterSliceGameObject class]])
        {
                ((DWPieSplitterSliceGameObject*)gw.Blackboard.PickupObject).Position=location;
            
                hasMovedSlice=YES;
         
        }
        
        if(hasMovedPie||hasMovedSlice||hasMovedSquare)
            [gw.Blackboard.PickupObject handleMessage:kDWmoveSpriteToPosition andPayload:nil withLogLevel:-1];
        
        // if we haven't yet created a new object, do it now
        if(hasMovedSquare && !createdNewCon && createdCont <= numberOfCagedContainers && needContAtMount)
        {
            [self createContainerAtMount];
            createdNewCon=YES;
        }
        if(hasMovedPie && !createdNewPie && createdPies <= numberOfCagedPies && needPieAtMount)
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
                [loggingService logEvent:BL_PA_PS_TOUCH_END_MOUNT_CAGED_SQUARE withAdditionalData:nil];
                [cont handleMessage:kDWswitchParentToMovementLayer];
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_pie_splitter_adding_object.wav")];
                // if this object isn't in the array, add it
                if(![activeCon containsObject:cont])[activeCon addObject:cont];
                
                // and if we've already split, and there are no active slices, remove existing and re-split for more containers
                if(hasSplit && numberOfCagedSlices==0)
                {
                    [self removeSlices];
                    [self splitPies];
                }
                else if(hasSplit && numberOfCagedSlices>0)
                {
                    [self resetSlicesToPies];
                }
                
            }
            else {
                // if we're not landing on the dropzone and were previously there, remove object from array
                [loggingService logEvent:BL_PA_PS_TOUCH_END_RETURN_CAGED_SQUARE withAdditionalData:nil];
                if([activeCon containsObject:cont])[activeCon removeObject:cont];
                
                if(hasSplit)
                {
                    [self removeSlices];
                    [self splitPies];
                    [cont.mySlices removeAllObjects];
                }

                // and if it wasn't - eject it back to it's mount
                [cont handleMessage:kDWswitchParentToRenderLayer];
                [cont handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:-1];
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
                [loggingService logEvent:BL_PA_PS_TOUCH_END_MOUNT_CAGED_PIE withAdditionalData:nil];
                // if this object isn't in the array, add it
                [pie.mySprite setScale:1.0f];
                
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_pie_splitter_adding_object.wav")];
                
                if(![activePie containsObject:pie])
                    [activePie addObject:pie];
            }
            else {
                // if we're not landing on the dropzone and were previously there, remove object from array
                [loggingService logEvent:BL_PA_PS_TOUCH_END_RETURN_CAGED_PIE withAdditionalData:nil];
                if([activePie containsObject:pie])
                    [activePie removeObject:pie];
                
                // and if it wasn't - eject it back to it's mount
                [gw.Blackboard.PickupObject handleMessage:kDWresetToMountPosition andPayload:nil withLogLevel:-1];
            }

//            if(createdNewPie){
                [self resetSlicesToPies];
                
                [self splitPies];
                
//            }
            
            [self reorderActivePies];
        }
        
        // is a slice?
        if([gw.Blackboard.PickupObject isKindOfClass:[DWPieSplitterSliceGameObject class]])
        {
            NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
            [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:-1];
            
            DWPieSplitterSliceGameObject *slice=(DWPieSplitterSliceGameObject *)gw.Blackboard.PickupObject;
            
            // if we have a dropobject then we need to be mounted to it
            if(slice.myCont)
            {
                if(gw.Blackboard.DropObject)
                {
                    [loggingService logEvent:BL_PA_PS_TOUCH_END_MOUNT_SLICE_TO_PIE withAdditionalData:nil];
                    if(slice.myCont)
                        [slice.myCont handleMessage:kDWunsetMountedObject];
                    [slice handleMessage:kDWunsetMount];
                    [gw.Blackboard.PickupObject handleMessage:kDWsetMount];
                    [gw.Blackboard.DropObject handleMessage:kDWsetMountedObject];
                    hasASliceInCont=YES;
                    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_pie_splitter_dropping_slice.wav")];
                }
                else if(!gw.Blackboard.DropObject)
                {
                    [gw.Blackboard.PickupObject handleMessage:kDWsetMount];
                    [slice.myCont handleMessage:kDWsetMountedObject];
                    hasASliceInCont=YES;

                }

            }
            
            else if(gw.Blackboard.DropObject)
            {
                [loggingService logEvent:BL_PA_PS_TOUCH_END_MOUNT_SLICE_TO_PIE withAdditionalData:nil];
                if(slice.myCont)[slice.myCont handleMessage:kDWunsetMountedObject];
                [slice handleMessage:kDWunsetMount];
                [gw.Blackboard.PickupObject handleMessage:kDWsetMount];
                [gw.Blackboard.DropObject handleMessage:kDWsetMountedObject];
                hasASliceInCont=YES;
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_pie_splitter_dropping_slice.wav")];
            }
            else {

                DWPieSplitterContainerGameObject *cont=(DWPieSplitterContainerGameObject *)slice.myCont;
                [loggingService logEvent:BL_PA_PS_TOUCH_END_MOUNT_SLICE_TO_SQUARE withAdditionalData:nil];
                slice.Position=location;
                [cont handleMessage:kDWunsetMountedObject];
                [slice handleMessage:kDWunsetMount];
                [slice handleMessage:kDWmoveSpriteToHome];
            }
            
            [slice.myPie handleMessage:kDWreorderPieSlices];
        }
        
    }
    
    
    //[self balanceLayer];
    [self balanceContainers];
    
    if(!sparkles&&[self allContainersEqual])
    {
        [self tintThroughAllSlices];
        sparkles=YES;
    }
    
    if(hasMovedSquare)
        [loggingService logEvent:BL_PA_PS_TOUCH_MOVE_MOVE_SQUARE withAdditionalData:nil];
        
    if(hasMovedPie)
        [loggingService logEvent:BL_PA_PS_TOUCH_MOVE_MOVE_PIE withAdditionalData:nil];
        
    if(hasMovedSlice)
        [loggingService logEvent:BL_PA_PS_TOUCH_MOVE_MOVE_SLICE withAdditionalData:nil];
    
    madeGhost=NO;
    hasMovedSquare=NO;
    hasMovedPie=NO;
    hasMovedSlice=NO;
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
    hasMovedSquare=NO;
    hasMovedPie=NO;
    hasMovedSlice=NO;
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
        [toolHost doWinning];
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

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    
}

#pragma mark - dealloc
-(void) dealloc
{
    
    if(activePie)[activePie release];
    if(activeCon)[activeCon release];

    [renderLayer release];
    [movementLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [gw release];

    
    [super dealloc];
}
@end
