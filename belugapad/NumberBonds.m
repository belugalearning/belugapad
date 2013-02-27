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
#import "LogPoller.h"
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
static float kNBFontSizeSmall=22.0f;
static float kNBFontSizeLarge=35.0f;

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
    
    timeSinceInteractionOrShake+=delta;
    if(timeSinceInteractionOrShake>kTimeToMountedShake)
    {
        BOOL isWinning=[self evalExpression];
        
        if(!hasUsedBlock) {
            for(int i=0;i<[mountedObjects count];i++)
            {
                if([[mountedObjects objectAtIndex:i]isKindOfClass:[NSNull class]])continue;
                NSArray *a=[mountedObjects objectAtIndex:i];
                
                for(DWNBondObjectGameObject *pogo in a)
                {
                    [pogo.BaseNode runAction:[InteractionFeedback shakeAction]];
                }
            }
            
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_bonds_interaction_feedback_bars_shaking.wav")];
        }
        timeSinceInteractionOrShake=0.0f;
        if(isWinning)[toolHost shakeCommitButton];
    }
    
    for(int i=0;i<[mountedObjects count];i++)
    {
        if([[mountedObjects objectAtIndex:i]isKindOfClass:[NSNull class]])continue;
        NSArray *a=[mountedObjects objectAtIndex:i];
        
        for(DWNBondObjectGameObject *pogo in a)
        {
            if(!CGPointEqualToPoint(pogo.BaseNode.position, pogo.MountPosition) && pogo.BaseNode.numberOfRunningActions==0)
                pogo.BaseNode.position=pogo.MountPosition;
        }
    }

    for(int i=0;i<10;i++){
        if(blocksUsedFromThisStore[i]<0)blocksUsedFromThisStore[i]=0;
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
    initHints=[pdef objectForKey:INIT_HINTS];
    [initHints retain];
    
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
    else if(solutionMode==kSolutionUniqueCompositionsOfValue)
    {
        evalUniqueCopmositionTarget=[[pdef objectForKey:@"EVAL_UNIQUE_COMPOSITION_TARGET"] intValue];
    }
    
    //min/max eval modes
    evalMinPerRow=0; evalMaxPerRow=0;
    if([pdef objectForKey:@"EVAL_MIN_PER_ROW"]) evalMinPerRow=[[pdef objectForKey:@"EVAL_MIN_PER_ROW"] intValue];
    if([pdef objectForKey:@"EVAL_MAX_PER_ROW"]) evalMaxPerRow=[[pdef objectForKey:@"EVAL_MAX_PER_ROW"] intValue];
    
    if([pdef objectForKey:BAR_ASSISTANCE])
        barAssistance=[[pdef objectForKey:BAR_ASSISTANCE]boolValue];
    else
        barAssistance=NO;
    
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
    allRows = [[NSMutableArray alloc]init];
    
    if([initCages count]==1)
        [usersService notifyStartingFeatureKey:@"NUMBERBONDS_SINGLE_VALUE_ANSWER"];
    else if([initCages count]>1)
        [usersService notifyStartingFeatureKey:@"NUMBERBONDS_MULTI_VALUE_ANSWER"];
}

