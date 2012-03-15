//
//  BNLineSelectorRender.m
//  belugapad
//
//  Created by David Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "global.h"
#import "ToolScene.h"
#import "BNLineSelectorRender.h"
#import "DWSelectorGameObject.h"

@implementation BNLineSelectorRender

-(BNLineSelectorRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineSelectorRender*)[super initWithGameObject:aGameObject withData:data];
    selector = (DWSelectorGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        [self setSprite];
    }
    if(messageType==kDWrenderSelection)
    {
        NSNumber *num=[payload objectForKey:@"VALUE"];
        [self renderLabelSelection:[num stringValue]];
    }
}

-(void)renderLabelSelection:(NSString*)labelText
{
    if(selectionLabel)
    {
        [[gameWorld GameScene].ForeLayer removeChild:selectionLabel cleanup:YES];
    }
    
    selectionLabel=[CCLabelTTF labelWithString:labelText fontName:@"Helvetica" fontSize:40];
    [selectionLabel setPosition:CGPointMake(selector.pos.x, selector.pos.y+10)];
    [[gameWorld GameScene].ForeLayer addChild:selectionLabel];
}

-(void)setSprite
{
    NSString *sname=[[gameObject store] objectForKey:RENDER_IMAGE_NAME];
    if(!sname) sname=@"selector.png";
    
    mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/numberline/%@", sname]))];
    
    //tagged for staged introduction into problem
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [mySprite setTag:2];
        [mySprite setOpacity:0];
    }
    
    [mySprite setPosition:ccp(selector.pos.x, selector.pos.y)];
    
    
    [[gameWorld GameScene].ForeLayer addChild:mySprite z:0];
    
    CCSprite *connector=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/selector-connector.png")];
    [connector setPosition:CGPointMake(selector.pos.x, selector.pos.y-92)];
    [connector setTag:3];
    [connector setOpacity:0];
    [[gameWorld GameScene].ForeLayer addChild:connector];
    
    
}


@end
