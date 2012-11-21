//
//  SGBtxeTextBackgroundRender.m
//  belugapad
//
//  Created by gareth on 14/08/2012.
//
//

#import "SGBtxeTextBackgroundRender.h"
#import "SGBtxePlaceholder.h"
#import "global.h"

@implementation SGBtxeTextBackgroundRender

@synthesize backgroundNode;

-(SGBtxeTextBackgroundRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        self.backgroundNode=nil;
    }
    return self;
}

-(void)setColourOfBackgroundTo:(ccColor3B)thisColour
{
    for(CCSprite *s in backgroundNode.children)
    {
        [s setColor:thisColour];
    }
}

-(void)setupDrawWithSize:(CGSize)size
{
    BOOL isPlaceholder=NO;
    backgroundNode=[[CCNode alloc]init];
    CCSprite *lh=nil;
    CCSprite *m=nil;
    CCSprite *rh=nil;
    
    if([(id<NSObject>)ParentGO isKindOfClass:[SGBtxePlaceholder class]])
        isPlaceholder=YES;
    
    if(isPlaceholder)
    {
        lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Left.png")];
        m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Middle.png")];
        rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Right.png")];
//        [rh setPosition:ccp(((m.contentSize.width)*m.scaleX)+(rh.contentSize.width)*2, 0)];
    }
    else
    {
        lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Left.png")];
        m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Middle.png")];
        rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Right.png")];
//        [rh setPosition:ccp(m.contentSize.width/2+(rh.contentSize.width/2), 0)];
    }
    
    m.scaleX=size.width / m.contentSize.width;
    m.scaleY=size.height / m.contentSize.height;
    
    lh.scaleY=size.height / m.contentSize.height;
    rh.scaleY=size.height / m.contentSize.height;
    
    [self.backgroundNode setPosition:ccp(0, -3)];
    [lh setPosition:ccp(-((m.contentSize.width/2)*m.scaleX)-(lh.contentSize.width/2),0)];
    [rh setPosition:ccp(((m.contentSize.width/2)*m.scaleX)+(rh.contentSize.width/2), 0)];

    [backgroundNode addChild:lh];
    [backgroundNode addChild:m];
    [backgroundNode addChild:rh];
    
//    backgroundNode=[[CCNode alloc]init];
//    CCSprite *lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Left.png")];
//    CCSprite *m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Middle.png")];
//    CCSprite *rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Right.png")];
//    
//    m.scaleX=size.width / m.contentSize.width;
//    m.scaleY=size.height / m.contentSize.height;
//    
//    lh.scaleY=size.height / m.contentSize.height;
//    rh.scaleY=size.height / m.contentSize.height;
//    
//    [self.backgroundNode setPosition:ccp(0, -3)];
//    [lh setPosition:ccp(-((m.contentSize.width/2)*m.scaleX)-(lh.contentSize.width/2),0)];
//    [rh setPosition:ccp(((m.contentSize.width/2)*m.scaleX)+(rh.contentSize.width/2), 0)];
//    [backgroundNode addChild:lh];
//    [backgroundNode addChild:m];
//    [backgroundNode addChild:rh];
}

-(void)updatePosition:(CGPoint)position
{
    self.backgroundNode.position=ccpAdd(position, ccp(0, -3));
}

-(void)dealloc
{
    self.backgroundNode=nil;
    
    [super dealloc];
}

@end
