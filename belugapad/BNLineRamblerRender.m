//
//  BNLineRamblerRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNLineRamblerRender.h"
#import "DWRamblerGameObject.h"
#import "global.h"
#import "BLMath.h"

//static float kIndicatorYOffset=15.0f;
static float kIndicatorYOffset=0.0f;

//static float kLabelOffset=-170.0f;
static float kLabelOffset=0.0f;
static NSString *kLabelFont=@"visgrad1.fnt";

@implementation BNLineRamblerRender

-(BNLineRamblerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineRamblerRender*)[super initWithGameObject:aGameObject withData:data];
    
    ramblerGameObject=(DWRamblerGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        [self setupStuff];
    }
    
    if(messageType==kDWnlineReleaseRamblerAtOffset)
    {
        //clean up rendering stuff
        //labels
//        NSMutableArray *cleanLabels=[[NSMutableArray alloc] init];
//        
//        for(NSNumber *key in [assLabels allKeys])
//        {
//            CCLabelBMFont *l=[assLabels objectForKey:key];
//            if(!l.visible) [cleanLabels addObject:key];
//            [gameWorld.Blackboard.ComponentRenderLayer removeChild:l cleanup:YES];
//        }
//        [assLabels removeObjectsForKeys:cleanLabels];
    }
}

-(void)setupStuff
{
    //build circle lookups for swoosh drawing
    [self setupSwooshCircleOffsets];
    
    //build sprites, etc
    assStartTerminator=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_LineStubLeft.png")];
    [assStartTerminator setVisible:NO];
    [gameWorld.Blackboard.ComponentRenderLayer addChild:assStartTerminator];
    
    assEndTerminator=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_LineStubRight.png")];
    [assEndTerminator setVisible:NO];
    [gameWorld.Blackboard.ComponentRenderLayer addChild:assEndTerminator];
    
    int baseSegs=(gameWorld.Blackboard.hostCX * 2) / ramblerGameObject.DefaultSegmentSize + 4;
    
    //to hack full screen offset scrolling without adjusting actual offset
    baseSegs=baseSegs * 4;

    assBlankSegments=[[NSMutableArray alloc] init];
    assLineSegments=[[NSMutableArray alloc] init];
    assIndicators=[[NSMutableArray alloc] init];
    assNumberBackgrounds=[[NSMutableArray alloc] init];
    jumpSprites=[[NSMutableArray alloc] init];
    jumpLabels=[[NSMutableArray alloc] init];
    
    //repeat the fors so we add the stuff in the right paint order
    
    for (int i=0; i<baseSegs; i++) {
        CCSprite *blank=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_LineSeg.png")];
        [blank setVisible:NO];
        [assBlankSegments addObject:blank];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:blank z:1];
    }
    
    for (int i=0; i<baseSegs; i++) {
        CCSprite *line=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_LineMiddle115.png")];
        [line setVisible:NO];
        [assLineSegments addObject:line];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:line z:2];
    }
    
    for (int i=0; i<baseSegs; i++) {
        CCSprite *ind=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_Segment-NumberShown.png")];
        [ind setVisible:NO];
        [assIndicators addObject:ind];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:ind z:3];
    }
    
    for (int i=0; i<baseSegs; i++) {
        CCSprite *numback=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_Segment-NumberBackground.png")];
        [numback setVisible:YES];
        [assNumberBackgrounds addObject:numback];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:numback z:4];
    }
    

//    for (int i=0; i<baseSegs; i++) {
//        //currently unused
//        CCSprite *jump=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/jump_section.png")];
//        [jump setVisible:NO];
//        [jump setPosition:ccp(512, 384)];
//        [jumpSprites addObject:jump];
//        [gameWorld.Blackboard.ComponentRenderLayer addChild:jump z:2];
//    }

    assLabels=[[NSMutableDictionary alloc] init];
    labelLayer=[[CCLayer alloc] init];
    [gameWorld.Blackboard.ComponentRenderLayer addChild:labelLayer z:5];
    
    
    bmlabels=[[NSMutableArray alloc] init];
    for (int i=0; i<20; i++)
    {
        CCLabelBMFont *f=[CCLabelBMFont labelWithString:@"0123456789.," fntFile:BUNDLE_FULL_PATH(@"/images/fonts/chango24.fnt")];
        [bmlabels addObject:f];
        [labelLayer addChild:f z:99];
    }
    
    if(ramblerGameObject.MarkerValuePositions)
    {
        markerSprites=[[NSMutableArray alloc] init];
        for (NSNumber *n in ramblerGameObject.MarkerValuePositions) {
            CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/NL_Marker.png")];
            [gameWorld.Blackboard.ComponentRenderLayer addChild:s z:98];
            [markerSprites addObject:s];
        }
    }
}

