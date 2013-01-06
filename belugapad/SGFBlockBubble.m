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

@synthesize MySprite, Position, RenderLayer, GroupsInMe, Replacement, zIndex;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"SGFblockBubble"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }

-(SGFBlockBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andReplacement:(BOOL)isReplacement
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.GroupsInMe=[[[NSMutableArray alloc]init]autorelease];
        self.Replacement=isReplacement;
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
}

-(void)setup
{
    MySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/bubble.png")];
    [MySprite setPosition:Position];
    [gameWorld.Blackboard.RenderLayer addChild:MySprite];
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [MySprite setOpacity:0];
        [MySprite setTag:2];
    }
    
    if(Replacement)
    {
        [MySprite runAction:[CCMoveTo actionWithDuration:0.75f position:ccp(Position.x,300)]];
    }
    
//    if(IsOperatorBubble)
//    {
//        NSString *str=nil;
//        if(OperatorType==1)
//            str=@"+";
//        else if(OperatorType==2)
//            str=@"x";
//            
//        [MySprite setScale:0.4f];
//        CCLabelTTF *lbl=[CCLabelTTF labelWithString:str fontName:@"Chango" fontSize:16.0f];
//        [MySprite addChild:lbl];
//    }
    
}

-(void)addGroup:(id)thisGroup
{
    if(![GroupsInMe containsObject:thisGroup])
    {
        [GroupsInMe addObject:thisGroup];
        NSLog(@"add group - count %d", [GroupsInMe count]);
    }
}

-(void)removeGroup:(id)thisGroup
{
    if([GroupsInMe containsObject:thisGroup])
    {
        [GroupsInMe removeObject:thisGroup];
        NSLog(@"remove group - count %d", [GroupsInMe count]);
    }
}

-(int)containedGroups
{
    return [GroupsInMe count];
}

-(void)fadeAndDestroy
{
    
    [GroupsInMe removeAllObjects];

//    [MySprite removeFromParentAndCleanup:YES];
    
//    [gameWorld delayRemoveGameObject:self];
    
    CCMoveTo *fadeAct=[CCFadeOut actionWithDuration:0.5f];
    CCAction *cleanUpSprite=[CCCallBlock actionWithBlock:^{[MySprite removeFromParentAndCleanup:YES];}];
    CCAction *cleanUpGO=[CCCallBlock actionWithBlock:^{[gameWorld delayRemoveGameObject:self];}];
    CCSequence *sequence=[CCSequence actions:fadeAct, cleanUpSprite, cleanUpGO, nil];
    [MySprite runAction:sequence];
    
}

-(void)dealloc
{
    RenderLayer=nil;
    MySprite=nil;
    GroupsInMe=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;
    
    [super dealloc];
}

@end
