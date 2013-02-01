//
//  LongDivision.m
//  belugapad
//
//  Created by David Amphlett on 25/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "LongDivision.h"
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

@interface LongDivision()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation LongDivision

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
        
        [self setupClippingNode];
        
        renderingChanges=YES;
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
    
        gw.Blackboard.inProblemSetup = NO;
        
        drawNode=[[CCDrawNode alloc] init];
        scaleDrawNode=[[CCDrawNode alloc] init];
        [self.ForeLayer addChild:drawNode];
        [clippingNode addChild:scaleDrawNode];
//        [self createClippingNode];
    }
    
    return self;
}

-(void)setupClippingNode
{
    spriteMask=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Magnify_Mask.png")];
    maskOuter=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Magnify_Glass.png")];
    
    magnifyBar=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Magnify_Bar_Full.png")];

    
    clippingNode=[CCClippingNode clippingNode];
    clippingNode.contentSize=CGSizeMake(2*cx, 2*cy);
    clippingNode.anchorPoint=ccp(0.5f,0.5f);
    clippingNode.position=ccp(cx,cy);
    clippingNode.stencil=spriteMask;
    //clippingNode.alphaThreshold=0.05f;

    spriteMask.position=ccp(800,130);
    maskOuter.position=ccp(800,150);
    [magnifyBar setPosition:ccp(150,74)];
    [clippingNode addChild:magnifyBar];
    [clippingNode addChild:spriteMask];

    [self.ForeLayer addChild:clippingNode];
    [self.ForeLayer addChild:maskOuter];
    
    [clippingNode setVisible:NO];
    [magnifyBar setOpacity:0];
    [spriteMask setOpacity:0];
    [maskOuter setOpacity:0];
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
    
    if(lastTotal!=currentTotal)
    {
        if(currentTotal>lastTotal && currentTotal<(dividend/divisor) && !expressionIsEqual)
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_long_division_general_growing_block.wav")];
        
        lastTotal=currentTotal;
        renderingChanges=YES;
        
        [loggingService logEvent:BL_PA_LD_TOUCH_END_CHANGE_WHEEL_VALUE withAdditionalData:[NSNumber numberWithFloat:currentTotal]];
    }
    
    
    
    if(expressionIsEqual && !audioHasPlayedOnTarget)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_long_division_general_target_reached.wav")];
        audioHasPlayedOnTarget=YES;
        audioHasPlayedOverTarget=NO;
    }
    else if(currentTotal>(dividend/divisor) && !audioHasPlayedOverTarget){
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_long_division_general_block_over_target.wav")];
        audioHasPlayedOverTarget=YES;
        audioHasPlayedOnTarget=NO;
    }
    else if(currentTotal<(dividend/divisor))
    {
        audioHasPlayedOnTarget=NO;
        audioHasPlayedOverTarget=NO;
    }
    // this sets the good/bad sum indicator if the mode is enabled
    if(goodBadHighlight)
    {
        if(expressionIsEqual)
        {
            [lblCurrentTotal setColor:ccc3(0, 255,0)];
        }else{
            [lblCurrentTotal setColor:ccc3(255,0,0)];
        }
    }
    
    // then update the actual text of it
    [lblCurrentTotal setString:[NSString stringWithFormat:@"%g", currentTotal]];
    
    if(renderingChanges){
        [self removeCurrentLabels];
        [self drawState];
    }
    if(evalMode==kProblemEvalAuto && !hasEvaluated)
        [self evalProblem];
    
}

-(void)removeCurrentLabels
{
    for(CCLabelTTF *l in allLabels)
    {
        [l removeFromParentAndCleanup:YES];
    }
    
    for(CCSprite *s in allSprites)
    {
        [s removeFromParentAndCleanup:YES];
    }
}