-(void)doUpdate:(ccTime)delta
{
    int segsInCX=(gameWorld.Blackboard.hostCX / ramblerGameObject.DefaultSegmentSize);
        
    float minValuePos=ramblerGameObject.BubblePos - ((segsInCX * 4) * ramblerGameObject.CurrentSegmentValue);
    float maxValuePos=ramblerGameObject.BubblePos + ((segsInCX * 4) * ramblerGameObject.CurrentSegmentValue);
    
    //add the touchxoffset to the maxvalue, or decrement from the minimum value
    float touchDrawOffset=((int)(-ramblerGameObject.HeldMoveOffsetX / ramblerGameObject.DefaultSegmentSize)) * ramblerGameObject.CurrentSegmentValue;
    maxValuePos+=touchDrawOffset;
    minValuePos+=touchDrawOffset;
    
//    NSLog(@"min %f max %f tdo %f", minValuePos, maxValuePos, touchDrawOffset);

    int assBlankIndex=0;
    int assLineIndex=0;
    int assIndicatorIndex=0;
    int assNumberBackIndex=0;
    int jumpSpriteIndex=0;
    int bmlabelindex=0;
    
    //[labelLayer removeAllChildrenWithCleanup:YES];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    
    [assStartTerminator setVisible:NO];
    [assEndTerminator setVisible:NO];
    
    for(CCSprite *ms in markerSprites)
    {
        ms.visible=NO;
    }
    
//    NSLog(@"current segment value %f", ramblerGameObject.CurrentSegmentValue);
    
    for (int iValue=minValuePos; iValue<=maxValuePos; iValue+=ramblerGameObject.CurrentSegmentValue) {
        
        float diffInValFromCentre=iValue-ramblerGameObject.Value;
        CGPoint segStartPos=CGPointMake(ramblerGameObject.Pos.x + ramblerGameObject.TouchXOffset + (diffInValFromCentre / ramblerGameObject.CurrentSegmentValue) * ramblerGameObject.DefaultSegmentSize, ramblerGameObject.Pos.y);
        CGPoint segStartPosForLine = CGPointMake(segStartPos.x + ramblerGameObject.DefaultSegmentSize / 2.0f, segStartPos.y);
        
        if(segStartPos.x > -ramblerGameObject.DefaultSegmentSize && segStartPos.x < (2*gameWorld.Blackboard.hostCX))
        {
            
            //line segment rendering --------------------------------------------------------------------------------------
            if(ramblerGameObject.MinValue && iValue<[ramblerGameObject.MinValue intValue])
            {
                //render as blank
                CCSprite *assBlank=[assBlankSegments objectAtIndex:assBlankIndex];
                [assBlank setVisible:YES];
                [assBlank setPosition:segStartPosForLine];
                
                assBlankIndex++;
            }
            
            if((!ramblerGameObject.MinValue || iValue>=[ramblerGameObject.MinValue intValue]) && (!ramblerGameObject.MaxValue || iValue < [ramblerGameObject.MaxValue intValue]))
            {
                //render as line
                CCSprite *assLine=[assLineSegments objectAtIndex:assLineIndex];
                [assLine setVisible:YES];
                [assLine setPosition:segStartPosForLine];
                
                assLineIndex++;
            }
            
            if(ramblerGameObject.MaxValue && iValue>= [ramblerGameObject.MaxValue intValue])
            {
                //render as blank
                CCSprite *assBlank=[assBlankSegments objectAtIndex:assBlankIndex];
                [assBlank setVisible:YES];
                [assBlank setPosition:segStartPosForLine];
                
                assBlankIndex++;
            }
            //-------------------------------------------------------------------------------------------------------------
            
            //place start / end indicators---------------------------------------------------------------------------------
            if(ramblerGameObject.MinValue && iValue==[ramblerGameObject.MinValue intValue])
            {
                [assStartTerminator setVisible:YES];
                [assStartTerminator setPosition:ccp(segStartPos.x-36.5f, segStartPos.y)];
            }
            if(ramblerGameObject.MaxValue && iValue==[ramblerGameObject.MaxValue intValue])
            {
                [assEndTerminator setVisible:YES];
                [assEndTerminator setPosition:ccp(segStartPos.x+36.5f, segStartPos.y)];
            }
            //-------------------------------------------------------------------------------------------------------------
            
            
            //markers -----------------------------------------------------------------------------------------------------
            if(ramblerGameObject.MarkerValuePositions)
            {
                for(int i=0; i<ramblerGameObject.MarkerValuePositions.count; i++)
                {
                    NSNumber *n=[ramblerGameObject.MarkerValuePositions objectAtIndex:i];
                    if(n.intValue==iValue)
                    {
                        CCSprite *s=[markerSprites objectAtIndex:i];
                        [s setPosition:segStartPos];
                        s.visible=YES;
                    }
                }
            }
            // ------------------------------------------------------------------------------------------------------------
            
            //render number indicator -------------------------------------------------------------------------------------

            float thisNumber=(float)iValue;
            BOOL renderNotch=NO;
            
            if(thisNumber==[ramblerGameObject.MinValue floatValue] && !ramblerGameObject.HideStartNotch) renderNotch=YES;
            else if(thisNumber==[ramblerGameObject.MaxValue floatValue] && !ramblerGameObject.HideEndNotch) renderNotch=YES;
            else if(ramblerGameObject.ShowNotchesAtIntervals)
            {
                for (NSNumber *n in ramblerGameObject.ShowNotchesAtIntervals) {
                    int totalRem = (int)thisNumber % [n intValue];
                    if (totalRem==0) {
                        renderNotch=YES;
                        break;
                    }
                }
            }
            else if (!ramblerGameObject.HideAllNotches) renderNotch=YES;
            
            //force off if past begining or end (new behaviour)
            if(iValue<[ramblerGameObject.MinValue intValue] || iValue>[ramblerGameObject.MaxValue intValue])
            {
                renderNotch=NO;
            }

            CCSprite *ind=[assIndicators objectAtIndex:assIndicatorIndex];
            [ind setVisible:renderNotch];
            [ind setPosition:CGPointMake(segStartPos.x, segStartPos.y - kIndicatorYOffset)];

            //change opcaity for on-line and off-line items
            if((!ramblerGameObject.MinValue || iValue>=[ramblerGameObject.MinValue intValue]) && (!ramblerGameObject.MaxValue || iValue <= [ramblerGameObject.MaxValue intValue]))
            {
                [ind setOpacity:255];
            }
            else {
                [ind setOpacity:50];
            }


            assIndicatorIndex++;
            
            //-------------------------------------------------------------------------------------------------------------
            
            
            //label / font render -----------------------------------------------------------------------------------------

            if((!ramblerGameObject.MinValue || iValue>=[ramblerGameObject.MinValue intValue]) && (!ramblerGameObject.MaxValue || iValue <= [ramblerGameObject.MaxValue intValue]))
            {
//                NSNumber *numRender=[NSNumber numberWithInt:iValue];
                NSNumber *numRender=[[NSNumber alloc] initWithInt:iValue];
                
                float thisNumber=[numRender intValue];
                BOOL renderNumber=NO;
                
                if(thisNumber==[ramblerGameObject.MinValue floatValue] && !ramblerGameObject.HideStartNumber) renderNumber=YES;
                else if(thisNumber==[ramblerGameObject.MaxValue floatValue] && !ramblerGameObject.HideEndNumber) renderNumber=YES;
                else if(ramblerGameObject.ShowNumbersAtIntervals)
                {
                    for (NSNumber *n in ramblerGameObject.ShowNumbersAtIntervals) {
                        int totalRem = (int)thisNumber % [n intValue];
                        if (totalRem==0) {
                            renderNumber=YES;
                            break;
                        }
                    }
                }
                else if (!ramblerGameObject.HideAllNumbers) renderNumber=YES;
                
                
                if(renderNumber)
                {
                    //get background down first
                    CCSprite *ind=[assNumberBackgrounds objectAtIndex:assNumberBackIndex];
                    [ind setPosition:CGPointMake(segStartPos.x, segStartPos.y - kIndicatorYOffset)];
                    [ind setVisible:YES];
                    assNumberBackIndex++;
                    
                    int displayNum=[numRender intValue] + ramblerGameObject.DisplayNumberOffset;
                    
                    NSString *writeText=[[NSString alloc] initWithFormat:@"%d", displayNum];
                    
                    if(ramblerGameObject.DisplayNumberDP>0 && ramblerGameObject.DisplayNumberMultiplier!=1)
                    {
                        float multDisplayNum=displayNum * ramblerGameObject.DisplayNumberMultiplier;
                        
                        NSString *fmt=[[NSString alloc] initWithFormat:@"%%.%df", ramblerGameObject.DisplayNumberDP];
                        writeText=[NSString stringWithFormat:fmt, multDisplayNum];
                        [fmt release];
                    }
                    
                    int fontSize=24;
                    
                    if(writeText.length==3) fontSize=15;
                    if(writeText.length==4) fontSize=12;
                    if(writeText.length>4) fontSize=9;

                    CCLabelBMFont *lex=[bmlabels objectAtIndex:bmlabelindex];
                    bmlabelindex++;
                    lex.string=writeText;
                    lex.visible=YES;
            
                    [lex setPosition:CGPointMake(segStartPos.x, segStartPos.y+kLabelOffset)];
                    
                    [writeText release];
                }
                
                //tidy up number rendering
                [numRender release];
                
            }
            
    //        CCLabelBMFont *lbl=[assLabels objectForKey:numRender];
    //        if(!lbl)
    //        {
    //            lbl=[CCLabelBMFont labelWithString:[numRender stringValue] fntFile:kLabelFont];
    ////            lbl=[CCLabelTTF labelWithString:[numRender stringValue] fontName:GENERIC_FONT fontSize:24.0f];
    //            [gameWorld.Blackboard.ComponentRenderLayer addChild:lbl];
    //            [assLabels setObject:lbl forKey:numRender];
    //        }
    //        [lbl setVisible:YES];
    //        [lbl setPosition:CGPointMake(segStartPos.x, segStartPos.y+kLabelOffset)];
            //-------------------------------------------------------------------------------------------------------------

            
//            // jumps/ segments render -----------------------------------------------------------------------------------------
//
//            if(ramblerGameObject.UserJumps)
//            {
//                for(NSValue *jumpVal in ramblerGameObject.UserJumps)
//                {
//                    CGPoint jump=[jumpVal CGPointValue];
//                    int jumpStart=jump.x;
//                    int jumpLength=jump.y;
//                    
//                    if(iValue>=jumpStart && iValue<(jumpStart+jumpLength))
//                    {
//                        
//                        //draw a jump section
//                        CCSprite *s=[jumpSprites objectAtIndex:jumpSpriteIndex];
//                        [s setVisible:YES];
//                        [s setPosition:segStartPosForLine];
//                        
//                        jumpSpriteIndex++;
//                    }
//                }
//            }
//            
//            
//            //-------------------------------------------------------------------------------------------------------------

            
        }
    }
    
    //set invisible any remaining segements etc
    for (int i=assBlankIndex; i<[assBlankSegments count]; i++) {
        [[assBlankSegments objectAtIndex:i] setVisible:NO];
    }
    for (int i=assLineIndex; i<[assLineSegments count]; i++) {
        [[assLineSegments objectAtIndex:i] setVisible:NO];
    }
    for (int i=assIndicatorIndex; i<[assIndicators count]; i++) {
        [[assIndicators objectAtIndex:i] setVisible:NO];
    }
    for (int i=jumpSpriteIndex; i<[jumpSprites count]; i++)
    {
        [[jumpSprites objectAtIndex:i] setVisible:NO];
    }
    for(int i=assNumberBackIndex; i<[assNumberBackgrounds count]; i++)
    {
        [[assNumberBackgrounds objectAtIndex:i] setVisible:NO];
    }
    for(int i=bmlabelindex; i<[bmlabels count]; i++)
    {
        [[bmlabels objectAtIndex:i] setVisible:NO];
    }
    
    
//    for(int i=0; i<[assNumberBackgrounds count]; i++)
//    {
//        [[assNumberBackgrounds objectAtIndex:i] setVisible:NO];
//    }
}

