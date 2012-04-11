//
//  ColumnAddition.m
//  belugapad
//
//  Created by David Amphlett on 19/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ColumnAddition.h"
#import "ToolHost.h"
#import "ToolScene.h"
#import "global.h"
#import "BLMath.h"
#import "SimpleAudioEngine.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "Daemon.h"
#import "NLineConsts.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "ColumnAdditionConsts.h"

@implementation ColumnAddition
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
        sumBoxLayer=[[[CCLayer alloc]init]autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        [self.ForeLayer addChild:sumBoxLayer];
        [sumBoxLayer setPosition:kSumBoxLayerPos];
        
        gw.Blackboard.ComponentRenderLayer=self.ForeLayer;
        
        [self readPlist:pdef];
        
        [self populateGW];
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        toolState=kNoState;
        
        gw.Blackboard.inProblemSetup = NO;
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    [self updateLabels];
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

-(void)populateGW
{
    if(bkgOverlay) {
        CCSprite *bkg = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(bkgOverlay)];
        [bkg setPosition:ccp(cx, cy)];
        [self.BkgLayer addChild:bkg];
    }
    
    // populate our individual number arrays
    
    NSString *aColNos = [NSString stringWithFormat:@"%d", sourceA];
    NSString *bColNos = [NSString stringWithFormat:@"%d", sourceB];
    int backwardArrayPos = 4;
    
    for(int i=0; i<[aColNos length]; i++)
    {
        NSString *thisChar=[aColNos substringWithRange:NSMakeRange([aColNos length]-i-1, 1)];
        aCols[backwardArrayPos] = [thisChar intValue];
        backwardArrayPos--;
    }
    
    backwardArrayPos = 4;
    
    for(int i=0; i<[bColNos length]; i++)
    {
        
        NSString *thisChar=[bColNos substringWithRange:NSMakeRange([bColNos length]-i-1, 1)];
        bCols[backwardArrayPos] = [thisChar intValue];
        backwardArrayPos--;
    }
    
    colSpacing=kSumBoxWidth/6.0f;
    
    
    for(int i=0; i<5; i++)
    {
        float lblXPos=(i+1)*colSpacing;
        NSString *aColCurrentLabel;
        NSString *bColCurrentLabel;
        
        // just display labels that are actually required
        if(i-(5-[aColNos length])<=[aColNos length]>0) {
            aColCurrentLabel = [NSString stringWithFormat:@"%d", aCols[i]];
            aColLabelEnabled[i] = YES;
        }
        else aColCurrentLabel = @"0";
        if(i-(5-[bColNos length])<=[bColNos length]>0) {
            bColCurrentLabel = [NSString stringWithFormat:@"%d", bCols[i]];   
            bColLabelEnabled[i] = YES;
        }
        else bColCurrentLabel = @"0";
        
        
        //bColCurrentLabel = [NSString stringWithFormat:@"%d", bCols[i]];
        
        aColLabels[i] = [CCLabelTTF labelWithString:aColCurrentLabel fontName:PROBLEM_DESC_FONT fontSize:kFontLabelSize];
        
        bColLabels[i] = [CCLabelTTF labelWithString:bColCurrentLabel fontName:PROBLEM_DESC_FONT fontSize:kFontLabelSize];
        
        sColLabels[i] = [CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:kFontLabelSize];
        
        // if there are any labels that we can't see that are disabled (ie A, 34, B, 234) we set the missing label to be enabled
        if(i-(5-[aColNos length])<=[aColNos length]==0) { [aColLabels[i] setVisible:NO]; }
        if(i-(5-[bColNos length])<=[bColNos length]==0) { [bColLabels[i] setVisible:NO]; }

        [aColLabels[i] setPosition:ccp(lblXPos, 500)];
        
        [bColLabels[i] setPosition:ccp(lblXPos, 350)];
        
        [sColLabels[i] setPosition:ccp(lblXPos, 200)];
        
        [aColLabels[i] setTag:2];
        
        [bColLabels[i] setTag:2];
        
        [aColLabels[i] setOpacity:0];
        
        [bColLabels[i] setOpacity:0];
        
        [sumBoxLayer addChild:aColLabels[i]];
        
        [sumBoxLayer addChild:bColLabels[i]];
        
        [sumBoxLayer addChild:sColLabels[i]];
    }
    
    //lblOperator = [CCLabelTTF labelWithString:@"+" fontName:PROBLEM_DESC_FONT fontSize:100.0f];
    btnOperator = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/columnadd/plus-inactive.png")];
    [btnOperator setPosition:ccp(colSpacing*0.3, 350)];
    [btnOperator setScale:kColumnAddAssetScale];
    [btnOperator setOpacity:0];
    [btnOperator setTag:2];
    [sumBoxLayer addChild:btnOperator];
    
    CCSprite *lnSeparatorTop = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/columnadd/separator.png")];
    [lnSeparatorTop setPosition:ccp(480, 260)];
    [lnSeparatorTop setTag:1];
    [lnSeparatorTop setOpacity:0];
    [sumBoxLayer addChild: lnSeparatorTop];
    
    CCSprite *lnSeparatorBottom = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/columnadd/separator.png")];
    [lnSeparatorBottom setPosition:ccp(480, 160)];
    [lnSeparatorBottom setTag:1];
    [lnSeparatorBottom setOpacity:0];
    [sumBoxLayer addChild: lnSeparatorBottom];
    
}

