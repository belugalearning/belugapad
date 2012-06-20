//
//  BDotGridAnchorTouch.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridShapeTouch.h"
#import "DWDotGridShapeGameObject.h"
#import "DWDotGridTileGameObject.h"
#import "DWDotGridHandleGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "UsersService.h"
#import "AppDelegate.h"

@interface BDotGridShapeTouch()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}
@end

@implementation BDotGridShapeTouch

-(BDotGridShapeTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridShapeTouch*)[super initWithGameObject:aGameObject withData:data];
    shape=(DWDotGridShapeGameObject*)gameObject;
    
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
    if(messageType==kDWswitchSelection)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self checkTouchSwitchSelection:loc];
    }
    if(messageType==kDWmoveShape)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self moveShape:loc];
        
    }
    if(messageType==kDWresizeShape)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self resizeShape:loc];
    }

}

-(void)checkTouchSwitchSelection:(CGPoint)location
{
    // THE TINTING BEHAVIOUR HERE CAN ALSO BE APPLIED BY THE TILE OBJECT RENDER
    // check through this shape's tiles
    for(DWDotGridTileGameObject *tile in shape.tiles)
    {
        // and for each one see if the hit was in a tile box
        if(CGRectContainsPoint(tile.mySprite.boundingBox, location) && !shape.Disabled)
        {
            
            // then if that tile is not selected, make it red
            if(!tile.Selected){
                [tile.mySprite setColor:ccc3(89,133,136)];
                tile.Selected=YES;
                [usersService logEvent:BL_PA_DG_TOUCH_BEGIN_SELECT_TILE withAdditionalData:nil];
            }
            
            // otherwise, make it white again
            else{
                [tile.mySprite setColor:ccc3(255, 255, 255)];
                tile.Selected=NO;
                [usersService logEvent:BL_PA_DG_TOUCH_BEGIN_DESELECT_TILE withAdditionalData:nil];
            }
        }
    }
}

-(void)resizeShape:(CGPoint)location
{

    gameWorld.Blackboard.FirstAnchor=(DWGameObject*)shape.firstAnchor;
    gameWorld.Blackboard.LastAnchor=(DWGameObject*)shape.lastAnchor;
}

-(void)moveShape:(CGPoint)location
{
    NSLog(@"do stuff here to do stuff to move!");
}

-(void) dealloc
{
    [super dealloc];
}

@end
