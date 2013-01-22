//
//  SGBtxeIconRender.m
//  belugapad
//
//  Created by gareth on 01/10/2012.
//
//

#import "SGBtxeIconRender.h"
#import "global.h"

@implementation SGBtxeIconRender

@synthesize sprite;
@synthesize assetType;

-(SGBtxeIconRender*)initWithGameObject:(id<Bounding, MovingInteractive, Icon>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        self.sprite=nil;
    }
    return self;
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    self.sprite.opacity=0;
    [self.sprite runAction:
     [CCSequence actions:
      [CCDelayTime actionWithDuration:startTime],
      [CCFadeTo actionWithDuration:0.2f opacity:255],
      nil]];
}

-(void)setupDraw
{
    if(!gameWorld.Blackboard.btxeIconBatch)
    {

        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/btxe/iconsets/goo_things.plist")];
        gameWorld.Blackboard.btxeIconBatch=[CCSpriteBatchNode batchNodeWithFile:BUNDLE_FULL_PATH(@"/images/btxe/iconsets/goo_things.png")];
        
        
        [gameWorld.Blackboard.RenderLayer addChild:gameWorld.Blackboard.btxeIconBatch];
    }
    
    NSString *sname=ParentGO.tag;
    if(![ParentGO.iconTag isEqualToString:@""]) sname=ParentGO.iconTag;
    
    sname=[sname stringByAppendingString:@".png"];
    
    self.sprite=[CCSprite spriteWithSpriteFrameName:sname];
    [gameWorld.Blackboard.btxeIconBatch addChild:sprite];
    self.sprite.position=ParentGO.position;
}

-(void)updatePosition:(CGPoint)position
{
    self.sprite.position=position;
    //NSLog(@"position at %@", NSStringFromCGPoint(position));
}

-(void)updatePositionWithAnimation:(CGPoint)position
{
    self.sprite.position=position;
    
    self.sprite.opacity=0;
    [self.sprite runAction:[CCSequence actions:[CCFadeIn actionWithDuration:0.7f], nil]];
    
//    [self.sprite runAction:[CCMoveTo actionWithDuration:0.25f position:position]];
    NSLog(@"position at %@", NSStringFromCGPoint(position));
}

-(void)inflateZindex
{
    sprite.zOrder=99;
}
-(void)deflateZindex
{
    sprite.zOrder=0;
}

-(void)dealloc
{
    self.sprite=nil;
    
    [super dealloc];
}

@end
