//
//  TimesTableMenu.m
//  belugapad
//
//  Created by David Amphlett on 22/02/2013.
//
//

#import "TimesTableMenu.h"
#import "AppDelegate.h"
#import "ContentService.h"
#import "ToolHost.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "TTAppUState.h"

const float moveToCentreTime=0.2f;
const float moveBackToPositionTime=0.2f;
const float backgroundFadeInTime=0.4f;
const float backgroundFadeOutTime=0.3f;
const float outerButtonPopOutTime=0.5f;
const float outerButtonPopOutDelay=0.1f;
const float outerButtonPopInTime=0.02f;
const float outerButtonPopInDelay=0.05f;

@implementation TimesTableMenu
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	TimesTableMenu *layer = [TimesTableMenu node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
        
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        ac = (AppController*)[[UIApplication sharedApplication] delegate];
        
        self.isTouchEnabled=YES;
        
        TTAppUState *ttappu=(TTAppUState*)ac.appustateService;
        int prevNumberOutstanding=[ttappu prevCountOfChallengingQuestions];
        int numberOutstanding=[ttappu countOfChallengingQuestions];
        NSLog(@"COUNT OF PREVIOUS CHALLENGING / CURRNENT: %d / %d", prevNumberOutstanding, numberOutstanding);
        
        renderLayer = [[[CCLayer alloc]init]autorelease];
        [self addChild:renderLayer];
    
        [self populateMenu];
        [self schedule:@selector(doUpdateOnTick:) interval:1.0f/60.0f];
	}
	return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
    if(CountdownToPipeline)
    {
        CountdownToPipelineTime-=delta;
        
        if(CountdownToPipelineTime<0)
        {
            if(RandomPipeline)
            {
                [self setupPipeline];
                NSLog(@"i start random pipe here %d", currentSelectionIndex);
                
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_play.wav")];
                
                [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
            }
            else if(ChallengePipeline)
            {
                if(challengeCounter==0){
                    ReturnChallengeOrRandom=YES;
                    [self returnCurrentBigNumber];
                    return;
                }
                [self setupPipeline];
                NSLog(@"i start challenge pipe here %d", currentSelectionIndex);
                
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_play.wav")];
                
                [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
            }
            
            CountdownToPipeline=NO;
        }
    }
    
    if(IsCountingDownChallengeScore)
    {
        challengeCounter+=challengeDecrementer;
        
        if(challengeCounter<challengesLeft)
        {
            challengeCounter=challengesLeft;
            IsCountingDownChallengeScore=NO;
            challengeLabel=nil;
            ReturnChallengeOrRandom=YES;
        }
        
        NSString *sScore=@"";
        NSNumberFormatter *nf = [NSNumberFormatter new];
        nf.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *thisNumber=[NSNumber numberWithFloat:(int)challengeCounter];
        sScore = [nf stringFromNumber:thisNumber];
        [nf release];
        
        [challengeLabel setString:sScore];
        
    }
    if(ReturnChallengeOrRandom)
    {
        ReturnChallengeRandomCountdown-=delta;
        if(ReturnChallengeRandomCountdown<0)
        {
            [self returnCurrentBigNumber];
            ReturnChallengeOrRandom=NO;
        }
    }
}

-(void)populateMenu
{
    gameState=@"SHOW_MAIN_MENU";
    sceneButtons=[[NSMutableArray alloc]init];
    currentSelectionButtons=[[NSMutableArray alloc]init];
    sceneButtonPositions=[[NSMutableArray alloc]init];
    sceneButtonMedals=[[NSMutableArray alloc]init];
    currentSelectionIndex=-1;
    
    TTAppUState *ttappu=(TTAppUState*)ac.appustateService;
    
    CCSprite *background=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ttbg/sand_background.png")];
    [background setPosition:ccp(cx,cy)];
    [renderLayer addChild:background];
    
    totalTab=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/menu/total_score_tab.png")];
//    [totalTab setAnchorPoint:ccp(1,0.5)];
    [totalTab setPosition:ccp(lx-(totalTab.contentSize.width/2),ly-50)];
    [renderLayer addChild:totalTab];
    
    infoBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/menu/info_button.png")];
    [infoBtn setPosition:ccp(30,30)];
    [renderLayer addChild:infoBtn];
    
    float xStartPos=179.0f;
    float yStartPos=593.0f;
    float xSpacing=208.0f;
    float ySpacing=165.0f;
    int colPerRow=4;
    int currentCol=0;
    int currentRow=0;
    
    int totalPerc=0;
    
    // the main buttons
    
    for(int i=0;i<12;i++)
    {
        float thisXPos=xStartPos+(currentCol*xSpacing);
        float thisYPos=yStartPos-(currentRow*ySpacing);
        
        NSString *f=[NSString stringWithFormat:@"/images/timestables/menu/button_small_%d.png", i+1];
    
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
        [s setPosition:ccp(thisXPos,thisYPos)];
        [renderLayer addChild:s];
        
        float thisPerc=([ttappu getScoreForX:i+1]+0.5f);
        int roundPerc=(int)thisPerc;
        totalPerc+=roundPerc;
        
        NSString *stringPerc=[NSString stringWithFormat:@"%d%%", roundPerc];
        
        NSString *percBadge=nil;
        
        if(roundPerc>=25 && roundPerc<=66)
            percBadge=@"bronze";
        else if(roundPerc>=67 && roundPerc<=99)
            percBadge=@"silver";
        else if(roundPerc==100)
            percBadge=@"gold";
        
        CCLabelTTF *l=[CCLabelTTF labelWithString:stringPerc fontName:CHANGO fontSize:17.0f];
        [l setPosition:ccp(s.contentSize.width/2,23)];
        [s addChild:l];
        
        NSString *percBadgeFile=[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/timestables/menu/star_coin_%@.png"), percBadge];
        
        if(percBadge){
            CCSprite *percProg=[CCSprite spriteWithFile:percBadgeFile];
            [percProg setPosition:ccp(s.contentSize.width-10,15)];
            [s addChild:percProg];
            [sceneButtonMedals addObject:percProg];
        }
        else
        {
            [sceneButtonMedals addObject:[NSNull null]];
        }
        
        currentCol++;
        if(currentCol>colPerRow-1)
        {
            currentRow++;
            currentCol=0;
        }
        
        [sceneButtons addObject:s];
        [sceneButtonPositions addObject:[NSValue valueWithCGPoint:s.position]];
    }
    
    // the 2 bottom buttons
    for(int i=0;i<2;i++)
    {
        
        float thisXPos=xStartPos+((currentCol+1)*xSpacing);
        float thisYPos=yStartPos-(currentRow*ySpacing);
        currentCol++;
        
        NSString *name=nil;
        if(i==0)
            name=@"random";
        else if(i==1)
            name=@"challenging";
        
        NSString *f=[NSString stringWithFormat:@"/images/timestables/menu/button_small_%@.png", name];
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
        [s setPosition:ccp(thisXPos,thisYPos)];
        [renderLayer addChild:s];
        
        [sceneButtons addObject:s];
        [sceneButtonMedals addObject:[NSNull null]];
        [sceneButtonPositions addObject:[NSValue valueWithCGPoint:s.position]];
        
        if(i==1)
        {
            CCSprite *notLabel=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/menu/notification_small.png")];
            [notLabel setPosition:ccp(s.contentSize.width/1.18,s.contentSize.height/1.5)];
            [s addChild:notLabel];
            
            TTAppUState *ttappu=(TTAppUState*)ac.appustateService;
            int numberOutstanding=[ttappu countOfChallengingQuestions];
            
            NSString *numberLeft=[NSString stringWithFormat:@"%d", numberOutstanding];
            
            CCLabelTTF *l=[CCLabelTTF labelWithString:numberLeft fontName:CHANGO fontSize:20.0f];
            [l setPosition:ccp(1+notLabel.contentSize.width/2,2+notLabel.contentSize.height/2)];
            [notLabel addChild:l];
        }
    }
    
    totalPercentage=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d%%",totalPerc/12] fontName:CHANGO fontSize:56.0f];

    [totalPercentage setPosition:totalTab.position];
    [renderLayer addChild:totalPercentage];
    
    if(ac.NumberShowing){
        
        ReturnChallengeRandomCountdown=1.0f;
        
        if(ac.PreviousNumber<12)
            [self createBigNumberWithoutAnimationOf:ac.PreviousNumber];
        else if(ac.PreviousNumber==12)
            [self createBigRandomWithoutAnimationOf:ac.PreviousNumber];
        else if(ac.PreviousNumber==13)
            [self createBigChallengeWithoutAnimationOf:ac.PreviousNumber];
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_success.wav")];
    }
    
}

-(void)slideScoreTab:(int)direction
{
    if(direction==1){
        [totalTab runAction:[CCEaseBounceIn actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp(totalTab.position.x+250,totalTab.position.y)]]];
        [totalPercentage runAction:[CCEaseBounceIn actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp(totalPercentage.position.x+250,totalPercentage.position.y)]]];
    }
    else if(direction==-1){
        [totalTab runAction:[CCEaseBounceIn actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp(totalTab.position.x-250,totalTab.position.y)]]];
        [totalPercentage runAction:[CCEaseBounceIn actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp(totalPercentage.position.x-250,totalPercentage.position.y)]]];
    }
    else if(direction==2){
        [totalTab setPosition:ccp(totalTab.position.x+250,totalTab.position.y)];
        [totalPercentage setPosition:ccp(totalPercentage.position.x+250,totalPercentage.position.y)];
    }
}

