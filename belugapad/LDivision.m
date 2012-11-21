//
//  LDivision.m
//  belugapad
//
//  Created by David Amphlett on 25/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "LDivision.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "BLMath.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "UsersService.h"
#import "DWNWheelGameObject.h"
#import "SimpleAudioEngine.h"

@interface LDivision()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation LDivision

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
        
        drawNode=[[CCDrawNode alloc] init];
        [self.ForeLayer addChild:drawNode];
        
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    
    // work out the current total
    //    currentTotal=nWheel.OutputValue/(pow((double)startColValue,-1));
    currentTotal=[nWheel.StrOutputValue floatValue];
    
    //effective 4-digit precision evaluation test
    int prec=10000;
    int sum=(int)(currentTotal*divisor*prec);
    int idividend=(int)(dividend*prec);
    expressionIsEqual=(sum==idividend);
    
    // this sets the good/bad sum indicator if the mode is enabled
    if(goodBadHighlight)
    {
        if(expressionIsEqual)
        {
            [lblCurrentTotal setColor:ccc3(0, 255,0)];
            audioHasPlayedOverTarget=NO;
            audioHasPlayedOnTarget=YES;
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_long_division_general_block_target_reached.wav")];
        }else{
            [lblCurrentTotal setColor:ccc3(255,0,0)];
            if(!audioHasPlayedOverTarget){
                [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_long_division_general_block_over_target.wav")];
                audioHasPlayedOverTarget=YES;
                audioHasPlayedOnTarget=NO;
            }
        }
    }
    
    // then update the actual text of it
    [lblCurrentTotal setString:[NSString stringWithFormat:@"%g", currentTotal]];
    
    [self drawState];

    if(evalMode==kProblemEvalAuto && !hasEvaluated)
        [self evalProblem];
    
}

-(void)drawState
{
    float xInset=100.0f;
    float yInset=350.0f;
    float barW=824.0f;
    float barH=100.0f;

    ccColor4F lineCol=ccc4f(1, 1, 1, 1);
    ccColor4F boxCol=ccc4f(1, 1, 1, 0.5f);
    float lineRad=3.0f;
    
    [drawNode clear];
    
    [drawNode drawSegmentFrom:ccp(xInset, yInset-25.0f) to:ccp(xInset+barW, yInset-25.0f) radius:lineRad color:lineCol];
    
    CGPoint verts[4];
    verts[0]=ccp(100,350);
    verts[1]=ccp(100,450);
    verts[2]=ccp(924,450);
    verts[3]=ccp(924,350);
    
    CGPoint *firstVert=&verts[0];
    
    [drawNode drawPolyWithVerts:firstVert count:4 fillColor:ccc4f(1, 1, 1, 0.5f) borderWidth:3 borderColor:ccc4f(1, 1, 1, 1)];
    
    
    int magOrder=[self magnitudeOf:(int)currentTotal];
    int sigFigs=0;
    float magMult=pow(10, magOrder-1);
    NSString *digits=[NSString stringWithFormat:@"%f", currentTotal];
    for(int i=0; i<digits.length && sigFigs<columnsInPicker; i++)
    {
        NSString *c=[[digits substringFromIndex:i] substringToIndex:1];
        if([c isEqualToString:@"0"])
        {
            if(sigFigs)
            {
                magMult=magMult / 10.0f;
            }
        }
        else if([c isEqualToString:@"."])
        {
            sigFigs++;
            //do nothing, just skip past on to the next column
        }
        else
        {
            NSLog(@"%@ x %f x pval", c, magMult);
            sigFigs++;
            magMult=magMult / 10.0f;
        }
    }
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    dividend=[[pdef objectForKey:DIVIDEND] floatValue];
    divisor=[[pdef objectForKey:DIVISOR] floatValue];
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    goodBadHighlight=[[pdef objectForKey:GOOD_BAD_HIGHLIGHT] boolValue];
    renderBlockLabels=[[pdef objectForKey:RENDERBLOCK_LABELS] boolValue];
    
    columnsInPicker=[[pdef objectForKey:COLUMNS_IN_PICKER]intValue];
    
    
    labelInfo=[[NSMutableDictionary alloc]init];
    
}

-(void)populateGW
{
//
    renderedBlocks=[[NSMutableArray alloc]init];
    
    
    // add the big multiplier behind the numbers
    CCLabelTTF *multiplier=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"x%g",divisor] fontName:SOURCE fontSize:200.0f];
    [multiplier setPosition:ccp(820,202)];
    [multiplier setOpacity:25];
    [renderLayer addChild:multiplier];
    
    lblCurrentTotal=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
    [lblCurrentTotal setPosition:ccp(cx,50)];
    [renderLayer addChild:lblCurrentTotal];


    
    [self setupNumberWheel];
}

-(void)setupNumberWheel
{
    DWNWheelGameObject *w=[DWNWheelGameObject alloc];
    [gw populateAndAddGameObject:w withTemplateName:@"TnumberWheel"];
    w.Components=columnsInPicker;
    w.Position=ccp(lx-150,580);
    w.RenderLayer=renderLayer;
    w.SpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ov.png", w.Components];
    w.HasDecimals=YES;
    w.HasNegative=YES;
    [w handleMessage:kDWsetupStuff];
    nWheel=w;
}

-(int)magnitudeOf:(int)thisNo
{
    int no=thisNo;
    int mag=0;
    
    while(no>0)
    {
        mag++;
        no=no/10;
    }
    
    return mag;
}



#pragma mark - touches events



#pragma mark - evaluation

-(void)evalProblem
{
    if(expressionIsEqual)
    {
        hasEvaluated=YES;
        [toolHost doWinning];
    }
    else {
        if(evalMode==kProblemEvalOnCommit)
        {
            [toolHost showProblemIncompleteMessage]; 
            [toolHost resetProblem];
        }
    }
    
}

#pragma mark - meta question align
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

-(void) dealloc
{
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [renderLayer release];
        
    //tear down
    if(numberRows)[numberRows release];
    if(numberLayers)[numberLayers release];
    if(renderedBlocks)[renderedBlocks release];
    if(labelInfo)[labelInfo release];
    
    [gw release];
    
    [super dealloc];
}
@end