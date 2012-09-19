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
#import "DWDotGridAnchorGameObject.h"
#import "DWDotGridTileGameObject.h"

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
                s.myHeight=[CCLabelTTF labelWithString:strHeight fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
                [gameWorld.Blackboard.ComponentRenderLayer addChild:s.myHeight];
            }
            else
            {
                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
                [s.myHeight setString:strHeight];
            }
            if(!s.myWidth)
            {
                s.myWidth=[CCLabelTTF labelWithString:strWidth fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
                [s.myWidth setPosition:ccp(xPosForWidthLabel,yPosForWidthLabel)];
                [gameWorld.Blackboard.ComponentRenderLayer addChild:s.myWidth];
            }
            else
            {
                [s.myWidth setPosition:ccp(xPosForWidthLabel,yPosForWidthLabel)];
                [s.myWidth setString:strWidth];
            }
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        
        //GJ: these make no sense -- bool is never used
        //BOOL useAnimation = NO;
        //if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setPos];
    }

    if(messageType==kDWdismantle)
    {
        for(DWDotGridTileGameObject *t in s.tiles)
        {
            [t handleMessage:kDWdismantle];
        }
        
        [s.myHeight removeFromParentAndCleanup:YES];
        [s.myWidth removeFromParentAndCleanup:YES];
        [gameWorld delayRemoveGameObject:s];
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