-(void)createBigNumberOf:(int)thisNumber
{
    if(ReturningBigNumber)return;
    [self slideScoreTab:1];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_expand.wav")];
    gameState=@"SHOW_TABLES";
    
    CCSprite *original=[sceneButtons objectAtIndex:thisNumber];
    CCLabelTTF *originalLabel=[original.children objectAtIndex:0];
    
    CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveToCentreTime position:ccp(cx,cy)];
    CCScaleTo *st=[CCScaleTo actionWithDuration:moveToCentreTime scale:1.0f];
    
    CCEaseInOut *ea=[CCEaseInOut actionWithAction:mtc rate:2.0f];
    CCCallBlock *numbers=[CCCallBlock actionWithBlock:^{[self setupOutsideButtons];}];
    CCCallBlock *playbtn=[CCCallBlock actionWithBlock:^{[self setupPlayButton];}];
    CCSequence *sq=[CCSequence actions:ea, playbtn, numbers, nil];
    
    NSString *f=nil;
    
    if(thisNumber<12)
        f=@"/images/timestables/menu/button_big_bg.png";
    else if(thisNumber==12)
        f=@"/images/timestables/menu/button_big_random.png";
    else if(thisNumber==13)
        f=@"/images/timestables/menu/button_big_challenging.png";
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
    [s setPosition:original.position];
    [s setScale:0.38f];

    
    CCLabelTTF *l=[CCLabelTTF labelWithString:originalLabel.string fontName:CHANGO fontSize:56.0f];
    [l setPosition:ccp(s.contentSize.width/2,60)];
    [s addChild:l];
    [renderLayer addChild:s z:20];
    
    
    if(thisNumber<12){
        // create the number label
        CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%dx", thisNumber+1] fontName:CHANGO fontSize:164.0f];
        [l setPosition:ccp((s.contentSize.width/2),(s.contentSize.height/2)+15)];
        [s addChild:l];
        [self setupOutsideButtons];
    }
    
    [s runAction:sq];
    [s runAction:st];
    [original runAction:[CCFadeOut actionWithDuration:0.1f]];
    [originalLabel runAction:[CCFadeOut actionWithDuration:0.1f]];
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        CCSprite *sM=[sceneButtonMedals objectAtIndex:i];
        if(![sM isKindOfClass:[NSNull class]] && i!=currentSelectionIndex)[sM runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
        else if(![sM isKindOfClass:[NSNull class]] && i==currentSelectionIndex)[sM runAction:[CCFadeOut actionWithDuration:backgroundFadeInTime]];
        
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        CCSprite *sL=[s.children objectAtIndex:0];
        if(s)[s runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
        if(sL)[sL runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
    }
    
    currentSelection=s;
    currentSelectionIndex=thisNumber;
    ac.NumberShowing=YES;
    ac.PreviousNumber=thisNumber;
}

-(void)createBigRandom:(int)thisNumber
{
    if(ReturningBigNumber)return;
    [self slideScoreTab:1];
    RandomPipeline=YES;
    CountdownToPipeline=YES;
    CountdownToPipelineTime=moveToCentreTime+0.3f;
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_expand.wav")];
    gameState=@"SHOW_TABLES";
    
    CCSprite *original=[sceneButtons objectAtIndex:thisNumber];
    
    CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveToCentreTime position:ccp(cx,cy)];
    CCScaleTo *st=[CCScaleTo actionWithDuration:moveToCentreTime scale:1.0f];
    
    CCEaseInOut *ea=[CCEaseInOut actionWithAction:mtc rate:2.0f];
    CCSequence *sq=[CCSequence actions:ea, nil];
    
    NSString *f=@"/images/timestables/menu/button_big_random.png";
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
    [s setPosition:original.position];
    [s setScale:0.38f];
    
    [renderLayer addChild:s];
    
    [s runAction:sq];
    [s runAction:st];
    [original runAction:[CCFadeOut actionWithDuration:0.1f]];
    
    currentSelection=s;
    currentSelectionIndex=thisNumber;
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        CCSprite *sL=[s.children objectAtIndex:0];
        CCSprite *sM=[sceneButtonMedals objectAtIndex:i];
        if(s)[s runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
        if(sL)[sL runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
        if(![sM isKindOfClass:[NSNull class]])[sM runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
    }
    
    ac.NumberShowing=YES;
    ac.PreviousNumber=thisNumber;
    
}

-(void)createBigChallenge:(int)thisNumber
{
    if(ReturningBigNumber)return;
    [self slideScoreTab:1];
    
    TTAppUState *ttappu=(TTAppUState*)ac.appustateService;
    int previousRemaining=[ttappu prevCountOfChallengingQuestions];
    int newRemaining=[ttappu countOfChallengingQuestions];
    
    challengeCounter=previousRemaining;
    challengesLeft=newRemaining;
    
    
    ChallengePipeline=YES;
    CountdownToPipeline=YES;
    CountdownToPipelineTime=moveToCentreTime+0.3f;
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_expand.wav")];
    gameState=@"SHOW_TABLES";
    
    CCSprite *original=[sceneButtons objectAtIndex:thisNumber];
    CCSprite *originalNotification=[original.children objectAtIndex:0];
    CCLabelTTF *originalLabel=[[[original.children objectAtIndex:0] children]objectAtIndex:0];
    
    CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveToCentreTime position:ccp(cx,cy)];
    CCScaleTo *st=[CCScaleTo actionWithDuration:moveToCentreTime scale:1.0f];
    
    CCEaseInOut *ea=[CCEaseInOut actionWithAction:mtc rate:2.0f];
    CCSequence *sq=[CCSequence actions:ea, nil];
    
    NSString *f=@"/images/timestables/menu/button_big_challenging.png";
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
    [s setPosition:original.position];
    [s setScale:0.38f];
    
    CCSprite *n=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/menu/notification_expanded.png")];
    
    
    
    [n setPosition:[s convertToNodeSpace:[original convertToWorldSpace:originalNotification.position]]];
    [s addChild:n];
    
    
    CCLabelTTF *l=[CCLabelTTF labelWithString:originalLabel.string fontName:CHANGO fontSize:56.0f];
    [l setPosition:ccp(1+(n.contentSize.width/2),2+(n.contentSize.height/2))];
    [n addChild:l];
    [renderLayer addChild:s z:20];
    
    [s runAction:sq];
    [s runAction:st];
    [original runAction:[CCFadeOut actionWithDuration:0.1f]];
    [originalLabel runAction:[CCFadeOut actionWithDuration:0.1f]];
    [originalNotification runAction:[CCFadeOut actionWithDuration:0.1f]];
    
    currentSelection=s;
    currentSelectionIndex=thisNumber;
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        CCSprite *sL=[s.children objectAtIndex:0];
        CCSprite *sM=[sceneButtonMedals objectAtIndex:i];
        if(s)[s runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
        if(sL)[sL runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
        if(![sM isKindOfClass:[NSNull class]])[sM runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:50]];
    }
    
    ac.NumberShowing=YES;
    ac.PreviousNumber=thisNumber;
}

-(void)createBigRandomWithoutAnimationOf:(int)thisNumber
{
    ReturnChallengeOrRandom=YES;
    [self slideScoreTab:2];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_expand.wav")];
    gameState=@"SHOW_TABLES";
    
    NSString *f=@"/images/timestables/menu/button_big_random.png";
    
    CCSprite *original=[sceneButtons objectAtIndex:thisNumber];
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
    [s setPosition:ccp(cx,cy)];
    
    [renderLayer addChild:s];
    
    [original setOpacity:0];
    
    currentSelection=s;
    currentSelectionIndex=thisNumber;
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        CCSprite *sL=[s.children objectAtIndex:0];
        CCSprite *sM=[sceneButtonMedals objectAtIndex:i];
        if(s)[s setOpacity:50];
        if(sL)[sL setOpacity:50];
        if(![sM isKindOfClass:[NSNull class]])[sM setOpacity:50];
    }
    
    ac.NumberShowing=YES;
    ac.PreviousNumber=thisNumber;
    
}

