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
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
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
        
        gw.Blackboard.inProblemSetup = NO;
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    [self updateLabels];
    
}

-(void)populateGW
{
    
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
        // only show labels where we don't have 0s (until an 'actual' number starts)
        if(!aCols[i] == 0 && !bCols[i] == 0)
        {
            float lblXPos=(i+1)*colSpacing;
            NSString *aColCurrentLabel = [NSString stringWithFormat:@"%d", aCols[i]];
            
            NSString *bColCurrentLabel = [NSString stringWithFormat:@"%d", bCols[i]];
            
            aColLabels[i] = [CCLabelTTF labelWithString:aColCurrentLabel fontName:PROBLEM_DESC_FONT fontSize:kFontLabelSize];
            
            bColLabels[i] = [CCLabelTTF labelWithString:bColCurrentLabel fontName:PROBLEM_DESC_FONT fontSize:kFontLabelSize];
            
            sColLabels[i] = [CCLabelTTF labelWithString:@"#" fontName:PROBLEM_DESC_FONT fontSize:kFontLabelSize];
            

            [aColLabels[i] setPosition:ccp(lblXPos, 500)];
            
            [bColLabels[i] setPosition:ccp(lblXPos, 350)];
            
            [sColLabels[i] setPosition:ccp(lblXPos, 200)];
            
            [sumBoxLayer addChild:aColLabels[i]];
            
            [sumBoxLayer addChild:bColLabels[i]];
            
            [sumBoxLayer addChild:sColLabels[i]];
        }
    }
    
    lblOperator = [CCLabelTTF labelWithString:@"+" fontName:PROBLEM_DESC_FONT fontSize:100.0f];
    [lblOperator setPosition:ccp(colSpacing*0.3, 350)];
    [lblOperator setVisible:NO];
    [sumBoxLayer addChild:lblOperator];
    
}

-(void)updateLabels
{
    for(int i=0; i<5; i++)
    {
        // if we have 1 individual number in col A and col B we want to show the operator
        if(toolState==kNumberSelected && aColLabelSelected[i] && bColLabelSelected[i])
        {
            [lblOperator setVisible:YES];
            return;
        }
        else {
            [lblOperator setVisible:NO];
        }
        
        if(aColLabelSelected[i] && bColLabelSelected[i] && lblOperatorSelected)
        {
            NSString *addString = [NSString stringWithFormat:@"%d", aCols[i]+bCols[i]];
            [sColLabels[i] setString:addString];
            [self switchOperator];
            [self deselectNumberAExcept:-1];
            [self deselectNumberBExcept:-1];
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/putdown.wav")];
            toolState=kNoState;
            DLog(@"Switched tool state: %d", toolState);
            return;
        }
    }
}

-(void)deselectNumberAExcept:(int)thisNumber
{
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
            aColLabelSelected[i]=NO;
            [aColLabels[i] setColor:ccc3(255,255,255)];
        }
    }
}

-(void)deselectNumberBExcept:(int)thisNumber
{
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
            bColLabelSelected[i]=NO;
            [bColLabels[i] setColor:ccc3(255,255,255)];
        }
    }
}

-(void)switchOperator
{
    if(!lblOperatorSelected)
    {
        [lblOperator setColor:ccc3(0,255,0)];
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
        lblOperatorSelected=YES;
    }
    else 
    {
        [lblOperator setColor:ccc3(255,255,255)];
        lblOperatorSelected=NO;
    }
}

-(void)readPlist:(NSDictionary*)pdef
{
    sourceA = [[pdef objectForKey:NUMBER_A] intValue];
    sourceB = [[pdef objectForKey:NUMBER_B] intValue];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    touching=YES;
    
        // loop over the number A, check for touches
        for(int i=0; i<5; i++)
        {
            // create a dynamic hitbox using the position properties of the current label, check for a touch in it
            CGRect curHit = CGRectMake(aColLabels[i].position.x-(kFontLabelSize), aColLabels[i].position.y-(kFontLabelSize), kFontLabelSize*2, kFontLabelSize*2);

            if(CGRectContainsPoint(curHit, [sumBoxLayer convertToNodeSpace:location]))
               {
                   if(!aColLabelSelected[i])
                   {
                       DLog(@"Label position is x %f y %f", aColLabels[i].position.x, aColLabels[i].position.y);
                       DLog(@"Hitbox is: x %f, y %f, width %f, height %f", curHit.origin.x, curHit.origin.y, curHit.size.width, curHit.size.height);
                       DLog(@"Touch is at: x %f, y %f", location.x, location.y);
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
    
        // check operator touhes
            CGRect curHit = CGRectMake(lblOperator.position.x-(kFontLabelSize), lblOperator.position.y-(kFontLabelSize), kFontLabelSize*2, kFontLabelSize*2);
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
    
    // loop over the number B, check for touches

    
        for(int i=0; i<5; i++)
        {
            CGRect curHit = CGRectMake(bColLabels[i].position.x-(kFontLabelSize), bColLabels[i].position.y-(kFontLabelSize), kFontLabelSize*2, kFontLabelSize*2);
            
            if(CGRectContainsPoint(curHit, [sumBoxLayer convertToNodeSpace:location]))
            {
                if(!bColLabelSelected[i]) {
                    [self deselectNumberBExcept:i];
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
    
    touching=NO;
}

@end
