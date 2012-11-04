//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExprBuilder.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"

#import "SGGameWorld.h"

#import "SGBtxeRow.h"
#import "SGBtxeText.h"
#import "SGBtxeObjectText.h"
#import "SGBtxeMissingVar.h"
#import "SGBtxeContainerMgr.h"
#import "SGBtxeObjectNumber.h"

@interface ExprBuilder()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;

}

@end

@implementation ExprBuilder

#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] view].multipleTouchEnabled=NO;
        
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
        
        rows=[[NSMutableArray alloc]init];
        
        [self readPlist:pdef];
        [self populateGW];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

#pragma mark - loops

-(void)doUpdate:(ccTime)delta
{
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
}

-(void)draw
{
    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    evalType=[pdef objectForKey:EVAL_TYPE];
    
    if([pdef objectForKey:@"EXPR_STAGES"])
    {
        exprStages=[[pdef objectForKey:@"EXPR_STAGES"] copy];
    }
    else
    {
        @throw [NSException exceptionWithName:@"expr plist read exception" reason:@"EXPR_STAGES not found" userInfo:nil];
    }
    
    NSNumber *rrow2=[pdef objectForKey:@"REPEAT_ROW2_X"];
    if(rrow2)repeatRow2Count=[rrow2 intValue];
    
    NSNumber *urowmax=[pdef objectForKey:@"USER_REPEAT_ROW2_TOMAX_X"];
    if(urowmax)userRepeatRow2Max=[rrow2 intValue];
    
    NSNumber *ncardmin=[pdef objectForKey:@"NUMBER_CARD_ROW_MIN"];
    NSNumber *ncardmax=[pdef objectForKey:@"NUMBER_CARD_ROW_MAX"];
    NSNumber *ncardint=[pdef objectForKey:@"NUMBER_CARD_INTERVAL"];
    
    if(ncardmax && ncardmin && ncardint)
    {
        presentNumberCardRow=YES;
        numberCardRowInterval=[ncardint intValue];
        numberCardRowMax=[ncardmax intValue];
        numberCardRowMin=[ncardmin intValue];
        
        NSNumber *ncardrandomise=[pdef objectForKey:@"NUMBER_CARD_RANDOMISE"];
        if(ncardrandomise)numberCardRandomOrder=[ncardrandomise boolValue];
    }
    
}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;
    
    //number of expression stages
    int rowcount=[exprStages count];
    
    //repeat number of expressions stages
    if(repeatRow2Count>0 && rowcount==2) rowcount=repeatRow2Count+1;
    
    float row0base=2*cy;
    float rowSpace=row0base / (rowcount+1);
    
    // iterate and create rows
    for(int i=0; i<rowcount; i++)
    {
        SGBtxeRow *row=[[SGBtxeRow alloc] initWithGameWorld:gw andRenderLayer:self.ForeLayer];
        [rows addObject:row];
        
        if(i==0 || repeatRow2Count==0)
        {
            [row parseXML:[exprStages objectAtIndex:i]];
        }
        else if (repeatRow2Count>0)
        {
            [row parseXML:[exprStages objectAtIndex:1]];
        }
        
        
        [row setupDraw];
        
        
        if(i==0)
        {
            //position at top, top aligned, with spacer underneath
            row.position=ccp(cx, (cy*2) - 95);
            row.forceVAlignTop=YES;
            
            //question separator bar -- flow with bottom of row 0
            CCSprite *questionSeparatorSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/Question_Separator.png")];
            [self.ForeLayer addChild:questionSeparatorSprite];
            
            
            //build the ncard row if we have one
            if(presentNumberCardRow)
            {
                ncardRow=[[SGBtxeRow alloc] initWithGameWorld:gw andRenderLayer:self.ForeLayer];
                
                NSMutableArray *cardAddBuffer=[[NSMutableArray alloc] init];
                
                //add the cards
                for(int icard=numberCardRowMin; icard<=numberCardRowMax; icard+=numberCardRowInterval)
                {
                    SGBtxeObjectNumber *n=[[SGBtxeObjectNumber alloc] initWithGameWorld:gw];
                    n.numberText=[NSString stringWithFormat:@"%d", icard];
                    n.enabled=YES;
                    
                    [cardAddBuffer addObject:n];
                    [n release];
                }
                
                if(numberCardRandomOrder)
                {
                    while(cardAddBuffer.count>0)
                    {
                        int i=(arc4random()%cardAddBuffer.count);
                        [ncardRow.containerMgrComponent addObjectToContainer:[cardAddBuffer objectAtIndex:i]];
                        [cardAddBuffer removeObjectAtIndex:i];
                    }
                }
                else
                {
                    for(SGBtxeObjectNumber *n in cardAddBuffer)
                        [ncardRow.containerMgrComponent addObjectToContainer:n];
                }
                
                //let go of the buffer
                [cardAddBuffer release];
                
                [ncardRow setupDraw];
                ncardRow.position=ccpAdd(row.position, ccp(0, -ncardRow.size.height-QUESTION_SEPARATOR_PADDING));
            }
            
            float sepYpos=-(row.size.height) - QUESTION_SEPARATOR_PADDING;
            
            //add extra padding if we're going to do a number card wheel
            if(presentNumberCardRow)
            {
                sepYpos-=ncardRow.size.height - (QUESTION_SEPARATOR_PADDING*2);
            }
            
            questionSeparatorSprite.position=ccpAdd(row.position, ccp(0, sepYpos));
            
            row0base=questionSeparatorSprite.position.y-QUESTION_SEPARATOR_PADDING;
            rowSpace=row0base / (rowcount + 1);
        }
        else
        {
            //distribute in available space
            row.position = ccp(cx, row0base - (i*rowSpace));
        }

        
        [row release];
    }
    
    
    //if we have ncardrow, then add it to rows (at end for now?)
    if(ncardRow) [rows addObject:ncardRow];
    
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
    lastTouch=location;
    
    if(isHoldingObject) return;  // no multi-touch but let's be sure

    for(id<MovingInteractive, NSObject> o in gw.AllGameObjects)
    {
        if([o conformsToProtocol:@protocol(MovingInteractive)])
        {
            id<Bounding> obounding=(id<Bounding>)o;
            CGRect hitbox=CGRectMake(obounding.worldPosition.x - (BTXE_OTBKG_WIDTH_OVERDRAW_PAD + obounding.size.width) / 2.0f, obounding.worldPosition.y-BTXE_VPAD-(obounding.size.height / 2.0f), obounding.size.width + BTXE_OTBKG_WIDTH_OVERDRAW_PAD, obounding.size.height + 2*BTXE_VPAD);
            
            if(o.enabled && CGRectContainsPoint(hitbox, location))
            {
                heldObject=o;
                isHoldingObject=YES;
                
                [(id<MovingInteractive>)o inflateZIndex];
                
                for(SGBtxeRow *r in rows)
                {
                    if([r containsObject:o]) [r inflateZindex];
                }
            }
        }
    }
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;

    if(isHoldingObject)
    {
        //track that object's position
        heldObject.worldPosition=location;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
    if(heldObject)
    {
        //test new location for target / drop
        for(id<Interactive, NSObject> o in [gw AllGameObjectsCopy])
        {
            if([o conformsToProtocol:@protocol(Interactive)])
            {
                if(!o.enabled
                   && [heldObject.tag isEqualToString:o.tag]
                   && [BLMath DistanceBetween:o.worldPosition and:location]<=BTXE_PICKUP_PROXIMITY)
                {
                    //this object is proximate, disabled and the same tag
                    [o activate];
                }
                
                if([o conformsToProtocol:@protocol(BtxeMount)] && [BLMath DistanceBetween:o.worldPosition and:location]<=BTXE_PICKUP_PROXIMITY)
                {
                    id<BtxeMount, Interactive> pho=(id<BtxeMount, Interactive>)o;
                    
                    //mount the object on the place holder
                    [pho duplicateAndMountThisObject:(id<MovingInteractive, NSObject>)heldObject];

                    //move this to the mount's position
                    heldObject.position=pho.position;
                }
            }
        }
        
        [heldObject returnToBase];
        
        [heldObject deflateZindex];
        for(SGBtxeRow *r in rows)
        {
            [r deflateZindex];
        }
        
        heldObject=nil;
        isHoldingObject=NO;
    }
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    // empty selected objects
    
    if(heldObject)
        [heldObject deflateZindex];
    
    for(SGBtxeRow *r in rows)
    {
        [r deflateZindex];
    }
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    if([evalType isEqualToString:@"ALL_ENABLED"])
    {
        //check for interactive components that are disabled -- if in that mode
        for(SGGameObject *o in gw.AllGameObjects)
        {
            if([o conformsToProtocol:@protocol(Interactive)])
            {
                id<Interactive> io=(id<Interactive>)o;
                if(io.enabled==NO)
                {
                    //first disbled element fails the evaluation
                    return NO;
                }
            }
        }

        //none found, assume yes
        return YES;
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
        self.ProblemComplete=YES;
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
    [exprStages release];
    if(ncardRow)[ncardRow release];
    [rows release];
    
    //write log on problem switch
    
    [renderLayer release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
