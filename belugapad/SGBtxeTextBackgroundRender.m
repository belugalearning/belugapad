//
//  SGBtxeTextBackgroundRender.m
//  belugapad
//
//  Created by gareth on 14/08/2012.
//
//

#import "SGBtxeTextBackgroundRender.h"
#import "global.h"

@implementation SGBtxeTextBackgroundRender

@synthesize sprite;

-(SGBtxeTextBackgroundRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        self.sprite=nil;
    }
    return self;
}

-(void)setColourOfBackgroundTo:(ccColor3B)thisColour
{
    [self.sprite setColor:thisColour];
}

-(void)setupDrawWithSize:(CGSize)size
{
    self.sprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Middle.png")];
    self.sprite.scaleX=size.width / self.sprite.contentSize.width;
    self.sprite.scaleY=size.height / self.sprite.contentSize.height;
    
    [self.sprite setPosition:ccp(0, -3)];
}

-(void)updatePosition:(CGPoint)position
{
    self.sprite.position=ccpAdd(position, ccp(0, -3));
}

-(void)dealloc
{
    self.sprite=nil;
    
    [super dealloc];
}

@end
