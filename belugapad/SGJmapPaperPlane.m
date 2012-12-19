//
//  SGJmapPaperPlane.m
//  belugapad
//
//  Created by David Amphlett on 18/12/2012.
//
//

#import "SGJmapPaperPlane.h"
#import "global.h"

@implementation SGJmapPaperPlane
@synthesize Position;
@synthesize RenderBatch;
@synthesize Visible;
@synthesize ProximityEvalComponent;
@synthesize PlaneType, planeSprite;
@synthesize RenderLayer;

-(SGJmapPaperPlane*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=nil;
        self.ProximityEvalComponent=nil;
        self.RenderLayer=aRenderLayer;
        Position=aPosition;
        self.Visible=NO;
    }
    return self;
    
}


-(void)setup
{
    NSString *spriteFileName=[NSString stringWithFormat:@"/images/jmap/planes/plane_%d.png",PlaneType];
    planeSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(spriteFileName)];
    [planeSprite setPosition:Position];
    [RenderLayer addChild:planeSprite];
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)draw:(int)z
{
    
}

-(BOOL)checkTouchOnMeAt:(CGPoint)location
{
    if(CGRectContainsPoint(planeSprite.boundingBox, [planeSprite convertToNodeSpace:location]))
    {
        [planeSprite runAction:[CCFadeOut actionWithDuration:2.0f]];
        return YES;
    }else{
        return NO;
    }
}

-(void)dealloc
{
    self.RenderLayer=nil;
    self.planeSprite=nil;
    [super dealloc];
}

@end
