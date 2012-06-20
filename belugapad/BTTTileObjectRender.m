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
#import "AppDelegate.h"
#import "UsersService.h"

@interface BTTTileObjectRender()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BTTTileObjectRender

-(BTTTileObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BTTTileObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
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
            [tile.myText setColor:ccc3(200,200,200)];
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
    NSDictionary *tileCoords = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:tile.myXpos], [NSNumber numberWithInt:tile.myYpos], nil] forKey:@"tileCoords"];
    
    if (tile.Disabled)
    {
        [usersService logEvent:BL_PA_TT_TOUCH_BEGIN_TAP_DISABLED_BOX withAdditionalData:tileCoords];
    }    
    else if(!tile.Selected)
    {
        [usersService logEvent:BL_PA_TT_TOUCH_BEGIN_SELECT_ANSWER withAdditionalData:tileCoords];
        [gameWorld.Blackboard.SelectedObjects addObject:tile];
        tile.Selected=YES;
        tile.selSprite=[CCSprite spriteWithFile:[NSString stringWithFormat:BUNDLE_FULL_PATH(@"/images/timestables/selectionbox%d.png"), tile.Size]];
        [tile.selSprite setPosition:tile.Position];
        [tile.mySprite.parent addChild:tile.selSprite z:1000];
        
    }
    else
    {
        [usersService logEvent:BL_PA_TT_TOUCH_BEGIN_DESELECT_ANSWER withAdditionalData:tileCoords];
        [gameWorld.Blackboard.SelectedObjects removeObject:tile];
        tile.Selected=NO;
        [tile.selSprite removeFromParentAndCleanup:YES];
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
