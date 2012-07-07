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
            signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/NodeOverlayBackground.png")];
            
            //show play again
            CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/PlayAgainButton.png")];
            [playSprite setPosition:ccp(240, 30)];
            [signSprite addChild:playSprite];
            
            //days ago
            CCLabelTTF *days=[CCLabelTTF labelWithString:@"Today" dimensions:CGSizeMake(300, 100) alignment:UITextAlignmentLeft fontName:@"Helvetica" fontSize:48.0f];
            [days setPosition:ccp(165, 32)];
            [days setColor:ccc3(150, 150, 150)];
            [signSprite addChild:days];
        }
        else {
            //mastery node
            signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/NodeOverlayBackground.png")];
            
            if(ParentGO.EnabledAndComplete)
            {
                //show play again
                CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/PlayAgainButton.png")];
                [playSprite setPosition:ccp(240, 30)];
                [signSprite addChild:playSprite];
                
                //days ago
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"Today" dimensions:CGSizeMake(300, 100) alignment:UITextAlignmentLeft fontName:@"Helvetica" fontSize:48.0f];
                [days setPosition:ccp(165, 32)];
                [days setColor:ccc3(150, 150, 150)];
                [signSprite addChild:days];
            }
            else {
                //show play, new
                CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/PlayButton.png")];
                [playSprite setPosition:ccp(240, 30)];
                [signSprite addChild:playSprite];
                
                CCSprite *newSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/NewBanner.png")];
                [newSprite setPosition:ccp(270, 115)];
                [signSprite addChild:newSprite];
        
                //days ago
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"Never" dimensions:CGSizeMake(300, 100) alignment:UITextAlignmentLeft fontName:@"Helvetica" fontSize:48.0f];
                [days setPosition:ccp(165, 32)];
                [days setColor:ccc3(150, 150, 150)];
                [signSprite addChild:days];
            }
            
            //node title
            CCLabelTTF *title=[CCLabelTTF labelWithString:ParentGO.UserVisibleString dimensions:CGSizeMake(300, 150) alignment:UITextAlignmentLeft fontName:@"Helvetica" fontSize:18.0f];
            [title setPosition:ccp(195, 63)];
            [title setColor:ccc3(90, 90, 90)];
            [signSprite addChild:title];
        }
        
        [gameWorld.Blackboard.RenderLayer addChild:signSprite];
    }
    
    [signSprite setOpacity:255];
    [signSprite setScale:0];
    [signSprite setPosition:ParentGO.Position];
    
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
