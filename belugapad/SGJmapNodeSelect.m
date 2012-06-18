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

static float hitProximity=40.0f;

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
    if([BLMath DistanceBetween:ParentGO.Position and:pos]<hitProximity)
    {
      
        if(ParentGO.Selected)
        {
            //already selected -- start pipeline
            
            NSLog(@"i'm starting! %@", ParentGO._id);
            ParentGO.Selected=YES;
        }
        
        else
        {
            //select me / show sign 
            //todo -- this should only work if enabled (otherwise resort to mastery node if applicable)
            
            [self showSign];
            
            NSLog(@"i'm selected! %@", ParentGO._id);
            ParentGO.Selected=YES;
        }
        
    }
    else {
        [self removeSign];
        ParentGO.Selected=NO;

    }
    
    return ParentGO.Selected;
}

-(void)deselect
{
    ParentGO.Selected=NO;
}

-(void)showSign
{
    if(!signSprite)
    {
        signSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/sign.png")];
        [ParentGO.RenderBatch.parent addChild:signSprite];
    }
    
    [signSprite setOpacity:255];
    [signSprite setScale:0];
    [signSprite setPosition:ParentGO.Position];
    
    [signSprite runAction:[InteractionFeedback enlargeTo1xAction]];
}

-(void)removeSign
{
    if(signSprite && ParentGO.Selected)
    {
        [signSprite runAction:[InteractionFeedback reduceTo0xAndHide]];
    }
}

@end
