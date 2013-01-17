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
#import "DWNWheelGameObject.h"


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
    
    for(int i=0;i<[numberWheels count];i++)
    {
        DWNWheelGameObject *w=[numberWheels objectAtIndex:i];
        if(w.OutputValue>(int)wheelMax)
        {
            c[i]=wheelMax;
            w.InputValue=(int)wheelMax;
            [w handleMessage:kDWupdateObjectData];
            [amount[i] setString:[NSString stringWithFormat:@"%d", c[i]]];
        }
        else
        {
            c[i]=w.OutputValue;
            [amount[i] setString:[NSString stringWithFormat:@"%d", c[i]]];
        }
    }
    if(evalMode==kProblemEvalAuto)[self evalProblem];
    
    [mbox setColor:ccc3((c[0]/wheelMax)*255,(c[1]/wheelMax)*255,(c[2]/wheelMax)*255)];
}

-(void)draw
{
    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType=[[pdef objectForKey:REJECT_TYPE] intValue];


    initValue[0]=[[pdef objectForKey:INIT_VALUE_RED]intValue];
    initValue[1]=[[pdef objectForKey:INIT_VALUE_GREEN]intValue];
    initValue[2]=[[pdef objectForKey:INIT_VALUE_BLUE]intValue];
    
    recipe[0]=[[pdef objectForKey:RECIPE_RED]intValue];
    recipe[1]=[[pdef objectForKey:RECIPE_GREEN]intValue];
    recipe[2]=[[pdef objectForKey:RECIPE_BLUE]intValue];
    
    if([pdef objectForKey:EVAL_VALUE_RED]){
        evalValue[0]=[[pdef objectForKey:EVAL_VALUE_RED]intValue];
        wheelLocked[0]=NO;
    }else{
        evalValue[0]=initValue[0];
        wheelLocked[0]=YES;
    }
    if([pdef objectForKey:EVAL_VALUE_GREEN]){
        evalValue[1]=[[pdef objectForKey:EVAL_VALUE_GREEN]intValue];
        wheelLocked[1]=NO;
    }else{
        evalValue[1]=initValue[1];
        wheelLocked[1]=YES;
    }
    if([pdef objectForKey:EVAL_VALUE_BLUE]){
        evalValue[2]=[[pdef objectForKey:EVAL_VALUE_BLUE]intValue];
        wheelLocked[2]=NO;
    }else{
        evalValue[2]=initValue[2];
        wheelLocked[2]=YES;
    }
    wheelMax=[[pdef objectForKey:WHEEL_MAX]floatValue];
    
    if(!numberWheels)
        numberWheels=[[[NSMutableArray alloc]init]retain];
    
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
    [mcolour setColor:ccc3((evalValue[0]/wheelMax)*255, (evalValue[1]/wheelMax)*255, (evalValue[2]/wheelMax)*255)];
    [renderLayer addChild:mcolour];
    
    CCLabelTTF *recipeRedLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipe[0]] fontName:CHANGO fontSize:20];
    CCLabelTTF *recipeGreenLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipe[1]] fontName:CHANGO fontSize:20];
    CCLabelTTF *recipeBlueLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipe[2]] fontName:CHANGO fontSize:20];
    
    
    [recipeRedLabel setPosition:ccp(810,550)];
    [recipeGreenLabel setPosition:ccp(810,518)];
    [recipeBlueLabel setPosition:ccp(810,482)];
    
    [recipeRedLabel setColor:ccc3(237,28,36)];
    [recipeGreenLabel setColor:ccc3(0,165,80)];
    [recipeBlueLabel setColor:ccc3(46,48,146)];
    
    [renderLayer addChild:recipeRedLabel];
    [renderLayer addChild:recipeGreenLabel];
    [renderLayer addChild:recipeBlueLabel];
    

    amount[0]=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipe[0]] fontName:CHANGO fontSize:20];
    amount[1]=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipe[1]] fontName:CHANGO fontSize:20];
    amount[2]=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", recipe[2]] fontName:CHANGO fontSize:20];
    
    [amount[0] setPosition:ccp(910,550)];
    [amount[1] setPosition:ccp(910,518)];
    [amount[2] setPosition:ccp(910,482)];
    
    [amount[0] setColor:ccc3(237,28,36)];
    [amount[1] setColor:ccc3(0,165,80)];
    [amount[2] setColor:ccc3(46,48,146)];
    
    [renderLayer addChild:amount[0]];
    [renderLayer addChild:amount[1]];
    [renderLayer addChild:amount[2]];
    
    for(int i=0;i<3;i++)
    {
        DWNWheelGameObject *w=[DWNWheelGameObject alloc];
        [gw populateAndAddGameObject:w withTemplateName:@"TnumberWheel"];
        w.Components=3;
        w.Position=ccp(140+(i*200),600);
        w.RenderLayer=renderLayer;
        w.Locked=wheelLocked[i];
        w.SpriteFileName=@"/images/numberwheel/3slots.png";
        [w handleMessage:kDWsetupStuff];
        w.InputValue=initValue[i];
        w.OutputValue=w.InputValue;
        [w handleMessage:kDWupdateObjectData];
        [numberWheels addObject:w];
        [w release];
    }
    
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
    int countCorrect=0;
    
    for(int i=0;i<[numberWheels count];i++)
    {
        DWNWheelGameObject *w=[numberWheels objectAtIndex:i];
        
        if(w.OutputValue==evalValue[i])
            countCorrect++;
    }
    
    if(countCorrect==3)
        return YES;
    else
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
    
    [renderLayer release];
    

    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
