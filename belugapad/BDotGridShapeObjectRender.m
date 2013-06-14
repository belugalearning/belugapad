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
        
        DWDotGridAnchorGameObject *fa=(DWDotGridAnchorGameObject*)s.firstAnchor;
        DWDotGridAnchorGameObject *la=(DWDotGridAnchorGameObject*)s.lastAnchor;
        
        CGPoint bottomLeft=fa.Position;
        CGPoint topRight=la.Position;
        
        float topMostY=0;
        float leftMostX=0;
        float botMostY=0;
        float rightMostX=0;
        
        if(bottomLeft.y<topRight.y)
        {
            topMostY=topRight.y;
            botMostY=bottomLeft.y;
        }
        else
        {
            topMostY=bottomLeft.y;
            botMostY=topRight.y;
        }
        
        if(bottomLeft.x<topRight.x)
        {
            leftMostX=bottomLeft.x;
            rightMostX=topRight.x;
        }
        else
        {
            leftMostX=topRight.x;
            rightMostX=bottomLeft.x;
        }
        
        float halfWayHeight=(bottomLeft.y+topRight.y)/2;
        float halfWayWidth=(bottomLeft.x+topRight.x)/2;
        
        s.centreX=halfWayWidth;
        s.centreY=halfWayHeight;
        s.top=topMostY;
        s.bottom=botMostY;
        s.right=rightMostX;
        s.left=leftMostX;
        
            
            if(!s.tiles||[s.tiles count]==0)return;
            

            if(s.countLabelType && !s.countBubble)
            {
                
                
                float halfWayWidth=(bottomLeft.x+topRight.x)/2;
                CCSprite *countBubble=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/dotgrid/DG_counter_multiplication.png")];
                float botMostYAdj=botMostY-(countBubble.contentSize.height/1.5);
                CCLabelTTF *countBubbleLabel=[CCLabelTTF labelWithString:@"" fontName:CHANGO fontSize:20.0f];
                [countBubbleLabel setPosition:ccp(countBubble.contentSize.width/2, countBubble.contentSize.height/2)];
                [countBubble setPosition:ccp(halfWayWidth,botMostYAdj)];
                [countBubble setVisible:NO];
                
                if(!s.shapeGroup)
                {
                    s.countBubble=countBubble;
                    s.countLabel=countBubbleLabel;
                }
                else
                {
                    DWDotGridShapeGroupGameObject *sg=(DWDotGridShapeGroupGameObject*)s.shapeGroup;
                    if(!sg.countBubble){
                        sg.countBubble=countBubble;
                        sg.countLabel=countBubbleLabel;
                        s.countBubble=countBubble;
                    }
                }
                
                [s.RenderLayer addChild: countBubble];
                [countBubble addChild:countBubbleLabel];
            }
            
            if(s.countBubble)
            {
                float botMostYAdj=botMostY-(s.countBubble.contentSize.height/1.5);
                [s.countBubble setPosition:ccp(halfWayWidth,botMostYAdj)];
                [s handleMessage:kDWupdateLabels];
            }

        
    }
    if (messageType==kDWshapeDrawLabels)
    {
        if(s.RenderDimensions)
        {
            NSLog(@"shape is: %f, %f, %d, %d", s.ShapeX, s.ShapeY, (int)s.firstBoundaryAnchor, (int)s.lastBoundaryAnchor);
            
            //                if(s.shapeGroup)
            //                {
            //
            //                    DWDotGridShapeGroupGameObject *sg=(DWDotGridShapeGroupGameObject*)s.shapeGroup;
            //                    if(!sg.hasLabels)
            //                        sg.hasLabels=YES;
            //                    else
            //                        return;
            //                }
            
            DWDotGridAnchorGameObject *fa=(DWDotGridAnchorGameObject*)s.firstBoundaryAnchor;
            DWDotGridAnchorGameObject *la=(DWDotGridAnchorGameObject*)s.lastBoundaryAnchor;
            
            CGPoint bottomLeft=fa.Position;
            CGPoint topRight=la.Position;
            
            float topMostY=0;
            float leftMostX=0;
            float botMostY=0;
            float rightMostX=0;
            
            if(bottomLeft.y<topRight.y)
            {
                topMostY=topRight.y;
                botMostY=bottomLeft.y;
            }
            else
            {
                topMostY=bottomLeft.y;
                botMostY=topRight.y;
            }
            
            if(bottomLeft.x<topRight.x)
            {
                leftMostX=bottomLeft.x;
                rightMostX=topRight.x;
            }
            else
            {
                leftMostX=topRight.x;
                rightMostX=bottomLeft.x;
            }
            
            float halfWayHeight=(bottomLeft.y+topRight.y)/2;
            float halfWayWidth=(bottomLeft.x+topRight.x)/2;
            
            s.centreX=halfWayWidth;
            s.centreY=halfWayHeight;
            
            
            // height label
            int height=fabsf(fa.myYpos-la.myYpos);
            NSString *strHeight=[NSString stringWithFormat:@"%g", s.ShapeY];
            
            float yPosForHeightLabel=halfWayHeight;
            float xPosForHeightLabel=leftMostX-30;
            
            // width label
            
            int width=fabsf(fa.myXpos-la.myXpos);
            NSString *strWidth=[NSString stringWithFormat:@"%g", s.ShapeX];
            
            float yPosForWidthLabel=topMostY+30;
            float xPosForWidthLabel=halfWayWidth;
            
            if(!s.myHeight)
            {
                
                s.myHeight=[CCLabelTTF labelWithString:strHeight fontName:CHANGO fontSize:PROBLEM_DESC_FONT_SIZE];
                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
                
                if(gameWorld.Blackboard.inProblemSetup)
                {
                    [s.myHeight setOpacity:0];
                    [s.myHeight setTag:2];
                }
                
                [s.RenderLayer addChild:s.myHeight];
            }
            else
            {
                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
                [s.myHeight setString:strHeight];
            }
            if(!s.myWidth)
            {
                
                s.myWidth=[CCLabelTTF labelWithString:strWidth fontName:CHANGO fontSize:PROBLEM_DESC_FONT_SIZE];
                [s.myWidth setPosition:ccp(xPosForWidthLabel,yPosForWidthLabel)];
                
                if(gameWorld.Blackboard.inProblemSetup)
                {
                    [s.myWidth setOpacity:0];
                    [s.myWidth setTag:2];
                }
                
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
                
                if(s.autoUpdateWheel)[s.MyNumberWheel handleMessage:kDWupdateLabels];
            }
        }
        
    }

    
    if (messageType==kDWmoveSpriteToPosition) {
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
        if(s.myHeight)
            [[s.myHeight parent] removeChild:s.myHeight cleanup:YES];
        if(s.myWidth)
            [[s.myWidth parent] removeChild:s.myHeight cleanup:YES];
        
        if(s.countBubble)
           [[s.countBubble parent] removeChild:s.countBubble cleanup:YES];
        
        for(DWDotGridTileGameObject *t in s.tiles)
        {
            [t handleMessage:kDWdismantle];
        }
        
        if(s.resizeHandle)
        {
            [s.resizeHandle handleMessage:kDWdismantle];
            ((DWDotGridHandleGameObject*)s.resizeHandle).myShape=nil;
        }
        if(s.MyNumberWheel)
            [s.MyNumberWheel handleMessage:kDWdismantle];
            

        
        if(s.hintArrowX)
            [s.hintArrowX removeFromParentAndCleanup:YES];
        
        if(s.hintArrowY)
            [s.hintArrowY removeFromParentAndCleanup:YES];

        s.shapeGroup=nil;
        //[s.myHeight removeFromParentAndCleanup:YES];
        //[s.myWidth removeFromParentAndCleanup:YES];
        
        [gameWorld delayRemoveGameObject:s];
    }

    if(messageType==kDWupdateObjectData)
    {
        [self updateObjectDataFromNumberWheel];
    }
}

