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
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"


@implementation BDotGridShapeTouch

-(BDotGridShapeTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridShapeTouch*)[super initWithGameObject:aGameObject withData:data];
    shape=(DWDotGridShapeGameObject*)gameObject;
    
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
    if(messageType==kDWswitchSelection)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self checkTouchSwitchSelection:loc];
    }
}

-(void)checkTouchSwitchSelection:(CGPoint)location
{
    // THE TINTING BEHAVIOUR HERE CAN ALSO BE APPLIED BY THE TILE OBJECT RENDER
    // check through this shape's tiles
    for(DWDotGridTileGameObject *tile in shape.tiles)
    {
        // and for each one see if the hit was in a tile box
        if(CGRectContainsPoint(tile.mySprite.boundingBox, location))
        {
            
            // then if that tile is not selected, make it red
            if(!tile.Selected){
                [tile.mySprite setColor:ccc3(255, 0, 0)];
                tile.Selected=YES;
            }
            
            // otherwise, make it white again
            else{
                [tile.mySprite setColor:ccc3(255, 255, 255)];
                tile.Selected=NO;
            }
        }
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