-(void) drawFromMid:(CGPoint)mid andYOffset:(float)yOffset
{
    if(ramblerGameObject.showJumpLabels){
        for(CCLabelTTF *l in jumpLabels)
        {
            [l removeFromParentAndCleanup:YES];
        }
        [jumpLabels removeAllObjects];
    }
    //intended for in-loop draw
    if(ramblerGameObject.UserJumps)
    {
        int fontSize=30;
        for(NSValue *jumpVal in ramblerGameObject.UserJumps)
        {
            CGPoint jump=[jumpVal CGPointValue];
            float jumpStart=(jump.x / ramblerGameObject.CurrentSegmentValue) * ramblerGameObject.DefaultSegmentSize + mid.x + ramblerGameObject.TouchXOffset;
            float jumpLength=(jump.y / ramblerGameObject.CurrentSegmentValue) * ramblerGameObject.DefaultSegmentSize;
            
            CGPoint origin=ccp(jumpStart, mid.y + yOffset);
                if(ramblerGameObject.showJumpLabels){
                    NSString *lString=[NSString stringWithFormat:@"%g", (jumpLength/ramblerGameObject.DefaultSegmentSize)*ramblerGameObject.CurrentSegmentValue];
                        CCLabelBMFont *l=[[CCLabelBMFont alloc]initWithString:lString fntFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/fonts/chango%d.fnt"),fontSize]];
                        //                CCLabelTTF *l=[CCLabelTTF labelWithString:lString fontName:CHANGO fontSize:30.0f];
                    [l setPosition:ccp(jumpStart+(jumpLength/2), mid.y+90)];
                    [l setColor:ccWHITE];
                    [gameWorld.Blackboard.ComponentRenderLayer addChild:l];
                    [jumpLabels addObject:l];
            }
            
            ccBezierConfig bc;
            
            if(jumpLength>0)
            {
                bc.controlPoint_1=ccpAdd(ccp(jumpStart, mid.y), ccp(20, 40));
                bc.controlPoint_2=ccpAdd(ccp(jumpStart + jumpLength, mid.y), ccp(-40, 100));
                bc.endPosition=ccp(jumpStart + jumpLength, mid.y + yOffset + 10.0f);
            }
            else
            {
                bc.controlPoint_1=ccpAdd(ccp(jumpStart, mid.y), ccp(-20, 40));
                bc.controlPoint_2=ccpAdd(ccp(jumpStart + jumpLength, mid.y), ccp(40, 100));
                bc.endPosition=ccp(jumpStart + jumpLength, mid.y + yOffset + 10.0f);
            }

            if(jumpLength>0 && bc.endPosition.x<0) continue;
            if(jumpLength<0 && origin.x<0) continue;
            
            int drawSteps=STEPS;
            if([CCDirector sharedDirector].contentScaleFactor>1) drawSteps*=2;
            
            for(int i=0; i<STEPS; i++)
            {
                ccBezierConfig bc2;

                bc2.controlPoint_1=bc.controlPoint_1;
                bc2.controlPoint_2=bc.controlPoint_2;
                
                if(jumpLength>0) bc2.endPosition=ccpAdd(bc.endPosition, circleOffsetsFwd[i]);
                else bc2.endPosition=ccpAdd(bc.endPosition, circleOffsetsBwd[i]);

                
                //aliasing stuff ==========
                if(i==0)
                {
                    //origin=ccpAdd(origin, ccp(10, 0));
                    bc2.endPosition=ccpAdd(bc2.endPosition, ccp(-1, 0));
                    bc2.controlPoint_1=ccpAdd(bc2.controlPoint_1, ccp(5, 0));
                    bc2.controlPoint_2=ccpAdd(bc2.controlPoint_2, ccp(-2, 0));
                    ccDrawColor4B(255, 255, 255, 50);
                }
                else if(i==STEPS-1)
                {
                    origin=ccpAdd(origin, ccp(-1, 1));
                    ccDrawColor4B(255, 255, 255, 50);
                }
                else
                {
                    int step=i;
                    if (i>STEPS/2.0f) step =(STEPS/2.0f) - (i-(STEPS/2.0f));
                    int o=100 + (155 * step / (STEPS/2.0f));
                    ccDrawColor4B(255, 255, 255, o);
                }
                // ========================
                
                ccDrawCubicBezier(origin, bc2.controlPoint_1, bc2.controlPoint_2, bc2.endPosition, 40);
            }
            
        }
    }
}

-(void) setupSwooshCircleOffsets
{
    int drawSteps=STEPS;
    if([CCDirector sharedDirector].contentScaleFactor>1) drawSteps*=2;
    
    for(int i=0; i<STEPS; i++)
    {
        float a=225.0f-((180/STEPS) * i);
        CGPoint o=[BLMath ProjectMovementWithX:0 andY:8.0f forRotation:a];
        circleOffsetsFwd[i]=o;
    }
    for(int i=0; i<STEPS; i++)
    {
        float a=315.0f-((180/STEPS) * i);
        CGPoint o=[BLMath ProjectMovementWithX:0 andY:8.0f forRotation:a];
        circleOffsetsBwd[i]=o;
    }
    
}

-(void)dealloc
{
    [assBlankSegments release];
    [assLineSegments release];
    [assIndicators release];
    [assLabels release];
    [assNumberBackgrounds release];
    [labelLayer release];
    [markerSprites release];
    [jumpSprites release];
    
    [super dealloc];
}

@end
