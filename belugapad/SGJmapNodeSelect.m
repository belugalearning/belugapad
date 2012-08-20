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

#import "AppDelegate.h"
#import "ContentService.h"

#import "SGJmapNode.h"
#import "SGJmapMasteryNode.h"

#import "JMap.h"

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
    
    if([gameObject isKindOfClass:[SGJmapMasteryNode class]])
        if(((SGJmapMasteryNode*)gameObject).Disabled)
            return NO;
    
    if([BLMath DistanceBetween:ParentGO.Position and:pos]<(ParentGO.Selected ? ParentGO.HitProximitySign : ParentGO.HitProximity))
    {
        ret=YES;
      
        if(ParentGO.Selected)
        {
            //already selected -- start pipeline
            ContentService *cs=(ContentService*)((AppController*)[UIApplication sharedApplication].delegate).contentService;
            
            if([cs createAndStartFunnelForNode:ParentGO._id])
            {
                //[((AppController*)[UIApplication sharedApplication].delegate) startToolHostFromJmapPos:ParentGO.Position];
                
                [((JMap*)[gameWorld GameScene]) startTransitionToToolHostWithPos:ParentGO.Position];
            }
            
            NSLog(@"i'm starting! %@", ParentGO._id);
            ParentGO.Selected=YES;
        }
        
        else
        {
            //select me / show sign 
            //todo -- this should only work if enabled (otherwise resort to mastery node if applicable)
            
            //this is a bit hacky -- and a good demonstration of why this should potentially be two components
            if([gameObject isKindOfClass:[SGJmapNode class]])
            {
                SGJmapNode *gom=(SGJmapNode*)gameObject;
                if(gom.EnabledAndComplete)
                {
                    //show the sign on our own node
                    [self showSignWithForce:NO];
                }
                else {
                    //show the sign on our parent mastery
                    [gom.MasteryNode.NodeSelectComponent showSignWithForce:YES];
                }
            }
            else {
                //this is mastery -- pop the sign
                [self showSignWithForce:NO];
            }
        }
        
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
            if(ParentGO.EnabledAndComplete)
                signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/tooltip-base-tall.png")];
            else
                signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/tooltip-base-small.png")];
            
            //show play again
            CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/play-button-normal.png")];
            [playSprite setPosition:ccp(signSprite.contentSize.width / 2.0f, 40)];
            [signSprite addChild:playSprite];
            
            CCLabelTTF *playlabel=[CCLabelTTF labelWithString:@"PLAY AGAIN" fontName:@"Chango" fontSize:18.0f];
            playlabel.position=ccp(playSprite.contentSize.width / 2.0f, playSprite.contentSize.height / 2.0f);
            [playSprite addChild:playlabel];
            
            CCLabelTTF *score=[CCLabelTTF labelWithString:@"BEST SCORE: 16,024" dimensions:CGSizeMake(180, 100) alignment:UITextAlignmentLeft fontName:@"Source Sans Pro" fontSize:15.0f];
            [score setPosition:ccp(100, 85)];
            [score setColor:ccc3(255, 255, 255)];
            [signSprite addChild:score];
            
            CCSprite *newSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/ribbon-perfect.png")];
            [newSprite setPosition:ccp(signSprite.contentSize.width - (newSprite.contentSize.width / 2.0f), (signSprite.contentSize.height - (newSprite.contentSize.height / 2.0f)))];
            [signSprite addChild:newSprite];
            
            //days ago
            CCLabelTTF *days=[CCLabelTTF labelWithString:@"LAST PLAYED: TODAY" dimensions:CGSizeMake(180, 100) alignment:UITextAlignmentLeft fontName:@"Source Sans Pro" fontSize:14.0f];
            [days setPosition:ccp(100, 45)];
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
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"LAST PLAYED: TODAY" dimensions:CGSizeMake(180, 100) alignment:UITextAlignmentLeft fontName:@"Source Sans Pro" fontSize:14.0f];
                [days setPosition:ccp(100, 45)];
                [days setColor:ccc3(200, 200, 200)];
                [signSprite addChild:days];
                
                CCLabelTTF *playlabel=[CCLabelTTF labelWithString:@"PLAY AGAIN" fontName:@"Chango" fontSize:18.0f];
                playlabel.position=ccp(playSprite.contentSize.width / 2.0f, playSprite.contentSize.height / 2.0f);
                [playSprite addChild:playlabel];
                
                CCLabelTTF *score=[CCLabelTTF labelWithString:@"BEST SCORE: 96,418" dimensions:CGSizeMake(180, 100) alignment:UITextAlignmentLeft fontName:@"Source Sans Pro" fontSize:15.0f];
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
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"NEVER PLAYED" dimensions:CGSizeMake(180, 100) alignment:UITextAlignmentLeft fontName:@"Source Sans Pro" fontSize:14.0f];
                [days setPosition:ccp(100, 45)];
                [days setColor:ccc3(255, 255, 255)];
                [signSprite addChild:days];
            }
        }
        
        [gameWorld.Blackboard.RenderLayer addChild:signSprite z:3];
    }
    
    [signSprite setOpacity:255];
    [signSprite setScale:0];
    [signSprite setPosition:[BLMath AddVector:ccp(0, 30 + (signSprite.contentSize.height / 2.0f)) toVector:ParentGO.Position]];
    
    [signSprite runAction:[InteractionFeedback enlargeTo1xAction]];
    
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