-(void)createBigChallengeWithoutAnimationOf:(int)thisNumber
{
    [self slideScoreTab:2];
    
    TTAppUState *ttappu=(TTAppUState*)ac.appustateService;
    int previousRemaining=[ttappu prevCountOfChallengingQuestions];
    int newRemaining=[ttappu countOfChallengingQuestions];
    
    [ttappu purgePreviousState];
    
    challengeCounter=previousRemaining;
    challengesLeft=newRemaining;
//    challengeCounter=15;
//    challengesLeft=10;
    
    CCSprite *original=[sceneButtons objectAtIndex:thisNumber];
    CCSprite *originalNot=[original.children objectAtIndex:0];
    CCLabelTTF *originalLabel=[[[original.children objectAtIndex:0] children]objectAtIndex:0];
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_expand.wav")];
    gameState=@"SHOW_TABLES";
    
    NSString *f=@"/images/timestables/menu/notification_big.png";
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
    [s setPosition:ccp(cx,cy)];
    
    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", previousRemaining] fontName:CHANGO fontSize:56.0f];
    [l setPosition:ccp(1+(s.contentSize.width/2),2+(s.contentSize.height/2))];
    [s addChild:l];
    [renderLayer addChild:s z:20];
    
    challengeLabel=l;
    
    currentSelection=s;
    currentSelectionIndex=thisNumber;
    
    [original setOpacity:0];
    [originalLabel setOpacity:0];
    [originalNot setOpacity:0];
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        CCSprite *sL=[s.children objectAtIndex:0];
        CCSprite *sM=[sceneButtonMedals objectAtIndex:i];
        if(s)[s setOpacity:50];
        if(sL)[sL setOpacity:50];
        if(![sM isKindOfClass:[NSNull class]])[sM setOpacity:50];
    }

    ChallengeReturnFromPipeline=YES;
    challengeDecrementer=-0.7;

    IsCountingDownChallengeScore=YES;
    ac.NumberShowing=YES;
    ac.PreviousNumber=thisNumber;
}


