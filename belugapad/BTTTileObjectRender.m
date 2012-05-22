//
//  BDotGridAnchorObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BTTTileObjectRender.h"
#import "DWTTTileGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"

@implementation BTTTileObjectRender

-(BTTTileObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BTTTileObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    
    tile=(DWTTTileGameObject*)gameObject;
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!tile.mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!tile.mySprite) { 
            [self setSprite];
        }

        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
    }
    if(messageType==kDWdismantle)
    {
        [[tile.mySprite parent] removeChild:tile.mySprite cleanup:YES];
    } 
    
    if(messageType==kDWswitchSelection)
    {
        if(tile.operatorType==kOperatorAdd)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos+tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
        else if(tile.operatorType==kOperatorSub)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos-tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
        else if(tile.operatorType==kOperatorMul)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos*tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
        else if(tile.operatorType==kOperatorDiv)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", tile.myXpos/tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE]; 
        [tile.myText setPosition:[tile.mySprite convertToNodeSpace:tile.Position]];
        [tile.myText setColor:ccc3(83,93,100)];
        if(gameWorld.Blackboard.inProblemSetup){
            [tile.myText setTag:3];
            [tile.myText setOpacity:0];
        }
        [tile.mySprite addChild:tile.myText];
    }
}



-(void)setSprite
{    

    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

        
    spriteFileName=[NSString stringWithFormat:@"/images/timestables/tile%d.png", tile.Size];
    tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [tile.mySprite setPosition:tile.Position];
    //[anch.mySprite setScale:0.5f];
    
    if(tile.Disabled)[tile.mySprite setColor:ccc3(40,40,40)];
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [tile.mySprite setTag:1];
        [tile.mySprite setOpacity:0];
    }

    

    [[gameWorld Blackboard].ComponentRenderLayer addChild:tile.mySprite z:2];

}

-(void)switchSelection
{
    if(tile.Disabled)
    {
        [gameWorld.Blackboard.SelectedObjects removeObject:tile];
    }
    else {
        [gameWorld.Blackboard.SelectedObjects addObject:tile];
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
