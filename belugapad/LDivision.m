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

const float kSpaceBetweenNumbers=280.0f;
const float kSpaceBetweenRows=80.0f;
const float kRenderBlockWidth=1000.0f;
const float kScaleOfLesserBlocks=0.6f;

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
        self.NoScaleLayer=[[CCLayer alloc]init];
        topSection=[[CCLayer alloc]init];
        bottomSection=[[CCLayer alloc]init];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolNoScaleLayer:self.NoScaleLayer];
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
    
    [self createAndUpdateLabels];
    // then update the actual text of it
    [lblCurrentTotal setString:[NSString stringWithFormat:@"%g", currentTotal]];
    

    float thisNum=[nWheel.StrOutputValue floatValue];

    

    if(evalMode==kProblemEvalAuto && !hasEvaluated)
        [self evalProblem];
    
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
    [renderLayer addChild:topSection];
    [renderLayer addChild:bottomSection];
    

    renderedBlocks=[[NSMutableArray alloc]init];
    
    
    // add the big multiplier behind the numbers
    CCLabelTTF *multiplier=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"x%g",divisor] fontName:SOURCE fontSize:200.0f];
    [multiplier setPosition:ccp(820,202)];
    [multiplier setOpacity:25];
    [renderLayer addChild:multiplier];
    
    lblCurrentTotal=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
    [lblCurrentTotal setPosition:ccp(cx,50)];
    [renderLayer addChild:lblCurrentTotal];
    
    line=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/LDivision/LD_Bar.png")];
    [line setPosition:ccp(cx,450)];
    [topSection addChild:line];
    


    // set up start and end marker
    startMarker=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/LDivision/marker.png")];
    endMarker=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/LDivision/marker.png")];
    [startMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x-(line.contentSize.width/2)+5, line.position.y)]];
    [endMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x+(line.contentSize.width/2)-5, line.position.y)]];
    CCLabelTTF *start=[CCLabelTTF labelWithString:@"0" fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
    CCLabelTTF *end=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", dividend] fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
    [start setPosition:ccp(10,60)];
    [end setPosition:ccp(10,60)];
    [startMarker addChild:start];
    [endMarker addChild:end];
    
    [self.NoScaleLayer addChild:startMarker];
    [self.NoScaleLayer addChild:endMarker];

    
    [self setupNumberWheel];
    
    //[self createVisibleNumbers];
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
    //    w.InputValue=000;
    //    w.OutputValue=w.InputValue;
    //    [w handleMessage:kDWupdateObjectData];
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

-(void)createAndUpdateLabels
{
    for(NSString *key in labelInfo)
    {
        NSMutableDictionary *d=[labelInfo objectForKey:key];
        
        int selected=[[d objectForKey:SELECTED]intValue];
        
        if(![d objectForKey:LABEL])
        {
            if(selected>0)
            {
                CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@ x %d = %d", key, selected, [key intValue]*selected] fontName:CHANGO fontSize:40.0f];
                [d setObject:l forKey:LABEL];
                [l setPosition:ccp(150,cx-(40*[[labelInfo allKeys]indexOfObject:key]))];
                [renderLayer addChild:l];
                
                // create a label
            }
        }
        else
        {
            CCLabelTTF *l=[d objectForKey:LABEL];
            if(selected==0)
            {
                [l removeFromParentAndCleanup:YES];
                [d removeObjectForKey:LABEL];
                // remove the label
            }
            else if(selected>0)
            {
                [l setPosition:ccp(150,cx-(40*[[labelInfo allKeys]indexOfObject:key]))];
                [l setString:[NSString stringWithFormat:@"%@ x %d = %d", key, selected, [key intValue]*selected]];
            }
        }
        
    }
}

#pragma mark - render interaction
-(void)updateLabels:(CGPoint)position
{
    [markerText setString:[NSString stringWithFormat:@"%g", currentTotal*divisor]];
    //    [marker setPosition:[topSection convertToWorldSpace:position]];
    [marker setPosition:position];
    [startMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x-(line.contentSize.width/2)+2, line.position.y)]];
    [endMarker setPosition:[topSection convertToWorldSpace:ccp(line.position.x+(line.contentSize.width/2)-2, line.position.y)]];
}



#pragma mark - touches events


-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToWorldSpace:location];
    lastTouch=location;
    touchStart=location;
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    //NSMutableDictionary *pl=[NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGPoint:location] forKey:POS];
    
    lastTouch=location;
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    //returns YES if the tool expression evaluates succesfully
    return YES;
    
}

-(void)evalProblem
{
    BOOL isWinning=expressionIsEqual;
    
    if(isWinning)
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
    [self.NoScaleLayer release];
    
    [topSection release];
    [bottomSection release];
    
    //tear down
    if(numberRows)[numberRows release];
    if(numberLayers)[numberLayers release];
    if(renderedBlocks)[renderedBlocks release];
    if(labelInfo)[labelInfo release];
    
    [gw release];
    
    [super dealloc];
}
@end