-(void)drawState
{
    float expTotal=(dividend/divisor);
    float visTrigger=expTotal*0.8;
    if(!clippingNode.visible && currentTotal>=visTrigger)
    {
        [magnifyBar setOpacity:0];
        [spriteMask setOpacity:0];
        [maskOuter setOpacity:0];
        [clippingNode setVisible:YES];
        [magnifyBar runAction:[CCFadeIn actionWithDuration:1.0f]];
        [spriteMask runAction:[CCFadeIn actionWithDuration:1.0f]];
        [maskOuter runAction:[CCFadeIn actionWithDuration:1.0f]];
    }
    else if(clippingNode.visible && currentTotal<visTrigger)
    {
        [clippingNode setVisible:NO];
        [magnifyBar runAction:[CCFadeOut actionWithDuration:1.0f]];
        [spriteMask runAction:[CCFadeOut actionWithDuration:1.0f]];
        [maskOuter runAction:[CCFadeOut actionWithDuration:1.0f]];
    }
    
    float xInset=100.0f;
    float yInset=362.0f;
    float barW=824.0f;
    float barH=60.0f;
    float startBarPos=xInset;
    float endBarPos;
    float lblStartYPos=yInset-80;
    float labelFontSize=26.0f;
    float lineSize=0.0f;
    float tblSpriteSize=50;
    float lblStartXPos=xInset+tblSpriteSize;
    
    int colIndex=nWheel.Components;
    
    [drawNode clear];
    [scaleDrawNode clear];
    [scaleDrawNode setPosition:ccp(-760,-570)];


    int magOrder=[self magnitudeOf:(int)currentTotal];
    int sigFigs=0;
    float magMult=pow(10, magOrder-1);
    NSString *digits=[NSString stringWithFormat:@"%g", currentTotal];
    BOOL gotZeroRow=NO;
    BOOL drawShadow=NO;
    for(int i=0; i<digits.length && sigFigs<columnsInPicker; i++)
    {
        NSString *c=[[digits substringFromIndex:i] substringToIndex:1];
        NSLog(@"colIndex %d, curNum=%@, i=%d digitsL=%d comp=%d", colIndex, c, i, digits.length, digits.length-i);
        if([c isEqualToString:@"0"])
        {
            if(currentTotal==0 && !gotZeroRow)
            {
                gotZeroRow=YES;
                CCSprite *s=nil;
                for(int i=0;i<4;i++)
                {
                    NSString *str=nil;
                    
                    if(i==0)
                        str=[NSString stringWithFormat:@"%g", [c floatValue]*magMult];
                    else if(i==1)
                        str=@"x";
                    else if(i==2)
                        str=[NSString stringWithFormat:@"%g", divisor];
                    else if(i==3)
                        str=[NSString stringWithFormat:@"%g", ([c floatValue]*magMult)*divisor];
                    
                    s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Table_Item.png")];
                    [s setPosition:ccp(lblStartXPos, lblStartYPos)];
                    [renderLayer addChild:s];
                    [allSprites addObject:s];
                    
                    //CCLabelTTF *l=[CCLabelTTF labelWithString:str fontName:CHANGO fontSize:30.0f];
                    CCLabelTTF *l=[CCLabelTTF labelWithString:str fontName:CHANGO fontSize:labelFontSize dimensions:CGSizeMake(s.contentSize.width-8,s.contentSize.height) hAlignment:UITextAlignmentRight vAlignment:UIBaselineAdjustmentAlignCenters];
                    [l setAnchorPoint:ccp(0.5,0.5)];
                    [l setPosition:ccp(lblStartXPos, lblStartYPos)];
                    [renderLayer addChild:l];
                    [allLabels addObject:l];
                    
                    lblStartXPos=lblStartXPos+(s.contentSize.width*1.03);
                }
                
                lblStartYPos=lblStartYPos-(s.contentSize.height*1.05);
                
                colIndex--;
                //NSLog(@"%@ x %f x pval", c, magMult);
                sigFigs++;
                magMult=magMult / 10.0f;
            }
            
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
            gotZeroRow=YES;
            drawShadow=YES;
            // declare our positional variables for drawing
            endBarPos=startBarPos+((divisor*magMult)*[c floatValue]/dividend*barW);
            float sectionSize=(endBarPos-startBarPos)/[c floatValue];
            float sectionStartPos=startBarPos+sectionSize;
            lineSize+=((divisor*magMult)*[c floatValue]/dividend*barW);
            lblStartXPos=xInset+tblSpriteSize;
            
            // and out points for drawing
            CGPoint block[4];
            block[0]=ccp(startBarPos,yInset);
            block[1]=ccp(startBarPos,yInset+barH);
            block[2]=ccp(endBarPos,yInset+barH);
            block[3]=ccp(endBarPos,yInset);
            
            // change the startbar pos
            startBarPos=startBarPos+(endBarPos-startBarPos);
            
            // draw the upper label
            
            //if(fabsf([c intValue]-([c floatValue]*magMult))==0)
            //{
            float thisVal=([c floatValue]*divisor)*magMult;
            
            float rem=thisVal-(int)thisVal;
            if(rem==0)
            {
                CCSprite *m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Label_Line.png")];
                [m setPosition:ccp(endBarPos,yInset+barH+15)];
                [renderLayer addChild:m];
                [allSprites addObject:m];
        

                CCLabelTTF *u=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", thisVal] fontName:CHANGO fontSize:labelFontSize*0.9];
                [u setPosition:ccp(endBarPos,yInset+barH+m.contentSize.height+15)];
                [renderLayer addChild:u];
                [allLabels addObject:u];
            }
            
            CGPoint *firstCo=&block[0];
            ccColor3B curCol;
            ccColor3B sepLine=ccc3(68,71,72);
            ccColor4F sepLine4=ccc4FFromccc3B(sepLine);
            sepLine4=ccc4f(sepLine4.r, sepLine4.g, sepLine4.b, (float)maskOuter.opacity/255);
            
            if(currentTotal>(dividend/divisor))
                curCol=ccc3(255,0,0);
            else
                curCol=kLongDivColour[(digits.length-i)-1];
            
            ccColor4F curCol4=ccc4FFromccc3B(curCol);
            curCol4=ccc4f(curCol4.r, curCol4.g, curCol4.b, (float)maskOuter.opacity/255);
            
            // draw the current block
            [drawNode drawPolyWithVerts:firstCo count:4 fillColor:ccc4FFromccc3B(curCol) borderWidth:1 borderColor:ccc4FFromccc3B(curCol)];
            
            [scaleDrawNode drawPolyWithVerts:firstCo count:4 fillColor:curCol4 borderWidth:1 borderColor:curCol4];
            
            // and all of it's separators
            for(int i=0;i<[c intValue];i++)
            {
                if(i<[c intValue]-1){
                    [drawNode drawSegmentFrom:ccp(sectionStartPos,block[0].y-1) to:ccp(sectionStartPos,block[1].y+1) radius:0.5f color:ccc4FFromccc3B(sepLine)];
                    [scaleDrawNode drawSegmentFrom:ccp(sectionStartPos,block[0].y-1) to:ccp(sectionStartPos,block[1].y+1) radius:0.5f color:sepLine4];
                    sectionStartPos+=sectionSize;
                }
//                float curTot=0;
                
//                if(rem>0)
//                {
//                    curTot+=((i+1)*magMult)*divisor;
//                    NSLog(@"thislabel %g", curTot);
////                    float barStart=magnifyBar.position.x-((magnifyBar.contentSize.width*magnifyBar.scale)/2);
//                    CGPoint relPos=[clippingNode convertToNodeSpace:ccp(sectionStartPos,block[1].y)];
//                    CCSprite *m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Label_Line.png")];
//                    //[m setPosition:ccp(barStart+(lineSize*scaleDrawNode.scale),magnifyBar.position.y+(barH*scaleDrawNode.scale)+m.contentSize.height)];
//                    [m setPosition:ccp(relPos.x,relPos.y+5)];
//                    [clippingNode addChild:m];
//                    [allSprites addObject:m];
//                    
//                    CCLabelTTF *u=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", curTot] fontName:CHANGO fontSize:10.0f];
//                    //[u setPosition:ccp(barStart+(lineSize*scaleDrawNode.scale),magnifyBar.position.y+(barH*scaleDrawNode.scale)+m.contentSize.height+15)];
//                    [u setPosition:ccp(relPos.x,relPos.y+10)];
//                    [scaleDrawNode addChild:u];
//                    [allLabels addObject:u];
//                }
            }

            // and the labelling stuffs
            CCSprite *s=nil;
            for(int i=0;i<4;i++)
            {
                NSString *str=nil;
                
                if(i==0 && magMult>=1)
                    str=[NSString stringWithFormat:@"%g", [c floatValue]];
                else if(i==0 && magMult<1)
                    str=[NSString stringWithFormat:@"%g", [c floatValue]*magMult];
                else if(i==1)
                    str=@"x";
                else if(i==2)
                    str=[NSString stringWithFormat:@"%g", magMult*divisor];
                else if(i==3)
                    str=[NSString stringWithFormat:@"%g", ([c floatValue]*magMult)*divisor];
                
                s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Table_Item.png")];
                [s setPosition:ccp(lblStartXPos, lblStartYPos)];
                [renderLayer addChild:s];
                [allSprites addObject:s];
                
                //CCLabelTTF *l=[CCLabelTTF labelWithString:str fontName:CHANGO fontSize:30.0f];
                CCLabelTTF *l=[CCLabelTTF labelWithString:str fontName:CHANGO fontSize:labelFontSize dimensions:CGSizeMake(s.contentSize.width-8,s.contentSize.height) hAlignment:UITextAlignmentRight vAlignment:UIBaselineAdjustmentAlignCenters];
                [l setAnchorPoint:ccp(0.5,0.5)];
                [l setPosition:ccp(lblStartXPos, lblStartYPos)];
                [renderLayer addChild:l];
                [allLabels addObject:l];
                
                lblStartXPos=lblStartXPos+(s.contentSize.width*1.03);
            }
            
            lblStartYPos=lblStartYPos-(s.contentSize.height*1.05);
            
            colIndex--;
            //NSLog(@"%@ x %f x pval", c, magMult);
            sigFigs++;
            magMult=magMult / 10.0f;
        }
    }
    
    if(drawShadow){
        CGPoint verts[4];
        verts[0]=ccp(xInset-1,yInset-1);
        verts[1]=ccp(xInset-1,yInset+1);
        verts[2]=ccp(xInset+lineSize,yInset+1);
        verts[3]=ccp(xInset+lineSize,yInset-1);
        float myOpac=(maskOuter.opacity/255)*100;
        
        
        CGPoint *firstVert=&verts[0];
        [drawNode drawPolyWithVerts:firstVert count:4 fillColor:ccc4FFromccc4B(ccc4(22, 22, 22, 100)) borderWidth:0 borderColor:ccc4FFromccc4B(ccc4(22, 22, 22, 100))];
        [scaleDrawNode drawPolyWithVerts:firstVert count:4 fillColor:ccc4FFromccc4B(ccc4(22, 22, 22, myOpac)) borderWidth:0 borderColor:ccc4FFromccc4B(ccc4(22, 22, 22, myOpac))];
        
    }
    
    if(currentTotal>0){
    
        CCSprite *tot=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Table_Total.png")];
        [tot setPosition:ccp(xInset+tblSpriteSize+((tot.contentSize.width*1.03)*3), lblStartYPos)];
        [renderLayer addChild:tot];
        [allSprites addObject:tot];
        
        CCLabelTTF *lTot=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", currentTotal*divisor] fontName:CHANGO fontSize:labelFontSize dimensions:CGSizeMake(tot.contentSize.width-8,tot.contentSize.height) hAlignment:UITextAlignmentRight vAlignment:UIBaselineAdjustmentAlignCenters];

        [lTot setAnchorPoint:ccp(0.5,0.5)];
        [lTot setPosition:ccp(xInset+tblSpriteSize+((tot.contentSize.width*1.03)*3), lblStartYPos)];
        [renderLayer addChild:lTot];
        [allLabels addObject:lTot];
    }
    

    scaleDrawNode.scale=1.8f;
    
    renderingChanges=NO;
    
    if(clippingNode.visible && currentTotal>=visTrigger && maskOuter.opacity<255)
        renderingChanges=YES;
    
    NSLog(@"maskOuter.opacity %f", (float)maskOuter.opacity);
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
    
    goodBadHighlight=NO;
    
    [usersService notifyStartingFeatureKey:@"LONGDIVISION_INTRO"];
}

