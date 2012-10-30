//
//  BDotGridAnchorTouch.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridShapeTouch.h"
#import "DWDotGridShapeGameObject.h"
#import "DWDotGridShapeGroupGameObject.h"
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
    location=[shape.RenderLayer convertToNodeSpace:location];
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
                    gameWorld.Blackboard.ProximateObject=shape;
                    
                }
                if(shape.MyNumberWheel)
                {
                    DWNWheelGameObject *w=(DWNWheelGameObject*)shape.MyNumberWheel;
                    
                    w.InputValue=[shape.tiles count];
                    [w handleMessage:kDWupdateObjectData];
                    
                    if(w.CountBubbleLabel)
                        [w.CountBubbleLabel setString:[NSString stringWithFormat:@"%d", [shape.tiles count]]];
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
                if(shape.MyNumberWheel)
                {
                    DWNWheelGameObject *w=(DWNWheelGameObject*)shape.MyNumberWheel;
                    w.InputValue=0;
                    [w handleMessage:kDWupdateObjectData];
                    
                    if(w.CountBubbleLabel)
                        [w.CountBubbleLabel setString:@"0"];
                }
                return;
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
                gameWorld.Blackboard.ProximateObject=tile;
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
                DWNWheelGameObject *w=(DWNWheelGameObject*)shape.MyNumberWheel;
                w.InputValue=theValue;
                [w handleMessage:kDWupdateObjectData];
                
                if(w.CountBubbleLabel)
                    [w.CountBubbleLabel setString:[NSString stringWithFormat:@"%d", theValue]];
            }
            if(shape.countLabelType)
            {
                if([shape.countLabelType isEqualToString:@"SHOW_SELECTED"])
                {
                    if(shape.countLabel && !shape.shapeGroup)
                    {
                        [shape.countBubble setVisible:YES];
                        NSString *newStr=[NSString stringWithFormat:@"%d",[self returnSelectedTiles]];
                        [shape.countLabel setString:newStr];
                    }
                    else if(shape.shapeGroup)
                    {
                        NSString *newStr=[NSString stringWithFormat:@"%d",[self returnSelectedTilesInShapeGroup]];
                        DWDotGridShapeGroupGameObject *sg=(DWDotGridShapeGroupGameObject*)shape.shapeGroup;
                        [sg.countBubble setVisible:YES];
                        [sg.countLabel setString:newStr];
                    }
                    
                }
                else if([shape.countLabelType isEqualToString:@"SHOW_FRACTION"])
                {

                    if(shape.countLabel && !shape.shapeGroup)
                    {
                        [shape.countBubble setVisible:YES];
                        NSString *newStr=[NSString stringWithFormat:@"%d/%d",[self returnSelectedTiles], [shape.tiles count]];
                        [shape.countLabel setString:newStr];
                    }
                    else if(shape.shapeGroup)
                    {
                        DWDotGridShapeGroupGameObject *sg=(DWDotGridShapeGroupGameObject*)shape.shapeGroup;
                        [sg.countBubble setVisible:YES];
                        NSString *newStr=[NSString stringWithFormat:@"%d/%d",[self returnSelectedTilesInShapeGroup], [self returnTotalTilesInShapeGroup]];
                        [sg.countLabel setString:newStr];
                    }
                }
            }
        }
    }
}

-(int)returnSelectedTiles
{
    int selectedTiles=0;
    
    for(DWDotGridTileGameObject *t in shape.tiles)
    {
        if(t.Selected)
            selectedTiles++;
    }
    
    return selectedTiles;
}

-(int)returnSelectedTilesInShapeGroup
{
    int selectedTiles=0;
    DWDotGridShapeGroupGameObject *sg=(DWDotGridShapeGroupGameObject*)shape.shapeGroup;
    
    for(DWDotGridShapeGameObject *s in sg.shapesInMe)
    {
        for(int i=0;i<[s.tiles count];i++)
        {
            DWDotGridTileGameObject *t=[s.tiles objectAtIndex:i];
            if(t.Selected)
                selectedTiles++;
        }
    }
    return selectedTiles;
}

-(int)returnTotalTilesInShapeGroup
{
    int totalTiles=0;
    DWDotGridShapeGroupGameObject *sg=(DWDotGridShapeGroupGameObject*)shape.shapeGroup;
    
    for(DWDotGridShapeGameObject *s in sg.shapesInMe)
    {
        totalTiles+=[s.tiles count];
    }
    return totalTiles;
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