-(void)updateObjectDataFromNumberWheel
{
    if(s.MyNumberWheel && s.value==0)
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
    else if(s.MyNumberWheel && s.value>0)
    {
        DWNWheelGameObject *w=(DWNWheelGameObject*)s.MyNumberWheel;
        if(w.OutputValue<s.value)
        {
            for(DWDotGridTileGameObject *t in s.tiles)
            {
                t.Selected=NO;
                [t.selectedSprite setVisible:NO];
            }
        }
        else if(w.OutputValue>s.value)
        {
            w.InputValue=s.value;
            [w handleMessage:kDWupdateObjectData];
            for(DWDotGridTileGameObject *t in s.tiles)
            {
                t.Selected=YES;
                [t.selectedSprite setVisible:YES];
                [t.selectedSprite setColor:ccc3(255,0,0)];
                [t.selectedSprite runAction:[CCTintTo actionWithDuration:0.5f red:255 green:255 blue:255]];
            }
            
        }
        else
        {
            for(DWDotGridTileGameObject *t in s.tiles)
            {
                t.Selected=YES;
                [t.selectedSprite setVisible:YES];
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
    s.tiles=nil;
    s.firstAnchor=nil;
    s.lastAnchor=nil;
    s.shapeGroup=nil;
    s.myHeight=nil;
    s.myWidth=nil;
    s.countBubble=nil;
    [super dealloc];
}

@end