-(void)createBigNumberWithoutAnimationOf:(int)thisNumber
{
    [self slideScoreTab:2];
    gameState=@"SHOW_TABLES";
    
    CCSprite *original=[sceneButtons objectAtIndex:thisNumber];
    CCLabelTTF *originalLabel=[original.children objectAtIndex:0];
    
    NSString *f=nil;
    
    if(thisNumber<12)
        f=@"/images/timestables/menu/button_big_bg.png";
    else if(thisNumber==12)
        f=@"/images/timestables/menu/button_big_random.png";
    else if(thisNumber==13)
        f=@"/images/timestables/menu/button_big_challenging.png";
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
    [s setPosition:ccp(cx,cy)];
    [s setScale:1.0f];

    [renderLayer addChild:s z:20];
    
    CCLabelTTF *l=[CCLabelTTF labelWithString:originalLabel.string fontName:CHANGO fontSize:56.0f];
    [l setPosition:ccp(s.contentSize.width/2,60)];
    [s addChild:l];
    
    if(thisNumber<12){
        // create the number label
        CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%dx", thisNumber+1] fontName:CHANGO fontSize:164.0f];
        [l setPosition:ccp(s.contentSize.width/2,(s.contentSize.height/2)+15)];
        [s addChild:l];
        [self setupOutsideButtons];
    }
    
    [original setOpacity:50];
    [originalLabel setOpacity:50];
    
    currentSelection=s;
    currentSelectionIndex=thisNumber;
    
    [self setupPlayButtonWithAnimation:NO];
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        CCSprite *sM=[sceneButtonMedals objectAtIndex:i];
        if(![sM isKindOfClass:[NSNull class]] && i!=currentSelectionIndex)[sM setOpacity:50];
        else if(![sM isKindOfClass:[NSNull class]] && i==currentSelectionIndex)[sM setOpacity:0];
        
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        CCSprite *sL=[s.children objectAtIndex:0];
        if(s)[s setOpacity:50];
        if(sL)[sL setOpacity:50];
    }
}