-(void)populateGW
{

    int dockSize=12;
    float initBarStartYPos=532.0f;
    float dockPieceYPos=initBarStartYPos;
    float initCageStartYPos=0.0f;
    
    if(useBlockScaling)
        initCageStartYPos=dockPieceYPos-43;
    else
        initCageStartYPos=dockPieceYPos-48;
    
    float initCageBadgePos=initCageStartYPos+2;
    
    float dockMidSpacing=0.0f;
    
    if(useBlockScaling)
        dockMidSpacing=35.0f;
    else
        dockMidSpacing=60.0f;
    
    if([initCages count]>0)
    {
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
            
            if(i==0 && useBlockScaling)
                dockPieceYPos-=42.0f;
            else if(i==0 && !useBlockScaling)
                dockPieceYPos-=55.0f;
            else if(i==dockSize-2)
                dockPieceYPos-=42.0f;
            else
                dockPieceYPos-=dockMidSpacing;
            
        }
    }

    // do stuff with our INIT_BARS (DWNBondRowGameObject)
    
    for (int i=0;i<[initBars count]; i++)
    {
        
        float xStartPos=(cx+200-((([[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue]+2)*50)/2)+25);
        
        DWNBondRowGameObject *prgo = [DWNBondRowGameObject alloc];
        [gw populateAndAddGameObject:prgo withTemplateName:@"TnBondRow"];
        [loggingService.logPoller registerPollee:(id<LogPolling>)prgo];
        prgo.Position=ccp(xStartPos,initBarStartYPos);
        prgo.Length = [[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue];
        prgo.Locked = [[[initBars objectAtIndex:i] objectForKey:LOCKED] boolValue];
    
        [createdRows addObject:prgo];
        initBarStartYPos-=100;
        
        [prgo release];
    }
    
    // do stuff with our INIT_CAGES (DWNBondStoreGameObject)
    
    
    for(int i=0;i<10;i++)
    {
        DWNBondObjectGameObject *pogo = [DWNBondObjectGameObject alloc];
        [gw populateAndAddGameObject:pogo withTemplateName:@"TnBondObject"];
        [loggingService.logPoller registerPollee:(id<LogPolling>)pogo];
        pogo.IndexPos=i;
        pogo.HintObject=YES;
        pogo.Length=i+1;
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
        

        [mountedObjects addObject:[NSNull null]];
        [mountedObjectBadges addObject:[NSNull null]];
        [mountedObjectLabels addObject:[NSNull null]];

    }
    
    
    for (int i=0;i<[initCages count]; i++)
    {
        int thisLength=0;
        NSMutableArray *currentVal=[[NSMutableArray alloc]init];
        DWNBondObjectGameObject *pogo = [DWNBondObjectGameObject alloc];
        [gw populateAndAddGameObject:pogo withTemplateName:@"TnBondObject"];
        [loggingService.logPoller registerPollee:(id<LogPolling>)pogo];
        //pogo.Position=ccp(25-(numberStacked*2),650-(i*65)+(numberStacked*3));
        pogo.Length=[[[initCages objectAtIndex:i] objectForKey:LENGTH] intValue];
        pogo.IndexPos=pogo.Length-1;
        thisLength=pogo.Length;
        blocksForThisStore[pogo.IndexPos]=[[[initCages objectAtIndex:i] objectForKey:QUANTITY] intValue];
        blocksUsedFromThisStore[pogo.IndexPos]=0;
        
        if(blocksForThisStore[pogo.IndexPos]==blocksUsedFromThisStore[pogo.IndexPos])
            storeCanCreate[pogo.IndexPos]=NO;
        else
            storeCanCreate[pogo.IndexPos]=YES;
            
            if([[initCages objectAtIndex:i] objectForKey:LABEL])
            {
                float fontSize=0.0f;
                if(pogo.Length<3)
                    fontSize=kNBFontSizeSmall;
                else
                    fontSize=kNBFontSizeLarge;
                
                pogo.Label=[CCLabelTTF labelWithString:[[initCages objectAtIndex:i] objectForKey:LABEL] fontName:CHANGO fontSize:fontSize];
            }
            
            
            if(!useBlockScaling){
                pogo.IsScaled=YES;
                pogo.NoScaleBlock=YES;
                pogo.Position=ccp(20,initCageStartYPos-(pogo.IndexPos*dockMidSpacing));
            }
            else
            {
                pogo.Position=ccp(20,initCageStartYPos-(pogo.IndexPos*dockMidSpacing));
            }
            
            pogo.MountPosition = pogo.Position;
            
            
            [currentVal addObject:pogo];

        [mountedObjects replaceObjectAtIndex:thisLength-1 withObject:currentVal];
        
        if(showBadgesOnCages)
        {
            
            CCSprite *thisBadge=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/partition/NB_Notification.png")];
            CCLabelTTF *thisLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",[[mountedObjects objectAtIndex:thisLength-1]count]] fontName:@"Source Sans Pro" fontSize:16.0f];
            
            if(!useBlockScaling)
                [thisBadge setPosition:ccp(20+(50*thisLength),initCageBadgePos-((thisLength-1)*dockMidSpacing-10))];
            else
                [thisBadge setPosition:ccp(20+(50*(thisLength*0.5)),initCageBadgePos-((thisLength-1)*dockMidSpacing-10))];
            [thisLabel setPosition:ccp(15,12)];
            
            [renderLayer addChild:thisBadge z:1000];
            [thisBadge addChild:thisLabel];
            
            [thisBadge setTag:3];
            [thisLabel setTag:3];
            [thisBadge setOpacity:0];
            [thisLabel setOpacity:0];
            

            [mountedObjectLabels replaceObjectAtIndex:thisLength-1 withObject:thisLabel];
            [mountedObjectBadges replaceObjectAtIndex:thisLength-1 withObject:thisBadge];
        }
        
        [currentVal release];
    }
    
    for (int i=0;i<[initHints count]; i++)
    {
        int insRow=[[[initHints objectAtIndex:i] objectForKey:PUT_IN_ROW] intValue];
        int insLength=[[[initHints objectAtIndex:i] objectForKey:LENGTH] intValue];
        DWNBondObjectGameObject *hint = [DWNBondObjectGameObject alloc];
        [gw populateAndAddGameObject:hint withTemplateName:@"TnBondObject"];
        [loggingService.logPoller registerPollee:(id<LogPolling>)hint];
        
        hint.Length = insLength;
        
        hint.InitedObject=YES;
        hint.HintObject=YES;
        
        DWNBondRowGameObject *prgo = (DWNBondRowGameObject*)[createdRows objectAtIndex:insRow];
        NSDictionary *pl=[NSDictionary dictionaryWithObject:prgo forKey:MOUNT];
        [hint handleMessage:kDWsetMount andPayload:pl withLogLevel:-1];
        hint.Position = prgo.Position;
        hint.MountPosition = prgo.Position;
        [prgo handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:0];
        
        [hint release];
    }
    
    // do stuff with our INIT_OBJECTS (DWNBondObjectGameObject)    
    for (int i=0;i<[initObjects count]; i++)
    {
        int insRow=[[[initObjects objectAtIndex:i] objectForKey:PUT_IN_ROW] intValue];
        int insLength=[[[initObjects objectAtIndex:i] objectForKey:LENGTH] intValue];
        NSString *fillText=@"";
        DWNBondObjectGameObject *pogo = [DWNBondObjectGameObject alloc];
        [gw populateAndAddGameObject:pogo withTemplateName:@"TnBondObject"];
        [loggingService.logPoller registerPollee:(id<LogPolling>)pogo];
        pogo.Length = insLength;
        
        pogo.InitedObject=YES;
        
        if([[initObjects objectAtIndex:i]objectForKey:LABEL]) fillText = [[initObjects objectAtIndex:i]objectForKey:LABEL];
        else fillText=[NSString stringWithFormat:@"%d", insLength];
        
        float fontSize=0.0f;
        if(pogo.Length<3)
            fontSize=kNBFontSizeSmall;
        else
            fontSize=kNBFontSizeLarge;
        
        pogo.Label = [CCLabelTTF labelWithString:fillText fontName:CHANGO fontSize:fontSize];
        
        DWNBondRowGameObject *prgo = (DWNBondRowGameObject*)[createdRows objectAtIndex:insRow];
        NSDictionary *pl=[NSDictionary dictionaryWithObject:prgo forKey:MOUNT];
        [pogo handleMessage:kDWsetMount andPayload:pl withLogLevel:-1];
        pogo.Position = prgo.Position;
        pogo.MountPosition = prgo.Position;
        [prgo handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:0];
        
        [allRows addObject:prgo];
        [fillText release];
        [pogo release];
    }

}

-(void)updateLabels
{
    for(int i=0;i<[mountedObjectLabels count];i++)
    {
        if([[mountedObjectLabels objectAtIndex:i] isKindOfClass:[NSNull class]])continue;
        CCLabelTTF *thisLabel=[mountedObjectLabels objectAtIndex:i];
        CCSprite *thisSprite=[mountedObjectBadges objectAtIndex:i];
        int blocksLeft=blocksForThisStore[i]-blocksUsedFromThisStore[i];
        
        if(blocksLeft>0)
        {
            [thisSprite setVisible:YES];
            [thisLabel setVisible:YES];
            thisLabel.string=[NSString stringWithFormat:@"%d",blocksLeft];
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

-(void)compareHintsAndMountedObjects
{
    [self compareHintsAndMountedObjects:YES];
}

-(void)compareHintsAndMountedObjects:(BOOL)shouldMoveRows
{
    NSMutableArray *swappedRowIndexes=[[NSMutableArray alloc] init];
    
    BOOL foundAMatch=NO;
    // for each row
    for(int i=0;i<[createdRows count];i++)
    {
        if([swappedRowIndexes containsObject:[NSNumber numberWithInt:i]])
        {
            NSLog(@"already swapped");
            continue;
        }
        
        DWNBondRowGameObject *r=[createdRows objectAtIndex:i];
        
        if(r.Locked)continue;
        
        NSMutableArray *hints=[NSMutableArray arrayWithArray:r.HintObjects];
        NSMutableArray *mounted=r.MountedObjects;
        
        BOOL foundAPerfectMatch=NO;
        
        //check if I myself match
        if([self checkIfThisRowIsAPerfectPartialMatch:i ofTheseHints:hints])
        {
            NSLog(@"found perfect match");
            foundAPerfectMatch=YES;
        }
        else
        {
            //look for a perfect match elsewhere, and swap hints if one found
            for(int f=0;f<[createdRows count];f++)
            {
                if([self checkIfThisRowIsAPerfectPartialMatch:f ofTheseHints:hints] && i!=f)
                {
                    NSLog(@"found other perfect parital -- swapping %d with %d", f, i);
                    [self exchangeHintsOnThisRow:f withHintsOnThisRow:i];
                    
                    [swappedRowIndexes addObject:[NSNumber numberWithInt:f]];
                    [swappedRowIndexes addObject:[NSNumber numberWithInt:i]];
                    
                    
                    foundAPerfectMatch=YES;
                    break;
                }
            }
        }
        
        if(!foundAPerfectMatch)
        {
        
            // we need to look at it's hint objects and mounted objects
            
            for(int h=0;h<[hints count];h++)
            {
                    BOOL hasMatch=NO;
                    int matchedNo=0;
                    int matchedWithNo=0;
                    DWNBondObjectGameObject *thisHint=[hints objectAtIndex:h];
                    
                    for(int m=0;m<[mounted count];m++)
                    {
                        DWNBondObjectGameObject *thisMounted=[mounted objectAtIndex:m];
                        
                        if(thisHint.Length==thisMounted.Length)
                        {
                            NSLog(@"(%d) got match at %d against %d - thisHint length %d, thisMounted length %d", i, m, h, thisHint.Length, thisMounted.Length);
                            matchedNo=m;
                            matchedWithNo=h;
                            hasMatch=YES;
                            foundAMatch=YES;
                            break;
                        }
                    }

                    if(hasMatch)
                    {
                        NSLog(@"got match %d. count of hints %d", matchedNo, [hints count]);
                        
                        if(matchedNo<[hints count])
                        {
                            [r.HintObjects exchangeObjectAtIndex:matchedNo withObjectAtIndex:matchedWithNo];
                            
                            foundAMatch=YES;
                        }
                    }

                }
            }
        
    }
    
    [swappedRowIndexes release];
    
}

-(BOOL)checkIfThisRowIsAPerfectPartialMatch: (int)row ofTheseHints:(NSMutableArray*)hints
{
    if(!hints)return NO;
    if(hints.count==0)return NO;
    
    DWNBondRowGameObject *r=[createdRows objectAtIndex:row];
    
    if(r.MountedObjects.count ==0) return NO;
    if (r.Locked)return NO;
    
    NSMutableArray *mounted=r.MountedObjects;

    int i=0;
    for(DWNBondObjectGameObject *o in mounted)
    {
        DWNBondObjectGameObject *h=[hints objectAtIndex:i];
        if(h.Length!=o.Length)
        {
            return NO;
        }
        i++;
    }
    
    return YES;
}

-(BOOL)checkIfTheseHints:(NSMutableArray*)theseHints GoToThisRow:(int)thisRow
{
    DWNBondRowGameObject *r=[createdRows objectAtIndex:thisRow];
    
    if (r.Locked)return NO;
    
    NSMutableArray *mounted=r.MountedObjects;
    
    for(int h=0;h<[theseHints count];h++)
    {
        BOOL hasMatch=NO;
        DWNBondObjectGameObject *thisHint=[theseHints objectAtIndex:h];
        
        for(int m=0;m<[mounted count];m++)
        {
            DWNBondObjectGameObject *thisMounted=[mounted objectAtIndex:m];
            
            if(thisHint.Length==thisMounted.Length)
            {
                hasMatch=YES;
                break;
            }
        }
        
        if(hasMatch)return YES;
    }

    return NO;
}

-(void)exchangeHintsOnThisRow:(int)thisRow withHintsOnThisRow:(int)thatRow
{
    DWNBondRowGameObject *thisOne=[createdRows objectAtIndex:thisRow];
    DWNBondRowGameObject *thatOne=[createdRows objectAtIndex:thatRow];
    
    for(DWNBondObjectGameObject *o in thisOne.HintObjects)
    {
        NSLog(@"PRE this one: %d", o.Length);
    }
    for(DWNBondObjectGameObject *o in thatOne.HintObjects)
    {
        NSLog(@"PRE that one: %d", o.Length);
    }
    
    
    
    NSMutableArray *thisOneHints=[NSMutableArray arrayWithArray:thisOne.HintObjects];

    thisOne.HintObjects=thatOne.HintObjects;
    thatOne.HintObjects=thisOneHints;
    doNotSendPositionEval=YES;
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_bonds_general_bar_assistance.wav")];
    
    for(DWNBondObjectGameObject *o in thisOne.HintObjects)
    {
        for(CCSprite *s in o.BaseNode.children)
        {
            NSLog(@"this one: %d", o.Length);
            
            CCFadeOut *fadeOutAct=[CCFadeOut actionWithDuration:0.3f];
            CCDelayTime *delayTime=[CCDelayTime actionWithDuration:0.5f];
            CCCallBlock *resetEval=[CCCallBlock actionWithBlock:^{[thisOne handleMessage:kDWresetPositionEval];}];
            CCFadeIn *fadeInAct=[CCFadeIn actionWithDuration:0.3f];
            
            CCSequence *sequence=[CCSequence actions:fadeOutAct, delayTime, resetEval, fadeInAct, nil];
            
            [s runAction:sequence];
    
        }
    }
    
    for(DWNBondObjectGameObject *o in thatOne.HintObjects)
    {
        NSLog(@"that one: %d", o.Length);

        for(CCNode *s in o.BaseNode.children)
        {
            CCFadeOut *fadeOutAct=[CCFadeOut actionWithDuration:0.3f];
            CCDelayTime *delayTime=[CCDelayTime actionWithDuration:0.5f];
            CCCallBlock *resetEval=[CCCallBlock actionWithBlock:^{[thatOne handleMessage:kDWresetPositionEval];}];
            CCCallBlock *disallowEval=[CCCallBlock actionWithBlock:^{doNotSendPositionEval=NO;}];
            CCFadeIn *fadeInAct=[CCFadeIn actionWithDuration:0.3f];
            
            CCSequence *sequence=[CCSequence actions:fadeOutAct, delayTime, resetEval, fadeInAct, disallowEval, nil];
            
            [s runAction:sequence];
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
        
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_bonds_general_bar_picked_up_and_expanding.wav")];
        
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
        
        [[gw Blackboard].PickupObject handleMessage:kDWmoveSpriteToPosition andPayload:pl withLogLevel:-1];
        
        DWNBondObjectGameObject *pogo = (DWNBondObjectGameObject*)[gw Blackboard].PickupObject;
        
        pogo.MovePosition = location;
        
        for(DWNBondRowGameObject *r in allRows)
        {
            [r handleMessage:kDWareYouADropTarget];
        }
        
        if(blocksUsedFromThisStore[pogo.IndexPos]==blocksForThisStore[pogo.IndexPos]-1 && storeCanCreate[pogo.IndexPos])
            storeCanCreate[pogo.IndexPos]=NO;
        
        
        if(!createdNewBar && blocksUsedFromThisStore[pogo.IndexPos]<blocksForThisStore[pogo.IndexPos])
        {
            createdNewBar=YES;
            if(blocksUsedFromThisStore[pogo.IndexPos]<blocksForThisStore[pogo.IndexPos] && !previousMount)
                blocksUsedFromThisStore[pogo.IndexPos]++;
            
            if(!storeCanCreate[pogo.IndexPos])return;
            
            
            NSLog(@"blocksUsedFromThisStore = %d, blocksForThisStore = %d", blocksUsedFromThisStore[pogo.IndexPos],blocksForThisStore[pogo.IndexPos]);
            

            DWNBondObjectGameObject *newbar = [[DWNBondObjectGameObject alloc] autorelease];
            [gw populateAndAddGameObject:newbar withTemplateName:@"TnBondObject"];
            [loggingService.logPoller registerPollee:(id<LogPolling>)newbar];
            newbar.Length=pogo.Length;
            newbar.IndexPos=newbar.Length-1;

            
            float fontSize=0.0f;
            if(newbar.Length<3)
                fontSize=kNBFontSizeSmall;
            else
                fontSize=kNBFontSizeLarge;
            
            newbar.Label=[CCLabelTTF labelWithString:pogo.Label.string fontName:CHANGO fontSize:fontSize];
            
            
            
            if(!useBlockScaling){
                newbar.IsScaled=YES;
                newbar.NoScaleBlock=YES;
                newbar.Position=pogo.MountPosition;
            }
            else
            {
                newbar.Position=pogo.MountPosition;
            }
            
            newbar.MountPosition = newbar.Position;
            
            [newbar handleMessage:kDWsetupStuff];
        }

        //previously removex b/c of log perf - restored for testing with sans-Couchbase logging
        
        hasMovedBlock=YES;

        
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
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_bonds_general_bar_dropped.wav")];
            [self compareHintsAndMountedObjects];
            hasUsedBlock=YES;
            
            // touch ended on a row so we've set it. log it's value
            [loggingService logEvent:BL_PA_NB_TOUCH_END_ON_ROW
                withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:pogo.ObjectValue] forKey:@"objectValue"]];
        }
        else
        {
            if(barAssistance && gw.Blackboard.ProximateObject)
            {
                float addedLength=0.0f;
                [gw.Blackboard.ProximateObject handleMessage:kDWresetPositionEval];
                DWNBondRowGameObject *nbr=(DWNBondRowGameObject*)gw.Blackboard.ProximateObject;
                DWNBondObjectGameObject *po=(DWNBondObjectGameObject*)gw.Blackboard.PickupObject;
                
                float totalPlusPickup=nbr.MyHeldValue+po.Length;
                float difference=totalPlusPickup-nbr.Length;
                float pickupValueThatCanGoIn=po.Length-difference;
                

                if(totalPlusPickup>nbr.Length)
                {
                    
                    // TODO: this needs to actually remove the GO
                    for(CCSprite *s in po.BaseNode.children)
                    {
                        CCFadeOut *fo=[CCFadeOut actionWithDuration:1.5f];
                        CCFadeIn *fi=[CCFadeIn actionWithDuration:0.5f];


                        CCAction *sth=[CCCallBlock actionWithBlock:^{[po handleMessage:kDWmoveSpriteToHome];blocksUsedFromThisStore[po.IndexPos]--;}];
                        CCAction *remt=[CCCallBlock actionWithBlock:^{[[mountedObjects objectAtIndex:po.IndexPos] addObject:po];}];
                        CCSequence *sq=nil;
                        
                        if([po.BaseNode.children indexOfObject:s]==[po.BaseNode.children count]-1)
                            sq=[CCSequence actions:fo, sth, remt, fi, nil];
                        else
                            sq=[CCSequence actions:fo, fi, nil];
                        [s runAction:sq];
                    }
                    
                    for(int i=0;i<2;i++)
                    {

                        DWNBondObjectGameObject *no = [DWNBondObjectGameObject alloc];
                        [gw populateAndAddGameObject:no withTemplateName:@"TnBondObject"];
                        
                        [loggingService.logPoller registerPollee:(id<LogPolling>)no];
                        
                        if(i==0)
                            no.Length=pickupValueThatCanGoIn;
                        else
                            no.Length=difference;
                        
                        
                        CGPoint retPos=CGPointZero;
                        for(int i=0;i<[mountedObjects count];i++)
                        {
                            if([[mountedObjects objectAtIndex:i]isKindOfClass:[NSNull class]])continue;
                            NSArray *a=[mountedObjects objectAtIndex:i];
                            
                                if([a count]>0)
                                {
                                    DWNBondObjectGameObject *pos=[a objectAtIndex:0];
                                    if(pos.Length==no.Length)
                                        retPos=pos.Position;
                                }
                            
                        }
                        
                        
                        no.InitedObject=YES;
                        
                        no.Position=ccp(nbr.Position.x+(nbr.MyHeldValue*50+(addedLength*50)),nbr.Position.y);
                        addedLength+=no.Length;
                        
                        [no handleMessage:kDWsetupStuff];
                        
                        for(CCSprite *n in no.BaseNode.children)
                        {
                            [n setOpacity:0];
                            CCFadeIn *fi=[CCFadeIn actionWithDuration:1.5f];
                            CCDelayTime *dt=[CCDelayTime actionWithDuration:2.0f];
                            CCAction *mbn=[CCCallBlock actionWithBlock:^{[no.BaseNode runAction:[CCMoveTo actionWithDuration:0.5f position:retPos]];}];
                            CCFadeOut *fo=[CCFadeOut actionWithDuration:0.5f];
                            CCAction *dgo=[CCCallBlock actionWithBlock:^{[gw delayRemoveGameObject:no];}];
                            CCSequence *sq=[CCSequence actions:fi, dt, mbn, fo, dgo, nil];
                            [n runAction:sq];
                        }
                        
                        [no release];
                    }
                    
                    
                    
                    
                }
                
                else{
                    [po handleMessage:kDWmoveSpriteToHome];
                    blocksUsedFromThisStore[po.IndexPos]--;
                }
                [self setTouchVarsToOff];
                
                return;
    
            }
            if(((DWNBondObjectGameObject*)gw.Blackboard.PickupObject).InitedObject)
            {
                [gw.Blackboard.PickupObject handleMessage:kDWsetMount andPayload:[NSDictionary dictionaryWithObject:previousMount forKey:MOUNT] withLogLevel:0];
                if(!doNotSendPositionEval)
                    [gw handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:-1];
                [self setTouchVarsToOff];
                return;
            }

            
                [pogo handleMessage:kDWmoveSpriteToHome];
                blocksUsedFromThisStore[pogo.IndexPos]--;

                [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_number_bonds_general_bar_fly_back.wav")];
                [[mountedObjects objectAtIndex:pogo.IndexPos] addObject:gw.Blackboard.PickupObject];
                
                [gw handleMessage:kDWhighlight andPayload:nil withLogLevel:-1];  
                
                // log that we dropped into space
                [loggingService logEvent:BL_PA_NB_TOUCH_END_IN_SPACE
                    withAdditionalData:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:pogo.ObjectValue] forKey:@"objectValue"]];

        }
    }
    
    
    if(!doNotSendPositionEval)
        [gw handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:-1];
    
    [self setTouchVarsToOff];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setTouchVarsToOff];
}