-(void)populateGW
{
    renderedBlocks=[[NSMutableArray alloc]init];
    allLabels=[[NSMutableArray alloc]init];
    allSprites=[[NSMutableArray alloc]init];
    
    CCSprite *barBg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Bar_Background.png")];
    [barBg setPosition:ccp(cx,405)];
    [renderLayer addChild:barBg];
    
    CCSprite *barUnderneathThing=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Bar.png")];
    [barUnderneathThing setPosition:ccp(cx, 356)];
    [renderLayer addChild:barUnderneathThing];
    
    CCLabelTTF *zeroLabel=[CCLabelTTF labelWithString:@"0" fontName:CHANGO fontSize:26.0f];
    [zeroLabel setPosition:ccp(barUnderneathThing.position.x-barUnderneathThing.contentSize.width/2, barUnderneathThing.position.y-20)];
    [renderLayer addChild:zeroLabel];
    
    CCLabelTTF *expectedLabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g",dividend] fontName:CHANGO fontSize:26.0f];
    [expectedLabel setPosition:ccp(barUnderneathThing.position.x+barUnderneathThing.contentSize.width/2, barUnderneathThing.position.y-20)];
    [renderLayer addChild:expectedLabel];
    
    [self setupNumberWheel];
    
    for(int i=0;i<nWheel.Components;i++)
    {
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_NW_Label.png")];
        [s setPosition:ccp(963.5-(i*(nWheel.ComponentWidth+(nWheel.ComponentSpacing))),568)];
        [s setColor:kLongDivColour[i]];
        [renderLayer addChild:s z:50];
    }
    
    lastTotal=currentTotal;
}

