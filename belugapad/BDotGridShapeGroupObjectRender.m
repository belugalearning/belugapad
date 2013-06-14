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
    NSLog(@"was messaged: %d", messageType);
    
    
    if(messageType==kDWsetupStuff)
    {

    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        
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
