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
        //[tile.mySprite setColor:ccc3(255,0,0)];
        NSLog(@"tile hit - my value is %d, myXpos %d, myYpos %d", tile.myXpos*tile.myYpos, tile.myXpos, tile.myYpos);
        if(!tile.myText)
        {

            if(tile.operatorType==kOperatorAdd)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos+tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
            else if(tile.operatorType==kOperatorSub)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos-tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
            else if(tile.operatorType==kOperatorMul)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos*tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
            else if(tile.operatorType==kOperatorDiv)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", tile.myXpos/tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
            
            [tile.myText setPosition:[tile.mySprite convertToNodeSpace:tile.Position]];
            [tile.myText setColor:ccc3(0,0,0)];
            [tile.mySprite addChild:tile.myText];

            //NSLog(@"myText pos - %@, sprite pos %@", NSStringFromCGPoint(tile.myText.position), NSStringFromCGPoint(tile.mySprite.position));
            
        }
    }    
}

-(void) dealloc
{
    [super dealloc];
}

@end
