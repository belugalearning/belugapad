//
//  SGFBlockOpBubble.m
//  belugapad
//
//  Created by David Amphlett on 04/09/2012.
//
//

#import "SGFBlockOpBubble.h"

#import "global.h"

@implementation SGFBlockOpBubble

@synthesize MySprite, Position, RenderLayer, OperatorType, Replacement, Label;

-(SGFBlockOpBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
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
    MySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/opbubble.png")];
    [MySprite setPosition:ccp(Position.x,-50)];
    [gameWorld.Blackboard.RenderLayer addChild:MySprite];
    
    
    NSString *str=nil;
    if(OperatorType==1)
        str=@"+";
    else if(OperatorType==2)
        str=@"x";

    float lblXPos=MySprite.contentSize.width/2;
    float lblYPos=MySprite.contentSize.height/2;
    
    Label=[CCLabelTTF labelWithString:str fontName:@"Chango" fontSize:40.0f];
    [Label setPosition:ccp(lblXPos,lblYPos)];
    [MySprite addChild:Label];
    
    [MySprite runAction:[CCMoveTo actionWithDuration:0.4f position:Position]];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    if(CGRectContainsPoint(MySprite.boundingBox, location))
    {
        return YES;
    }
    
    return NO;
}

-(void)fadeAndDestroy
{
    CCMoveTo *fadeAct=[CCFadeOut actionWithDuration:0.5f];
    CCAction *cleanUpSprite=[CCCallBlock actionWithBlock:^{[MySprite removeFromParentAndCleanup:YES];}];
    CCAction *cleanUpGO=[CCCallBlock actionWithBlock:^{[gameWorld delayRemoveGameObject:self];}];
    CCSequence *sequence=[CCSequence actions:fadeAct, cleanUpSprite, cleanUpGO, nil];
    [MySprite runAction:sequence];

    CCMoveTo *fadeActLabel=[CCFadeOut actionWithDuration:0.5f];
    CCAction *cleanUpSpriteLabel=[CCCallBlock actionWithBlock:^{[Label removeFromParentAndCleanup:YES];}];
    CCSequence *sequenceLabel=[CCSequence actions:fadeActLabel, cleanUpSpriteLabel, nil];
    [Label runAction:sequenceLabel];
    
    MySprite=nil;
}

@end
