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
}

-(void)setSprite
{
    NSString *sname=[[gameObject store] objectForKey:RENDER_IMAGE_NAME];
    if(!sname) sname=@"selector.png";
    
    mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/numberline/%@", sname]))];
    
    //tagged for staged introduction into problem
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [mySprite setTag:1];
        [mySprite setOpacity:0];
    }
    
    [mySprite setPosition:ccp(selector.pos.x, selector.pos.y)];
    
    
    [[gameWorld GameScene].ForeLayer addChild:mySprite z:0];
    
}


@end