-(void)returnCurrentBigNumber{
    if(currentSelection==nil)return;
    if([currentSelection numberOfRunningActions]>0)return;
    
    ReturningBigNumber=YES;
    
    [self slideScoreTab:-1];
    
    NSLog(@"returning big number - current selection index %d", currentSelectionIndex);
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_contract.wav")];
    
    ac.NumberShowing=NO;
    float remTime=outerButtonPopInTime;
    
    if(currentSelectionIndex<12){
        
        for(int i=0;i<[currentSelectionButtons count];i++)
        {
            CCSprite *s=[currentSelectionButtons objectAtIndex:i];
            CCMoveTo *mtc=[CCMoveTo actionWithDuration:remTime position:ccp(cx,cy)];
            CCEaseBounceOut *bo=[CCEaseBounceOut actionWithAction:mtc];
            CCCallBlock *remMe=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
            CCSequence *thisSQ=[CCSequence actions:bo, remMe, nil];
            [s runAction:thisSQ];
            remTime+=outerButtonPopInDelay;
        }
        
        [currentSelectionButtons removeAllObjects];
        
        CCSprite *s=currentSelection;
        CCSprite *o=[sceneButtons objectAtIndex:currentSelectionIndex];
        CCLabelTTF *oL=[o.children objectAtIndex:0];
        CCLabelTTF *playLabel=[s.children objectAtIndex:1];
        CCSprite *play=nil;

        
        CGPoint thisPos=[[sceneButtonPositions objectAtIndex:currentSelectionIndex]CGPointValue];

        if(s.children.count>2){
            play=[s.children objectAtIndex:2];
            CCScaleTo *playbtnscale=[CCScaleTo actionWithDuration:0.3f scale:0.0f];
            CCEaseBounceIn *bo=[CCEaseBounceIn actionWithAction:playbtnscale];
            [play runAction:bo];
        }
        
        CCScaleTo *playlblscale=[CCScaleTo actionWithDuration:0.4f scale:1.0f];
        CCEaseBounceIn*boL=[CCEaseBounceIn actionWithAction:playlblscale];
        [playLabel runAction:boL];

        
        CCDelayTime *dt=[CCDelayTime actionWithDuration:remTime];
        CCDelayTime *dt2=[CCDelayTime actionWithDuration:remTime];
        CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveBackToPositionTime position:thisPos];
        CCScaleTo *st=[CCScaleTo actionWithDuration:moveBackToPositionTime scale:0.38f];
        
        CCCallBlock *remove=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
        CCCallBlock *opacity=[CCCallBlock actionWithBlock:^{[o setOpacity:255];ReturningBigNumber=NO;}];
        CCCallBlock *opacityLabel=[CCCallBlock actionWithBlock:^{[oL setOpacity:255];}];
        
        CCSequence *sortbiggie=[CCSequence actions:dt, mtc, remove, opacity, opacityLabel, nil];
        CCSequence *sortbiggiescale=[CCSequence actions:dt2, st, nil];
        
        [s runAction:sortbiggie];
        [s runAction:sortbiggiescale];
        

    }
    
    else if(currentSelectionIndex==12)
    {
        CCSprite *s=currentSelection;
        CCSprite *o=[sceneButtons objectAtIndex:currentSelectionIndex];
        CCLabelTTF *oL=[o.children objectAtIndex:0];
        
        CCSprite *play=[s.children objectAtIndex:2];
        CCLabelTTF *playLabel=[s.children objectAtIndex:1];
        
        CGPoint thisPos=[[sceneButtonPositions objectAtIndex:currentSelectionIndex]CGPointValue];
        
        
        CCScaleTo *playbtnscale=[CCScaleTo actionWithDuration:0.3f scale:0.0f];
        CCEaseBounceIn *bo=[CCEaseBounceIn actionWithAction:playbtnscale];
        [play runAction:bo];
        
        
        CCScaleTo *playlblscale=[CCScaleTo actionWithDuration:0.4f scale:1.0f];
        CCEaseBounceIn*boL=[CCEaseBounceIn actionWithAction:playlblscale];
        [playLabel runAction:boL];
        
        
        CCDelayTime *dt=[CCDelayTime actionWithDuration:remTime];
        CCDelayTime *dt2=[CCDelayTime actionWithDuration:remTime];
        CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveBackToPositionTime position:thisPos];
        CCScaleTo *st=[CCScaleTo actionWithDuration:moveBackToPositionTime scale:0.38f];
        
        CCCallBlock *remove=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
        CCCallBlock *opacity=[CCCallBlock actionWithBlock:^{[o setOpacity:255];ReturningBigNumber=NO;}];
        CCCallBlock *opacityLabel=[CCCallBlock actionWithBlock:^{[oL setOpacity:255];}];
        
        CCSequence *sortbiggie=[CCSequence actions:dt, mtc, remove, opacity, opacityLabel, nil];
        CCSequence *sortbiggiescale=[CCSequence actions:dt2, st, nil];
        
        [s runAction:sortbiggie];
        [s runAction:sortbiggiescale];
    }
    else if(currentSelectionIndex==13 && !ChallengeReturnFromPipeline)
    {
        CCSprite *s=currentSelection;
        CCSprite *o=[sceneButtons objectAtIndex:currentSelectionIndex];
        CCSprite *oN=[o.children objectAtIndex:0];
        CCLabelTTF *oL=[[[o.children objectAtIndex:0] children]objectAtIndex:0];
        
        CCSprite *play=[s.children objectAtIndex:0];
        
        CGPoint thisPos=[[sceneButtonPositions objectAtIndex:currentSelectionIndex]CGPointValue];
        
        
        CCScaleTo *playbtnscale=[CCScaleTo actionWithDuration:0.3f scale:0.0f];
        CCEaseBounceIn *bo=[CCEaseBounceIn actionWithAction:playbtnscale];
        [play runAction:bo];
        
        
        CCDelayTime *dt=[CCDelayTime actionWithDuration:remTime];
        CCDelayTime *dt2=[CCDelayTime actionWithDuration:remTime];
        CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveBackToPositionTime position:thisPos];
        CCScaleTo *st=[CCScaleTo actionWithDuration:moveBackToPositionTime scale:0.38f];
        
        CCCallBlock *remove=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
        CCCallBlock *opacity=[CCCallBlock actionWithBlock:^{[o setOpacity:255];}];
        CCCallBlock *opacityN=[CCCallBlock actionWithBlock:^{[oN setOpacity:255];}];
        CCCallBlock *opacityL=[CCCallBlock actionWithBlock:^{[oL setOpacity:255];ReturningBigNumber=NO;}];
        
        
        CCSequence *sortbiggie=[CCSequence actions:dt, mtc, remove, opacity, opacityN, opacityL, nil];
        CCSequence *sortbiggiescale=[CCSequence actions:dt2, st, nil];
        
        [s runAction:sortbiggie];
        [s runAction:sortbiggiescale];
    }
    else if(currentSelectionIndex==13 && ChallengeReturnFromPipeline)
    {
        CCSprite *s=currentSelection;
        CCSprite *o=[sceneButtons objectAtIndex:currentSelectionIndex];
        CCSprite *oN=[o.children objectAtIndex:0];
        CCLabelTTF *oL=[[[o.children objectAtIndex:0] children]objectAtIndex:0];
        
        CCSprite *play=[s.children objectAtIndex:0];
        
        CGPoint thisPos=[[sceneButtonPositions objectAtIndex:currentSelectionIndex]CGPointValue];
        
        
        CCScaleTo *playbtnscale=[CCScaleTo actionWithDuration:0.3f scale:0.0f];
        CCEaseBounceIn *bo=[CCEaseBounceIn actionWithAction:playbtnscale];
        [play runAction:bo];
        
        
        CCDelayTime *dt=[CCDelayTime actionWithDuration:remTime];
        CCDelayTime *dt2=[CCDelayTime actionWithDuration:remTime];
        CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveBackToPositionTime position:thisPos];
        CCScaleTo *st=[CCScaleTo actionWithDuration:moveBackToPositionTime scale:0.38f];
        
        CCCallBlock *remove=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
        CCCallBlock *opacity=[CCCallBlock actionWithBlock:^{[o setOpacity:255];}];
        CCCallBlock *opacityN=[CCCallBlock actionWithBlock:^{[oN setOpacity:255];}];
        CCCallBlock *opacityL=[CCCallBlock actionWithBlock:^{[oL setOpacity:255];ReturningBigNumber=NO;}];
        
        
        CCSequence *sortbiggie=[CCSequence actions:dt, mtc, remove, opacity, opacityN, opacityL, nil];
        CCSequence *sortbiggiescale=[CCSequence actions:dt2, st, nil];
        
        [s runAction:sortbiggie];
        [s runAction:sortbiggiescale];
    }
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        CCSprite *sM=[sceneButtonMedals objectAtIndex:i];
        
        CCDelayTime *di=[CCDelayTime actionWithDuration:moveBackToPositionTime+remTime];
        CCFadeIn *fi=[CCFadeIn actionWithDuration:backgroundFadeInTime];
        CCSequence *sq=[CCSequence actionOne:di two:fi];
        
        if(![sM isKindOfClass:[NSNull class]])[sM runAction:sq];
        
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        CCSprite *sL=[s.children objectAtIndex:0];

        if(s)[s runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:255]];
        if(sL)[sL runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:255]];
    }
    
    NSLog(@"returned big number - current selection index %d", currentSelectionIndex);
    
    ReturnChallengeOrRandom=NO;
    RandomPipeline=NO;
    ChallengePipeline=NO;
    CountdownToPipeline=NO;
    currentSelection=nil;
    currentSelectionIndex=-1;
    gameState=@"SHOW_MAIN_MENU";
    
}

