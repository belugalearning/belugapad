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
        if(!tile.myText && !tile.Disabled)
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
    
    if(messageType==kDWhandleTap)
    {
        [self handleTap];
    }
}



-(void)setSprite
{    

    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

    
    if(tile.isEndXPiece)spriteFileName=[NSString stringWithFormat:@"/images/timestables/tile%d_end_row.png", tile.Size];
    else if(tile.isEndYPiece)spriteFileName=[NSString stringWithFormat:@"/images/timestables/tile%d_end_col.png", tile.Size];
    else if(tile.isCornerPiece)spriteFileName=[NSString stringWithFormat:@"/images/timestables/tile%d_end_corner.png", tile.Size];

    else spriteFileName=[NSString stringWithFormat:@"/images/timestables/tile%d.png", tile.Size];
    
    tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [tile.mySprite setPosition:tile.Position];
    
    if(tile.Disabled && !tile.isEndXPiece && !tile.isEndYPiece && !tile.isCornerPiece)[tile.mySprite setColor:ccc3(40,40,40)];
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [tile.mySprite setTag:1];
        [tile.mySprite setOpacity:0];
    }

    

    [[gameWorld Blackboard].ComponentRenderLayer addChild:tile.mySprite z:2];

}

-(void)handleTap
{
    
    if(!tile.Selected && !tile.Disabled)
    {
        tile.Selected=YES;
        [gameWorld.Blackboard.SelectedObjects addObject:tile];
        tile.selSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/timestables/selectionbox%d.png"), tile.Size]];

        [tile.selSprite setPosition:tile.Position];
        [tile.mySprite.parent addChild:tile.selSprite z:1000];
        
    }
    else
    { 
        tile.Selected=NO;
        [gameWorld.Blackboard.SelectedObjects removeObject:tile];
        [tile.selSprite removeFromParentAndCleanup:YES];
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
