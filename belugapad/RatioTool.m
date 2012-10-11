//
//  RatioTool.m
//  belugapad
//
//  Created by David Amphlett on 11/10/2012.
//
//
//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RatioTool.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"
#import "LoggingService.h"
#import "AppDelegate.h"

#import "NumberLayout.h"

#import "DWGameWorld.h"


@interface RatioTool()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    DWGameWorld *gw;

}

@end

@implementation RatioTool


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
        
        renderLayer = [[CCLayer alloc] init];
        [self.ForeLayer addChild:renderLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        loggingService = ac.loggingService;
        
        
        [self readPlist:pdef];
        [self populateGW];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

#pragma mark - loops

-(void)doUpdateOnTick:(ccTime)delta
{
    [gw doUpdate:delta];
    
    
}

-(void)draw
{
    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType=[[pdef objectForKey:REJECT_TYPE] intValue];


    initValueBlue=0;
    initValueRed=0;
    initValueGreen=0;
    
    recipeRed=[[pdef objectForKey:RECIPE_RED]intValue];
    recipeBlue=[[pdef objectForKey:RECIPE_BLUE]intValue];
    recipeGreen=[[pdef objectForKey:RECIPE_GREEN]intValue];
    

    if([pdef objectForKey:EVAL_VALUE_BLUE])
        evalValueBlue=[[pdef objectForKey:EVAL_VALUE_BLUE]intValue];
    else
        evalValueBlue=initValueBlue;
    
    if([pdef objectForKey:EVAL_VALUE_RED])
        evalValueRed=[[pdef objectForKey:EVAL_VALUE_RED]intValue];
    else
        evalValueRed=initValueRed;
    
    if([pdef objectForKey:EVAL_VALUE_GREEN])
        evalValueGreen=[[pdef objectForKey:EVAL_VALUE_GREEN]intValue];
    else
        evalValueGreen=initValueGreen;

    wheelMax=[[pdef objectForKey:WHEEL_MAX]intValue];
    
    for(int i=0;i<3;i++)
    {
        
    }
    
}

-(void)populateGW
{
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    CCSprite *bkg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ratio/ratio-overlay-01.png")];
    [bkg setPosition:ccp(cx,cy)];
    [renderLayer addChild:bkg];

    mbox=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ratio/matchbox.png")];
    [mbox setPosition:ccp(425,310)];
    [renderLayer addChild:mbox];

    CCSprite *mcolour=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/ratio/matchcolourbox-01.png")];
    [mcolour setPosition:ccp(908,628)];
    [mcolour setColor:ccc3(evalValueRed, evalValueGreen, evalValueBlue)];
    [renderLayer addChild:mcolour];
    
    CCLabelTTF *recipeRedLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipeRed] fontName:CHANGO fontSize:20];
    CCLabelTTF *recipeGreenLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipeGreen] fontName:CHANGO fontSize:20];
    CCLabelTTF *recipeBlueLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipeBlue] fontName:CHANGO fontSize:20];
    
    
    [recipeRedLabel setPosition:ccp(810,550)];
    [recipeGreenLabel setPosition:ccp(810,518)];
    [recipeBlueLabel setPosition:ccp(810,482)];
    
    [recipeRedLabel setColor:ccc3(237,28,36)];
    [recipeGreenLabel setColor:ccc3(0,165,80)];
    [recipeBlueLabel setColor:ccc3(46,48,146)];
    
    [renderLayer addChild:recipeRedLabel];
    [renderLayer addChild:recipeGreenLabel];
    [renderLayer addChild:recipeBlueLabel];
    

    amountRed=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipeRed] fontName:CHANGO fontSize:20];
    amountGreen=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipeGreen] fontName:CHANGO fontSize:20];
    amountBlue=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipeBlue] fontName:CHANGO fontSize:20];
    
    [amountRed setPosition:ccp(910,550)];
    [amountGreen setPosition:ccp(910,518)];
    [amountBlue setPosition:ccp(910,482)];
    
    [amountRed setColor:ccc3(237,28,36)];
    [amountGreen setColor:ccc3(0,165,80)];
    [amountBlue setColor:ccc3(46,48,146)];
    
    [renderLayer addChild:amountRed];
    [renderLayer addChild:amountGreen];
    [renderLayer addChild:amountBlue];
    
}

#pragma mark - interaction



#pragma mark - CCPickerView for number wheel

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
    
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    
    
    
    
    
    lastTouch=location;
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
 
    
    // if we were moving the marker
    

    isTouching=NO;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    

    isTouching=NO;
    // empty selected objects
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
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

#pragma mark - dealloc
-(void) dealloc
{
    
    [renderLayer release];
    

    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
