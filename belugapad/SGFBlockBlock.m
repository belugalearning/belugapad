//
//  SGFBlockBlock.m
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import "SGFBlockBlock.h"
#import "global.h"

@implementation SGFBlockBlock

@synthesize Position, MyGroup;
@synthesize MySprite, RenderLayer;

-(SGFBlockBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
    }
    
    return self;
}

-(void)setup
{
    MySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/block.png")];
    [MySprite setPosition:Position];
    [RenderLayer addChild:MySprite];
}

-(void)move
{
    [MySprite setPosition:Position];
}

-(void)dealloc
{
    MyGroup=nil;
    MySprite=nil;
    [super dealloc];
}

@end
