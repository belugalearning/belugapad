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

-(void)setupDrawWithSize:(CGSize)size
{
    self.sprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/ot-bkg.png")];
    self.sprite.scaleX = size.width / BTXE_OTBKG_SPRITE_W;
    self.sprite.scaleY = size.height / BTXE_OTBKG_SPRITE_H;
}

-(void)updatePosition:(CGPoint)position
{
    self.sprite.position=position;
}

-(void)dealloc
{
    self.sprite=nil;
    
    [super dealloc];
}

@end