-(void)updateLabels
{
    BOOL canSwitchSelection=NO;
    for(int i=0; i<5; i++)
    {
        if(toolState==kNumberRemainderPress && rCols[i]>0)
        {
            sCols[i-1]=sCols[i-1]+rCols[i];
            rCols[i]=0;
            NSString *addString = [NSString stringWithFormat:@"%d", sCols[i-1]];
            [sColLabels[i-1] setString:addString];
            toolState=kNoState;
            DLog(@"Switched tool state: %d", toolState);
        }
        
        if((aColLabelSelected[i] || !aColLabelEnabled[i]) && (bColLabelSelected[i] || !bColLabelEnabled[i]) && lblOperatorSelected)
        {
            sCols[i]=sCols[i] + aCols[i] + bCols[i];
            
            if(sCols[i]>9)
            {
                toolState=kNumberRemainder;
                DLog(@"Switched tool state: %d", toolState);
                float lblXPos=(i+1)*(colSpacing*kColumnAddRemainderOffset);
                float lblXPosArrow=(i+1)*(colSpacing*kColumnAddRemainderArrowOffset);
                //do carry over
                aCols[i]=0;
                bCols[i]=0;
                rCols[i]=1;
                lblRemainder = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/columnadd/remainder.png")];
                [lblRemainder setPosition:ccp(lblXPos, 100)];
                [lblRemainder setScale:kColumnAddAssetScale];
                [sumBoxLayer addChild: lblRemainder];
                lblRemainderArrow = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/columnadd/arrow.png")];
                [lblRemainderArrow setPosition:ccp(lblXPosArrow, 100)];
                [lblRemainderArrow setScale:kColumnAddAssetScale];
                [sumBoxLayer addChild: lblRemainderArrow];
                
                
                //set sCols to remainder
                sCols[i]=sCols[i]-10;
            }
            else {
                toolState=kNoState;
                DLog(@"Switched tool state: %d", toolState);
            }
            if(aColLabelEnabled[i] || bColLabelEnabled[i])
            {
                // reset the A and B numbers to be 0 so the readd can't be done again
                aCols[i]=0;   
                bCols[i]=0;

                [aColLabels[i] setOpacity:50];
                [bColLabels[i] setOpacity:50];
                
                NSString *addString = [NSString stringWithFormat:@"%d", sCols[i]];
                [sColLabels[i] setString:addString];
                [sColLabels[i] setVisible:YES];
            }
            canSwitchSelection=YES;
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/putdown.wav")];
            DLog(@"Switched tool state: %d", toolState);
        }
    }
    if(canSwitchSelection)
    {
        [self deselectNumberAExcept:-1];
        [self deselectNumberBExcept:-1];
        [self switchOperator];
        if(lblOperatorActive)[self switchOperatorSprite];
    }
    [self evalProblem];
}

