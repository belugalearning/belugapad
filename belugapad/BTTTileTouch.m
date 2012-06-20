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
#import "AppDelegate.h"
#import "UsersService.h"

@interface BTTTileTouch()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BTTTileTouch

-(BTTTileTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BTTTileTouch*)[super initWithGameObject:aGameObject withData:data];
    tile=(DWTTTileGameObject*)gameObject;
    //init pos x & y in case they're not set elsewhere
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
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
    
    if(messageType==kDWshowCalcBubble)
    {

        tile.ansSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/answerbubble.png")];
        [tile.ansSprite setPosition:[tile.mySprite convertToNodeSpace:ccp(tile.mySprite.position.x, tile.mySprite.position.y+55)]];
        //[tile.ansSprite setPosition:ccp(tile.mySprite.position.x, tile.mySprite.position.y+55)];
        //[tile.mySprite.parent addChild:tile.ansSprite z:9999];
        [tile.selSprite addChild:tile.ansSprite z:9999];
        
        CCLabelTTF *myText=[CCLabelTTF alloc];
        
        
        if(tile.operatorType==kOperatorAdd)myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d+%d", tile.myXpos, tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
        else if(tile.operatorType==kOperatorSub)myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d-%d", tile.myXpos, tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
        else if(tile.operatorType==kOperatorMul)myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%dx%d", tile.myXpos, tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
        else if(tile.operatorType==kOperatorDiv)myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d/%d", tile.myXpos, tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        //[myText setPosition:[tile.mySprite convertToNodeSpace:ccp(tile.Position.x, tile.Position.y+55)]];
        [myText setPosition:ccp(tile.ansSprite.contentSize.width/2, (tile.ansSprite.contentSize.height/2)-2)];
        [myText setColor:ccc3(83,93,100)];
        [tile.ansSprite addChild:myText];
        
        [tile.ansSprite runAction:[CCFadeOut actionWithDuration:2.0f]];
        [myText runAction:[CCFadeOut actionWithDuration:2.0f]];

            
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
                [usersService logEvent:BL_PA_TT_TOUCH_BEGIN_REVEAL_ANSWER
                    withAdditionalData:[NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                                           [NSNumber numberWithInt:tile.myXpos],
                                                                           [NSNumber numberWithInt:tile.myYpos], nil]
                                                                   forKey:@"tileCoords"]];
                
                if(tile.operatorType==kOperatorAdd)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos+tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
                
                else if(tile.operatorType==kOperatorSub)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos-tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
               
                else if(tile.operatorType==kOperatorMul)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tile.myXpos*tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];   
                
                else if(tile.operatorType==kOperatorDiv)tile.myText=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%g", tile.myXpos/tile.myYpos] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE]; 
                
                [tile.myText setPosition:[tile.mySprite convertToNodeSpace:tile.Position]];
                [tile.myText setColor:ccc3(200,200,200)];
                [tile.mySprite addChild:tile.myText];

            }
            
            gameWorld.Blackboard.LastSelectedObject=gameObject;

        }
    }    
}

-(void) dealloc
{
    [super dealloc];
}

@end
