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
#import "DWNWheelGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "LoggingService.h"
#import "AppDelegate.h"

@interface BDotGridShapeTouch()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
}
@end

@implementation BDotGridShapeTouch

-(BDotGridShapeTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridShapeTouch*)[super initWithGameObject:aGameObject withData:data];
    shape=(DWDotGridShapeGameObject*)gameObject;
    
    //init pos x & y in case they're not set elsewhere
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    loggingService = ac.loggingService;
    contentService = ac.contentService;
    
    
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
        
        if(!shape.SelectAllTiles)
            [self checkTouchSwitchSelection:loc];
        else
            [self checkTouchAndSwitchAll:loc];
            
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

-(void)checkTouchAndSwitchAll:(CGPoint)location
{
    for(DWDotGridTileGameObject *tile in shape.tiles)
    {
        // and for each one see if the hit was in a tile box
        if(CGRectContainsPoint(tile.mySprite.boundingBox, location) && !shape.Disabled)
        {
            
            // then if that tile is not selected, make it red
            if(!tile.Selected){
                for(DWDotGridTileGameObject *t in shape.tiles)
                {
                    [t.selectedSprite setVisible:YES];
                    t.Selected=YES;
                    [loggingService logEvent:BL_PA_DG_TOUCH_BEGIN_SELECT_TILE withAdditionalData:nil];
                    
                }
                return;
            }
            // otherwise, make it white again
            else{
                for(DWDotGridTileGameObject *t in shape.tiles)
                {
                    [t.selectedSprite setVisible:NO];
                    t.Selected=NO;
                    [loggingService logEvent:BL_PA_DG_TOUCH_BEGIN_SELECT_TILE withAdditionalData:nil];
                }
                return;
            }
            
            if(shape.MyNumberWheel)
            {
                ((DWNWheelGameObject*)shape.MyNumberWheel).InputValue=[shape.tiles count];
                [shape.MyNumberWheel handleMessage:kDWupdateObjectData];
            }
        }
    }
}



-(void)checkTouchSwitchSelection:(CGPoint)location
{
    location=[shape.RenderLayer convertToNodeSpace:location];
    // THE TINTING BEHAVIOUR HERE CAN ALSO BE APPLIED BY THE TILE OBJECT RENDER
    // check through this shape's tiles
    for(DWDotGridTileGameObject *tile in shape.tiles)
    {
        // and for each one see if the hit was in a tile box
        if(CGRectContainsPoint(tile.mySprite.boundingBox, location) && !shape.Disabled)
        {
            
            // then if that tile is not selected, make it red
            if(!tile.Selected){
                [tile.selectedSprite setVisible:YES];
                tile.Selected=YES;
                [loggingService logEvent:BL_PA_DG_TOUCH_BEGIN_SELECT_TILE withAdditionalData:nil];
            }

            // otherwise, make it white again
            else{
                [tile.selectedSprite setVisible:NO];
                tile.Selected=NO;
                [loggingService logEvent:BL_PA_DG_TOUCH_BEGIN_DESELECT_TILE withAdditionalData:nil];
            }
            if(shape.MyNumberWheel)
            {
                int theValue=0;
                for(DWDotGridTileGameObject *t in shape.tiles)
                {
                    if(t.Selected)
                        theValue++;
                }
                
                ((DWNWheelGameObject*)shape.MyNumberWheel).InputValue=theValue;
                [shape.MyNumberWheel handleMessage:kDWupdateObjectData];
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