-(void)deselectNumberAExcept:(int)thisNumber
{
    //if(!aColLabels[thisNumber].visible) return;
    for(int i=0; i<5; i++)
    {
        // this is the number we want selected
        if(thisNumber == i)
        {
            aColLabelSelected[i]=YES;
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
            [aColLabels[i] setColor:ccc3(0,255,0)];
        }
        else 
        {
            if(aColLabelEnabled) aColLabelSelected[i]=NO;
            [aColLabels[i] setColor:ccc3(255,255,255)];
        }
    }
}

-(void)deselectNumberBExcept:(int)thisNumber
{
    //if(!bColLabels[thisNumber].visible) return;
    for(int i=0; i<5; i++)
    {
        // this is the number we want selected
        if(thisNumber == i)
        {
            bColLabelSelected[i]=YES;
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
            [bColLabels[i] setColor:ccc3(0,255,0)];
        }
        else 
        {
            if(bColLabelEnabled) bColLabelSelected[i]=NO;
            [bColLabels[i] setColor:ccc3(255,255,255)];
        }
    }
}

-(void)switchOperator
{
    if(!lblOperatorSelected)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
        lblOperatorSelected=YES;
    }
    else 
    {
        lblOperatorSelected=NO;
    }
}

-(void)switchOperatorSprite
{
    if(!lblOperatorActive)
    {
        lblOperatorActive=YES;
        [btnOperator setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/columnadd/plus-active.png")]];
    }
    else {
        lblOperatorActive=NO;
        [btnOperator setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(@"/images/columnadd/plus-inactive.png")]];
    }
}

-(void)readPlist:(NSDictionary*)pdef
{
    sourceA = [[pdef objectForKey:NUMBER_A] intValue];
    sourceB = [[pdef objectForKey:NUMBER_B] intValue];
    bkgOverlay = [pdef objectForKey:OVERLAY_FILENAME];
    [bkgOverlay retain];
}