-(void)setTouchVarsToOff
{
    [gw Blackboard].PickupObject=nil;
    [gw Blackboard].ProximateObject=nil;
    hasMovedBlock=NO;
    isTouching=NO;
    doNotSendPositionEval=NO;
    createdNewBar=NO;
    previousMount=nil;
}

#pragma mark - evaluation and reject

-(BOOL)evalMinMaxPerRow
{
    if(evalMinPerRow>0)
    {
        for (DWNBondRowGameObject *prgo in createdRows) {
            if (!prgo.Locked && prgo.MountedObjects.count <evalMinPerRow) return NO;
        }
    }
    
    if(evalMaxPerRow>0)
    {
        for(DWNBondRowGameObject *prgo in createdRows) {
            if (!prgo.Locked && prgo.MountedObjects.count>evalMaxPerRow) return NO;
        }
    }

    //otherwise min/max tests pass okay
    return YES;
}

-(int)getRowLengthFor:(DWNBondRowGameObject*)prgo
{
    int l=0;
    for(DWNBondObjectGameObject *pogo in prgo.MountedObjects)
    {
        l+=pogo.Length;
    }
    return l;
}

-(NSArray*)getSortedCompositionFor:(DWNBondRowGameObject*)prgo
{
    NSMutableArray *sizes=[[[NSMutableArray alloc] init] autorelease];
    for(DWNBondObjectGameObject *pogo in prgo.MountedObjects)
    {
        if(sizes.count==0)
        {
            [sizes addObject:[NSNumber numberWithInt:pogo.Length]];
        }
        else
        {
            for(int i=0;i<sizes.count;i++)
            {
                if([[sizes objectAtIndex:i] intValue]>pogo.Length)
                {
                    [sizes insertObject:[NSNumber numberWithInt:pogo.Length] atIndex:i];
                    break;
                }
                else if(i==sizes.count-1)
                {
                    [sizes addObject:[NSNumber numberWithInt:pogo.Length]];
                    break;
                }
            }
        }
    }
    return [NSArray arrayWithArray:sizes];
}

