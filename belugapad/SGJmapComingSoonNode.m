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
    
    NSString *labelText=UserVisibleString;
    
    CGPoint labelCentre=ccpAdd(ccp(75, -125), Position);
    CCLabelTTF *labelShadowSprite=[CCLabelTTF labelWithString:labelText fontName:@"Chango" fontSize:20.0f];
    [labelShadowSprite setPosition:ccpAdd(labelCentre, ccp(0, -3))];
    //[labelShadowSprite setRotation:[[islandData objectForKey:ISLAND_LABEL_ROT] floatValue]];
    [labelShadowSprite setColor:ccc3(0, 0, 0)];
    //    [labelShadowSprite setOpacity:0.2f*255];
    [labelShadowSprite setRotation:-8.0f];
    [labelShadowSprite setVisible:YES];
    
    [RenderLayer addChild:labelShadowSprite z:3];
    CCLabelTTF *labelSprite=[CCLabelTTF labelWithString:labelText fontName:@"Chango" fontSize:20.0f];
    [labelSprite setPosition:labelCentre];
    //[labelSprite setRotation:[[islandData objectForKey:ISLAND_LABEL_ROT] floatValue]];
    [labelSprite setVisible:YES];
    //    [labelSprite setOpacity:0.7f*255];
    [labelSprite setRotation:-8.0f];
    [RenderLayer addChild:labelSprite z:3];
    
    
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
