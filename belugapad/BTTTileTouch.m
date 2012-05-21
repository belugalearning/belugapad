//
//  BDotGridAnchorTouch.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BTTTileTouch.h"
#import "DWTTTileGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "ToolHost.h"
#import "BLMath.h"


@implementation BTTTileTouch

-(BTTTileTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BTTTileTouch*)[super initWithGameObject:aGameObject withData:data];
    tile=(DWTTTileGameObject*)gameObject;
    //init pos x & y in case they're not set elsewhere
    
    
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
     if(messageType==kDWrenderSelection)
     {
         
     }
    
    if(messageType==kDWcanITouchYou)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self checkTouch:loc];
    }
    
    if(messageType==kDWaddMeToSelection)
    {
        
    }
    
    if(messageType==kDWremoveMeFromSelection)
    {
        
    }
    
    if(messageType==kDWremoveAllFromSelection)
    {
        
    }
}

-(void)checkTouch:(CGPoint)hitLoc
{
    
    
    if(CGRectContainsPoint(tile.mySprite.boundingBox, hitLoc))
    {
        if(!tile.Disabled){

            NSLog(@"tile hit - my value is %d, myXpos %d, myYpos %d", tile.myXpos*tile.myYpos, tile.myXpos, tile.myYpos);
            if(!tile.myText)
            {

                tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos*tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
                [tile.myText setPosition:[tile.mySprite convertToNodeSpace:tile.Position]];
                [tile.myText setColor:ccc3(83,93,100)];
                [tile.mySprite addChild:tile.myText];

            }
            
            if(!tile.Selected)
            {
                tile.Selected=YES;
                [gameWorld.Blackboard.SelectedObjects addObject:tile];
                tile.selSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/selectionbox.png")];
                [tile.selSprite setPosition:[tile.mySprite convertToNodeSpace:tile.Position]];
                [tile.mySprite addChild:tile.selSprite];
                gameWorld.Blackboard.LastSelectedObject=gameObject;
            
            }
            else
            { 
                tile.Selected=NO;
                [gameWorld.Blackboard.SelectedObjects removeObject:tile];
                [tile.selSprite removeFromParentAndCleanup:YES];
            }
        }
    }    
}

-(void) dealloc
{
    [super dealloc];
}

@end
