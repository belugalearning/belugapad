//
//  SGFBlockOpBubble.m
//  belugapad
//
//  Created by David Amphlett on 04/09/2012.
//
//

#import "SGFBlockOpBubble.h"

#import "global.h"
#import "SimpleAudioEngine.h"

@implementation SGFBlockOpBubble

@synthesize MySprite, Position, RenderLayer, OperatorType, Replacement, Label, SupportedOperators, ChildOperators, zIndex;
// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"SGFBlockOpBubble"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.Position; }
-(SGFBlockOpBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andOperators:(NSArray*)theseOperators;
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
        self.SupportedOperators=theseOperators;
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
}

-(void)setup
{
    MySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/floating/op_bubble.png")];
    [MySprite setPosition:ccp(Position.x,-50)];
    [gameWorld.Blackboard.RenderLayer addChild:MySprite];
    
    
    NSString *str=nil;

    if([SupportedOperators count]==1)
    {
        float lblXPos=MySprite.contentSize.width/2;
        float lblYPos=MySprite.contentSize.height/2;
        str=[SupportedOperators objectAtIndex:0];
        Label=[CCLabelTTF labelWithString:str fontName:@"Chango" fontSize:40.0f];
        [Label setPosition:ccp(lblXPos,lblYPos)];
        [MySprite addChild:Label];
    }
    else if([SupportedOperators count]>1)
    {
       for(NSString *s in SupportedOperators)
       {
           NSLog(@"supported operator: %@", s);
       }
    }


    
    [MySprite runAction:[CCMoveTo actionWithDuration:0.4f position:Position]];
}

-(void)showOtherOperators
{
    if(!self.ChildOperators)
        self.ChildOperators=[[[NSMutableArray alloc]init] autorelease];
    
    if([self.ChildOperators count]==0)
    {
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_floating_block_general_multiple_operators_appearing.wav")];
        
        for(int i=0;i<[SupportedOperators count];i++)
        {
            CGPoint thisPos=CGPointZero;
            
            if([SupportedOperators count]==1)
            {
                thisPos=self.Position;
            }
            else if([SupportedOperators count]==2)
            {
                if(i==0)
                    thisPos=ccp(self.Position.x-75, self.Position.y+30);
                else if(i==1)
                    thisPos=ccp(self.Position.x+75, self.Position.y+30);
            }
            else if([SupportedOperators count]==3)
            {
                if(i==0)
                    thisPos=ccp(self.Position.x-75, self.Position.y+30);
                else if(i==1)
                    thisPos=ccp(self.Position.x+75, self.Position.y+30);
                else if(i==2)
                    thisPos=ccp(self.Position.x, self.Position.y+100);
            }
            else if([SupportedOperators count]==4)
            {
                if(i==0)
                    thisPos=ccp(self.Position.x-120, self.Position.y+20);
                else if(i==1)
                    thisPos=ccp(self.Position.x-45, self.Position.y+80);
                else if(i==2)
                    thisPos=ccp(self.Position.x+45, self.Position.y+80);
                else if(i==3)
                    thisPos=ccp(self.Position.x+120, self.Position.y+20);
            }
            NSArray *a=[NSArray arrayWithObject:[SupportedOperators objectAtIndex:i]];
            id<Operator,Rendered>op=[[[SGFBlockOpBubble alloc] initWithGameWorld:gameWorld andRenderLayer:gameWorld.Blackboard.RenderLayer andPosition:thisPos andOperators:a] autorelease];
            
            [self.ChildOperators addObject:op];
            
            [op setup];
        }
        
//        for(NSString *s in SupportedOperators)
//        {
//            NSArray *a=[NSArray arrayWithObject:s];
//            id<Operator,Rendered>op=[[[SGFBlockOpBubble alloc] initWithGameWorld:gameWorld andRenderLayer:gameWorld.Blackboard.RenderLayer andPosition:ccp(self.Position.x, self.Position.y-100+([SupportedOperators indexOfObject:s]*80)) andOperators:a] autorelease];
//            
//            [self.ChildOperators addObject:op];
//            
//            [op setup];
//        }
    }
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
    if([ChildOperators count]>0)
    {
        for (id<Operator,Rendered>thisOp in ChildOperators)
        {
            [thisOp fadeAndDestroy];
        }
    }
    
    
    
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

-(void)dealloc
{
    MySprite=nil;
    Label=nil;
    SupportedOperators=nil;
    ChildOperators=nil;
    self.logPollId=nil;
    if(logPollId)[logPollId release];
    logPollId=nil;
    [super dealloc];
}

@end
