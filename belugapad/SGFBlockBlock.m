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
@synthesize MySprite, RenderLayer, Replacement, zIndex;
// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"SGFBlockBlock"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }

-(SGFBlockBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
}

-(void)setup
{
    MySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/block.png")];
    [MySprite setPosition:Position];
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [MySprite setOpacity:0];
        [MySprite setTag:2];
    }
    
    [RenderLayer addChild:MySprite];
}

-(void)move
{
    [MySprite setPosition:Position];
}

-(void)fadeAndDestroy
{
    CCMoveTo *fadeAct=[CCFadeOut actionWithDuration:0.5f];
    CCAction *cleanUpSprite=[CCCallBlock actionWithBlock:^{[MySprite removeFromParentAndCleanup:YES];}];
    CCAction *cleanUpGO=[CCCallBlock actionWithBlock:^{[gameWorld delayRemoveGameObject:self];}];
    CCSequence *sequence=[CCSequence actions:fadeAct, cleanUpSprite, cleanUpGO, nil];
    [MySprite runAction:sequence];
    MyGroup=nil;
    MySprite=nil;
    
}

-(void)dealloc
{
    self.MyGroup=nil;
    self.MySprite=nil;
    self.logPollId=nil;
    if(logPollId)[logPollId release];
    logPollId=nil;
    [super dealloc];
}

@end
