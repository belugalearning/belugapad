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

@synthesize MySprite, Position, RenderLayer, IsOperatorBubble, OperatorType, GroupsInMe;

-(SGFBlockBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.GroupsInMe=[[NSMutableArray alloc]init];
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

-(void)dealloc
{
    MySprite=nil;
    GroupsInMe=nil;
    [super dealloc];
}

@end