-(void)evalProblem
{
    NSString *sColNos = [NSString stringWithFormat:@"%d", sourceA+sourceB];
    int backwardArrayPos = 4;
    int countRequired=[sColNos length];
    int countSolved=0;
    
    for(int i=0; i<[sColNos length]; i++)
    {
        NSString *thisChar=[sColNos substringWithRange:NSMakeRange([sColNos length]-i-1, 1)];
        if([thisChar intValue] == sCols[backwardArrayPos])
        {
            countSolved++;
        }
        backwardArrayPos--;
    }
    if(countSolved==countRequired)
    {
        [toolHost showProblemCompleteMessage];
        autoMoveToNextProblem=YES;
    }

}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    touching=YES;
    
    if(toolState==kNumberSelected||toolState==kNumberOperatorSelected||toolState==kNoState)
    {
        // loop over the number A, check for touches
        for(int i=0; i<5; i++)
        {
            // create a dynamic hitbox using the position properties of the current label, check for a touch in it
            CGRect curHit = CGRectMake(aColLabels[i].position.x-(kFontLabelSize), aColLabels[i].position.y-(kFontLabelSize), kFontLabelSize*2, kFontLabelSize*2);

            if(CGRectContainsPoint(curHit, [sumBoxLayer convertToNodeSpace:location]))
               {
                   if(!aColLabelSelected[i])
                   {
                    if(!lblOperatorActive) [self switchOperatorSprite];
                       [self deselectNumberAExcept:i];
                       toolState=kNumberSelected;
                       DLog(@"Switched tool state: %d", toolState);
                       return;                   
                   }
                   else {
                       [self deselectNumberAExcept:-1];
                       if(!bColLabelSelected[i])
                       {
                           toolState=kNoState;
                           DLog(@"Switched tool state: %d", toolState);
                       }
                   }
                   return;

               }
            
        }
    
        
        // loop over the number B, check for touches
        for(int i=0; i<5; i++)
        {
            CGRect curHit = CGRectMake(bColLabels[i].position.x-(kFontLabelSize), bColLabels[i].position.y-(kFontLabelSize), kFontLabelSize*2, kFontLabelSize*2);
            
            if(CGRectContainsPoint(curHit, [sumBoxLayer convertToNodeSpace:location]))
            {
                if(!bColLabelSelected[i]) {
                    if(!lblOperatorActive) [self switchOperatorSprite];
                    [self deselectNumberBExcept:i];
                    toolState=kNumberSelected;
                    DLog(@"Switched tool state: %d", toolState);
                    return;
                }
                else {
                    [self deselectNumberBExcept:-1];
                    // also check if the corresponding a column is deselected, reset tool state if so
                    if(!aColLabelSelected[i])
                    {
                        toolState=kNoState;
                        DLog(@"Switched tool state: %d", toolState);
                    }
                }
            }
        }
        
        // check operator touhes
        CGRect curHit = CGRectMake(btnOperator.position.x-(kFontLabelSize), btnOperator.position.y-(kFontLabelSize), kFontLabelSize*2, kFontLabelSize*2);
        if(CGRectContainsPoint(curHit, [sumBoxLayer convertToNodeSpace:location]))
        {
            [self switchOperator];
            if(lblOperatorSelected)
            {
                toolState=kNumberOperatorSelected;
                DLog(@"Switched tool state: %d", toolState);
            }
            return;
        }
    }
    // if there's a remainder force the user to do something with it
    if(toolState==kNumberRemainder) {
        
        CGRect curHit = CGRectMake(lblRemainder.position.x-(kFontLabelSize), lblRemainder.position.y-(kFontLabelSize), kFontLabelSize*2, kFontLabelSize*2);
        if(CGRectContainsPoint(curHit, [sumBoxLayer convertToNodeSpace:location]))
        {
            for (int i=0; i<5; i++)
            {
                if(rCols[i]>0)
                {
                    toolState=kNumberRemainderDrag;
                    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
                    DLog(@"Switched tool state: %d", toolState);
                    lblRemainderPos = lblRemainder.position;
                    [lblRemainderArrow setVisible:NO];

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
    if(toolState==kNumberRemainderDrag)
    {
        [lblRemainder setPosition:[sumBoxLayer convertToNodeSpace:location]];
    }


}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    touching=NO;
    if(toolState==kNumberRemainderDrag)
    {

        for(int i=0; i<5; i++)
        {
            // check we're on a col with a remainder
            if(rCols[i]>0)
            {
                // then check the position is the one to our left (i-1)
                CGRect curHit = CGRectMake(sColLabels[i-1].position.x-(kFontLabelSize), sColLabels[i-1].position.y-(kFontLabelSize), kFontLabelSize*3, kFontLabelSize*3);
                if(CGRectContainsPoint(curHit, [sumBoxLayer convertToNodeSpace:location]))
                {
                    // if it's in the right place, remove the sprite and set the game mode back to 'press' to eval
                    [sumBoxLayer removeChild:lblRemainder cleanup:YES];
                    toolState=kNumberRemainderPress;
                    DLog(@"Switched tool state: %d", toolState);
                    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
                }
                else {
                    [lblRemainderArrow setVisible:YES];
                    [lblRemainder runAction:[CCMoveTo actionWithDuration:kMoveTimeForRemainder position:lblRemainderPos]];
                    toolState=kNumberRemainder;
                    DLog(@"Switched tool state: %d", toolState);
                }
            }
        }
    }
}

-(void) dealloc
{
    //write log on problem switch
    [gw writeLogBufferToDiskWithKey:@"ColumnAddition"];
    
    //tear down
    [gw release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    if(bkgOverlay) [bkgOverlay release];
    
    [super dealloc];
}

@end
