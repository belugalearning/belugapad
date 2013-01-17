//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MQDisplay.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"
#import "LoggingService.h"
#import "AppDelegate.h"

#import "NumberLayout.h"

#import "SGGameWorld.h"
#import "SGFBlockObjectProtocols.h"
#import "SGFBlockBlock.h"
#import "SGFBlockBubble.h"
#import "SGFBlockOpBubble.h"
#import "SGFBlockGroup.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"

//CCPickerView
#define kComponentWidth 54
#define kComponentHeight 32
#define kComponentSpacing 0

@interface MQDisplay()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;
    
}

@end

@implementation MQDisplay

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
        
        gw = [[SGGameWorld alloc] initWithGameScene:renderLayer];
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

    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    initVisuals=[pdef objectForKey:DISPLAY];
    [initVisuals retain];
}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;
    sectionWidth=lx/[initVisuals count];
    [self setupVisuals];
}

-(void)setupVisuals
{
    for(int i=0;i<[initVisuals count];i++)
    {
        NSDictionary *d=[initVisuals objectAtIndex:i];
        // s = string from pdef
        // cS = column string (A/B/C)
        // cL = column answer label
        // a = 'answer' label
        
        NSString *s=[d objectForKey:LABEL];
        NSString *cS=[d objectForKey:STRING];
        
        CCLabelTTF *a=[CCLabelTTF labelWithString:s fontName:SOURCE fontSize:50.0f];
        [a setPosition:ccp((i+0.5)*sectionWidth, 500)];
        [renderLayer addChild:a];
        
        CCLabelTTF *cL=[CCLabelTTF labelWithString:cS fontName:SOURCE fontSize:80.0f dimensions:CGSizeMake(sectionWidth*0.7, 100) hAlignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeWordWrap];
        [cL setPosition:ccp((i+0.5)*sectionWidth, 400)];
        [renderLayer addChild:cL];
    }
}

#pragma mark - touches events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
    
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
    [initVisuals release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
