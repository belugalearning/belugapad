//
//  SGJmapNodeSelect.m
//  belugapad
//
//  Created by Gareth Jenkins on 18/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapNodeSelect.h"
#import "BLMath.h"
#import "global.h"
#import "InteractionFeedback.h"
#import "SimpleAudioEngine.h"

#import "AppDelegate.h"
#import "ContentService.h"

#import "SGJmapNode.h"
#import "SGJmapMasteryNode.h"

#import "JMap.h"
#import "UserNodeState.h"

@implementation SGJmapNodeSelect

-(SGJmapNodeSelect*)initWithGameObject:(id<Transform, CouchDerived, Selectable, Completable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(BOOL)trySelectionForPosition:(CGPoint)pos
{
    BOOL ret=NO;
    
    CGPoint testParentPos=ParentGO.Position;
    if([((NSObject*)ParentGO) isKindOfClass:[SGJmapMasteryNode class]])
    {
        testParentPos=((SGJmapMasteryNode*)ParentGO).MasteryPinPosition;
    }
    
    if([gameObject isKindOfClass:[SGJmapMasteryNode class]])
        if(((SGJmapMasteryNode*)gameObject).Disabled)
            return NO;
    
    if(ParentGO.Selected && CGRectContainsPoint(hitbox, pos))
    {
        ret=YES;
        //already selected -- start pipeline
        ContentService *cs=(ContentService*)((AppController*)[UIApplication sharedApplication].delegate).contentService;
        
        if([cs createAndStartFunnelForNode:ParentGO._id])
        {
            //[((AppController*)[UIApplication sharedApplication].delegate) startToolHostFromJmapPos:ParentGO.Position];
            
            //set last played
            AppController *ac=(AppController*)[UIApplication sharedApplication].delegate;
            ac.lastViewedNodeId=ParentGO._id;
            
            [((JMap*)[gameWorld GameScene]) startTransitionToToolHostWithPos:testParentPos];
        }
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_overlay_panel_tap.wav")];
        NSLog(@"i'm starting! %@", ParentGO._id);
        ParentGO.Selected=YES;
    }
    else if ([BLMath DistanceBetween:testParentPos and:pos]<ParentGO.HitProximity)
    {
        ret=YES;
      
        //no longer hacky at all -- completely miss the mastery/node check (no chance of hitting this anyway as there are no mastery pins, and allow direct access
        
        //this is mastery -- pop the sign
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_node_pin_tap.wav")];
        [self showSignWithForce:NO];
    }
    else {
        
        //only remove if the node hasn't just been forced on (by another)
        if(!forcedOn)
        {
            [self removeSign];
            ParentGO.Selected=NO;
        }
    }
    
    forcedOn=NO;
    return ret;
}

-(void)deselect
{
    ParentGO.Selected=NO;
}

-(void)showSignWithForce:(BOOL)forceOn
{
    forcedOn=forceOn;
    
    ParentGO.Selected=YES;
    
    if(!signSprite)
    {
        if([gameObject isKindOfClass:[SGJmapNode class]])
        {
            SGJmapNode *n=(SGJmapNode*)gameObject;
            
            NSString *sScore=@"";
            if(n.ustate.highScore>0)sScore=[NSString stringWithFormat:@"%d", n.ustate.highScore];
            NSString *sPlayButton=@"PLAY NOW";
            if(n.ustate.lastPlayed>0)sPlayButton=@"PLAY AGAIN";
         
//            NSDateFormatter *df=[[NSDateFormatter alloc]init];
//            [df setDateFormat:@"dd/MM/YYYY"];
//            NSString *lastPlayedDate=[df stringFromDate:ParentGO.DateLastPlayed];
//            [df release];
            
            NSString *displayString=nil;
            
            NSDate *today=[NSDate date];
            NSDate *lastPlayed=ParentGO.DateLastPlayed;
            
            NSTimeInterval secondsBetween=[today timeIntervalSinceDate:lastPlayed];
            int numberOfDays=secondsBetween/86400;
            int numberOfWeeks=numberOfDays/7;
            
            if(numberOfDays==0)
                displayString=@"TODAY";
            if(numberOfDays==1 && numberOfWeeks==0)
                displayString=[NSString stringWithFormat:@"%d DAY AGO", numberOfDays];
            else if(numberOfDays>1 && numberOfWeeks==0)
                displayString=[NSString stringWithFormat:@"%d DAYS AGO", numberOfDays];
            else if(numberOfDays>0 && numberOfWeeks==0)
                displayString=[NSString stringWithFormat:@"%d WEEK AGO", numberOfWeeks];
            else if(numberOfDays>0 && numberOfWeeks>0)
                displayString=[NSString stringWithFormat:@"%d WEEKS AGO", numberOfWeeks];
            
            NSString *splayed=@"NOT PLAYED";
            if(n.ustate.lastPlayed>0)splayed=[NSString stringWithFormat:@"LAST PLAYED\n%@", displayString];
            
            if(n.ustate.lastPlayed>0)
                signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/tooltip-base-tall.png")];
            else
                signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/tooltip-base-small.png")];
            
            //show play again
            CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/play-button-normal.png")];
            [playSprite setPosition:ccp(signSprite.contentSize.width / 2.0f, 40)];
            [signSprite addChild:playSprite];
            
            CCLabelTTF *playlabel=[CCLabelTTF labelWithString:sPlayButton fontName:@"Chango" fontSize:18.0f];
            playlabel.position=ccp(playSprite.contentSize.width / 2.0f, playSprite.contentSize.height / 2.0f);
            [playSprite addChild:playlabel];
            
            
            NSNumberFormatter *nf = [NSNumberFormatter new];
            nf.numberStyle = NSNumberFormatterDecimalStyle;
            NSNumber *thisNumber=[NSNumber numberWithFloat:[sScore floatValue]];
            sScore = [nf stringFromNumber:thisNumber];
            [nf release];

            if([thisNumber floatValue]>0)
            {
                CCLabelTTF *score=[CCLabelTTF labelWithString:sScore fontName:@"Source Sans Pro" fontSize:15.0f dimensions:CGSizeMake(180,100) hAlignment:UITextAlignmentLeft];
                
                [score setPosition:ccp(100, 85)];
                [score setColor:ccc3(255, 255, 255)];
                [signSprite addChild:score];
            }
            CCSprite *newSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/ribbon-perfect.png")];
            [newSprite setPosition:ccp(signSprite.contentSize.width - (newSprite.contentSize.width / 2.0f), (signSprite.contentSize.height - (newSprite.contentSize.height / 2.0f)))];
            [signSprite addChild:newSprite];

            
            CCLabelTTF *days=[CCLabelTTF labelWithString:splayed
                                              fontName:@"Source Sans Pro"
                                                fontSize:14.0f
                                              dimensions:CGSizeMake(180, 100) hAlignment:UITextAlignmentLeft ];
            [days setPosition:ccp(100, 50)];
            [days setColor:ccc3(200, 200, 200)];
            [signSprite addChild:days];
        }
        else {
            //mastery node
            if(ParentGO.EnabledAndComplete)
                signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/tooltip-base-tall.png")];
            else
                signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/tooltip-base-small.png")];
            
            CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/play-button-normal.png")];
            [playSprite setPosition:ccp(signSprite.contentSize.width / 2.0f, 40)];
            [signSprite addChild:playSprite];
            
            if(ParentGO.EnabledAndComplete)
            {
                //days ago
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"LAST PLAYED: TODAY" fontName:@"Source Sans Pro" fontSize:14.0f dimensions:CGSizeMake(180, 100) hAlignment:UITextAlignmentLeft];
                [days setPosition:ccp(100, 45)];
                [days setColor:ccc3(200, 200, 200)];
                [signSprite addChild:days];
                
                CCLabelTTF *playlabel=[CCLabelTTF labelWithString:@"PLAY AGAIN" fontName:@"Chango" fontSize:18.0f];
                playlabel.position=ccp(playSprite.contentSize.width / 2.0f, playSprite.contentSize.height / 2.0f);
                [playSprite addChild:playlabel];
                
                CCLabelTTF *score=[CCLabelTTF labelWithString:@"BEST SCORE: 96,418" fontName:@"Source Sans Pro" fontSize:15.0f dimensions:CGSizeMake(180, 100) hAlignment:UITextAlignmentLeft];
                [score setPosition:ccp(100, 85)];
                [score setColor:ccc3(255, 255, 255)];
                [signSprite addChild:score];
                
                CCSprite *newSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/ribbon-perfect.png")];
                [newSprite setPosition:ccp(signSprite.contentSize.width - (newSprite.contentSize.width / 2.0f), (signSprite.contentSize.height - (newSprite.contentSize.height / 2.0f)))];
                [signSprite addChild:newSprite];
            }
            else {
                CCLabelTTF *playlabel=[CCLabelTTF labelWithString:@"PLAY NOW" fontName:@"Chango" fontSize:18.0f];
                playlabel.position=ccp(playSprite.contentSize.width / 2.0f, playSprite.contentSize.height / 2.0f);
                [playSprite addChild:playlabel];
                
                //new sprite
                CCSprite *newSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/ribbon-new.png")];
                [newSprite setPosition:ccp(signSprite.contentSize.width - (newSprite.contentSize.width / 2.0f) - 1, 83)];
                [signSprite addChild:newSprite];
        
                //days ago
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"NEVER PLAYED" fontName:@"Source Sans Pro" fontSize:14.0f dimensions:CGSizeMake(180, 100) hAlignment:UITextAlignmentLeft];
                [days setPosition:ccp(100, 45)];
                [days setColor:ccc3(255, 255, 255)];
                [signSprite addChild:days];
            }
        }
        
        [gameWorld.Blackboard.RenderLayer addChild:signSprite z:3];
    }
    
    [signSprite setOpacity:255];
    [signSprite setScale:0];
    
    CGPoint placePos=ParentGO.Position;
    if([((NSObject*)ParentGO) isKindOfClass:[SGJmapMasteryNode class]])
        placePos=((SGJmapMasteryNode*)ParentGO).MasteryPinPosition;


    [signSprite setPosition:[BLMath AddVector:ccp(0, 30 + (signSprite.contentSize.height / 2.0f)) toVector:placePos]];
    
    [signSprite runAction:[InteractionFeedback enlargeTo1xAction]];
    
    hitbox=CGRectMake(signSprite.position.x-(signSprite.contentSize.width / 2.0f), signSprite.position.y-(signSprite.contentSize.height / 2.0f), signSprite.contentSize.width, 60);
    
    NSLog(@"i'm selected! %@", ParentGO._id);
}

-(void)removeSign
{
    if(signSprite && ParentGO.Selected)
    {
        [signSprite runAction:[InteractionFeedback reduceTo0xAndHide]];
    }
}

@end
