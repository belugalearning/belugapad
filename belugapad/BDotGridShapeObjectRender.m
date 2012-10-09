//
//  BDotGridShapeObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridShapeObjectRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWDotGridShapeGameObject.h"
#import "DWDotGridShapeGroupGameObject.h"
#import "DWDotGridAnchorGameObject.h"
#import "DWDotGridHandleGameObject.h"
#import "DWDotGridTileGameObject.h"
#import "DWNWheelGameObject.h"

@implementation BDotGridShapeObjectRender

-(BDotGridShapeObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridShapeObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    
    s=(DWDotGridShapeGameObject*)gameObject;
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!s.tiles||[s.tiles count]==0)return;
        
        if(s.shapeGroup)
        {
            DWDotGridShapeGroupGameObject *sg=(DWDotGridShapeGroupGameObject*)s.shapeGroup;
            if(!sg.hasLabels)
                sg.hasLabels=YES;
            else
                return;
        }
        
        if(s.RenderDimensions)
        {
            DWDotGridAnchorGameObject *fa=(DWDotGridAnchorGameObject*)s.firstAnchor;
            DWDotGridAnchorGameObject *la=(DWDotGridAnchorGameObject*)s.lastAnchor;
            
            CGPoint bottomLeft=fa.Position;
            CGPoint topRight=la.Position;
            
            float topMostY=0;
            float leftMostX=0;
            
            if(bottomLeft.y<topRight.y)
                topMostY=topRight.y;
            else
                topMostY=bottomLeft.y;
            
            if(bottomLeft.x<topRight.x)
                leftMostX=bottomLeft.x;
            else
                leftMostX=topRight.x;
                
            
            // height label
            int height=fabsf(fa.myYpos-la.myYpos);
            NSString *strHeight=[NSString stringWithFormat:@"%d", height];
            
            float halfWayHeight=(bottomLeft.y+topRight.y)/2;
            float yPosForHeightLabel=halfWayHeight;
            float xPosForHeightLabel=leftMostX-50;
            
            // width label
            
            int width=fabsf(fa.myXpos-la.myXpos);
            NSString *strWidth=[NSString stringWithFormat:@"%d", width];
            
            float halfWayWidth=(bottomLeft.x+topRight.x)/2;
            float yPosForWidthLabel=topMostY+50;
            float xPosForWidthLabel=halfWayWidth;
            
            if(!s.myHeight)
            {
                s.myHeight=[CCLabelTTF labelWithString:strHeight fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
                [s.RenderLayer addChild:s.myHeight];
            }
            else
            {
                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
                [s.myHeight setString:strHeight];
            }
            if(!s.myWidth)
            {
                s.myWidth=[CCLabelTTF labelWithString:strWidth fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
                [s.myWidth setPosition:ccp(xPosForWidthLabel,yPosForWidthLabel)];
                [s.RenderLayer addChild:s.myWidth];
            }
            else
            {
                [s.myWidth setPosition:ccp(xPosForWidthLabel,yPosForWidthLabel)];
                [s.myWidth setString:strWidth];
            }
            
            if(s.MyNumberWheel)
            {
                CCLabelTTF *l=nil;
                
                if(!((DWNWheelGameObject*)s.MyNumberWheel).Label)
                {
                    l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@x%@", s.myWidth.string, s.myHeight.string] fontName:SOURCE fontSize:26.0f];
                    ((DWNWheelGameObject*)s.MyNumberWheel).Label=l;
                    [((DWNWheelGameObject*)s.MyNumberWheel).RenderLayer addChild:l];
                }
                else
                {
                    l=((DWNWheelGameObject*)s.MyNumberWheel).Label;
                    [l setString:[NSString stringWithFormat:@"%@x%@", s.myWidth.string, s.myHeight.string]];
                }
                
                [s.MyNumberWheel handleMessage:kDWupdateLabels];
            }
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        
        //GJ: these make no sense -- bool is never used
        //BOOL useAnimation = NO;
        //if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setPos];
    }

    if(messageType==kDWupdateSprite)
    {
//        if(s.myHeight)
//            [s.myHeight setPosition:[s.RenderLayer convertToWorldSpace:s.myHeight.position]];
//        if(s.myWidth)
//            [s.myWidth setPosition:[s.RenderLayer convertToWorldSpace:s.myWidth.position]];
    }

    
    if(messageType==kDWdismantle)
    {
        for(DWDotGridTileGameObject *t in s.tiles)
        {
            [t handleMessage:kDWdismantle];
        }
        
        if(s.resizeHandle)
        {
            [s.resizeHandle handleMessage:kDWdismantle];
            ((DWDotGridHandleGameObject*)s.resizeHandle).myShape=nil;
        }
        [s.myHeight removeFromParentAndCleanup:YES];
        [s.myWidth removeFromParentAndCleanup:YES];
        [gameWorld delayRemoveGameObject:s];
    }

    if(messageType==kDWupdateObjectData)
    {
        [self updateObjectDataFromNumberWheel];
    }
}

-(void)updateObjectDataFromNumberWheel
{
    if(s.MyNumberWheel)
    {
        DWNWheelGameObject *w=(DWNWheelGameObject*)s.MyNumberWheel;
        if(w.OutputValue<=[s.tiles count]){
            int selectedTiles=0;
            int tilesRequired=0;
            
            
            for(DWDotGridTileGameObject *t in s.tiles)
            {
                if(t.Selected)
                    selectedTiles++;
            }
            
            if(selectedTiles<w.OutputValue)
            {
                tilesRequired=w.OutputValue-selectedTiles;
                
                for(DWDotGridTileGameObject *t in s.tiles)
                {
                    if(!t.Selected && tilesRequired>0){
                        t.Selected=YES;
                        [t.selectedSprite setVisible:YES];
                        tilesRequired--;
                    }
                }
            }
            else
            {
                tilesRequired=selectedTiles-w.OutputValue;
                NSLog(@"tiles requiring action %d", tilesRequired);
                
                for(DWDotGridTileGameObject *t in [s.tiles reverseObjectEnumerator])
                {
                    if(t.Selected && tilesRequired>0){
                        t.Selected=NO;
                        [t.selectedSprite setVisible:NO];
                        tilesRequired--;
                        
                        NSLog(@"deselected a tile (tilesreq: %d, w outputval %d", tilesRequired, w.OutputValue);
                    }
                }
            }
        }
        else
        {
            DWNWheelGameObject *w=(DWNWheelGameObject*)s.MyNumberWheel;
            w.InputValue=[s.tiles count];
            [s.MyNumberWheel handleMessage:kDWupdateObjectData];
            
            for(DWDotGridTileGameObject *t in s.tiles)
            {
                t.Selected=YES;
                [t.selectedSprite setVisible:YES];
                [t.selectedSprite setColor:ccc3(255,0,0)];
                [t.selectedSprite runAction:[CCTintTo actionWithDuration:0.5f red:255 green:255 blue:255]];
            }
            
        }
    }
}


-(void)setSprite
{    
    
    
}

-(void)setPos
{
    
    
}

-(void) dealloc
{
    [super dealloc];
    s.tiles=nil;
    s.firstAnchor=nil;
    s.lastAnchor=nil;
    s.shapeGroup=nil;
}

@end