-(void)setupNumberWheel
{
    DWNWheelGameObject *w=[DWNWheelGameObject alloc];
    [gw populateAndAddGameObject:w withTemplateName:@"TnumberWheel"];
    w.Components=columnsInPicker;
    w.SpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ov.png", w.Components];
    w.UnderlaySpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ul.png", w.Components];
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(w.SpriteFileName)];
    
    w.ComponentHeight=62;
    w.ComponentWidth=71;
    w.ComponentSpacing=6;
    w.Position=ccp(lx-w.ComponentSpacing-(s.contentSize.width/2),ly-150);
    w.RenderLayer=renderLayer;
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

-(void)createClippingNode
{
    CCClippingNode *clipper = [CCClippingNode clippingNode];
    clipper.contentSize = CGSizeMake(200, 200);
    clipper.anchorPoint = ccp(0.5, 0.5);
    clipper.position = ccp(800,500);
    [renderLayer addChild:clipper];
    
    CCDrawNode *stencil = [CCDrawNode node];
    CGPoint rectangle[] = {{0, 0}, {clipper.contentSize.width, 0}, {clipper.contentSize.width, clipper.contentSize.height}, {0, clipper.contentSize.height}};
    ccColor4F white = {1, 1, 1, 1};
    [stencil drawPolyWithVerts:rectangle count:4 fillColor:white borderWidth:1 borderColor:white];
    clipper.stencil = stencil;
    
    CCSprite *content = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/longdivision/LD_Magnify_Glass.png")];
    content.anchorPoint = ccp(0.5, 0.5);
    content.position = ccp(clipper.contentSize.width / 2, clipper.contentSize.height / 2);
    [clipper addChild:content];
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