-(BOOL)isArrayNumberData:(NSArray*) array1 sameAs:(NSArray*)array2
{
    if(array1.count!=array2.count)return NO;
    
    for(int i=0;i<array1.count; i++)
    {
        NSNumber *n1=[array1 objectAtIndex:i];
        NSNumber *n2=[array2 objectAtIndex:i];
        if([n1 intValue] != [n2 intValue]) return NO;
    }
        
    return YES;
}

-(BOOL)evalExpression
{
    if([self evalMinMaxPerRow]==NO)
    {
        //no need to proceed with rest of eval as min/max requirements were not passed
        return NO;
    }
    
    if(solutionMode==kSolutionUniqueCompositionsOfTopRow || solutionMode==kSolutionUniqueCompositionsOfValue)
    {
        int targetL=0;
        if(solutionMode==kSolutionUniqueCompositionsOfTopRow) targetL=[self getRowLengthFor:[createdRows objectAtIndex:0]];
        if(solutionMode==kSolutionUniqueCompositionsOfValue) targetL=evalUniqueCopmositionTarget;
        
        //every row's length must match target and have unique composition
        for (DWNBondRowGameObject *prgo in createdRows) {
            if([self getRowLengthFor:prgo]!=targetL) return NO;
        }
        
        //every row must be different from every other row
        for (DWNBondRowGameObject *prgo1 in createdRows) {
            for (DWNBondRowGameObject *prgo2 in createdRows) {
                if(prgo1!=prgo2)
                {
                    NSArray *s1=[self getSortedCompositionFor:prgo1];
                    NSArray *s2=[self getSortedCompositionFor:prgo2];
                    
                    if([self isArrayNumberData:s1 sameAs:s2])
                        return NO;
                }
            }
        }
        
        //assume eval was okay in the mode if no previous check has failed
        return YES;
    }
    
    if(solutionMode==kSolutionTopRow)
    {
        //returns YES if the tool expression evaluates succesfully
        toolHost.PpExpr=[BAExpressionTree treeWithRoot:[BAEqualsOperator operator]];
        
        //loop rows
        for (DWNBondRowGameObject *prgo in createdRows) {
            
            int cumRowLength = [self getRowLengthFor:prgo];
            
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
        NSMutableArray *correctRows=[[[NSMutableArray alloc]init] autorelease];
        NSMutableArray *usedSolutions=[[[NSMutableArray alloc]init] autorelease];
        NSMutableArray *usedGOs=[[[NSMutableArray alloc] init] autorelease];
        
        
        // for each row, we need to find whether their make-up is a solution
        for(DWNBondRowGameObject *r in createdRows)
        {
            if(r.Locked)continue;
            if([correctRows containsObject:r])continue;
            // for each row, check each solution
            for(NSArray *a in solutionsDef)
            {
                // we assume at the start that everything is right
                BOOL matchedAllObjects=YES; 
                // if there's no objects in this row, continue - if the row's already correct, continue
                if([r.MountedObjects count]==0)return NO;
                if([usedSolutions containsObject:a])continue;
                
                // loop through each mounted object
                for(int v=0;v<[r.MountedObjects count];v++)
                {
                    if([usedGOs containsObject:[r.MountedObjects objectAtIndex:v]])continue;
                    
                    if(matchedAllObjects)
                    {
                        // if the count in the array and amount of objects differ, we know we're in the wrong place
                        if([a count]!=[r.MountedObjects count])
                        {
                            matchedAllObjects=NO;
                            break;
                        }

                        // get our 2 values to compare
                        int reqVal=[[a objectAtIndex:v]intValue];
                        int thisVal=((DWNBondObjectGameObject*)[r.MountedObjects objectAtIndex:v]).Length;
                        [usedGOs addObject:[r.MountedObjects objectAtIndex:v]];

                        NSLog(@"checking value of object %d (%d) against %d (%d)", ((int)[r.MountedObjects objectAtIndex:v]), ((DWNBondObjectGameObject*)[r.MountedObjects objectAtIndex:v]).Length, (int)[a objectAtIndex:v], reqVal);
                        
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
        
        if(foundSolutions==[solutionsDef count])
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
        [toolHost doWinning];
    }
    else {
        if(rejectMode==kProblemRejectOnCommit && rejectType==kProblemAutomatedTransition)[self resetProblemFromReject];
        else if(rejectType==kProblemResetOnReject)[toolHost resetProblem];
        else [toolHost doIncomplete];
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

                    blocksUsedFromThisStore[pogo.IndexPos]--;
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

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    
}

#pragma mark - dealloc
-(void) dealloc
{
    [renderLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    for(id<LogPolling,NSObject> go in gw.AllGameObjects)
    {
        if([go isKindOfClass:[DWNBondObjectGameObject class]])
            [loggingService.logPoller unregisterPollee:go];
        else if([go isKindOfClass:[DWNBondRowGameObject class]])
            [loggingService.logPoller unregisterPollee:go];
        else if([go isKindOfClass:[DWNBondStoreGameObject class]])
            [loggingService.logPoller unregisterPollee:go];
    }
    
    //removing manual releases here -- causing msg_send issue

    initObjects=nil;
    initBars=nil;
    initCages=nil;
    initHints=nil;
    solutionsDef=nil;
    
    if(createdRows) [createdRows release];
    if(mountedObjects) [mountedObjects release];
    if(mountedObjectLabels) [mountedObjectLabels release];
    if(mountedObjectBadges) [mountedObjectBadges release];
    
    //tear down
    [gw release];
    
    [super dealloc];
}

@end
