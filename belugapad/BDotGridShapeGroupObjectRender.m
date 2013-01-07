//
//  BDotGridShapeGroupObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 18/09/2012.
//
//

#import "BDotGridShapeGroupObjectRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWDotGridShapeGameObject.h"
#import "DWDotGridShapeGroupGameObject.h"
#import "DWDotGridAnchorGameObject.h"

@implementation BDotGridShapeGroupObjectRender

-(BDotGridShapeGroupObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridShapeGroupObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    
    sg=(DWDotGridShapeGroupGameObject*)gameObject;
    sg.shapesInMe=[[[NSMutableArray alloc]init] autorelease];
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
//        if(!s.tiles||[s.tiles count]==0)return;
//        if(s.RenderDimensions)
//        {
//            DWDotGridAnchorGameObject *fa=(DWDotGridAnchorGameObject*)s.firstAnchor;
//            DWDotGridAnchorGameObject *la=(DWDotGridAnchorGameObject*)s.lastAnchor;
//            
//            CGPoint bottomLeft=fa.Position;
//            CGPoint topRight=la.Position;
//            
//            float topMostY=0;
//            float leftMostX=0;
//            
//            if(bottomLeft.y<topRight.y)
//                topMostY=topRight.y;
//            else
//                topMostY=bottomLeft.y;
//            
//            if(bottomLeft.x<topRight.x)
//                leftMostX=bottomLeft.x;
//            else
//                leftMostX=topRight.x;
//            
//            
//            // height label
//            int height=fabsf(fa.myYpos-la.myYpos);
//            NSString *strHeight=[NSString stringWithFormat:@"%d", height];
//            
//            float halfWayHeight=(bottomLeft.y+topRight.y)/2;
//            float yPosForHeightLabel=halfWayHeight;
//            float xPosForHeightLabel=leftMostX-50;
//            
//            // width label
//            
//            int width=fabsf(fa.myXpos-la.myXpos);
//            NSString *strWidth=[NSString stringWithFormat:@"%d", width];
//            
//            float halfWayWidth=(bottomLeft.x+topRight.x)/2;
//            float yPosForWidthLabel=topMostY+50;
//            float xPosForWidthLabel=halfWayWidth;
//            
//            if(!s.myHeight)
//            {
//                s.myHeight=[CCLabelTTF labelWithString:strHeight fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
//                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
//                [gameWorld.Blackboard.ComponentRenderLayer addChild:s.myHeight];
//            }
//            else
//            {
//                [s.myHeight setPosition:ccp(xPosForHeightLabel,yPosForHeightLabel)];
//                [s.myHeight setString:strHeight];
//            }
//            if(!s.myWidth)
//            {
//                s.myWidth=[CCLabelTTF labelWithString:strWidth fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
//                [s.myWidth setPosition:ccp(xPosForWidthLabel,yPosForWidthLabel)];
//                [gameWorld.Blackboard.ComponentRenderLayer addChild:s.myWidth];
//            }
//            else
//            {
//                [s.myWidth setPosition:ccp(xPosForWidthLabel,yPosForWidthLabel)];
//                [s.myWidth setString:strWidth];
//            }
//        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        
        //GJ: these make no sense -- bool is never used
        //BOOL useAnimation = NO;
        //if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setPos];
    }

    
    if(messageType==kDWdismantle)
    {
        NSLog(@"count of shapes in shape group %d", [sg.shapesInMe count]);
        for(DWDotGridShapeGameObject *s in [NSArray arrayWithArray:sg.shapesInMe])
        {
            
            if(s.countBubble)
                [s.countBubble removeFromParentAndCleanup:YES];
            
            if(s.myHeight)
                [s.myHeight removeFromParentAndCleanup:YES];
            if(s.myWidth)
                [s.myWidth removeFromParentAndCleanup:YES];
            
            [sg.shapesInMe removeObject:s];
            [s handleMessage:kDWdismantle];
        }
        sg.firstAnchor=nil;
        sg.lastAnchor=nil;
        sg.countBubble=nil;
        
        [gameWorld delayRemoveGameObject:sg];

//        for(DWDotGridShapeGameObject *s in sg.shapesInMe)
//        {
//            if(s.myHeight)
//                [s.myHeight removeFromParentAndCleanup:YES];
//            if(s.myWidth)
//                [s.myWidth removeFromParentAndCleanup:YES];
//            
//            [s handleMessage:kDWdismantle];
//        }
//        
//        [sg.shapesInMe removeAllObjects];
//        
//        sg.firstAnchor=nil;
//        sg.lastAnchor=nil;
//        
//        [gameWorld delayRemoveGameObject:sg];
        
        //destroy own game object
    }
}



-(void)setSprite
{
    
    
}

-(void)setPos
{
    
    
}

@end
