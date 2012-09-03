//
//  SGFBlockBubble.m
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import "SGFBlockBubble.h"
#import "global.h"

@implementation SGFBlockBubble

@synthesize MySprite, Position, RenderLayer, IsOperatorBubble, OperatorType;

-(SGFBlockBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
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
    MySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/bubble.png")];
    [MySprite setPosition:Position];
    [gameWorld.Blackboard.RenderLayer addChild:MySprite];
    
    if(IsOperatorBubble)
    {
        NSString *str=nil;
        if(OperatorType==1)
            str=@"+";
        else if(OperatorType==2)
            str=@"x";
            
        [MySprite setScale:0.4f];
        CCLabelTTF *lbl=[CCLabelTTF labelWithString:str fontName:@"Chango" fontSize:16.0f];
        [MySprite addChild:lbl];
    }
    
}

-(void)amIProximateTo:(id)thisObject
{
    
}

-(void)dealloc
{
    MySprite=nil;
    [super dealloc];
}

@end
