//
//  SGFBlockGroup.m
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import "SGFBlockGroup.h"
#import "BLMath.h"

@implementation SGFBlockGroup

@synthesize MyBlocks;
@synthesize MaxObjects;

-(SGFBlockGroup*) initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.MyBlocks=[[[NSMutableArray alloc]init]autorelease];
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
}

-(void)addObject:(id)thisObject
{
    if(![MyBlocks containsObject:thisObject])
    {
      if(MaxObjects>0 && [MyBlocks count]<MaxObjects)
          [MyBlocks addObject:thisObject];

      else if(MaxObjects==0)
          [MyBlocks addObject:thisObject];
        
        ((id<Moveable>)thisObject).MyGroup=self;

    }
}

-(void)removeObject:(id)thisObject
{
    if([MyBlocks containsObject:thisObject])
        [MyBlocks removeObject:thisObject];
    ((id<Moveable>)thisObject).MyGroup=nil;
}

-(BOOL)checkTouchInGroupAt:(CGPoint)location
{
    for(id<Rendered> block in MyBlocks)
    {
        CCSprite *s=block.MySprite;
        if(CGRectContainsPoint(s.boundingBox, location))
        {
            return YES;
        }
    }
    
    return NO;
}

-(void)inflateZIndexOfMyObjects
{
    for(id<Rendered,Moveable>block in MyBlocks)
    {
        NSLog(@"inflated from zIndex %d to 999", block.MySprite.zOrder);
        block.zIndex=[block.MySprite zOrder];
        [block.MySprite setZOrder:999];
    }
}

-(void)resetZIndexOfMyObjects
{
    for(id<Rendered,Moveable>block in MyBlocks)
    {
        [block.MySprite setZOrder:block.zIndex];
        NSLog(@"deflated from zIndex %d to %d", block.MySprite.zOrder, block.zIndex);
    }
}

-(void)moveGroupPositionFrom:(CGPoint)fromHere To:(CGPoint)here;
{
    for(id<Rendered,Moveable>block in MyBlocks)
    {
        CGPoint diff=[BLMath SubtractVector:fromHere from:here];
        
        //mod location by pickup offset
         
        float posX = block.Position.x + diff.x;
        float posY = block.Position.y + diff.y;
        
        block.Position=ccp(posX,posY);
        
        [block move];
    }
}

-(BOOL)checkIfInBubbleAt:(CGPoint)location
{
    for(id go in gameWorld.AllGameObjectsCopy)
    {
        if([go conformsToProtocol:@protocol(Target)])
        {
            id<Target,Rendered> thisBubble=(id<Target,Rendered>)go;
            CCSprite *s=thisBubble.MySprite;
            
            if(CGRectContainsPoint(s.boundingBox, location))
            {
                [thisBubble addGroup:self];
                [self tintBlocksTo:ccc3(0,255,0)];
                return YES;
            }
            else
            {
                [thisBubble removeGroup:self];
                [self tintBlocksTo:ccc3(255,255,255)];
            }
        }
    }
    return NO;
}

-(void)tintBlocksTo:(ccColor3B)thisColour
{
    for(id<Rendered>block in MyBlocks)
    {
        CCSprite *s=block.MySprite;
        [s setColor:thisColour];
    }
}

-(int)blocksInGroup
{
    return [MyBlocks count];
}

-(void)destroy
{
    if([self.MyBlocks count]==0)
        [gameWorld delayRemoveGameObject:self];
}

-(void)dealloc
{
    MyBlocks=nil;
    [super dealloc];
}


@end
