//
//  SGJmapPaperPlane.m
//  belugapad
//
//  Created by David Amphlett on 18/12/2012.
//
//

#import "SGJmapPaperPlane.h"
#import "global.h"
#import "BLMath.h"

@implementation SGJmapPaperPlane
@synthesize Position;
@synthesize RenderBatch;
@synthesize Visible;
@synthesize ProximityEvalComponent;
@synthesize PlaneType, planeSprite;
@synthesize RenderLayer;
@synthesize Destination;

-(SGJmapPaperPlane*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andDestination:(CGPoint) aDestination
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=nil;
        self.ProximityEvalComponent=nil;
        self.RenderLayer=aRenderLayer;
        Position=aPosition;
        self.Visible=NO;
        
        self.Destination=aDestination;
    }
    return self;
    
}


-(void)setup
{
    CGPoint path=[BLMath SubtractVector:self.Position from:self.Destination];
    float angle=[BLMath angleForVector:path];
    
    if(angle<22.5f) PlaneType=0;
    if(angle<67.5f) PlaneType=45;
    if(angle<112.5f) PlaneType=90;
    if(angle<157.5f) PlaneType=135;
    if(angle<202.5f) PlaneType=180;
    if(angle<247.5f) PlaneType=225;
    if(angle<292.5f) PlaneType=270;
    if(angle<337.5f) PlaneType=315;
    
    float remAngle=angle-PlaneType;
    if(angle>337.5f)remAngle=remAngle-360;
    
    NSString *spriteFileName=[NSString stringWithFormat:@"/images/jmap/planes/plane_%d.png",PlaneType];
    planeSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(spriteFileName)];
    [planeSprite setPosition:Position];
    planeSprite.rotation=remAngle;
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