-(void)checkForHitAt:(CGPoint)location
{
    if(CountdownToPipeline)return;
    
    BOOL gotHit=false;
    
    if([gameState isEqualToString:@"SHOW_MAIN_MENU"]){
        
        for(int i=0;i<[sceneButtons count];i++)
        {
            
            
            CCSprite *s=[sceneButtons objectAtIndex:i];
            if(CGRectContainsPoint(s.boundingBox, location) && currentSelection==nil && currentSelectionIndex!=i)
            {
                
                if(i<=11){
                    gotHit=YES;
                    [self createBigNumberOf:i];
                }
                else if(i==12){
                    // TODO: if has random or challnging number - start that pipeline
                    [self createBigRandom:i];
                }
                else if(i==13){
                    [self createBigChallenge:i];
                }
                
                break;
            }
        }
        
        if(CGRectContainsPoint(infoBtn.boundingBox, location))
        {
            if(!infoPnl){
                infoPnl=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/menu/info_panel.png")];
                [infoPnl setPosition:ccp(cx,cy)];
                [renderLayer addChild:infoPnl];
            }
            
            if(!infoPnl.visible)
                infoPnl.visible=YES;
        }

    }
    else if([gameState isEqualToString:@"SHOW_TABLES"] && !IsCountingDownChallengeScore){
        
        if([currentSelectionButtons count]==0 && currentSelectionIndex<12)return;
        
        for(int i=0;i<[currentSelectionButtons count];i++)
        {
            CCSprite *s=[currentSelectionButtons objectAtIndex:i];
            if(CGRectContainsPoint(s.boundingBox, location) && currentSelection!=nil)
            {
                gotHit=YES;
                NSLog(@"Got hit for number for %dx%d",currentSelectionIndex+1, i+1);
                
                [ac speakString:[NSString stringWithFormat:@"%d times %d is %d",currentSelectionIndex+1,i+1, (currentSelectionIndex+1)*(i+1)]];
                
                break;
            }
        }

        if(CGRectContainsPoint(currentSelection.boundingBox, location) && !gotHit && currentSelectionIndex<12)
        {
            [self setupPipeline];
            
            [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/ttapp/sfx_mult_menu_play.wav")];
            
            [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
            gotHit=YES;
        }
        
        if(!gotHit){
            [self returnCurrentBigNumber];
        }
    
    }
}

-(void)setupPipeline
{
    TTAppUState *ttappu=(TTAppUState*)ac.appustateService;
    [ttappu setupPipelineFor:currentSelectionIndex];
    
}

-(NSArray*)positionsInCircleWith:(int)points and:(double)radius and:(CGPoint)centre
{
    NSMutableArray *pointPos=[[NSMutableArray alloc]init];
    
    double slice = 2 * M_PI / points;
    for (int i = 0; i < points; i++)
    {
        double angle = slice * i;
        int newX = (int)(centre.x + radius * cos(angle));
        int newY = (int)(centre.y + radius * sin(angle));
        CGPoint p = ccp(newX, newY);
        [pointPos addObject:[NSValue valueWithCGPoint:p]];
    }
    
    return (NSArray*)pointPos;
}

-(void)setupPlayButton
{
    [self setupPlayButtonWithAnimation:YES];
}

-(void)setupPlayButtonWithAnimation:(BOOL)animate
{
    CCLabelTTF *l=[currentSelection.children objectAtIndex:1];
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/menu/play_button.png")];
    [s setPosition:ccp((currentSelection.contentSize.width/2)+10,(currentSelection.contentSize.height/2)+15)];
    [currentSelection addChild:s];
    
    if(animate){
        [s setScale:0];
        CCScaleTo *st=[CCScaleTo actionWithDuration:0.7f scale:1.0f];
        CCEaseBounceOut *bo=[CCEaseBounceOut actionWithAction:st];
        
        [s runAction:bo];
        
        CCScaleTo *stL=[CCScaleTo actionWithDuration:0.4f scale:0.3f];
        CCEaseBounceOut *boL=[CCEaseBounceOut actionWithAction:stL];
        [l runAction:boL];
    
    }
    else{
        [l setScale:0.3f];
    }
    
}

-(void)setupOutsideButtons
{
    BOOL exitedPipeline=ac.NumberShowing;
    NSArray *myPoints=[self positionsInCircleWith:12 and:250 and:ccp(cx,cy)];
    int currentPoint=2;
    float time=outerButtonPopOutTime;
    TTAppUState *ttappu=(TTAppUState*)ac.appustateService;
    
    if(currentSelectionButtons.count>0)
    {
        for(CCSprite *s in currentSelectionButtons)
            [s removeFromParentAndCleanup:YES];
        
        [currentSelectionButtons removeAllObjects];
    }
    
    for(int i=0;i<12;i++)
    {
        
        int currentXNumber=0;
        
        if(ac.NumberShowing)
            currentXNumber=ac.PreviousNumber+1;
        else
            currentXNumber=currentSelectionIndex+1;
        
        NSString *type=[ttappu getMedalForX:currentXNumber andY:i+1];
        
        NSString *prevtype=[ttappu getPreviousMedalForX:currentXNumber andY:i+1];
        
        NSString *f=nil;
        
        if(exitedPipeline)
            f=[NSString stringWithFormat:@"/images/timestables/menu/coin_%@_%d.png", prevtype, i+1];
        else
            f=[NSString stringWithFormat:@"/images/timestables/menu/coin_%@_%d.png", type, i+1];
        
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
        [s setPosition:ccp(cx,cy)];
        [renderLayer addChild:s z:18];
        
        [currentSelectionButtons addObject:s];
        
        CGPoint endPoint=[[myPoints objectAtIndex:currentPoint]CGPointValue];
        
        CCMoveTo *mt=[CCMoveTo actionWithDuration:time position:endPoint];
        CCEaseBounceOut *bi=[CCEaseBounceOut actionWithAction:mt];
        
        [s runAction:bi];
        
        if(exitedPipeline && ![type isEqualToString:prevtype])
        {
            // TODO: set up a new button here to bounce in
            NSLog(@"number %d / previous medal: %@, new medal %@", currentXNumber, prevtype, type);
            NSString *nf=[NSString stringWithFormat:@"/images/timestables/menu/coin_%@_%d.png", type, i+1];
            CCSprite *ns=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(nf)];
            [ns setScale:0.0f];
            [ns setPosition:endPoint];
            [renderLayer addChild:ns z:19];
            
            [currentSelectionButtons addObject:ns];
            [currentSelectionButtons exchangeObjectAtIndex:[currentSelectionButtons indexOfObject:ns] withObjectAtIndex:[currentSelectionButtons indexOfObject:s]];
            
            CCDelayTime *delayintro=[CCDelayTime actionWithDuration:time*2];
            CCScaleTo *scaleto=[CCScaleTo actionWithDuration:0.4f scale:1.0f];
            CCEaseBounceOut *bounce=[CCEaseBounceOut actionWithAction:scaleto];
            CCSequence *thisSequence=[CCSequence actionOne:delayintro two:bounce];
            [ns runAction:thisSequence];
            CCDelayTime *delayoutro=[CCDelayTime actionWithDuration:time*2];
            CCFadeOut *fadeoutold=[CCFadeOut actionWithDuration:0.2f];
            CCCallBlock *remold=[CCCallBlock actionWithBlock:^{[currentSelectionButtons removeObject:s]; [s removeFromParentAndCleanup:YES];}];
            CCSequence *removeold=[CCSequence actions:delayoutro,fadeoutold,remold,nil];
            [s runAction:removeold];
            
            
        }
        
        time+=outerButtonPopOutDelay;
        
        currentPoint--;
        
        if(currentPoint<0)
            currentPoint=11;
    }
    
    [ttappu purgePreviousState];
}

-(void)startPipelineFor:(int)thisNumber
{
    
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if(infoPnl.visible)
    {
        infoPnl.visible=false;
        return;
    }
    
    [self checkForHitAt:location];
    
    
}
-(void)dealloc
{
    [sceneButtons release];
    [super dealloc];
}
@end
