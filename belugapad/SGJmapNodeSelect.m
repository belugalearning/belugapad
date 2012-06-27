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

#import "JourneyScene.h"

static float hitProximity=40.0f;
static float hitProximitySign=100.0f;

@implementation SGJmapNodeSelect

-(SGJmapNodeSelect*)initWithGameObject:(id<Transform, CouchDerived, Selectable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(BOOL)trySelectionForPosition:(CGPoint)pos
{
    if([BLMath DistanceBetween:ParentGO.Position and:pos]<(ParentGO.Selected ? hitProximitySign : hitProximity))
    {
      
        if(ParentGO.Selected)
        {
            //already selected -- start pipeline
            ContentService *cs=(ContentService*)((AppController*)[UIApplication sharedApplication].delegate).contentService;
            
            if([cs createAndStartFunnelForNode:ParentGO._id])
            {
                //[((AppController*)[UIApplication sharedApplication].delegate) startToolHostFromJmapPos:ParentGO.Position];
                
                [((JourneyScene*)[gameWorld GameScene]) startTransitionToToolHostWithPos:ParentGO.Position];
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
    return ParentGO.Selected;
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
            signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/sign.png")];
            
        }
        else {
            //mastery node
            signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/NodeOverlayBackground.png")];
            
            if(ParentGO.EnabledAndComplete)
            {
                //show play again
                CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/PlayAgainButton.png")];
                [playSprite setPosition:ccp(50,-50)];
                [signSprite addChild:playSprite];
                
                //days ago
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"Today" fontName:@"Helvetica" fontSize:18.0f];
                [days setPosition:ccp(-50, -50)];
                [signSprite addChild:days];
            }
            else {
                //show play, new
                CCSprite *playSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/PlayButton.png")];
                [playSprite setPosition:ccp(50,-50)];
                [signSprite addChild:playSprite];
                
                CCSprite *newSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/NewBanner.png")];
                [newSprite setPosition:ccp(50, 50)];
                [signSprite addChild:newSprite];
        
                //days ago
                CCLabelTTF *days=[CCLabelTTF labelWithString:@"Never" fontName:@"Helvetica" fontSize:18.0f];
                [days setPosition:ccp(-50, -50)];
                [signSprite addChild:days];
            }
            
            //node title
            CCLabelTTF *title=[CCLabelTTF labelWithString:ParentGO.UserVisibleString fontName:@"Helvetica" fontSize:14.0f];
            [title setPosition:ccp(-50, 50)];
            [signSprite addChild:title];
        }
        
        [ParentGO.RenderBatch.parent addChild:signSprite];
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
