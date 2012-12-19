//
//  SGJmapComingSoonNode.m
//  belugapad
//
//  Created by David Amphlett on 18/12/2012.
//
//

#import "SGJmapComingSoonNode.h"
#import "global.h"

@implementation SGJmapComingSoonNode

@synthesize Position, RenderBatch, RenderLayer;
@synthesize _id, UserVisibleString;

-(SGJmapComingSoonNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=nil;
        self.RenderLayer=aRenderLayer;
        Position=aPosition;
    }
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)handleMessage:(SGMessageType)messageType
{
    if(messageType==kSGretainOffsetPosition)
    {
        //positionAsOffset=[BLMath SubtractVector:ParentGO.Position from:ParentGO.MasteryNode.Position];
    }
    if(messageType==kSGresetPositionUsingOffset)
    {
        //ParentGO.Position=[BLMath AddVector:ParentGO.MasteryNode.Position toVector:positionAsOffset];
        //[self updatePosition:ParentGO.Position];
    }
}

-(void)setup
{
    int islandNo=arc4random()%3+1;
    
    NSString *spriteFileName=[NSString stringWithFormat:@"/images/jmap/ComingSoon_Island_%d.png", islandNo];
    
    CCSprite *nodeSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(spriteFileName)];
    [nodeSprite setPosition:self.Position];
    [nodeSprite setVisible:YES];
    [RenderLayer addChild:nodeSprite];
    
}

-(void)dealloc
{
    self.RenderLayer=nil;
    self._id=nil;
    self.UserVisibleString=nil;
    
    [super dealloc];
}

@end
