//
//  BContainerRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BContainerRender.h"
#import "global.h"
#import "ToolScene.h"

@implementation BContainerRender

-(BContainerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BContainerRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        [self setSprite];
    }
    
    if(messageType==kDWenable)
    {
        [mySprite setVisible:YES];
    }
    
    if(messageType==kDWhighlight)
    {
        [self showHighlight];
    }

    if(messageType==kDWunhighlight)
    {
        [self hideHighlight];
    }
}

-(void)showHighlight
{
    if(myHighlight)return;
    
    NSString *sname=[[gameObject store] objectForKey:@"RENDER_HIGHLIGHT_IMAGE_NAME"];
    if(!sname) sname=@"obj-blockholder-mount1x1_block1.png";
    
    myHighlight=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/blockholders/%@", sname]))];    
    
    float x=[[[gameObject store] objectForKey:POS_X] floatValue];
    float y=[GOS_GET(POS_Y) floatValue];
    
    [myHighlight setPosition:ccp(x, y)];
    
    [[gameWorld GameScene].ForeLayer addChild:myHighlight z:0];
}

-(void)hideHighlight
{
    [[gameWorld GameScene].ForeLayer removeChild:myHighlight cleanup:YES];
    myHighlight=nil;
}

-(void)setSprite
{
    NSString *sname=[[gameObject store] objectForKey:RENDER_IMAGE_NAME];
    if(!sname) sname=@"obj-blockholder-mount1x1.png";
    
    mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/blockholders/%@", sname]))];
    
    //this is effectively redundant -- staged introduction will reset to max
    [mySprite setOpacity:120];

    //tagged for staged introduction into problem
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [mySprite setTag:1];
        [mySprite setOpacity:0];
    }
    
    float x=[[[gameObject store] objectForKey:POS_X] floatValue];
    float y=[GOS_GET(POS_Y) floatValue];
    
    [mySprite setPosition:ccp(x, y)];
    
    BOOL inactive=[[[gameObject store] objectForKey:HIDDEN] boolValue];
    if(inactive)
    {
        [mySprite setVisible:NO];
    }
    
    [[gameWorld GameScene].ForeLayer addChild:mySprite z:0];
    
}

-(void) dealloc
{
    [mySprite release];
    [super dealloc];
}


@end
